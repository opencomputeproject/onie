#
# Useful utilities.
#
#
# A simple class for accumulating counts or lists
#
class accumulator:
    def __init__(self):
        self._data = { }

    def incr(self, key, increment = 1):
        try:
            self._data[key] += increment
        except KeyError:
            self._data[key] = increment

    def get(self, key, default = None):
        try:
            return self._data[key]
        except KeyError:
            return default

    def append(self, key, item, unique = False):
        if unique and self._data.has_key(key) and \
           item in self._data[key]:
            return
        try:
            self._data[key].append(item)
        except KeyError:
            self._data[key] = [item]

    def keys(self):
        return self._data.keys()

    def __getitem__(self, key):
        return self._data[key]

