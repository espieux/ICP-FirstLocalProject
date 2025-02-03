import Nat8 "mo:base/Nat8";
import Debug "mo:base/Debug";
import Blob "mo:base/Blob";
import Nat "mo:base/Nat";
// The management canister's principal ID is "aaaaa-aa".
import IC "ic:aaaaa-aa";

actor {
  // Create a stable variable to store the current random number.
  // Stable variables persist across canister upgrades.
  stable var currentRandomNumber : Nat = 0;

  // Create a function to generate a new random number.
  // This function calls the raw_rand method of the management canister.
  // Then it uses the random bytes returned to generate a random number.
  private func generateNewNumber() : async () {
      let randomBytes = await IC.raw_rand();
      if (randomBytes.size() > 0) {
          // Use the first byte to generate a number between 0 and 255
          let bytes : [Nat8] = Blob.toArray(randomBytes);
          currentRandomNumber := Nat8.toNat(bytes[0]);
          Debug.print("Generated new random number: " # Nat.toText(currentRandomNumber));
      };
  };

  // Use a query call to get current random number.
  public query func getCurrentNumber() : async Nat {
      currentRandomNumber
  };

  public func init() : async () {
    await generateNewNumber();
  }
}