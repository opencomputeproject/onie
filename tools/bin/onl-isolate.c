/*
 * <bsn.cl fy=2011 v=onl>
 *
 *  Copyright 2011, 2012, 2013, 2014 Big Switch Networks, Inc.
 *
 * Licensed under the Eclipse Public License, Version 1.0 (the
 * "License"); you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at
 *
 *        http://www.eclipse.org/legal/epl-v10.html
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
 * either express or implied. See the License for the specific
 * language governing permissions and limitations under the
 * License.
 *
 * </bsn.cl>
 *
 *
 *
 * isolate: Run a command in a separate namespace, isolating network
 * and other system resources.
 *
 */

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <sched.h>
#include <sys/wait.h>
#include <unistd.h>
#include <syscall.h>
#include <string.h>
#include <grp.h>
#include <sys/param.h>
#include <getopt.h>
#include <fcntl.h>

int main(int argc, char *argv[])
{
    int help_flag = 0;
    int as_root_flag = 0;
    char *pre_script = "onl-isolate-pre";
    char *child_script = "onl-isolate-child";
    char *post_script = "onl-isolate-post";
    char *chroot_arg = NULL;
    char *chdir_arg = NULL;
    int pid;
    int pf[2];

    /* Creating a new namespace via clone() requires CAP_SYS_ADMIN privilege,
       so re-exec the process with sudo if we're not already root */
    if (getuid() != 0) {
        char *a[argc + 3];
        a[0] = "sudo";
        a[1] = "-E";
        memcpy(&a[2], argv, argc * sizeof(char *));
        a[argc + 2] = NULL;
        execvp("sudo", a);
        perror("sudo");
        return 1;
    }

    while (1) {
        static struct option long_options[] = {
            {"help", no_argument, NULL, 'h'
            },
            {"as-root", no_argument, NULL, 'r'
            },
            {"pre-script", required_argument, NULL, 'p'
            },
            {"child-script", required_argument, NULL, 'c'
            },
            {"post-script", required_argument, NULL, 't'
            },
            {"chroot", required_argument, NULL, 'o'
            },
            {"chdir", required_argument, NULL, 'd'
            },
            {0, 0, 0, 0
            }
        };
        int option_index = 0;
        int c = getopt_long(argc, argv, "+hrp:c:t:o:d:", long_options, &option_index);
        if (c == -1)
            break;
        switch (c) {
        case 0:
            break;
        case 'h':
            help_flag = 1;
            break;
        case 'r':
            as_root_flag = 1;
            break;
        case 'p':
            pre_script = optarg;
            break;
        case 'c':
            child_script = optarg;
            break;
        case 't':
            post_script = optarg;
            break;
        case 'o':
            chroot_arg = optarg;
            break;
        case 'd':
            chdir_arg = optarg;
            break;
        default:
            return 1;
        }
    }

    if (argc <= optind || help_flag) {
        printf("Usage: %s [OPTIONS] COMMAND\n\n", argv[0]);
        printf("  Run COMMAND in a separate namespace, isolating network and other\n");
        printf("  system resources.\n\n");
        printf("  Options:\n");
        printf("  -h|--help: Print this help message.\n");
        printf("  -p|--pre-script SCRIPT: Run SCRIPT in the parent process after\n");
        printf("         forking the child process.\n");
        printf("  -c|--child-script SCRIPT: Run SCRIPT in the child process before\n");
        printf("         executing the command.\n");
        printf("  -t|--post-script SCRIPT: Run SCRIPT in the parent process after\n");
        printf("         the child process terminates.\n");
        printf("  -r|--as-root: Run the command as root instead of SUDO_UID.\n");
        printf("  -o|--chroot DIR: Run command with root directory set to DIR.\n");
        printf("  -d|--chdir DIR: Change to DIR before running command.\n");
        return 1;
    }

    /* Create a pipe for the parent to tell child its pid */
    pipe(pf);

    /* Fork a child process with new namespaces */
    pid = syscall(SYS_clone, SIGCHLD | CLONE_NEWNET | CLONE_NEWPID | CLONE_NEWNS
                  | CLONE_NEWUTS | CLONE_NEWIPC, 0);
    if (pid < 0) {
        perror("clone");
        return 1;
    }
    if (pid == 0) {
        /* Child process */
        char *sudo_uid, *sudo_gid, *sudo_user = NULL;
        gid_t *sudo_groups = NULL;
        int sudo_ngroups = 0;
        int i;
        /* Reopen stdin/out/err if they are ttys (otherwise tcpdump uses
           buffered IO for some reason) */
        for (i = 0; i < 3; i++) {
            char *ttyn = ttyname(i);
            if (ttyn) {
                int ttyfd = open(ttyn, O_RDWR);
                close(i);
                dup2(ttyfd, i);
                close(ttyfd);
            }
        }
        close(pf[1]);
        /* Wait for the parent to tell us our pid */
        for (i = 0; i < (int) sizeof(pid); i++) {
            read(pf[0], ((char *) &pid) + i, 1);
        }
        close(pf[0]);
        signal(SIGINT, _exit);
        if (child_script) {
            /* Run the child setup script */
            char p[PATH_MAX];
            snprintf(p, sizeof(p), "%s %d", child_script, pid);
            system(p);
        }
        /* Figure out the pre-sudo user and group info before chrooting */
        sudo_uid = getenv("SUDO_UID");
        sudo_gid = getenv("SUDO_GID");
        sudo_user = getenv("SUDO_USER");
        if (sudo_user && sudo_gid) {
            gid_t gid = atoi(sudo_gid);
            getgrouplist(sudo_user, gid, NULL, &sudo_ngroups);
            if (sudo_ngroups > 0) {
                sudo_groups = malloc(sudo_ngroups * sizeof(gid_t));
                getgrouplist(sudo_user, gid, sudo_groups, &sudo_ngroups);
            }
        }
        if (chroot_arg)
            chroot(chroot_arg);
        if (chdir_arg)
            chdir(chdir_arg);
        if (!as_root_flag) {
            /* Reset user and group to their pre-sudo state */
            if (sudo_gid) {
                gid_t gid = atoi(sudo_gid);
                setgid(gid);
            }
            if (sudo_groups) {
                setgroups(sudo_ngroups, sudo_groups);
                free(sudo_groups);
            }
            if (sudo_uid) {
                uid_t uid = atoi(sudo_uid);
                setuid(uid);
            }
        }
        /* Exec the command */
        execvp(argv[optind], &argv[optind]);
        perror(argv[optind]);
    } else {
        /* Parent process */
        int status;
        signal(SIGINT, SIG_IGN);
        close(pf[0]);
        if (pre_script) {
            /* Run the parent setup script */
            char p[PATH_MAX];
            snprintf(p, sizeof(p), "%s %d", pre_script, pid);
            system(p);
        }
        /* Tell the child what its pid is */
        write(pf[1], &pid, sizeof(pid));
        close(pf[1]);
        /* Wait for the child to finish, and return its exit code */
        waitpid(pid, &status, 0);
        if (post_script) {
            /* Run the parent cleanup script */
            char p[PATH_MAX];
            snprintf(p, sizeof(p), "%s %d", post_script, pid);
            system(p);
        }
        if (WIFEXITED(status))
            return WEXITSTATUS(status);
    }
    return 1;
}
