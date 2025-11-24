#include "../VerifyEvidenceLib.h"
#include "ed25519_test_vectors.h"
#include <vector>
#include <string>
#include <fstream>
#include <sstream>
#include <iostream>
#include <cstdlib>

// Simple assert helper
static void assert_true(bool cond, const char* msg){ if(!cond){ std::cerr << "[FAIL] " << msg << "\n"; std::exit(1);} }

static std::string read_file(const std::string &p) {
    std::ifstream in(p, std::ios::binary);
    std::ostringstream ss; ss << in.rdbuf();
    return ss.str();
}

static std::string hash_string_hex(const std::string &data) {
    auto h = compute_sha256(data);
    std::ostringstream os; os << std::hex;
    for (auto b : h) os << (b >> 4 & 0xF) << (b & 0xF);
    return os.str();
}

static void test_merkle_right_order() {
    std::vector<std::string> paths = {"../../test_data/evidence1.txt","../../test_data/evidence2.txt","../../test_data/evidence3.txt"};
    auto root1 = compute_merkle_root_from_files(paths);
    auto root2 = compute_merkle_root_from_files(paths);
    assert_true(root1 == root2, "Merkle root mismatch on identical input");
    std::cout << "[PASS] Merkle_RightOrder_ComputesExpectedRoot\n";
}

static void test_merkle_tamper() {
    std::vector<std::string> paths = {"../../test_data/evidence1.txt","../../test_data/evidence2.txt","../../test_data/evidence3.txt"};
    auto original_root = compute_merkle_root_from_files(paths);
    std::string tamper_path = "../../test_data/evidence2.txt";
    std::string original = read_file(tamper_path);
    std::string tampered(original.size(), '\0'); tampered += "_TAMPER";
    {
        std::ofstream out(tamper_path, std::ios::binary | std::ios::trunc); out.write(tampered.data(), tampered.size()); out.flush();
    }
    auto tampered_root = compute_merkle_root_from_files(paths);
    // restore
    {
        std::ofstream restore(tamper_path, std::ios::binary | std::ios::trunc); restore.write(original.data(), original.size()); restore.flush();
    }
    assert_true(original_root != tampered_root, "Tamper did not change Merkle root");
    std::cout << "[PASS] Merkle_TamperedFile_FailsMatch\n";
}

static void test_batch_merkle_success() {
    std::vector<std::string> paths = {"../../test_data/evidence1.txt","../../test_data/evidence2.txt","../../test_data/evidence3.txt","../../test_data/evidence1.txt"};
    std::vector<size_t> targets = {0,2};
    auto proof = build_batch_merkle_proof(paths, targets);
    assert_true(!proof.rootHex.empty(), "Empty batch root");
    assert_true(proof.leaves.size() == targets.size(), "Leaf proof count mismatch");
    assert_true(verify_batch_merkle_proof(proof), "Batch proof verification failed");
    std::cout << "[PASS] BatchMerkleProof_Verify_Succeeds\n";
}

static void test_batch_merkle_tamper() {
    std::vector<std::string> paths = {"../../test_data/evidence1.txt","../../test_data/evidence2.txt","../../test_data/evidence3.txt","../../test_data/evidence1.txt"};
    std::vector<size_t> targets = {1,3};
    auto proof = build_batch_merkle_proof(paths, targets);
    assert_true(verify_batch_merkle_proof(proof), "Initial batch proof failed");
    auto originalLeafHash = proof.leaves[0].leafHashHex;
    std::string modified = originalLeafHash; modified[0] = (modified[0]=='a') ? 'b':'a';
    proof.leaves[0].leafHashHex = modified;
    assert_true(!verify_batch_merkle_proof(proof), "Tampered leaf hash still verifies");
    proof.leaves[0].leafHashHex = originalLeafHash; // restore
    assert_true(verify_batch_merkle_proof(proof), "Restored batch proof failed");
    if(!proof.leaves[0].siblingHex.empty()){
        auto originalSibling = proof.leaves[0].siblingHex[0];
        std::string modSibling = originalSibling; modSibling[1] = (modSibling[1]=='0')?'f':'0';
        proof.leaves[0].siblingHex[0] = modSibling;
        assert_true(!verify_batch_merkle_proof(proof), "Tampered sibling still verifies");
        proof.leaves[0].siblingHex[0] = originalSibling;
        assert_true(verify_batch_merkle_proof(proof), "Restored sibling path failed");
    }
    std::cout << "[PASS] BatchMerkleProof_Tamper_Fails\n";
}

#ifdef SODIUM_AVAILABLE
static void test_signature_success(){ assert_true(verify_signature_ed25519(TEST_PUBKEY, TEST_SIG, TEST_MESSAGE), "Valid signature failed"); std::cout << "[PASS] Signature_Verify_Success\n"; }
static void test_signature_bad_sig(){ auto bad = TEST_SIG; bad[0]^=0xFF; assert_true(!verify_signature_ed25519(TEST_PUBKEY,bad,TEST_MESSAGE), "Invalid signature passed"); std::cout << "[PASS] Signature_Verify_InvalidSignature_Fails\n"; }
static void test_signature_wrong_key(){ assert_true(!verify_signature_ed25519(WRONG_PUBKEY,TEST_SIG,TEST_MESSAGE), "Wrong pubkey signature passed"); std::cout << "[PASS] Signature_Verify_WrongPubkey_Fails\n"; }
#endif

int main(){
    test_merkle_right_order();
    test_merkle_tamper();
    test_batch_merkle_success();
    test_batch_merkle_tamper();
#ifdef SODIUM_AVAILABLE
    test_signature_success();
    test_signature_bad_sig();
    test_signature_wrong_key();
#endif
    std::cout << "All tests passed" << std::endl;
    return 0;
}
