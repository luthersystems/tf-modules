# Uniquely Identifying Names

Luther Style!

## Variables

### `max_length`

Optional. Maximum length for generated names. Default is `0` (no limit).

When set, the prefix portion of the name is truncated to fit within the limit
while always preserving the ID suffix for uniqueness. This is useful when
downstream modules append suffixes (e.g., `-exec`, `-role`) and the combined
name must stay within AWS service limits (64-char IAM roles, 50-char backup
rules, etc.).
