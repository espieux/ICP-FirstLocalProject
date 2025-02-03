import Nat8 "mo:base/Nat8";
import Debug "mo:base/Debug";
import Blob "mo:base/Blob";
import Nat "mo:base/Nat";
import Timer "mo:base/Timer";
import Cycles "mo:base/ExperimentalCycles";
import Text "mo:base/Text";
import Types "Types";
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
        currentRandomNumber;
    };

    // public func init() : async () {
    //   await generateNewNumber();
    // }

    // Initialize timer to generate a new number every 5 seconds
    let timer = Timer.recurringTimer(#seconds 5, generateNewNumber);

    // Define a public function to get the daily stats about ICP from the ICP API.
    public func getIcpInfo() : async Text {

        // Define the API endpoints to obtain data from.
        // This example uses the IC API, but any API endpoint can be used.
        let url = "https://ic-api.internetcomputer.org/api/v3/daily-stats?format=json";
        let transform_context : Types.TransformContext = {
            function = transform;
            context = Blob.fromArray([]);
        };

        // Define the http_request components.
        let http_request = {
            url = url;
            max_response_bytes = null; // Optional.
            headers = [];
            body = null; // Optional.
            method = #get;
            transform = ?transform_context;
        };

        // HTTP outcalls require cycles to be attached to the call.
        Cycles.add<system>(20_949_972_000);

        // Execute the HTTP outcall.
        let http_response = await IC.http_request(http_request);

        let response_body : Blob = http_response.body;
        switch (Text.decodeUtf8(response_body)) {
            case null { "No value returned" };
            case (?y) { y };
        };
    };

    // Define a transform function to return the status response and body.
    public query func transform(raw : Types.TransformArgs) : async IC.http_request_result {
        {
            status = raw.response.status;
            body = raw.response.body;
            headers = [];
        };
    };
};
