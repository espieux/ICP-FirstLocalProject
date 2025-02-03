import Timer "mo:base/Timer";
import Nat8 "mo:base/Nat8";
import Debug "mo:base/Debug";
import Blob "mo:base/Blob";
import Nat "mo:base/Nat";
import Cycles "mo:base/ExperimentalCycles";
import Text "mo:base/Text";
import Types "Types";

// The management canister's principal ID is "aaaaa-aa".
import IC "ic:aaaaa-aa";

actor {
    // Create a stable variable to store the current random number.
    // Stable variables persist across canister upgrades.
    stable var currentRandomNumber : Nat = 0;
    stable var proposalId : Text = "1";

    // Create a function to generate a new random number.
    // This function calls the raw_rand method of the management canister.
    // Then it uses the random bytes returned to generate a random number.
    private func generateNewNumber() : async () {
        let randomBytes = await IC.raw_rand();
        if (randomBytes.size() > 0) {
            // Use the first byte to generate a number between 133000 and 133255 (recent proposal numbers)
            let bytes : [Nat8] = Blob.toArray(randomBytes);
            currentRandomNumber := Nat8.toNat(bytes[0]) + 133000;
            proposalId := Nat.toText(currentRandomNumber);
        };
    };

    // Define a public function to get proposal information.
    public func getIcpInfo() : async Text {

        // Define the API endpoints to obtain data from.
        // This example uses the IC API, but any API endpoint can be used.
        let url = "https://ic-api.internetcomputer.org/api/v3/proposals/" # proposalId;
        let transform_context = {
            function = transform;
            context = Blob.fromArray([]);
        };

        // Define the http_request components.
        let http_request = {
            url = url;
            max_response_bytes = null; //optional for request
            headers = [];
            body = null; //optional for request
            method = #get;
            transform = ?transform_context;
        };

        // HTTP outcalls require cycles are attached to the call.
        Cycles.add<system>(20_949_972_000);

        // Execute the HTTPS outcall.
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

    private func printResults() : async () {
        Debug.print("Generated new random proposal number: " # Nat.toText(currentRandomNumber));
        let result : Text = await getIcpInfo();
        Debug.print("Proposal info obtained through HTTPS outcall: " # result);
    };

    // Initialize timer to generate new number every 30 seconds
    let timer1 = Timer.recurringTimer<system>(#seconds 30, generateNewNumber);
    // Initialize timer to send an HTTPS outcall and print the results every 32 seconds
    let timer2 = Timer.recurringTimer<system>(#seconds 32, printResults);
};
