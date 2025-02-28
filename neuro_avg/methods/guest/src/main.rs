#![no_main]                      // Entry point attribute for RISC Zero guest
use risc0_zkvm_guest::env;       // RISC Zero guest environment for I/O

risc0_zkvm_guest::entry!(main);

pub fn main() {
    // Read the private input (EEG data array) sent by the host.
    let eeg_data: Vec<u32> = env::read();  // The host will provide a vector of u32 readings

    // Compute the sum and average of the EEG readings.
    let sum: u64 = eeg_data.iter().map(|&x| x as u64).sum();
    let count = eeg_data.len() as u64;
    let avg: u64 = if count > 0 { sum / count } else { 0 };

    // Commit the average to the public journal (make it the proof’s output).
    env::commit(&avg);
}