// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module deepbook::math;

/// scaling setting for float
const FLOAT_SCALING: u64 = 1_000_000_000;
const FLOAT_SCALING_U128: u128 = 1_000_000_000;
const FLOAT_SCALING_U256: u256 = 1_000_000_000;

/// Error codes
const EInvalidPrecision: u64 = 0;

/// Multiply two floating numbers.
/// This function will round down the result.
public(package) fun mul(x: u64, y: u64): u64 {
    let (_, result) = mul_internal(x, y);

    result
}

public(package) fun mul_u128(x: u128, y: u128): u128 {
    let (_, result) = mul_internal_u128(x, y);

    result
}

/// Multiply two floating numbers.
/// This function will round up the result.
public(package) fun mul_round_up(x: u64, y: u64): u64 {
    let (is_round_down, result) = mul_internal(x, y);

    result + is_round_down
}

/// Divide two floating numbers.
/// This function will round down the result.
public(package) fun div(x: u64, y: u64): u64 {
    let (_, result) = div_internal(x, y);

    result
}

public(package) fun div_u128(x: u128, y: u128): u128 {
    let (_, result) = div_internal_u128(x, y);

    result
}

/// Divide two floating numbers.
/// This function will round up the result.
public(package) fun div_round_up(x: u64, y: u64): u64 {
    let (is_round_down, result) = div_internal(x, y);

    result + is_round_down
}

/// given a vector of u64, return the median
public(package) fun median(v: vector<u128>): u128 {
    let n = v.length();
    if (n == 0) {
        return 0
    };

    let sorted_v = quick_sort(v);
    if (n % 2 == 0) {
        mul_u128(
            (sorted_v[n / 2 - 1] + sorted_v[n / 2]),
            FLOAT_SCALING_U128 / 2,
        )
    } else {
        sorted_v[n / 2]
    }
}

/// Computes the integer square root of a scaled u64 value, assuming the
/// original value
/// is scaled by precision. The result will be in the same floating-point
/// representation.
public(package) fun sqrt(x: u64, precision: u64): u64 {
    assert!(precision <= FLOAT_SCALING, EInvalidPrecision);
    let multiplier = (FLOAT_SCALING / precision) as u128;
    let scaled_x: u128 = (x as u128) * multiplier * FLOAT_SCALING_U128;
    let sqrt_scaled_x: u128 = std::u128::sqrt(scaled_x);

    (sqrt_scaled_x / multiplier) as u64
}

public(package) fun is_power_of_ten(n: u64): bool {
    let mut num = n;

    if (num < 1) {
        false
    } else {
        while (num % 10 == 0) {
            num = num / 10;
        };

        num == 1
    }
}

fun quick_sort(data: vector<u128>): vector<u128> {
    if (data.length() <= 1) {
        return data
    };

    let pivot = data[0];
    let mut less = vector<u128>[];
    let mut equal = vector<u128>[];
    let mut greater = vector<u128>[];

    data.do!(|value| {
        if (value < pivot) {
            less.push_back(value);
        } else if (value == pivot) {
            equal.push_back(value);
        } else {
            greater.push_back(value);
        };
    });

    let mut sortedData = vector<u128>[];
    sortedData.append(quick_sort(less));
    sortedData.append(equal);
    sortedData.append(quick_sort(greater));
    sortedData
}

fun mul_internal(x: u64, y: u64): (u64, u64) {
    let x = x as u128;
    let y = y as u128;
    let round = if ((x * y) % FLOAT_SCALING_U128 == 0) 0 else 1;

    (round, (x * y / FLOAT_SCALING_U128) as u64)
}

fun mul_internal_u128(x: u128, y: u128): (u128, u128) {
    let x = x as u256;
    let y = y as u256;
    let round = if ((x * y) % FLOAT_SCALING_U256 == 0) 0 else 1;

    (round, (x * y / FLOAT_SCALING_U256) as u128)
}

fun div_internal(x: u64, y: u64): (u64, u64) {
    let x = x as u128;
    let y = y as u128;
    let round = if ((x * FLOAT_SCALING_U128 % y) == 0) 0 else 1;

    (round, (x * FLOAT_SCALING_U128 / y) as u64)
}

fun div_internal_u128(x: u128, y: u128): (u128, u128) {
    let x = x as u256;
    let y = y as u256;
    let round = if ((x * FLOAT_SCALING_U256 % y) == 0) 0 else 1;

    (round, (x * FLOAT_SCALING_U256 / y) as u128)
}

#[test]
/// Test median function
fun test_median() {
    let v = vector<u128>[
        1 * FLOAT_SCALING_U128,
        2 * FLOAT_SCALING_U128,
        3 * FLOAT_SCALING_U128,
        4 * FLOAT_SCALING_U128,
        5 * FLOAT_SCALING_U128,
    ];
    assert!(median(v) == 3 * FLOAT_SCALING_U128, 0);

    let v = vector<u128>[
        10 * FLOAT_SCALING_U128,
        15 * FLOAT_SCALING_U128,
        2 * FLOAT_SCALING_U128,
        3 * FLOAT_SCALING_U128,
        5 * FLOAT_SCALING_U128,
    ];
    assert!(median(v) == 5 * FLOAT_SCALING_U128, 0);

    let v = vector<u128>[
        10 * FLOAT_SCALING_U128,
        9 * FLOAT_SCALING_U128,
        23 * FLOAT_SCALING_U128,
        4 * FLOAT_SCALING_U128,
        5 * FLOAT_SCALING_U128,
        28 * FLOAT_SCALING_U128,
    ];
    assert!(median(v) == 9_500_000_000, 0);
}

#[test]
/// Test sqrt function
fun test_sqrt() {
    let scaling = 1_000_000;
    let precision_6 = 1_000_000;
    let precision_9 = 1_000_000_000;

    assert!(sqrt(0, precision_6) == 0, 0);
    assert!(sqrt(1 * scaling, precision_6) == 1 * scaling, 0);
    assert!(sqrt(2 * scaling, precision_6) == 1_414_213, 0);
    assert!(sqrt(25 * scaling, precision_6) == 5 * scaling, 0);
    assert!(sqrt(59 * scaling, precision_6) == 7_681_145, 0);
    assert!(sqrt(100_000 * scaling, precision_6) == 316_227_766, 0);
    assert!(sqrt(300_000 * scaling, precision_6) == 547_722_557, 0);
    assert!(sqrt(100_000_000, precision_6) == 10_000_000, 0);

    assert!(sqrt(0, precision_9) == 0, 0);
    assert!(sqrt(1_000 * scaling, precision_9) == 1_000 * scaling, 0);
    assert!(sqrt(2_000 * scaling, precision_9) == 1_414_213_562, 0);
    assert!(sqrt(2_250 * scaling, precision_9) == 1_500 * scaling, 0);
    assert!(sqrt(25_000 * scaling, precision_9) == 5_000 * scaling, 0);
    assert!(sqrt(59_000 * scaling, precision_9) == 7_681_145_747, 0);
    assert!(sqrt(100_000_000 * scaling, precision_9) == 316_227_766_016, 0);
    assert!(sqrt(300_000_000 * scaling, precision_9) == 547_722_557_505, 0);
    assert!(sqrt(100_000_000_000, precision_9) == 10_000_000_000, 0);
}

#[test]
/// Test is_power_of_ten function
fun test_is_power_of_ten() {
    assert!(is_power_of_ten(1), 0);
    assert!(is_power_of_ten(10), 0);
    assert!(is_power_of_ten(100), 0);
    assert!(is_power_of_ten(1000), 0);
    assert!(is_power_of_ten(10000), 0);
    assert!(is_power_of_ten(100000), 0);
    assert!(!is_power_of_ten(0), 0);
    assert!(!is_power_of_ten(2), 0);
    assert!(!is_power_of_ten(3), 0);
    assert!(!is_power_of_ten(20), 0);
    assert!(!is_power_of_ten(1001), 0);
}
