use risc0_zkvm::{Prover, Receipt};
use methods::{EEG_AVERAGE_GUEST_ELF, EEG_AVERAGE_GUEST_ID}; 
// ^^^ assume the project crate `methods` was generated to include the guest ELF path and image ID.

fn main() {
    // Example EEG data (private input). In practice, this could be loaded from a file or sensor.
    let eeg_data: Vec<u32> = vec![100, 102, 98, 105, 110, 95];
    
    // Initialize the RISC Zero prover with the compiled guest program.
    let mut prover = Prover::new(EEG_AVERAGE_GUEST_ELF, EEG_AVERAGE_GUEST_ID)
        .expect("Prover should be constructed");

    // Provide the EEG data to the guest program as input.
    prover.add_input_u32_slice(&eeg_data).expect("cannot send input to guest");

    // Run the guest program inside the zkVM to generate a proof (receipt).
    let receipt: Receipt = prover.run().expect("proving failed");

    // Extract the journal (public outputs) from the receipt.
    let journal = receipt.get_journal_vec();
    // Our guest committed a u64 average, which will be 8 bytes in little-endian in the journal.
    let avg_bytes: [u8; 8] = journal[0..8].try_into().expect("journal size incorrect");
    let computed_average = u64::from_le_bytes(avg_bytes);
    println!("Proof generated. EEG average = {}", computed_average);

    // Get the cryptographic proof (seal) from the receipt.
    let proof_bytes = receipt.get_seal_bytes();
    // In practice, we would now send `proof_bytes` and `computed_average` to the verifier (Gaia node or smart contract).
}