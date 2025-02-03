import IC "ic:aaaaa-aa";

module Types {

    // HTTPS outcalls have an optional "transform" key. These two types help describe it.
    // The transform function may transform the body in any way, add or remove headers, modify headers, etc.

    public type TransformArgs = {
        response : IC.http_request_result;
        context : Blob;
    };

    public type TransformContext = {
        function : shared query TransformArgs -> async IC.http_request_result;
        context : Blob;
    };

};
