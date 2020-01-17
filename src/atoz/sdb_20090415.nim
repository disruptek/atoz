
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon SimpleDB
## version: 2009-04-15
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon SimpleDB is a web service providing the core database functions of data indexing and querying in the cloud. By offloading the time and effort associated with building and operating a web-scale database, SimpleDB provides developers the freedom to focus on application development. <p> A traditional, clustered relational database requires a sizable upfront capital outlay, is complex to design, and often requires extensive and repetitive database administration. Amazon SimpleDB is dramatically simpler, requiring no schema, automatically indexing your data and providing a simple API for storage and access. This approach eliminates the administrative burden of data modeling, index maintenance, and performance tuning. Developers gain access to this functionality within Amazon's proven computing environment, are able to scale instantly, and pay only for what they use. </p> <p> Visit <a href="http://aws.amazon.com/simpledb/">http://aws.amazon.com/simpledb/</a> for more information. </p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/sdb/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_605573 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605573](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605573): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "sdb.ap-northeast-1.amazonaws.com", "ap-southeast-1": "sdb.ap-southeast-1.amazonaws.com",
                           "us-west-2": "sdb.us-west-2.amazonaws.com",
                           "eu-west-2": "sdb.eu-west-2.amazonaws.com", "ap-northeast-3": "sdb.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "sdb.eu-central-1.amazonaws.com",
                           "us-east-2": "sdb.us-east-2.amazonaws.com", "cn-northwest-1": "sdb.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "sdb.ap-south-1.amazonaws.com",
                           "eu-north-1": "sdb.eu-north-1.amazonaws.com", "ap-northeast-2": "sdb.ap-northeast-2.amazonaws.com",
                           "us-west-1": "sdb.us-west-1.amazonaws.com",
                           "us-gov-east-1": "sdb.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "sdb.eu-west-3.amazonaws.com",
                           "cn-north-1": "sdb.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "sdb.sa-east-1.amazonaws.com",
                           "eu-west-1": "sdb.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "sdb.us-gov-west-1.amazonaws.com", "ap-southeast-2": "sdb.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "sdb.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "sdb.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "sdb.ap-southeast-1.amazonaws.com",
      "us-west-2": "sdb.us-west-2.amazonaws.com",
      "eu-west-2": "sdb.eu-west-2.amazonaws.com",
      "ap-northeast-3": "sdb.ap-northeast-3.amazonaws.com",
      "eu-central-1": "sdb.eu-central-1.amazonaws.com",
      "us-east-2": "sdb.us-east-2.amazonaws.com",
      "cn-northwest-1": "sdb.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "sdb.ap-south-1.amazonaws.com",
      "eu-north-1": "sdb.eu-north-1.amazonaws.com",
      "ap-northeast-2": "sdb.ap-northeast-2.amazonaws.com",
      "us-west-1": "sdb.us-west-1.amazonaws.com",
      "us-gov-east-1": "sdb.us-gov-east-1.amazonaws.com",
      "eu-west-3": "sdb.eu-west-3.amazonaws.com",
      "cn-north-1": "sdb.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "sdb.sa-east-1.amazonaws.com",
      "eu-west-1": "sdb.eu-west-1.amazonaws.com",
      "us-gov-west-1": "sdb.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "sdb.ap-southeast-2.amazonaws.com",
      "ca-central-1": "sdb.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "sdb"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostBatchDeleteAttributes_606181 = ref object of OpenApiRestCall_605573
proc url_PostBatchDeleteAttributes_606183(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostBatchDeleteAttributes_606182(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_606184 = query.getOrDefault("Signature")
  valid_606184 = validateParameter(valid_606184, JString, required = true,
                                 default = nil)
  if valid_606184 != nil:
    section.add "Signature", valid_606184
  var valid_606185 = query.getOrDefault("AWSAccessKeyId")
  valid_606185 = validateParameter(valid_606185, JString, required = true,
                                 default = nil)
  if valid_606185 != nil:
    section.add "AWSAccessKeyId", valid_606185
  var valid_606186 = query.getOrDefault("SignatureMethod")
  valid_606186 = validateParameter(valid_606186, JString, required = true,
                                 default = nil)
  if valid_606186 != nil:
    section.add "SignatureMethod", valid_606186
  var valid_606187 = query.getOrDefault("Timestamp")
  valid_606187 = validateParameter(valid_606187, JString, required = true,
                                 default = nil)
  if valid_606187 != nil:
    section.add "Timestamp", valid_606187
  var valid_606188 = query.getOrDefault("Action")
  valid_606188 = validateParameter(valid_606188, JString, required = true,
                                 default = newJString("BatchDeleteAttributes"))
  if valid_606188 != nil:
    section.add "Action", valid_606188
  var valid_606189 = query.getOrDefault("Version")
  valid_606189 = validateParameter(valid_606189, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_606189 != nil:
    section.add "Version", valid_606189
  var valid_606190 = query.getOrDefault("SignatureVersion")
  valid_606190 = validateParameter(valid_606190, JString, required = true,
                                 default = nil)
  if valid_606190 != nil:
    section.add "SignatureVersion", valid_606190
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain in which the attributes are being deleted.
  ##   Items: JArray (required)
  ##        : A list of items on which to perform the operation.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606191 = formData.getOrDefault("DomainName")
  valid_606191 = validateParameter(valid_606191, JString, required = true,
                                 default = nil)
  if valid_606191 != nil:
    section.add "DomainName", valid_606191
  var valid_606192 = formData.getOrDefault("Items")
  valid_606192 = validateParameter(valid_606192, JArray, required = true, default = nil)
  if valid_606192 != nil:
    section.add "Items", valid_606192
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606193: Call_PostBatchDeleteAttributes_606181; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  let valid = call_606193.validator(path, query, header, formData, body)
  let scheme = call_606193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606193.url(scheme.get, call_606193.host, call_606193.base,
                         call_606193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606193, url, valid)

proc call*(call_606194: Call_PostBatchDeleteAttributes_606181; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; DomainName: string;
          Timestamp: string; Items: JsonNode; SignatureVersion: string;
          Action: string = "BatchDeleteAttributes"; Version: string = "2009-04-15"): Recallable =
  ## postBatchDeleteAttributes
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which the attributes are being deleted.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Items: JArray (required)
  ##        : A list of items on which to perform the operation.
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  var query_606195 = newJObject()
  var formData_606196 = newJObject()
  add(query_606195, "Signature", newJString(Signature))
  add(query_606195, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606195, "SignatureMethod", newJString(SignatureMethod))
  add(formData_606196, "DomainName", newJString(DomainName))
  add(query_606195, "Timestamp", newJString(Timestamp))
  add(query_606195, "Action", newJString(Action))
  if Items != nil:
    formData_606196.add "Items", Items
  add(query_606195, "Version", newJString(Version))
  add(query_606195, "SignatureVersion", newJString(SignatureVersion))
  result = call_606194.call(nil, query_606195, nil, formData_606196, nil)

var postBatchDeleteAttributes* = Call_PostBatchDeleteAttributes_606181(
    name: "postBatchDeleteAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=BatchDeleteAttributes",
    validator: validate_PostBatchDeleteAttributes_606182, base: "/",
    url: url_PostBatchDeleteAttributes_606183,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchDeleteAttributes_605911 = ref object of OpenApiRestCall_605573
proc url_GetBatchDeleteAttributes_605913(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBatchDeleteAttributes_605912(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   DomainName: JString (required)
  ##             : The name of the domain in which the attributes are being deleted.
  ##   Items: JArray (required)
  ##        : A list of items on which to perform the operation.
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_606025 = query.getOrDefault("Signature")
  valid_606025 = validateParameter(valid_606025, JString, required = true,
                                 default = nil)
  if valid_606025 != nil:
    section.add "Signature", valid_606025
  var valid_606026 = query.getOrDefault("AWSAccessKeyId")
  valid_606026 = validateParameter(valid_606026, JString, required = true,
                                 default = nil)
  if valid_606026 != nil:
    section.add "AWSAccessKeyId", valid_606026
  var valid_606027 = query.getOrDefault("SignatureMethod")
  valid_606027 = validateParameter(valid_606027, JString, required = true,
                                 default = nil)
  if valid_606027 != nil:
    section.add "SignatureMethod", valid_606027
  var valid_606028 = query.getOrDefault("DomainName")
  valid_606028 = validateParameter(valid_606028, JString, required = true,
                                 default = nil)
  if valid_606028 != nil:
    section.add "DomainName", valid_606028
  var valid_606029 = query.getOrDefault("Items")
  valid_606029 = validateParameter(valid_606029, JArray, required = true, default = nil)
  if valid_606029 != nil:
    section.add "Items", valid_606029
  var valid_606030 = query.getOrDefault("Timestamp")
  valid_606030 = validateParameter(valid_606030, JString, required = true,
                                 default = nil)
  if valid_606030 != nil:
    section.add "Timestamp", valid_606030
  var valid_606044 = query.getOrDefault("Action")
  valid_606044 = validateParameter(valid_606044, JString, required = true,
                                 default = newJString("BatchDeleteAttributes"))
  if valid_606044 != nil:
    section.add "Action", valid_606044
  var valid_606045 = query.getOrDefault("Version")
  valid_606045 = validateParameter(valid_606045, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_606045 != nil:
    section.add "Version", valid_606045
  var valid_606046 = query.getOrDefault("SignatureVersion")
  valid_606046 = validateParameter(valid_606046, JString, required = true,
                                 default = nil)
  if valid_606046 != nil:
    section.add "SignatureVersion", valid_606046
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606069: Call_GetBatchDeleteAttributes_605911; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  let valid = call_606069.validator(path, query, header, formData, body)
  let scheme = call_606069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606069.url(scheme.get, call_606069.host, call_606069.base,
                         call_606069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606069, url, valid)

proc call*(call_606140: Call_GetBatchDeleteAttributes_605911; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; DomainName: string;
          Items: JsonNode; Timestamp: string; SignatureVersion: string;
          Action: string = "BatchDeleteAttributes"; Version: string = "2009-04-15"): Recallable =
  ## getBatchDeleteAttributes
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which the attributes are being deleted.
  ##   Items: JArray (required)
  ##        : A list of items on which to perform the operation.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  var query_606141 = newJObject()
  add(query_606141, "Signature", newJString(Signature))
  add(query_606141, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606141, "SignatureMethod", newJString(SignatureMethod))
  add(query_606141, "DomainName", newJString(DomainName))
  if Items != nil:
    query_606141.add "Items", Items
  add(query_606141, "Timestamp", newJString(Timestamp))
  add(query_606141, "Action", newJString(Action))
  add(query_606141, "Version", newJString(Version))
  add(query_606141, "SignatureVersion", newJString(SignatureVersion))
  result = call_606140.call(nil, query_606141, nil, nil, nil)

var getBatchDeleteAttributes* = Call_GetBatchDeleteAttributes_605911(
    name: "getBatchDeleteAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=BatchDeleteAttributes",
    validator: validate_GetBatchDeleteAttributes_605912, base: "/",
    url: url_GetBatchDeleteAttributes_605913, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostBatchPutAttributes_606212 = ref object of OpenApiRestCall_605573
proc url_PostBatchPutAttributes_606214(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostBatchPutAttributes_606213(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_606215 = query.getOrDefault("Signature")
  valid_606215 = validateParameter(valid_606215, JString, required = true,
                                 default = nil)
  if valid_606215 != nil:
    section.add "Signature", valid_606215
  var valid_606216 = query.getOrDefault("AWSAccessKeyId")
  valid_606216 = validateParameter(valid_606216, JString, required = true,
                                 default = nil)
  if valid_606216 != nil:
    section.add "AWSAccessKeyId", valid_606216
  var valid_606217 = query.getOrDefault("SignatureMethod")
  valid_606217 = validateParameter(valid_606217, JString, required = true,
                                 default = nil)
  if valid_606217 != nil:
    section.add "SignatureMethod", valid_606217
  var valid_606218 = query.getOrDefault("Timestamp")
  valid_606218 = validateParameter(valid_606218, JString, required = true,
                                 default = nil)
  if valid_606218 != nil:
    section.add "Timestamp", valid_606218
  var valid_606219 = query.getOrDefault("Action")
  valid_606219 = validateParameter(valid_606219, JString, required = true,
                                 default = newJString("BatchPutAttributes"))
  if valid_606219 != nil:
    section.add "Action", valid_606219
  var valid_606220 = query.getOrDefault("Version")
  valid_606220 = validateParameter(valid_606220, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_606220 != nil:
    section.add "Version", valid_606220
  var valid_606221 = query.getOrDefault("SignatureVersion")
  valid_606221 = validateParameter(valid_606221, JString, required = true,
                                 default = nil)
  if valid_606221 != nil:
    section.add "SignatureVersion", valid_606221
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain in which the attributes are being stored.
  ##   Items: JArray (required)
  ##        : A list of items on which to perform the operation.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606222 = formData.getOrDefault("DomainName")
  valid_606222 = validateParameter(valid_606222, JString, required = true,
                                 default = nil)
  if valid_606222 != nil:
    section.add "DomainName", valid_606222
  var valid_606223 = formData.getOrDefault("Items")
  valid_606223 = validateParameter(valid_606223, JArray, required = true, default = nil)
  if valid_606223 != nil:
    section.add "Items", valid_606223
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606224: Call_PostBatchPutAttributes_606212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  let valid = call_606224.validator(path, query, header, formData, body)
  let scheme = call_606224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606224.url(scheme.get, call_606224.host, call_606224.base,
                         call_606224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606224, url, valid)

proc call*(call_606225: Call_PostBatchPutAttributes_606212; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; DomainName: string;
          Timestamp: string; Items: JsonNode; SignatureVersion: string;
          Action: string = "BatchPutAttributes"; Version: string = "2009-04-15"): Recallable =
  ## postBatchPutAttributes
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which the attributes are being stored.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Items: JArray (required)
  ##        : A list of items on which to perform the operation.
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  var query_606226 = newJObject()
  var formData_606227 = newJObject()
  add(query_606226, "Signature", newJString(Signature))
  add(query_606226, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606226, "SignatureMethod", newJString(SignatureMethod))
  add(formData_606227, "DomainName", newJString(DomainName))
  add(query_606226, "Timestamp", newJString(Timestamp))
  add(query_606226, "Action", newJString(Action))
  if Items != nil:
    formData_606227.add "Items", Items
  add(query_606226, "Version", newJString(Version))
  add(query_606226, "SignatureVersion", newJString(SignatureVersion))
  result = call_606225.call(nil, query_606226, nil, formData_606227, nil)

var postBatchPutAttributes* = Call_PostBatchPutAttributes_606212(
    name: "postBatchPutAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=BatchPutAttributes",
    validator: validate_PostBatchPutAttributes_606213, base: "/",
    url: url_PostBatchPutAttributes_606214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchPutAttributes_606197 = ref object of OpenApiRestCall_605573
proc url_GetBatchPutAttributes_606199(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBatchPutAttributes_606198(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   DomainName: JString (required)
  ##             : The name of the domain in which the attributes are being stored.
  ##   Items: JArray (required)
  ##        : A list of items on which to perform the operation.
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_606200 = query.getOrDefault("Signature")
  valid_606200 = validateParameter(valid_606200, JString, required = true,
                                 default = nil)
  if valid_606200 != nil:
    section.add "Signature", valid_606200
  var valid_606201 = query.getOrDefault("AWSAccessKeyId")
  valid_606201 = validateParameter(valid_606201, JString, required = true,
                                 default = nil)
  if valid_606201 != nil:
    section.add "AWSAccessKeyId", valid_606201
  var valid_606202 = query.getOrDefault("SignatureMethod")
  valid_606202 = validateParameter(valid_606202, JString, required = true,
                                 default = nil)
  if valid_606202 != nil:
    section.add "SignatureMethod", valid_606202
  var valid_606203 = query.getOrDefault("DomainName")
  valid_606203 = validateParameter(valid_606203, JString, required = true,
                                 default = nil)
  if valid_606203 != nil:
    section.add "DomainName", valid_606203
  var valid_606204 = query.getOrDefault("Items")
  valid_606204 = validateParameter(valid_606204, JArray, required = true, default = nil)
  if valid_606204 != nil:
    section.add "Items", valid_606204
  var valid_606205 = query.getOrDefault("Timestamp")
  valid_606205 = validateParameter(valid_606205, JString, required = true,
                                 default = nil)
  if valid_606205 != nil:
    section.add "Timestamp", valid_606205
  var valid_606206 = query.getOrDefault("Action")
  valid_606206 = validateParameter(valid_606206, JString, required = true,
                                 default = newJString("BatchPutAttributes"))
  if valid_606206 != nil:
    section.add "Action", valid_606206
  var valid_606207 = query.getOrDefault("Version")
  valid_606207 = validateParameter(valid_606207, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_606207 != nil:
    section.add "Version", valid_606207
  var valid_606208 = query.getOrDefault("SignatureVersion")
  valid_606208 = validateParameter(valid_606208, JString, required = true,
                                 default = nil)
  if valid_606208 != nil:
    section.add "SignatureVersion", valid_606208
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606209: Call_GetBatchPutAttributes_606197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  let valid = call_606209.validator(path, query, header, formData, body)
  let scheme = call_606209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606209.url(scheme.get, call_606209.host, call_606209.base,
                         call_606209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606209, url, valid)

proc call*(call_606210: Call_GetBatchPutAttributes_606197; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; DomainName: string;
          Items: JsonNode; Timestamp: string; SignatureVersion: string;
          Action: string = "BatchPutAttributes"; Version: string = "2009-04-15"): Recallable =
  ## getBatchPutAttributes
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which the attributes are being stored.
  ##   Items: JArray (required)
  ##        : A list of items on which to perform the operation.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  var query_606211 = newJObject()
  add(query_606211, "Signature", newJString(Signature))
  add(query_606211, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606211, "SignatureMethod", newJString(SignatureMethod))
  add(query_606211, "DomainName", newJString(DomainName))
  if Items != nil:
    query_606211.add "Items", Items
  add(query_606211, "Timestamp", newJString(Timestamp))
  add(query_606211, "Action", newJString(Action))
  add(query_606211, "Version", newJString(Version))
  add(query_606211, "SignatureVersion", newJString(SignatureVersion))
  result = call_606210.call(nil, query_606211, nil, nil, nil)

var getBatchPutAttributes* = Call_GetBatchPutAttributes_606197(
    name: "getBatchPutAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=BatchPutAttributes",
    validator: validate_GetBatchPutAttributes_606198, base: "/",
    url: url_GetBatchPutAttributes_606199, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDomain_606242 = ref object of OpenApiRestCall_605573
proc url_PostCreateDomain_606244(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDomain_606243(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_606245 = query.getOrDefault("Signature")
  valid_606245 = validateParameter(valid_606245, JString, required = true,
                                 default = nil)
  if valid_606245 != nil:
    section.add "Signature", valid_606245
  var valid_606246 = query.getOrDefault("AWSAccessKeyId")
  valid_606246 = validateParameter(valid_606246, JString, required = true,
                                 default = nil)
  if valid_606246 != nil:
    section.add "AWSAccessKeyId", valid_606246
  var valid_606247 = query.getOrDefault("SignatureMethod")
  valid_606247 = validateParameter(valid_606247, JString, required = true,
                                 default = nil)
  if valid_606247 != nil:
    section.add "SignatureMethod", valid_606247
  var valid_606248 = query.getOrDefault("Timestamp")
  valid_606248 = validateParameter(valid_606248, JString, required = true,
                                 default = nil)
  if valid_606248 != nil:
    section.add "Timestamp", valid_606248
  var valid_606249 = query.getOrDefault("Action")
  valid_606249 = validateParameter(valid_606249, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_606249 != nil:
    section.add "Action", valid_606249
  var valid_606250 = query.getOrDefault("Version")
  valid_606250 = validateParameter(valid_606250, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_606250 != nil:
    section.add "Version", valid_606250
  var valid_606251 = query.getOrDefault("SignatureVersion")
  valid_606251 = validateParameter(valid_606251, JString, required = true,
                                 default = nil)
  if valid_606251 != nil:
    section.add "SignatureVersion", valid_606251
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain to create. The name can range between 3 and 255 characters and can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606252 = formData.getOrDefault("DomainName")
  valid_606252 = validateParameter(valid_606252, JString, required = true,
                                 default = nil)
  if valid_606252 != nil:
    section.add "DomainName", valid_606252
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606253: Call_PostCreateDomain_606242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_PostCreateDomain_606242; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; DomainName: string;
          Timestamp: string; SignatureVersion: string;
          Action: string = "CreateDomain"; Version: string = "2009-04-15"): Recallable =
  ## postCreateDomain
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain to create. The name can range between 3 and 255 characters and can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  var query_606255 = newJObject()
  var formData_606256 = newJObject()
  add(query_606255, "Signature", newJString(Signature))
  add(query_606255, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606255, "SignatureMethod", newJString(SignatureMethod))
  add(formData_606256, "DomainName", newJString(DomainName))
  add(query_606255, "Timestamp", newJString(Timestamp))
  add(query_606255, "Action", newJString(Action))
  add(query_606255, "Version", newJString(Version))
  add(query_606255, "SignatureVersion", newJString(SignatureVersion))
  result = call_606254.call(nil, query_606255, nil, formData_606256, nil)

var postCreateDomain* = Call_PostCreateDomain_606242(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_606243,
    base: "/", url: url_PostCreateDomain_606244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_606228 = ref object of OpenApiRestCall_605573
proc url_GetCreateDomain_606230(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDomain_606229(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   DomainName: JString (required)
  ##             : The name of the domain to create. The name can range between 3 and 255 characters and can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'.
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_606231 = query.getOrDefault("Signature")
  valid_606231 = validateParameter(valid_606231, JString, required = true,
                                 default = nil)
  if valid_606231 != nil:
    section.add "Signature", valid_606231
  var valid_606232 = query.getOrDefault("AWSAccessKeyId")
  valid_606232 = validateParameter(valid_606232, JString, required = true,
                                 default = nil)
  if valid_606232 != nil:
    section.add "AWSAccessKeyId", valid_606232
  var valid_606233 = query.getOrDefault("SignatureMethod")
  valid_606233 = validateParameter(valid_606233, JString, required = true,
                                 default = nil)
  if valid_606233 != nil:
    section.add "SignatureMethod", valid_606233
  var valid_606234 = query.getOrDefault("DomainName")
  valid_606234 = validateParameter(valid_606234, JString, required = true,
                                 default = nil)
  if valid_606234 != nil:
    section.add "DomainName", valid_606234
  var valid_606235 = query.getOrDefault("Timestamp")
  valid_606235 = validateParameter(valid_606235, JString, required = true,
                                 default = nil)
  if valid_606235 != nil:
    section.add "Timestamp", valid_606235
  var valid_606236 = query.getOrDefault("Action")
  valid_606236 = validateParameter(valid_606236, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_606236 != nil:
    section.add "Action", valid_606236
  var valid_606237 = query.getOrDefault("Version")
  valid_606237 = validateParameter(valid_606237, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_606237 != nil:
    section.add "Version", valid_606237
  var valid_606238 = query.getOrDefault("SignatureVersion")
  valid_606238 = validateParameter(valid_606238, JString, required = true,
                                 default = nil)
  if valid_606238 != nil:
    section.add "SignatureVersion", valid_606238
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606239: Call_GetCreateDomain_606228; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  let valid = call_606239.validator(path, query, header, formData, body)
  let scheme = call_606239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606239.url(scheme.get, call_606239.host, call_606239.base,
                         call_606239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606239, url, valid)

proc call*(call_606240: Call_GetCreateDomain_606228; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; DomainName: string;
          Timestamp: string; SignatureVersion: string;
          Action: string = "CreateDomain"; Version: string = "2009-04-15"): Recallable =
  ## getCreateDomain
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain to create. The name can range between 3 and 255 characters and can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  var query_606241 = newJObject()
  add(query_606241, "Signature", newJString(Signature))
  add(query_606241, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606241, "SignatureMethod", newJString(SignatureMethod))
  add(query_606241, "DomainName", newJString(DomainName))
  add(query_606241, "Timestamp", newJString(Timestamp))
  add(query_606241, "Action", newJString(Action))
  add(query_606241, "Version", newJString(Version))
  add(query_606241, "SignatureVersion", newJString(SignatureVersion))
  result = call_606240.call(nil, query_606241, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_606228(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_606229,
    base: "/", url: url_GetCreateDomain_606230, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAttributes_606276 = ref object of OpenApiRestCall_605573
proc url_PostDeleteAttributes_606278(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteAttributes_606277(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_606279 = query.getOrDefault("Signature")
  valid_606279 = validateParameter(valid_606279, JString, required = true,
                                 default = nil)
  if valid_606279 != nil:
    section.add "Signature", valid_606279
  var valid_606280 = query.getOrDefault("AWSAccessKeyId")
  valid_606280 = validateParameter(valid_606280, JString, required = true,
                                 default = nil)
  if valid_606280 != nil:
    section.add "AWSAccessKeyId", valid_606280
  var valid_606281 = query.getOrDefault("SignatureMethod")
  valid_606281 = validateParameter(valid_606281, JString, required = true,
                                 default = nil)
  if valid_606281 != nil:
    section.add "SignatureMethod", valid_606281
  var valid_606282 = query.getOrDefault("Timestamp")
  valid_606282 = validateParameter(valid_606282, JString, required = true,
                                 default = nil)
  if valid_606282 != nil:
    section.add "Timestamp", valid_606282
  var valid_606283 = query.getOrDefault("Action")
  valid_606283 = validateParameter(valid_606283, JString, required = true,
                                 default = newJString("DeleteAttributes"))
  if valid_606283 != nil:
    section.add "Action", valid_606283
  var valid_606284 = query.getOrDefault("Version")
  valid_606284 = validateParameter(valid_606284, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_606284 != nil:
    section.add "Version", valid_606284
  var valid_606285 = query.getOrDefault("SignatureVersion")
  valid_606285 = validateParameter(valid_606285, JString, required = true,
                                 default = nil)
  if valid_606285 != nil:
    section.add "SignatureVersion", valid_606285
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   Expected.Value: JString
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   DomainName: JString (required)
  ##             : The name of the domain in which to perform the operation.
  ##   Attributes: JArray
  ##             : A list of Attributes. Similar to columns on a spreadsheet, attributes represent categories of data that can be assigned to items.
  ##   Expected.Name: JString
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  ##   Expected.Exists: JString
  ##                  :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   ItemName: JString (required)
  ##           : The name of the item. Similar to rows on a spreadsheet, items represent individual objects that contain one or more value-attribute pairs.
  section = newJObject()
  var valid_606286 = formData.getOrDefault("Expected.Value")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "Expected.Value", valid_606286
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606287 = formData.getOrDefault("DomainName")
  valid_606287 = validateParameter(valid_606287, JString, required = true,
                                 default = nil)
  if valid_606287 != nil:
    section.add "DomainName", valid_606287
  var valid_606288 = formData.getOrDefault("Attributes")
  valid_606288 = validateParameter(valid_606288, JArray, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "Attributes", valid_606288
  var valid_606289 = formData.getOrDefault("Expected.Name")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "Expected.Name", valid_606289
  var valid_606290 = formData.getOrDefault("Expected.Exists")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "Expected.Exists", valid_606290
  var valid_606291 = formData.getOrDefault("ItemName")
  valid_606291 = validateParameter(valid_606291, JString, required = true,
                                 default = nil)
  if valid_606291 != nil:
    section.add "ItemName", valid_606291
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606292: Call_PostDeleteAttributes_606276; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  let valid = call_606292.validator(path, query, header, formData, body)
  let scheme = call_606292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606292.url(scheme.get, call_606292.host, call_606292.base,
                         call_606292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606292, url, valid)

proc call*(call_606293: Call_PostDeleteAttributes_606276; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; DomainName: string;
          Timestamp: string; SignatureVersion: string; ItemName: string;
          ExpectedValue: string = ""; Attributes: JsonNode = nil;
          Action: string = "DeleteAttributes"; ExpectedName: string = "";
          Version: string = "2009-04-15"; ExpectedExists: string = ""): Recallable =
  ## postDeleteAttributes
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ##   ExpectedValue: string
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which to perform the operation.
  ##   Attributes: JArray
  ##             : A list of Attributes. Similar to columns on a spreadsheet, attributes represent categories of data that can be assigned to items.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   ExpectedName: string
  ##               :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  ##   Version: string (required)
  ##   ExpectedExists: string
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   SignatureVersion: string (required)
  ##   ItemName: string (required)
  ##           : The name of the item. Similar to rows on a spreadsheet, items represent individual objects that contain one or more value-attribute pairs.
  var query_606294 = newJObject()
  var formData_606295 = newJObject()
  add(formData_606295, "Expected.Value", newJString(ExpectedValue))
  add(query_606294, "Signature", newJString(Signature))
  add(query_606294, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606294, "SignatureMethod", newJString(SignatureMethod))
  add(formData_606295, "DomainName", newJString(DomainName))
  if Attributes != nil:
    formData_606295.add "Attributes", Attributes
  add(query_606294, "Timestamp", newJString(Timestamp))
  add(query_606294, "Action", newJString(Action))
  add(formData_606295, "Expected.Name", newJString(ExpectedName))
  add(query_606294, "Version", newJString(Version))
  add(formData_606295, "Expected.Exists", newJString(ExpectedExists))
  add(query_606294, "SignatureVersion", newJString(SignatureVersion))
  add(formData_606295, "ItemName", newJString(ItemName))
  result = call_606293.call(nil, query_606294, nil, formData_606295, nil)

var postDeleteAttributes* = Call_PostDeleteAttributes_606276(
    name: "postDeleteAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=DeleteAttributes",
    validator: validate_PostDeleteAttributes_606277, base: "/",
    url: url_PostDeleteAttributes_606278, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAttributes_606257 = ref object of OpenApiRestCall_605573
proc url_GetDeleteAttributes_606259(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteAttributes_606258(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Expected.Value: JString
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   SignatureMethod: JString (required)
  ##   DomainName: JString (required)
  ##             : The name of the domain in which to perform the operation.
  ##   Expected.Name: JString
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  ##   ItemName: JString (required)
  ##           : The name of the item. Similar to rows on a spreadsheet, items represent individual objects that contain one or more value-attribute pairs.
  ##   Expected.Exists: JString
  ##                  :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   Attributes: JArray
  ##             : A list of Attributes. Similar to columns on a spreadsheet, attributes represent categories of data that can be assigned to items.
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_606260 = query.getOrDefault("Signature")
  valid_606260 = validateParameter(valid_606260, JString, required = true,
                                 default = nil)
  if valid_606260 != nil:
    section.add "Signature", valid_606260
  var valid_606261 = query.getOrDefault("AWSAccessKeyId")
  valid_606261 = validateParameter(valid_606261, JString, required = true,
                                 default = nil)
  if valid_606261 != nil:
    section.add "AWSAccessKeyId", valid_606261
  var valid_606262 = query.getOrDefault("Expected.Value")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "Expected.Value", valid_606262
  var valid_606263 = query.getOrDefault("SignatureMethod")
  valid_606263 = validateParameter(valid_606263, JString, required = true,
                                 default = nil)
  if valid_606263 != nil:
    section.add "SignatureMethod", valid_606263
  var valid_606264 = query.getOrDefault("DomainName")
  valid_606264 = validateParameter(valid_606264, JString, required = true,
                                 default = nil)
  if valid_606264 != nil:
    section.add "DomainName", valid_606264
  var valid_606265 = query.getOrDefault("Expected.Name")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "Expected.Name", valid_606265
  var valid_606266 = query.getOrDefault("ItemName")
  valid_606266 = validateParameter(valid_606266, JString, required = true,
                                 default = nil)
  if valid_606266 != nil:
    section.add "ItemName", valid_606266
  var valid_606267 = query.getOrDefault("Expected.Exists")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "Expected.Exists", valid_606267
  var valid_606268 = query.getOrDefault("Attributes")
  valid_606268 = validateParameter(valid_606268, JArray, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "Attributes", valid_606268
  var valid_606269 = query.getOrDefault("Timestamp")
  valid_606269 = validateParameter(valid_606269, JString, required = true,
                                 default = nil)
  if valid_606269 != nil:
    section.add "Timestamp", valid_606269
  var valid_606270 = query.getOrDefault("Action")
  valid_606270 = validateParameter(valid_606270, JString, required = true,
                                 default = newJString("DeleteAttributes"))
  if valid_606270 != nil:
    section.add "Action", valid_606270
  var valid_606271 = query.getOrDefault("Version")
  valid_606271 = validateParameter(valid_606271, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_606271 != nil:
    section.add "Version", valid_606271
  var valid_606272 = query.getOrDefault("SignatureVersion")
  valid_606272 = validateParameter(valid_606272, JString, required = true,
                                 default = nil)
  if valid_606272 != nil:
    section.add "SignatureVersion", valid_606272
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606273: Call_GetDeleteAttributes_606257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  let valid = call_606273.validator(path, query, header, formData, body)
  let scheme = call_606273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606273.url(scheme.get, call_606273.host, call_606273.base,
                         call_606273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606273, url, valid)

proc call*(call_606274: Call_GetDeleteAttributes_606257; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; DomainName: string;
          ItemName: string; Timestamp: string; SignatureVersion: string;
          ExpectedValue: string = ""; ExpectedName: string = "";
          ExpectedExists: string = ""; Attributes: JsonNode = nil;
          Action: string = "DeleteAttributes"; Version: string = "2009-04-15"): Recallable =
  ## getDeleteAttributes
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   ExpectedValue: string
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which to perform the operation.
  ##   ExpectedName: string
  ##               :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  ##   ItemName: string (required)
  ##           : The name of the item. Similar to rows on a spreadsheet, items represent individual objects that contain one or more value-attribute pairs.
  ##   ExpectedExists: string
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   Attributes: JArray
  ##             : A list of Attributes. Similar to columns on a spreadsheet, attributes represent categories of data that can be assigned to items.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  var query_606275 = newJObject()
  add(query_606275, "Signature", newJString(Signature))
  add(query_606275, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606275, "Expected.Value", newJString(ExpectedValue))
  add(query_606275, "SignatureMethod", newJString(SignatureMethod))
  add(query_606275, "DomainName", newJString(DomainName))
  add(query_606275, "Expected.Name", newJString(ExpectedName))
  add(query_606275, "ItemName", newJString(ItemName))
  add(query_606275, "Expected.Exists", newJString(ExpectedExists))
  if Attributes != nil:
    query_606275.add "Attributes", Attributes
  add(query_606275, "Timestamp", newJString(Timestamp))
  add(query_606275, "Action", newJString(Action))
  add(query_606275, "Version", newJString(Version))
  add(query_606275, "SignatureVersion", newJString(SignatureVersion))
  result = call_606274.call(nil, query_606275, nil, nil, nil)

var getDeleteAttributes* = Call_GetDeleteAttributes_606257(
    name: "getDeleteAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=DeleteAttributes",
    validator: validate_GetDeleteAttributes_606258, base: "/",
    url: url_GetDeleteAttributes_606259, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_606310 = ref object of OpenApiRestCall_605573
proc url_PostDeleteDomain_606312(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDomain_606311(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_606313 = query.getOrDefault("Signature")
  valid_606313 = validateParameter(valid_606313, JString, required = true,
                                 default = nil)
  if valid_606313 != nil:
    section.add "Signature", valid_606313
  var valid_606314 = query.getOrDefault("AWSAccessKeyId")
  valid_606314 = validateParameter(valid_606314, JString, required = true,
                                 default = nil)
  if valid_606314 != nil:
    section.add "AWSAccessKeyId", valid_606314
  var valid_606315 = query.getOrDefault("SignatureMethod")
  valid_606315 = validateParameter(valid_606315, JString, required = true,
                                 default = nil)
  if valid_606315 != nil:
    section.add "SignatureMethod", valid_606315
  var valid_606316 = query.getOrDefault("Timestamp")
  valid_606316 = validateParameter(valid_606316, JString, required = true,
                                 default = nil)
  if valid_606316 != nil:
    section.add "Timestamp", valid_606316
  var valid_606317 = query.getOrDefault("Action")
  valid_606317 = validateParameter(valid_606317, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_606317 != nil:
    section.add "Action", valid_606317
  var valid_606318 = query.getOrDefault("Version")
  valid_606318 = validateParameter(valid_606318, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_606318 != nil:
    section.add "Version", valid_606318
  var valid_606319 = query.getOrDefault("SignatureVersion")
  valid_606319 = validateParameter(valid_606319, JString, required = true,
                                 default = nil)
  if valid_606319 != nil:
    section.add "SignatureVersion", valid_606319
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606320 = formData.getOrDefault("DomainName")
  valid_606320 = validateParameter(valid_606320, JString, required = true,
                                 default = nil)
  if valid_606320 != nil:
    section.add "DomainName", valid_606320
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606321: Call_PostDeleteDomain_606310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  let valid = call_606321.validator(path, query, header, formData, body)
  let scheme = call_606321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606321.url(scheme.get, call_606321.host, call_606321.base,
                         call_606321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606321, url, valid)

proc call*(call_606322: Call_PostDeleteDomain_606310; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; DomainName: string;
          Timestamp: string; SignatureVersion: string;
          Action: string = "DeleteDomain"; Version: string = "2009-04-15"): Recallable =
  ## postDeleteDomain
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain to delete.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  var query_606323 = newJObject()
  var formData_606324 = newJObject()
  add(query_606323, "Signature", newJString(Signature))
  add(query_606323, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606323, "SignatureMethod", newJString(SignatureMethod))
  add(formData_606324, "DomainName", newJString(DomainName))
  add(query_606323, "Timestamp", newJString(Timestamp))
  add(query_606323, "Action", newJString(Action))
  add(query_606323, "Version", newJString(Version))
  add(query_606323, "SignatureVersion", newJString(SignatureVersion))
  result = call_606322.call(nil, query_606323, nil, formData_606324, nil)

var postDeleteDomain* = Call_PostDeleteDomain_606310(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_606311,
    base: "/", url: url_PostDeleteDomain_606312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_606296 = ref object of OpenApiRestCall_605573
proc url_GetDeleteDomain_606298(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDomain_606297(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   DomainName: JString (required)
  ##             : The name of the domain to delete.
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_606299 = query.getOrDefault("Signature")
  valid_606299 = validateParameter(valid_606299, JString, required = true,
                                 default = nil)
  if valid_606299 != nil:
    section.add "Signature", valid_606299
  var valid_606300 = query.getOrDefault("AWSAccessKeyId")
  valid_606300 = validateParameter(valid_606300, JString, required = true,
                                 default = nil)
  if valid_606300 != nil:
    section.add "AWSAccessKeyId", valid_606300
  var valid_606301 = query.getOrDefault("SignatureMethod")
  valid_606301 = validateParameter(valid_606301, JString, required = true,
                                 default = nil)
  if valid_606301 != nil:
    section.add "SignatureMethod", valid_606301
  var valid_606302 = query.getOrDefault("DomainName")
  valid_606302 = validateParameter(valid_606302, JString, required = true,
                                 default = nil)
  if valid_606302 != nil:
    section.add "DomainName", valid_606302
  var valid_606303 = query.getOrDefault("Timestamp")
  valid_606303 = validateParameter(valid_606303, JString, required = true,
                                 default = nil)
  if valid_606303 != nil:
    section.add "Timestamp", valid_606303
  var valid_606304 = query.getOrDefault("Action")
  valid_606304 = validateParameter(valid_606304, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_606304 != nil:
    section.add "Action", valid_606304
  var valid_606305 = query.getOrDefault("Version")
  valid_606305 = validateParameter(valid_606305, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_606305 != nil:
    section.add "Version", valid_606305
  var valid_606306 = query.getOrDefault("SignatureVersion")
  valid_606306 = validateParameter(valid_606306, JString, required = true,
                                 default = nil)
  if valid_606306 != nil:
    section.add "SignatureVersion", valid_606306
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606307: Call_GetDeleteDomain_606296; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  let valid = call_606307.validator(path, query, header, formData, body)
  let scheme = call_606307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606307.url(scheme.get, call_606307.host, call_606307.base,
                         call_606307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606307, url, valid)

proc call*(call_606308: Call_GetDeleteDomain_606296; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; DomainName: string;
          Timestamp: string; SignatureVersion: string;
          Action: string = "DeleteDomain"; Version: string = "2009-04-15"): Recallable =
  ## getDeleteDomain
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain to delete.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  var query_606309 = newJObject()
  add(query_606309, "Signature", newJString(Signature))
  add(query_606309, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606309, "SignatureMethod", newJString(SignatureMethod))
  add(query_606309, "DomainName", newJString(DomainName))
  add(query_606309, "Timestamp", newJString(Timestamp))
  add(query_606309, "Action", newJString(Action))
  add(query_606309, "Version", newJString(Version))
  add(query_606309, "SignatureVersion", newJString(SignatureVersion))
  result = call_606308.call(nil, query_606309, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_606296(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_606297,
    base: "/", url: url_GetDeleteDomain_606298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDomainMetadata_606339 = ref object of OpenApiRestCall_605573
proc url_PostDomainMetadata_606341(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDomainMetadata_606340(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_606342 = query.getOrDefault("Signature")
  valid_606342 = validateParameter(valid_606342, JString, required = true,
                                 default = nil)
  if valid_606342 != nil:
    section.add "Signature", valid_606342
  var valid_606343 = query.getOrDefault("AWSAccessKeyId")
  valid_606343 = validateParameter(valid_606343, JString, required = true,
                                 default = nil)
  if valid_606343 != nil:
    section.add "AWSAccessKeyId", valid_606343
  var valid_606344 = query.getOrDefault("SignatureMethod")
  valid_606344 = validateParameter(valid_606344, JString, required = true,
                                 default = nil)
  if valid_606344 != nil:
    section.add "SignatureMethod", valid_606344
  var valid_606345 = query.getOrDefault("Timestamp")
  valid_606345 = validateParameter(valid_606345, JString, required = true,
                                 default = nil)
  if valid_606345 != nil:
    section.add "Timestamp", valid_606345
  var valid_606346 = query.getOrDefault("Action")
  valid_606346 = validateParameter(valid_606346, JString, required = true,
                                 default = newJString("DomainMetadata"))
  if valid_606346 != nil:
    section.add "Action", valid_606346
  var valid_606347 = query.getOrDefault("Version")
  valid_606347 = validateParameter(valid_606347, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_606347 != nil:
    section.add "Version", valid_606347
  var valid_606348 = query.getOrDefault("SignatureVersion")
  valid_606348 = validateParameter(valid_606348, JString, required = true,
                                 default = nil)
  if valid_606348 != nil:
    section.add "SignatureVersion", valid_606348
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain for which to display the metadata of.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606349 = formData.getOrDefault("DomainName")
  valid_606349 = validateParameter(valid_606349, JString, required = true,
                                 default = nil)
  if valid_606349 != nil:
    section.add "DomainName", valid_606349
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606350: Call_PostDomainMetadata_606339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  let valid = call_606350.validator(path, query, header, formData, body)
  let scheme = call_606350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606350.url(scheme.get, call_606350.host, call_606350.base,
                         call_606350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606350, url, valid)

proc call*(call_606351: Call_PostDomainMetadata_606339; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; DomainName: string;
          Timestamp: string; SignatureVersion: string;
          Action: string = "DomainMetadata"; Version: string = "2009-04-15"): Recallable =
  ## postDomainMetadata
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain for which to display the metadata of.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  var query_606352 = newJObject()
  var formData_606353 = newJObject()
  add(query_606352, "Signature", newJString(Signature))
  add(query_606352, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606352, "SignatureMethod", newJString(SignatureMethod))
  add(formData_606353, "DomainName", newJString(DomainName))
  add(query_606352, "Timestamp", newJString(Timestamp))
  add(query_606352, "Action", newJString(Action))
  add(query_606352, "Version", newJString(Version))
  add(query_606352, "SignatureVersion", newJString(SignatureVersion))
  result = call_606351.call(nil, query_606352, nil, formData_606353, nil)

var postDomainMetadata* = Call_PostDomainMetadata_606339(
    name: "postDomainMetadata", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=DomainMetadata",
    validator: validate_PostDomainMetadata_606340, base: "/",
    url: url_PostDomainMetadata_606341, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainMetadata_606325 = ref object of OpenApiRestCall_605573
proc url_GetDomainMetadata_606327(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDomainMetadata_606326(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   DomainName: JString (required)
  ##             : The name of the domain for which to display the metadata of.
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_606328 = query.getOrDefault("Signature")
  valid_606328 = validateParameter(valid_606328, JString, required = true,
                                 default = nil)
  if valid_606328 != nil:
    section.add "Signature", valid_606328
  var valid_606329 = query.getOrDefault("AWSAccessKeyId")
  valid_606329 = validateParameter(valid_606329, JString, required = true,
                                 default = nil)
  if valid_606329 != nil:
    section.add "AWSAccessKeyId", valid_606329
  var valid_606330 = query.getOrDefault("SignatureMethod")
  valid_606330 = validateParameter(valid_606330, JString, required = true,
                                 default = nil)
  if valid_606330 != nil:
    section.add "SignatureMethod", valid_606330
  var valid_606331 = query.getOrDefault("DomainName")
  valid_606331 = validateParameter(valid_606331, JString, required = true,
                                 default = nil)
  if valid_606331 != nil:
    section.add "DomainName", valid_606331
  var valid_606332 = query.getOrDefault("Timestamp")
  valid_606332 = validateParameter(valid_606332, JString, required = true,
                                 default = nil)
  if valid_606332 != nil:
    section.add "Timestamp", valid_606332
  var valid_606333 = query.getOrDefault("Action")
  valid_606333 = validateParameter(valid_606333, JString, required = true,
                                 default = newJString("DomainMetadata"))
  if valid_606333 != nil:
    section.add "Action", valid_606333
  var valid_606334 = query.getOrDefault("Version")
  valid_606334 = validateParameter(valid_606334, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_606334 != nil:
    section.add "Version", valid_606334
  var valid_606335 = query.getOrDefault("SignatureVersion")
  valid_606335 = validateParameter(valid_606335, JString, required = true,
                                 default = nil)
  if valid_606335 != nil:
    section.add "SignatureVersion", valid_606335
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606336: Call_GetDomainMetadata_606325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  let valid = call_606336.validator(path, query, header, formData, body)
  let scheme = call_606336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606336.url(scheme.get, call_606336.host, call_606336.base,
                         call_606336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606336, url, valid)

proc call*(call_606337: Call_GetDomainMetadata_606325; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; DomainName: string;
          Timestamp: string; SignatureVersion: string;
          Action: string = "DomainMetadata"; Version: string = "2009-04-15"): Recallable =
  ## getDomainMetadata
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain for which to display the metadata of.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  var query_606338 = newJObject()
  add(query_606338, "Signature", newJString(Signature))
  add(query_606338, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606338, "SignatureMethod", newJString(SignatureMethod))
  add(query_606338, "DomainName", newJString(DomainName))
  add(query_606338, "Timestamp", newJString(Timestamp))
  add(query_606338, "Action", newJString(Action))
  add(query_606338, "Version", newJString(Version))
  add(query_606338, "SignatureVersion", newJString(SignatureVersion))
  result = call_606337.call(nil, query_606338, nil, nil, nil)

var getDomainMetadata* = Call_GetDomainMetadata_606325(name: "getDomainMetadata",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=DomainMetadata", validator: validate_GetDomainMetadata_606326,
    base: "/", url: url_GetDomainMetadata_606327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetAttributes_606371 = ref object of OpenApiRestCall_605573
proc url_PostGetAttributes_606373(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetAttributes_606372(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_606374 = query.getOrDefault("Signature")
  valid_606374 = validateParameter(valid_606374, JString, required = true,
                                 default = nil)
  if valid_606374 != nil:
    section.add "Signature", valid_606374
  var valid_606375 = query.getOrDefault("AWSAccessKeyId")
  valid_606375 = validateParameter(valid_606375, JString, required = true,
                                 default = nil)
  if valid_606375 != nil:
    section.add "AWSAccessKeyId", valid_606375
  var valid_606376 = query.getOrDefault("SignatureMethod")
  valid_606376 = validateParameter(valid_606376, JString, required = true,
                                 default = nil)
  if valid_606376 != nil:
    section.add "SignatureMethod", valid_606376
  var valid_606377 = query.getOrDefault("Timestamp")
  valid_606377 = validateParameter(valid_606377, JString, required = true,
                                 default = nil)
  if valid_606377 != nil:
    section.add "Timestamp", valid_606377
  var valid_606378 = query.getOrDefault("Action")
  valid_606378 = validateParameter(valid_606378, JString, required = true,
                                 default = newJString("GetAttributes"))
  if valid_606378 != nil:
    section.add "Action", valid_606378
  var valid_606379 = query.getOrDefault("Version")
  valid_606379 = validateParameter(valid_606379, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_606379 != nil:
    section.add "Version", valid_606379
  var valid_606380 = query.getOrDefault("SignatureVersion")
  valid_606380 = validateParameter(valid_606380, JString, required = true,
                                 default = nil)
  if valid_606380 != nil:
    section.add "SignatureVersion", valid_606380
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   ConsistentRead: JBool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  ##   DomainName: JString (required)
  ##             : The name of the domain in which to perform the operation.
  ##   AttributeNames: JArray
  ##                 : The names of the attributes.
  ##   ItemName: JString (required)
  ##           : The name of the item.
  section = newJObject()
  var valid_606381 = formData.getOrDefault("ConsistentRead")
  valid_606381 = validateParameter(valid_606381, JBool, required = false, default = nil)
  if valid_606381 != nil:
    section.add "ConsistentRead", valid_606381
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606382 = formData.getOrDefault("DomainName")
  valid_606382 = validateParameter(valid_606382, JString, required = true,
                                 default = nil)
  if valid_606382 != nil:
    section.add "DomainName", valid_606382
  var valid_606383 = formData.getOrDefault("AttributeNames")
  valid_606383 = validateParameter(valid_606383, JArray, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "AttributeNames", valid_606383
  var valid_606384 = formData.getOrDefault("ItemName")
  valid_606384 = validateParameter(valid_606384, JString, required = true,
                                 default = nil)
  if valid_606384 != nil:
    section.add "ItemName", valid_606384
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606385: Call_PostGetAttributes_606371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  let valid = call_606385.validator(path, query, header, formData, body)
  let scheme = call_606385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606385.url(scheme.get, call_606385.host, call_606385.base,
                         call_606385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606385, url, valid)

proc call*(call_606386: Call_PostGetAttributes_606371; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; DomainName: string;
          Timestamp: string; SignatureVersion: string; ItemName: string;
          ConsistentRead: bool = false; AttributeNames: JsonNode = nil;
          Action: string = "GetAttributes"; Version: string = "2009-04-15"): Recallable =
  ## postGetAttributes
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   ConsistentRead: bool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  ##   DomainName: string (required)
  ##             : The name of the domain in which to perform the operation.
  ##   AttributeNames: JArray
  ##                 : The names of the attributes.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  ##   ItemName: string (required)
  ##           : The name of the item.
  var query_606387 = newJObject()
  var formData_606388 = newJObject()
  add(query_606387, "Signature", newJString(Signature))
  add(query_606387, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606387, "SignatureMethod", newJString(SignatureMethod))
  add(formData_606388, "ConsistentRead", newJBool(ConsistentRead))
  add(formData_606388, "DomainName", newJString(DomainName))
  if AttributeNames != nil:
    formData_606388.add "AttributeNames", AttributeNames
  add(query_606387, "Timestamp", newJString(Timestamp))
  add(query_606387, "Action", newJString(Action))
  add(query_606387, "Version", newJString(Version))
  add(query_606387, "SignatureVersion", newJString(SignatureVersion))
  add(formData_606388, "ItemName", newJString(ItemName))
  result = call_606386.call(nil, query_606387, nil, formData_606388, nil)

var postGetAttributes* = Call_PostGetAttributes_606371(name: "postGetAttributes",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=GetAttributes", validator: validate_PostGetAttributes_606372,
    base: "/", url: url_PostGetAttributes_606373,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetAttributes_606354 = ref object of OpenApiRestCall_605573
proc url_GetGetAttributes_606356(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetAttributes_606355(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   AttributeNames: JArray
  ##                 : The names of the attributes.
  ##   SignatureMethod: JString (required)
  ##   DomainName: JString (required)
  ##             : The name of the domain in which to perform the operation.
  ##   ItemName: JString (required)
  ##           : The name of the item.
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   ConsistentRead: JBool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_606357 = query.getOrDefault("Signature")
  valid_606357 = validateParameter(valid_606357, JString, required = true,
                                 default = nil)
  if valid_606357 != nil:
    section.add "Signature", valid_606357
  var valid_606358 = query.getOrDefault("AWSAccessKeyId")
  valid_606358 = validateParameter(valid_606358, JString, required = true,
                                 default = nil)
  if valid_606358 != nil:
    section.add "AWSAccessKeyId", valid_606358
  var valid_606359 = query.getOrDefault("AttributeNames")
  valid_606359 = validateParameter(valid_606359, JArray, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "AttributeNames", valid_606359
  var valid_606360 = query.getOrDefault("SignatureMethod")
  valid_606360 = validateParameter(valid_606360, JString, required = true,
                                 default = nil)
  if valid_606360 != nil:
    section.add "SignatureMethod", valid_606360
  var valid_606361 = query.getOrDefault("DomainName")
  valid_606361 = validateParameter(valid_606361, JString, required = true,
                                 default = nil)
  if valid_606361 != nil:
    section.add "DomainName", valid_606361
  var valid_606362 = query.getOrDefault("ItemName")
  valid_606362 = validateParameter(valid_606362, JString, required = true,
                                 default = nil)
  if valid_606362 != nil:
    section.add "ItemName", valid_606362
  var valid_606363 = query.getOrDefault("Timestamp")
  valid_606363 = validateParameter(valid_606363, JString, required = true,
                                 default = nil)
  if valid_606363 != nil:
    section.add "Timestamp", valid_606363
  var valid_606364 = query.getOrDefault("Action")
  valid_606364 = validateParameter(valid_606364, JString, required = true,
                                 default = newJString("GetAttributes"))
  if valid_606364 != nil:
    section.add "Action", valid_606364
  var valid_606365 = query.getOrDefault("ConsistentRead")
  valid_606365 = validateParameter(valid_606365, JBool, required = false, default = nil)
  if valid_606365 != nil:
    section.add "ConsistentRead", valid_606365
  var valid_606366 = query.getOrDefault("Version")
  valid_606366 = validateParameter(valid_606366, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_606366 != nil:
    section.add "Version", valid_606366
  var valid_606367 = query.getOrDefault("SignatureVersion")
  valid_606367 = validateParameter(valid_606367, JString, required = true,
                                 default = nil)
  if valid_606367 != nil:
    section.add "SignatureVersion", valid_606367
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606368: Call_GetGetAttributes_606354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  let valid = call_606368.validator(path, query, header, formData, body)
  let scheme = call_606368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606368.url(scheme.get, call_606368.host, call_606368.base,
                         call_606368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606368, url, valid)

proc call*(call_606369: Call_GetGetAttributes_606354; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; DomainName: string;
          ItemName: string; Timestamp: string; SignatureVersion: string;
          AttributeNames: JsonNode = nil; Action: string = "GetAttributes";
          ConsistentRead: bool = false; Version: string = "2009-04-15"): Recallable =
  ## getGetAttributes
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   AttributeNames: JArray
  ##                 : The names of the attributes.
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which to perform the operation.
  ##   ItemName: string (required)
  ##           : The name of the item.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   ConsistentRead: bool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  var query_606370 = newJObject()
  add(query_606370, "Signature", newJString(Signature))
  add(query_606370, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  if AttributeNames != nil:
    query_606370.add "AttributeNames", AttributeNames
  add(query_606370, "SignatureMethod", newJString(SignatureMethod))
  add(query_606370, "DomainName", newJString(DomainName))
  add(query_606370, "ItemName", newJString(ItemName))
  add(query_606370, "Timestamp", newJString(Timestamp))
  add(query_606370, "Action", newJString(Action))
  add(query_606370, "ConsistentRead", newJBool(ConsistentRead))
  add(query_606370, "Version", newJString(Version))
  add(query_606370, "SignatureVersion", newJString(SignatureVersion))
  result = call_606369.call(nil, query_606370, nil, nil, nil)

var getGetAttributes* = Call_GetGetAttributes_606354(name: "getGetAttributes",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=GetAttributes", validator: validate_GetGetAttributes_606355,
    base: "/", url: url_GetGetAttributes_606356,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDomains_606404 = ref object of OpenApiRestCall_605573
proc url_PostListDomains_606406(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListDomains_606405(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_606407 = query.getOrDefault("Signature")
  valid_606407 = validateParameter(valid_606407, JString, required = true,
                                 default = nil)
  if valid_606407 != nil:
    section.add "Signature", valid_606407
  var valid_606408 = query.getOrDefault("AWSAccessKeyId")
  valid_606408 = validateParameter(valid_606408, JString, required = true,
                                 default = nil)
  if valid_606408 != nil:
    section.add "AWSAccessKeyId", valid_606408
  var valid_606409 = query.getOrDefault("SignatureMethod")
  valid_606409 = validateParameter(valid_606409, JString, required = true,
                                 default = nil)
  if valid_606409 != nil:
    section.add "SignatureMethod", valid_606409
  var valid_606410 = query.getOrDefault("Timestamp")
  valid_606410 = validateParameter(valid_606410, JString, required = true,
                                 default = nil)
  if valid_606410 != nil:
    section.add "Timestamp", valid_606410
  var valid_606411 = query.getOrDefault("Action")
  valid_606411 = validateParameter(valid_606411, JString, required = true,
                                 default = newJString("ListDomains"))
  if valid_606411 != nil:
    section.add "Action", valid_606411
  var valid_606412 = query.getOrDefault("Version")
  valid_606412 = validateParameter(valid_606412, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_606412 != nil:
    section.add "Version", valid_606412
  var valid_606413 = query.getOrDefault("SignatureVersion")
  valid_606413 = validateParameter(valid_606413, JString, required = true,
                                 default = nil)
  if valid_606413 != nil:
    section.add "SignatureVersion", valid_606413
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : A string informing Amazon SimpleDB where to start the next list of domain names.
  ##   MaxNumberOfDomains: JInt
  ##                     : The maximum number of domain names you want returned. The range is 1 to 100. The default setting is 100.
  section = newJObject()
  var valid_606414 = formData.getOrDefault("NextToken")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "NextToken", valid_606414
  var valid_606415 = formData.getOrDefault("MaxNumberOfDomains")
  valid_606415 = validateParameter(valid_606415, JInt, required = false, default = nil)
  if valid_606415 != nil:
    section.add "MaxNumberOfDomains", valid_606415
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606416: Call_PostListDomains_606404; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  let valid = call_606416.validator(path, query, header, formData, body)
  let scheme = call_606416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606416.url(scheme.get, call_606416.host, call_606416.base,
                         call_606416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606416, url, valid)

proc call*(call_606417: Call_PostListDomains_606404; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; Timestamp: string;
          SignatureVersion: string; NextToken: string = "";
          MaxNumberOfDomains: int = 0; Action: string = "ListDomains";
          Version: string = "2009-04-15"): Recallable =
  ## postListDomains
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   NextToken: string
  ##            : A string informing Amazon SimpleDB where to start the next list of domain names.
  ##   SignatureMethod: string (required)
  ##   MaxNumberOfDomains: int
  ##                     : The maximum number of domain names you want returned. The range is 1 to 100. The default setting is 100.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  var query_606418 = newJObject()
  var formData_606419 = newJObject()
  add(query_606418, "Signature", newJString(Signature))
  add(query_606418, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_606419, "NextToken", newJString(NextToken))
  add(query_606418, "SignatureMethod", newJString(SignatureMethod))
  add(formData_606419, "MaxNumberOfDomains", newJInt(MaxNumberOfDomains))
  add(query_606418, "Timestamp", newJString(Timestamp))
  add(query_606418, "Action", newJString(Action))
  add(query_606418, "Version", newJString(Version))
  add(query_606418, "SignatureVersion", newJString(SignatureVersion))
  result = call_606417.call(nil, query_606418, nil, formData_606419, nil)

var postListDomains* = Call_PostListDomains_606404(name: "postListDomains",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=ListDomains", validator: validate_PostListDomains_606405,
    base: "/", url: url_PostListDomains_606406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDomains_606389 = ref object of OpenApiRestCall_605573
proc url_GetListDomains_606391(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListDomains_606390(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   NextToken: JString
  ##            : A string informing Amazon SimpleDB where to start the next list of domain names.
  ##   MaxNumberOfDomains: JInt
  ##                     : The maximum number of domain names you want returned. The range is 1 to 100. The default setting is 100.
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_606392 = query.getOrDefault("Signature")
  valid_606392 = validateParameter(valid_606392, JString, required = true,
                                 default = nil)
  if valid_606392 != nil:
    section.add "Signature", valid_606392
  var valid_606393 = query.getOrDefault("AWSAccessKeyId")
  valid_606393 = validateParameter(valid_606393, JString, required = true,
                                 default = nil)
  if valid_606393 != nil:
    section.add "AWSAccessKeyId", valid_606393
  var valid_606394 = query.getOrDefault("SignatureMethod")
  valid_606394 = validateParameter(valid_606394, JString, required = true,
                                 default = nil)
  if valid_606394 != nil:
    section.add "SignatureMethod", valid_606394
  var valid_606395 = query.getOrDefault("NextToken")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "NextToken", valid_606395
  var valid_606396 = query.getOrDefault("MaxNumberOfDomains")
  valid_606396 = validateParameter(valid_606396, JInt, required = false, default = nil)
  if valid_606396 != nil:
    section.add "MaxNumberOfDomains", valid_606396
  var valid_606397 = query.getOrDefault("Timestamp")
  valid_606397 = validateParameter(valid_606397, JString, required = true,
                                 default = nil)
  if valid_606397 != nil:
    section.add "Timestamp", valid_606397
  var valid_606398 = query.getOrDefault("Action")
  valid_606398 = validateParameter(valid_606398, JString, required = true,
                                 default = newJString("ListDomains"))
  if valid_606398 != nil:
    section.add "Action", valid_606398
  var valid_606399 = query.getOrDefault("Version")
  valid_606399 = validateParameter(valid_606399, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_606399 != nil:
    section.add "Version", valid_606399
  var valid_606400 = query.getOrDefault("SignatureVersion")
  valid_606400 = validateParameter(valid_606400, JString, required = true,
                                 default = nil)
  if valid_606400 != nil:
    section.add "SignatureVersion", valid_606400
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606401: Call_GetListDomains_606389; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  let valid = call_606401.validator(path, query, header, formData, body)
  let scheme = call_606401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606401.url(scheme.get, call_606401.host, call_606401.base,
                         call_606401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606401, url, valid)

proc call*(call_606402: Call_GetListDomains_606389; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; Timestamp: string;
          SignatureVersion: string; NextToken: string = "";
          MaxNumberOfDomains: int = 0; Action: string = "ListDomains";
          Version: string = "2009-04-15"): Recallable =
  ## getListDomains
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   NextToken: string
  ##            : A string informing Amazon SimpleDB where to start the next list of domain names.
  ##   MaxNumberOfDomains: int
  ##                     : The maximum number of domain names you want returned. The range is 1 to 100. The default setting is 100.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  var query_606403 = newJObject()
  add(query_606403, "Signature", newJString(Signature))
  add(query_606403, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606403, "SignatureMethod", newJString(SignatureMethod))
  add(query_606403, "NextToken", newJString(NextToken))
  add(query_606403, "MaxNumberOfDomains", newJInt(MaxNumberOfDomains))
  add(query_606403, "Timestamp", newJString(Timestamp))
  add(query_606403, "Action", newJString(Action))
  add(query_606403, "Version", newJString(Version))
  add(query_606403, "SignatureVersion", newJString(SignatureVersion))
  result = call_606402.call(nil, query_606403, nil, nil, nil)

var getListDomains* = Call_GetListDomains_606389(name: "getListDomains",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=ListDomains", validator: validate_GetListDomains_606390,
    base: "/", url: url_GetListDomains_606391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutAttributes_606439 = ref object of OpenApiRestCall_605573
proc url_PostPutAttributes_606441(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPutAttributes_606440(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_606442 = query.getOrDefault("Signature")
  valid_606442 = validateParameter(valid_606442, JString, required = true,
                                 default = nil)
  if valid_606442 != nil:
    section.add "Signature", valid_606442
  var valid_606443 = query.getOrDefault("AWSAccessKeyId")
  valid_606443 = validateParameter(valid_606443, JString, required = true,
                                 default = nil)
  if valid_606443 != nil:
    section.add "AWSAccessKeyId", valid_606443
  var valid_606444 = query.getOrDefault("SignatureMethod")
  valid_606444 = validateParameter(valid_606444, JString, required = true,
                                 default = nil)
  if valid_606444 != nil:
    section.add "SignatureMethod", valid_606444
  var valid_606445 = query.getOrDefault("Timestamp")
  valid_606445 = validateParameter(valid_606445, JString, required = true,
                                 default = nil)
  if valid_606445 != nil:
    section.add "Timestamp", valid_606445
  var valid_606446 = query.getOrDefault("Action")
  valid_606446 = validateParameter(valid_606446, JString, required = true,
                                 default = newJString("PutAttributes"))
  if valid_606446 != nil:
    section.add "Action", valid_606446
  var valid_606447 = query.getOrDefault("Version")
  valid_606447 = validateParameter(valid_606447, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_606447 != nil:
    section.add "Version", valid_606447
  var valid_606448 = query.getOrDefault("SignatureVersion")
  valid_606448 = validateParameter(valid_606448, JString, required = true,
                                 default = nil)
  if valid_606448 != nil:
    section.add "SignatureVersion", valid_606448
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   Expected.Value: JString
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   DomainName: JString (required)
  ##             : The name of the domain in which to perform the operation.
  ##   Attributes: JArray (required)
  ##             : The list of attributes.
  ##   Expected.Name: JString
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  ##   Expected.Exists: JString
  ##                  :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   ItemName: JString (required)
  ##           : The name of the item.
  section = newJObject()
  var valid_606449 = formData.getOrDefault("Expected.Value")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "Expected.Value", valid_606449
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606450 = formData.getOrDefault("DomainName")
  valid_606450 = validateParameter(valid_606450, JString, required = true,
                                 default = nil)
  if valid_606450 != nil:
    section.add "DomainName", valid_606450
  var valid_606451 = formData.getOrDefault("Attributes")
  valid_606451 = validateParameter(valid_606451, JArray, required = true, default = nil)
  if valid_606451 != nil:
    section.add "Attributes", valid_606451
  var valid_606452 = formData.getOrDefault("Expected.Name")
  valid_606452 = validateParameter(valid_606452, JString, required = false,
                                 default = nil)
  if valid_606452 != nil:
    section.add "Expected.Name", valid_606452
  var valid_606453 = formData.getOrDefault("Expected.Exists")
  valid_606453 = validateParameter(valid_606453, JString, required = false,
                                 default = nil)
  if valid_606453 != nil:
    section.add "Expected.Exists", valid_606453
  var valid_606454 = formData.getOrDefault("ItemName")
  valid_606454 = validateParameter(valid_606454, JString, required = true,
                                 default = nil)
  if valid_606454 != nil:
    section.add "ItemName", valid_606454
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606455: Call_PostPutAttributes_606439; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  let valid = call_606455.validator(path, query, header, formData, body)
  let scheme = call_606455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606455.url(scheme.get, call_606455.host, call_606455.base,
                         call_606455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606455, url, valid)

proc call*(call_606456: Call_PostPutAttributes_606439; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; DomainName: string;
          Attributes: JsonNode; Timestamp: string; SignatureVersion: string;
          ItemName: string; ExpectedValue: string = "";
          Action: string = "PutAttributes"; ExpectedName: string = "";
          Version: string = "2009-04-15"; ExpectedExists: string = ""): Recallable =
  ## postPutAttributes
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ##   ExpectedValue: string
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which to perform the operation.
  ##   Attributes: JArray (required)
  ##             : The list of attributes.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   ExpectedName: string
  ##               :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  ##   Version: string (required)
  ##   ExpectedExists: string
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   SignatureVersion: string (required)
  ##   ItemName: string (required)
  ##           : The name of the item.
  var query_606457 = newJObject()
  var formData_606458 = newJObject()
  add(formData_606458, "Expected.Value", newJString(ExpectedValue))
  add(query_606457, "Signature", newJString(Signature))
  add(query_606457, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606457, "SignatureMethod", newJString(SignatureMethod))
  add(formData_606458, "DomainName", newJString(DomainName))
  if Attributes != nil:
    formData_606458.add "Attributes", Attributes
  add(query_606457, "Timestamp", newJString(Timestamp))
  add(query_606457, "Action", newJString(Action))
  add(formData_606458, "Expected.Name", newJString(ExpectedName))
  add(query_606457, "Version", newJString(Version))
  add(formData_606458, "Expected.Exists", newJString(ExpectedExists))
  add(query_606457, "SignatureVersion", newJString(SignatureVersion))
  add(formData_606458, "ItemName", newJString(ItemName))
  result = call_606456.call(nil, query_606457, nil, formData_606458, nil)

var postPutAttributes* = Call_PostPutAttributes_606439(name: "postPutAttributes",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=PutAttributes", validator: validate_PostPutAttributes_606440,
    base: "/", url: url_PostPutAttributes_606441,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutAttributes_606420 = ref object of OpenApiRestCall_605573
proc url_GetPutAttributes_606422(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPutAttributes_606421(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Expected.Value: JString
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   SignatureMethod: JString (required)
  ##   DomainName: JString (required)
  ##             : The name of the domain in which to perform the operation.
  ##   Expected.Name: JString
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  ##   ItemName: JString (required)
  ##           : The name of the item.
  ##   Expected.Exists: JString
  ##                  :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   Attributes: JArray (required)
  ##             : The list of attributes.
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_606423 = query.getOrDefault("Signature")
  valid_606423 = validateParameter(valid_606423, JString, required = true,
                                 default = nil)
  if valid_606423 != nil:
    section.add "Signature", valid_606423
  var valid_606424 = query.getOrDefault("AWSAccessKeyId")
  valid_606424 = validateParameter(valid_606424, JString, required = true,
                                 default = nil)
  if valid_606424 != nil:
    section.add "AWSAccessKeyId", valid_606424
  var valid_606425 = query.getOrDefault("Expected.Value")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "Expected.Value", valid_606425
  var valid_606426 = query.getOrDefault("SignatureMethod")
  valid_606426 = validateParameter(valid_606426, JString, required = true,
                                 default = nil)
  if valid_606426 != nil:
    section.add "SignatureMethod", valid_606426
  var valid_606427 = query.getOrDefault("DomainName")
  valid_606427 = validateParameter(valid_606427, JString, required = true,
                                 default = nil)
  if valid_606427 != nil:
    section.add "DomainName", valid_606427
  var valid_606428 = query.getOrDefault("Expected.Name")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "Expected.Name", valid_606428
  var valid_606429 = query.getOrDefault("ItemName")
  valid_606429 = validateParameter(valid_606429, JString, required = true,
                                 default = nil)
  if valid_606429 != nil:
    section.add "ItemName", valid_606429
  var valid_606430 = query.getOrDefault("Expected.Exists")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "Expected.Exists", valid_606430
  var valid_606431 = query.getOrDefault("Attributes")
  valid_606431 = validateParameter(valid_606431, JArray, required = true, default = nil)
  if valid_606431 != nil:
    section.add "Attributes", valid_606431
  var valid_606432 = query.getOrDefault("Timestamp")
  valid_606432 = validateParameter(valid_606432, JString, required = true,
                                 default = nil)
  if valid_606432 != nil:
    section.add "Timestamp", valid_606432
  var valid_606433 = query.getOrDefault("Action")
  valid_606433 = validateParameter(valid_606433, JString, required = true,
                                 default = newJString("PutAttributes"))
  if valid_606433 != nil:
    section.add "Action", valid_606433
  var valid_606434 = query.getOrDefault("Version")
  valid_606434 = validateParameter(valid_606434, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_606434 != nil:
    section.add "Version", valid_606434
  var valid_606435 = query.getOrDefault("SignatureVersion")
  valid_606435 = validateParameter(valid_606435, JString, required = true,
                                 default = nil)
  if valid_606435 != nil:
    section.add "SignatureVersion", valid_606435
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606436: Call_GetPutAttributes_606420; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  let valid = call_606436.validator(path, query, header, formData, body)
  let scheme = call_606436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606436.url(scheme.get, call_606436.host, call_606436.base,
                         call_606436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606436, url, valid)

proc call*(call_606437: Call_GetPutAttributes_606420; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; DomainName: string;
          ItemName: string; Attributes: JsonNode; Timestamp: string;
          SignatureVersion: string; ExpectedValue: string = "";
          ExpectedName: string = ""; ExpectedExists: string = "";
          Action: string = "PutAttributes"; Version: string = "2009-04-15"): Recallable =
  ## getPutAttributes
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   ExpectedValue: string
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which to perform the operation.
  ##   ExpectedName: string
  ##               :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  ##   ItemName: string (required)
  ##           : The name of the item.
  ##   ExpectedExists: string
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   Attributes: JArray (required)
  ##             : The list of attributes.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  var query_606438 = newJObject()
  add(query_606438, "Signature", newJString(Signature))
  add(query_606438, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606438, "Expected.Value", newJString(ExpectedValue))
  add(query_606438, "SignatureMethod", newJString(SignatureMethod))
  add(query_606438, "DomainName", newJString(DomainName))
  add(query_606438, "Expected.Name", newJString(ExpectedName))
  add(query_606438, "ItemName", newJString(ItemName))
  add(query_606438, "Expected.Exists", newJString(ExpectedExists))
  if Attributes != nil:
    query_606438.add "Attributes", Attributes
  add(query_606438, "Timestamp", newJString(Timestamp))
  add(query_606438, "Action", newJString(Action))
  add(query_606438, "Version", newJString(Version))
  add(query_606438, "SignatureVersion", newJString(SignatureVersion))
  result = call_606437.call(nil, query_606438, nil, nil, nil)

var getPutAttributes* = Call_GetPutAttributes_606420(name: "getPutAttributes",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=PutAttributes", validator: validate_GetPutAttributes_606421,
    base: "/", url: url_GetPutAttributes_606422,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSelect_606475 = ref object of OpenApiRestCall_605573
proc url_PostSelect_606477(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSelect_606476(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_606478 = query.getOrDefault("Signature")
  valid_606478 = validateParameter(valid_606478, JString, required = true,
                                 default = nil)
  if valid_606478 != nil:
    section.add "Signature", valid_606478
  var valid_606479 = query.getOrDefault("AWSAccessKeyId")
  valid_606479 = validateParameter(valid_606479, JString, required = true,
                                 default = nil)
  if valid_606479 != nil:
    section.add "AWSAccessKeyId", valid_606479
  var valid_606480 = query.getOrDefault("SignatureMethod")
  valid_606480 = validateParameter(valid_606480, JString, required = true,
                                 default = nil)
  if valid_606480 != nil:
    section.add "SignatureMethod", valid_606480
  var valid_606481 = query.getOrDefault("Timestamp")
  valid_606481 = validateParameter(valid_606481, JString, required = true,
                                 default = nil)
  if valid_606481 != nil:
    section.add "Timestamp", valid_606481
  var valid_606482 = query.getOrDefault("Action")
  valid_606482 = validateParameter(valid_606482, JString, required = true,
                                 default = newJString("Select"))
  if valid_606482 != nil:
    section.add "Action", valid_606482
  var valid_606483 = query.getOrDefault("Version")
  valid_606483 = validateParameter(valid_606483, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_606483 != nil:
    section.add "Version", valid_606483
  var valid_606484 = query.getOrDefault("SignatureVersion")
  valid_606484 = validateParameter(valid_606484, JString, required = true,
                                 default = nil)
  if valid_606484 != nil:
    section.add "SignatureVersion", valid_606484
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : A string informing Amazon SimpleDB where to start the next list of <code>ItemNames</code>.
  ##   SelectExpression: JString (required)
  ##                   : The expression used to query the domain.
  ##   ConsistentRead: JBool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  section = newJObject()
  var valid_606485 = formData.getOrDefault("NextToken")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "NextToken", valid_606485
  assert formData != nil, "formData argument is necessary due to required `SelectExpression` field"
  var valid_606486 = formData.getOrDefault("SelectExpression")
  valid_606486 = validateParameter(valid_606486, JString, required = true,
                                 default = nil)
  if valid_606486 != nil:
    section.add "SelectExpression", valid_606486
  var valid_606487 = formData.getOrDefault("ConsistentRead")
  valid_606487 = validateParameter(valid_606487, JBool, required = false, default = nil)
  if valid_606487 != nil:
    section.add "ConsistentRead", valid_606487
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606488: Call_PostSelect_606475; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  let valid = call_606488.validator(path, query, header, formData, body)
  let scheme = call_606488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606488.url(scheme.get, call_606488.host, call_606488.base,
                         call_606488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606488, url, valid)

proc call*(call_606489: Call_PostSelect_606475; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; SelectExpression: string;
          Timestamp: string; SignatureVersion: string; NextToken: string = "";
          ConsistentRead: bool = false; Action: string = "Select";
          Version: string = "2009-04-15"): Recallable =
  ## postSelect
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   NextToken: string
  ##            : A string informing Amazon SimpleDB where to start the next list of <code>ItemNames</code>.
  ##   SignatureMethod: string (required)
  ##   SelectExpression: string (required)
  ##                   : The expression used to query the domain.
  ##   ConsistentRead: bool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  var query_606490 = newJObject()
  var formData_606491 = newJObject()
  add(query_606490, "Signature", newJString(Signature))
  add(query_606490, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_606491, "NextToken", newJString(NextToken))
  add(query_606490, "SignatureMethod", newJString(SignatureMethod))
  add(formData_606491, "SelectExpression", newJString(SelectExpression))
  add(formData_606491, "ConsistentRead", newJBool(ConsistentRead))
  add(query_606490, "Timestamp", newJString(Timestamp))
  add(query_606490, "Action", newJString(Action))
  add(query_606490, "Version", newJString(Version))
  add(query_606490, "SignatureVersion", newJString(SignatureVersion))
  result = call_606489.call(nil, query_606490, nil, formData_606491, nil)

var postSelect* = Call_PostSelect_606475(name: "postSelect",
                                      meth: HttpMethod.HttpPost,
                                      host: "sdb.amazonaws.com",
                                      route: "/#Action=Select",
                                      validator: validate_PostSelect_606476,
                                      base: "/", url: url_PostSelect_606477,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSelect_606459 = ref object of OpenApiRestCall_605573
proc url_GetSelect_606461(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSelect_606460(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   NextToken: JString
  ##            : A string informing Amazon SimpleDB where to start the next list of <code>ItemNames</code>.
  ##   SelectExpression: JString (required)
  ##                   : The expression used to query the domain.
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   ConsistentRead: JBool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_606462 = query.getOrDefault("Signature")
  valid_606462 = validateParameter(valid_606462, JString, required = true,
                                 default = nil)
  if valid_606462 != nil:
    section.add "Signature", valid_606462
  var valid_606463 = query.getOrDefault("AWSAccessKeyId")
  valid_606463 = validateParameter(valid_606463, JString, required = true,
                                 default = nil)
  if valid_606463 != nil:
    section.add "AWSAccessKeyId", valid_606463
  var valid_606464 = query.getOrDefault("SignatureMethod")
  valid_606464 = validateParameter(valid_606464, JString, required = true,
                                 default = nil)
  if valid_606464 != nil:
    section.add "SignatureMethod", valid_606464
  var valid_606465 = query.getOrDefault("NextToken")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "NextToken", valid_606465
  var valid_606466 = query.getOrDefault("SelectExpression")
  valid_606466 = validateParameter(valid_606466, JString, required = true,
                                 default = nil)
  if valid_606466 != nil:
    section.add "SelectExpression", valid_606466
  var valid_606467 = query.getOrDefault("Timestamp")
  valid_606467 = validateParameter(valid_606467, JString, required = true,
                                 default = nil)
  if valid_606467 != nil:
    section.add "Timestamp", valid_606467
  var valid_606468 = query.getOrDefault("Action")
  valid_606468 = validateParameter(valid_606468, JString, required = true,
                                 default = newJString("Select"))
  if valid_606468 != nil:
    section.add "Action", valid_606468
  var valid_606469 = query.getOrDefault("ConsistentRead")
  valid_606469 = validateParameter(valid_606469, JBool, required = false, default = nil)
  if valid_606469 != nil:
    section.add "ConsistentRead", valid_606469
  var valid_606470 = query.getOrDefault("Version")
  valid_606470 = validateParameter(valid_606470, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_606470 != nil:
    section.add "Version", valid_606470
  var valid_606471 = query.getOrDefault("SignatureVersion")
  valid_606471 = validateParameter(valid_606471, JString, required = true,
                                 default = nil)
  if valid_606471 != nil:
    section.add "SignatureVersion", valid_606471
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606472: Call_GetSelect_606459; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  let valid = call_606472.validator(path, query, header, formData, body)
  let scheme = call_606472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606472.url(scheme.get, call_606472.host, call_606472.base,
                         call_606472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606472, url, valid)

proc call*(call_606473: Call_GetSelect_606459; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; SelectExpression: string;
          Timestamp: string; SignatureVersion: string; NextToken: string = "";
          Action: string = "Select"; ConsistentRead: bool = false;
          Version: string = "2009-04-15"): Recallable =
  ## getSelect
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   NextToken: string
  ##            : A string informing Amazon SimpleDB where to start the next list of <code>ItemNames</code>.
  ##   SelectExpression: string (required)
  ##                   : The expression used to query the domain.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   ConsistentRead: bool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  var query_606474 = newJObject()
  add(query_606474, "Signature", newJString(Signature))
  add(query_606474, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606474, "SignatureMethod", newJString(SignatureMethod))
  add(query_606474, "NextToken", newJString(NextToken))
  add(query_606474, "SelectExpression", newJString(SelectExpression))
  add(query_606474, "Timestamp", newJString(Timestamp))
  add(query_606474, "Action", newJString(Action))
  add(query_606474, "ConsistentRead", newJBool(ConsistentRead))
  add(query_606474, "Version", newJString(Version))
  add(query_606474, "SignatureVersion", newJString(SignatureVersion))
  result = call_606473.call(nil, query_606474, nil, nil, nil)

var getSelect* = Call_GetSelect_606459(name: "getSelect", meth: HttpMethod.HttpGet,
                                    host: "sdb.amazonaws.com",
                                    route: "/#Action=Select",
                                    validator: validate_GetSelect_606460,
                                    base: "/", url: url_GetSelect_606461,
                                    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
