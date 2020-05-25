#importonce

.namespace LookupTables {
// Used when checking keyboard
number_key_to_row_bitmask:
    .byte %1110_1111  // 0 key, row 4
    .byte %0111_1111  // 1 key, row 7
    .byte %0111_1111  // 2 key, row 7
    .byte %1111_1101  // 3 key, row 1
    .byte %1111_1101  // 4 key, row 1
    .byte %1111_1011  // 5 key, row 2
number_key_to_column_bitmask:
    .byte %0000_1000  // 0 key, column 3
    .byte %0000_0001  // 1 key, column 0
    .byte %0000_1000  // 2 key, column 3
    .byte %0000_0001  // 3 key, column 0
    .byte %0000_1000  // 4 key, column 3
    .byte %0000_0001  // 5 key, column 0
}
