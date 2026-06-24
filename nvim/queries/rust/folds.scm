; extends
; Fold runs of consecutive line/doc comments, and multi-line block comments.
(line_comment)+ @fold
(block_comment) @fold
