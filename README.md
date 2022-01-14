# IO

Converts lines from stdin from one format to another.

Works great for combining `jq` with `mysql`

## Example

```bash
$ cat samples/test.tsv | io tsv json
{"a": "A", "b": "B"}
{"a": "AA", "b": "BB"}

$ cat samples/test.csv | io csv json
{"a": "A", "b": "B"}
{"a": "AA", "b": "BB"}

$ mysql ... -e "select user_id, name from user" | io tsv json
{"user_id": "1", "name": "A"}
{"user_id": "2", "name": "B"}

$ mysql ... -e "select user_id, name from user" | io tsv json | jq .name
"A"
"B"

$ mysql ... -e "select user_id, name from user" | io tsv json | jq '{id:.user_id, name}' | io json csv
"id", "name"
"1", "A"
"2", "B"
```

## Installation

`io` will need to be copied to `/usr/local/bin`. Either do so manually, or use `make install`.

```
$ sudo make install
cp io /usr/local/bin
chmod +x /usr/local/bin/io
```

## Supported Formats

| name | read | write | notes |
|---|---|---|---|
| csv | yes | yes | first line will be treated as headers for both read and write
| tsv | yes | yes | first line will be treated as headers for both read and write
| json | yes | yes |
| xml | no | no | 

