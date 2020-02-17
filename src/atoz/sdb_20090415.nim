
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

  OpenApiRestCall_610642 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610642](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610642): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
  Call_PostBatchDeleteAttributes_611250 = ref object of OpenApiRestCall_610642
proc url_PostBatchDeleteAttributes_611252(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostBatchDeleteAttributes_611251(path: JsonNode; query: JsonNode;
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
  var valid_611253 = query.getOrDefault("Signature")
  valid_611253 = validateParameter(valid_611253, JString, required = true,
                                 default = nil)
  if valid_611253 != nil:
    section.add "Signature", valid_611253
  var valid_611254 = query.getOrDefault("AWSAccessKeyId")
  valid_611254 = validateParameter(valid_611254, JString, required = true,
                                 default = nil)
  if valid_611254 != nil:
    section.add "AWSAccessKeyId", valid_611254
  var valid_611255 = query.getOrDefault("SignatureMethod")
  valid_611255 = validateParameter(valid_611255, JString, required = true,
                                 default = nil)
  if valid_611255 != nil:
    section.add "SignatureMethod", valid_611255
  var valid_611256 = query.getOrDefault("Timestamp")
  valid_611256 = validateParameter(valid_611256, JString, required = true,
                                 default = nil)
  if valid_611256 != nil:
    section.add "Timestamp", valid_611256
  var valid_611257 = query.getOrDefault("Action")
  valid_611257 = validateParameter(valid_611257, JString, required = true,
                                 default = newJString("BatchDeleteAttributes"))
  if valid_611257 != nil:
    section.add "Action", valid_611257
  var valid_611258 = query.getOrDefault("Version")
  valid_611258 = validateParameter(valid_611258, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_611258 != nil:
    section.add "Version", valid_611258
  var valid_611259 = query.getOrDefault("SignatureVersion")
  valid_611259 = validateParameter(valid_611259, JString, required = true,
                                 default = nil)
  if valid_611259 != nil:
    section.add "SignatureVersion", valid_611259
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
  var valid_611260 = formData.getOrDefault("DomainName")
  valid_611260 = validateParameter(valid_611260, JString, required = true,
                                 default = nil)
  if valid_611260 != nil:
    section.add "DomainName", valid_611260
  var valid_611261 = formData.getOrDefault("Items")
  valid_611261 = validateParameter(valid_611261, JArray, required = true, default = nil)
  if valid_611261 != nil:
    section.add "Items", valid_611261
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611262: Call_PostBatchDeleteAttributes_611250; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  let valid = call_611262.validator(path, query, header, formData, body)
  let scheme = call_611262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611262.url(scheme.get, call_611262.host, call_611262.base,
                         call_611262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611262, url, valid)

proc call*(call_611263: Call_PostBatchDeleteAttributes_611250; Signature: string;
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
  var query_611264 = newJObject()
  var formData_611265 = newJObject()
  add(query_611264, "Signature", newJString(Signature))
  add(query_611264, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611264, "SignatureMethod", newJString(SignatureMethod))
  add(formData_611265, "DomainName", newJString(DomainName))
  add(query_611264, "Timestamp", newJString(Timestamp))
  add(query_611264, "Action", newJString(Action))
  if Items != nil:
    formData_611265.add "Items", Items
  add(query_611264, "Version", newJString(Version))
  add(query_611264, "SignatureVersion", newJString(SignatureVersion))
  result = call_611263.call(nil, query_611264, nil, formData_611265, nil)

var postBatchDeleteAttributes* = Call_PostBatchDeleteAttributes_611250(
    name: "postBatchDeleteAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=BatchDeleteAttributes",
    validator: validate_PostBatchDeleteAttributes_611251, base: "/",
    url: url_PostBatchDeleteAttributes_611252,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchDeleteAttributes_610980 = ref object of OpenApiRestCall_610642
proc url_GetBatchDeleteAttributes_610982(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBatchDeleteAttributes_610981(path: JsonNode; query: JsonNode;
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
  var valid_611094 = query.getOrDefault("Signature")
  valid_611094 = validateParameter(valid_611094, JString, required = true,
                                 default = nil)
  if valid_611094 != nil:
    section.add "Signature", valid_611094
  var valid_611095 = query.getOrDefault("AWSAccessKeyId")
  valid_611095 = validateParameter(valid_611095, JString, required = true,
                                 default = nil)
  if valid_611095 != nil:
    section.add "AWSAccessKeyId", valid_611095
  var valid_611096 = query.getOrDefault("SignatureMethod")
  valid_611096 = validateParameter(valid_611096, JString, required = true,
                                 default = nil)
  if valid_611096 != nil:
    section.add "SignatureMethod", valid_611096
  var valid_611097 = query.getOrDefault("DomainName")
  valid_611097 = validateParameter(valid_611097, JString, required = true,
                                 default = nil)
  if valid_611097 != nil:
    section.add "DomainName", valid_611097
  var valid_611098 = query.getOrDefault("Items")
  valid_611098 = validateParameter(valid_611098, JArray, required = true, default = nil)
  if valid_611098 != nil:
    section.add "Items", valid_611098
  var valid_611099 = query.getOrDefault("Timestamp")
  valid_611099 = validateParameter(valid_611099, JString, required = true,
                                 default = nil)
  if valid_611099 != nil:
    section.add "Timestamp", valid_611099
  var valid_611113 = query.getOrDefault("Action")
  valid_611113 = validateParameter(valid_611113, JString, required = true,
                                 default = newJString("BatchDeleteAttributes"))
  if valid_611113 != nil:
    section.add "Action", valid_611113
  var valid_611114 = query.getOrDefault("Version")
  valid_611114 = validateParameter(valid_611114, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_611114 != nil:
    section.add "Version", valid_611114
  var valid_611115 = query.getOrDefault("SignatureVersion")
  valid_611115 = validateParameter(valid_611115, JString, required = true,
                                 default = nil)
  if valid_611115 != nil:
    section.add "SignatureVersion", valid_611115
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611138: Call_GetBatchDeleteAttributes_610980; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  let valid = call_611138.validator(path, query, header, formData, body)
  let scheme = call_611138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611138.url(scheme.get, call_611138.host, call_611138.base,
                         call_611138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611138, url, valid)

proc call*(call_611209: Call_GetBatchDeleteAttributes_610980; Signature: string;
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
  var query_611210 = newJObject()
  add(query_611210, "Signature", newJString(Signature))
  add(query_611210, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611210, "SignatureMethod", newJString(SignatureMethod))
  add(query_611210, "DomainName", newJString(DomainName))
  if Items != nil:
    query_611210.add "Items", Items
  add(query_611210, "Timestamp", newJString(Timestamp))
  add(query_611210, "Action", newJString(Action))
  add(query_611210, "Version", newJString(Version))
  add(query_611210, "SignatureVersion", newJString(SignatureVersion))
  result = call_611209.call(nil, query_611210, nil, nil, nil)

var getBatchDeleteAttributes* = Call_GetBatchDeleteAttributes_610980(
    name: "getBatchDeleteAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=BatchDeleteAttributes",
    validator: validate_GetBatchDeleteAttributes_610981, base: "/",
    url: url_GetBatchDeleteAttributes_610982, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostBatchPutAttributes_611281 = ref object of OpenApiRestCall_610642
proc url_PostBatchPutAttributes_611283(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostBatchPutAttributes_611282(path: JsonNode; query: JsonNode;
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
  var valid_611284 = query.getOrDefault("Signature")
  valid_611284 = validateParameter(valid_611284, JString, required = true,
                                 default = nil)
  if valid_611284 != nil:
    section.add "Signature", valid_611284
  var valid_611285 = query.getOrDefault("AWSAccessKeyId")
  valid_611285 = validateParameter(valid_611285, JString, required = true,
                                 default = nil)
  if valid_611285 != nil:
    section.add "AWSAccessKeyId", valid_611285
  var valid_611286 = query.getOrDefault("SignatureMethod")
  valid_611286 = validateParameter(valid_611286, JString, required = true,
                                 default = nil)
  if valid_611286 != nil:
    section.add "SignatureMethod", valid_611286
  var valid_611287 = query.getOrDefault("Timestamp")
  valid_611287 = validateParameter(valid_611287, JString, required = true,
                                 default = nil)
  if valid_611287 != nil:
    section.add "Timestamp", valid_611287
  var valid_611288 = query.getOrDefault("Action")
  valid_611288 = validateParameter(valid_611288, JString, required = true,
                                 default = newJString("BatchPutAttributes"))
  if valid_611288 != nil:
    section.add "Action", valid_611288
  var valid_611289 = query.getOrDefault("Version")
  valid_611289 = validateParameter(valid_611289, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_611289 != nil:
    section.add "Version", valid_611289
  var valid_611290 = query.getOrDefault("SignatureVersion")
  valid_611290 = validateParameter(valid_611290, JString, required = true,
                                 default = nil)
  if valid_611290 != nil:
    section.add "SignatureVersion", valid_611290
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
  var valid_611291 = formData.getOrDefault("DomainName")
  valid_611291 = validateParameter(valid_611291, JString, required = true,
                                 default = nil)
  if valid_611291 != nil:
    section.add "DomainName", valid_611291
  var valid_611292 = formData.getOrDefault("Items")
  valid_611292 = validateParameter(valid_611292, JArray, required = true, default = nil)
  if valid_611292 != nil:
    section.add "Items", valid_611292
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611293: Call_PostBatchPutAttributes_611281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  let valid = call_611293.validator(path, query, header, formData, body)
  let scheme = call_611293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611293.url(scheme.get, call_611293.host, call_611293.base,
                         call_611293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611293, url, valid)

proc call*(call_611294: Call_PostBatchPutAttributes_611281; Signature: string;
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
  var query_611295 = newJObject()
  var formData_611296 = newJObject()
  add(query_611295, "Signature", newJString(Signature))
  add(query_611295, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611295, "SignatureMethod", newJString(SignatureMethod))
  add(formData_611296, "DomainName", newJString(DomainName))
  add(query_611295, "Timestamp", newJString(Timestamp))
  add(query_611295, "Action", newJString(Action))
  if Items != nil:
    formData_611296.add "Items", Items
  add(query_611295, "Version", newJString(Version))
  add(query_611295, "SignatureVersion", newJString(SignatureVersion))
  result = call_611294.call(nil, query_611295, nil, formData_611296, nil)

var postBatchPutAttributes* = Call_PostBatchPutAttributes_611281(
    name: "postBatchPutAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=BatchPutAttributes",
    validator: validate_PostBatchPutAttributes_611282, base: "/",
    url: url_PostBatchPutAttributes_611283, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchPutAttributes_611266 = ref object of OpenApiRestCall_610642
proc url_GetBatchPutAttributes_611268(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBatchPutAttributes_611267(path: JsonNode; query: JsonNode;
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
  var valid_611269 = query.getOrDefault("Signature")
  valid_611269 = validateParameter(valid_611269, JString, required = true,
                                 default = nil)
  if valid_611269 != nil:
    section.add "Signature", valid_611269
  var valid_611270 = query.getOrDefault("AWSAccessKeyId")
  valid_611270 = validateParameter(valid_611270, JString, required = true,
                                 default = nil)
  if valid_611270 != nil:
    section.add "AWSAccessKeyId", valid_611270
  var valid_611271 = query.getOrDefault("SignatureMethod")
  valid_611271 = validateParameter(valid_611271, JString, required = true,
                                 default = nil)
  if valid_611271 != nil:
    section.add "SignatureMethod", valid_611271
  var valid_611272 = query.getOrDefault("DomainName")
  valid_611272 = validateParameter(valid_611272, JString, required = true,
                                 default = nil)
  if valid_611272 != nil:
    section.add "DomainName", valid_611272
  var valid_611273 = query.getOrDefault("Items")
  valid_611273 = validateParameter(valid_611273, JArray, required = true, default = nil)
  if valid_611273 != nil:
    section.add "Items", valid_611273
  var valid_611274 = query.getOrDefault("Timestamp")
  valid_611274 = validateParameter(valid_611274, JString, required = true,
                                 default = nil)
  if valid_611274 != nil:
    section.add "Timestamp", valid_611274
  var valid_611275 = query.getOrDefault("Action")
  valid_611275 = validateParameter(valid_611275, JString, required = true,
                                 default = newJString("BatchPutAttributes"))
  if valid_611275 != nil:
    section.add "Action", valid_611275
  var valid_611276 = query.getOrDefault("Version")
  valid_611276 = validateParameter(valid_611276, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_611276 != nil:
    section.add "Version", valid_611276
  var valid_611277 = query.getOrDefault("SignatureVersion")
  valid_611277 = validateParameter(valid_611277, JString, required = true,
                                 default = nil)
  if valid_611277 != nil:
    section.add "SignatureVersion", valid_611277
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611278: Call_GetBatchPutAttributes_611266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  let valid = call_611278.validator(path, query, header, formData, body)
  let scheme = call_611278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611278.url(scheme.get, call_611278.host, call_611278.base,
                         call_611278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611278, url, valid)

proc call*(call_611279: Call_GetBatchPutAttributes_611266; Signature: string;
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
  var query_611280 = newJObject()
  add(query_611280, "Signature", newJString(Signature))
  add(query_611280, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611280, "SignatureMethod", newJString(SignatureMethod))
  add(query_611280, "DomainName", newJString(DomainName))
  if Items != nil:
    query_611280.add "Items", Items
  add(query_611280, "Timestamp", newJString(Timestamp))
  add(query_611280, "Action", newJString(Action))
  add(query_611280, "Version", newJString(Version))
  add(query_611280, "SignatureVersion", newJString(SignatureVersion))
  result = call_611279.call(nil, query_611280, nil, nil, nil)

var getBatchPutAttributes* = Call_GetBatchPutAttributes_611266(
    name: "getBatchPutAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=BatchPutAttributes",
    validator: validate_GetBatchPutAttributes_611267, base: "/",
    url: url_GetBatchPutAttributes_611268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDomain_611311 = ref object of OpenApiRestCall_610642
proc url_PostCreateDomain_611313(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDomain_611312(path: JsonNode; query: JsonNode;
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
  var valid_611314 = query.getOrDefault("Signature")
  valid_611314 = validateParameter(valid_611314, JString, required = true,
                                 default = nil)
  if valid_611314 != nil:
    section.add "Signature", valid_611314
  var valid_611315 = query.getOrDefault("AWSAccessKeyId")
  valid_611315 = validateParameter(valid_611315, JString, required = true,
                                 default = nil)
  if valid_611315 != nil:
    section.add "AWSAccessKeyId", valid_611315
  var valid_611316 = query.getOrDefault("SignatureMethod")
  valid_611316 = validateParameter(valid_611316, JString, required = true,
                                 default = nil)
  if valid_611316 != nil:
    section.add "SignatureMethod", valid_611316
  var valid_611317 = query.getOrDefault("Timestamp")
  valid_611317 = validateParameter(valid_611317, JString, required = true,
                                 default = nil)
  if valid_611317 != nil:
    section.add "Timestamp", valid_611317
  var valid_611318 = query.getOrDefault("Action")
  valid_611318 = validateParameter(valid_611318, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_611318 != nil:
    section.add "Action", valid_611318
  var valid_611319 = query.getOrDefault("Version")
  valid_611319 = validateParameter(valid_611319, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_611319 != nil:
    section.add "Version", valid_611319
  var valid_611320 = query.getOrDefault("SignatureVersion")
  valid_611320 = validateParameter(valid_611320, JString, required = true,
                                 default = nil)
  if valid_611320 != nil:
    section.add "SignatureVersion", valid_611320
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain to create. The name can range between 3 and 255 characters and can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611321 = formData.getOrDefault("DomainName")
  valid_611321 = validateParameter(valid_611321, JString, required = true,
                                 default = nil)
  if valid_611321 != nil:
    section.add "DomainName", valid_611321
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611322: Call_PostCreateDomain_611311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  let valid = call_611322.validator(path, query, header, formData, body)
  let scheme = call_611322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611322.url(scheme.get, call_611322.host, call_611322.base,
                         call_611322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611322, url, valid)

proc call*(call_611323: Call_PostCreateDomain_611311; Signature: string;
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
  var query_611324 = newJObject()
  var formData_611325 = newJObject()
  add(query_611324, "Signature", newJString(Signature))
  add(query_611324, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611324, "SignatureMethod", newJString(SignatureMethod))
  add(formData_611325, "DomainName", newJString(DomainName))
  add(query_611324, "Timestamp", newJString(Timestamp))
  add(query_611324, "Action", newJString(Action))
  add(query_611324, "Version", newJString(Version))
  add(query_611324, "SignatureVersion", newJString(SignatureVersion))
  result = call_611323.call(nil, query_611324, nil, formData_611325, nil)

var postCreateDomain* = Call_PostCreateDomain_611311(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_611312,
    base: "/", url: url_PostCreateDomain_611313,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_611297 = ref object of OpenApiRestCall_610642
proc url_GetCreateDomain_611299(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDomain_611298(path: JsonNode; query: JsonNode;
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
  var valid_611300 = query.getOrDefault("Signature")
  valid_611300 = validateParameter(valid_611300, JString, required = true,
                                 default = nil)
  if valid_611300 != nil:
    section.add "Signature", valid_611300
  var valid_611301 = query.getOrDefault("AWSAccessKeyId")
  valid_611301 = validateParameter(valid_611301, JString, required = true,
                                 default = nil)
  if valid_611301 != nil:
    section.add "AWSAccessKeyId", valid_611301
  var valid_611302 = query.getOrDefault("SignatureMethod")
  valid_611302 = validateParameter(valid_611302, JString, required = true,
                                 default = nil)
  if valid_611302 != nil:
    section.add "SignatureMethod", valid_611302
  var valid_611303 = query.getOrDefault("DomainName")
  valid_611303 = validateParameter(valid_611303, JString, required = true,
                                 default = nil)
  if valid_611303 != nil:
    section.add "DomainName", valid_611303
  var valid_611304 = query.getOrDefault("Timestamp")
  valid_611304 = validateParameter(valid_611304, JString, required = true,
                                 default = nil)
  if valid_611304 != nil:
    section.add "Timestamp", valid_611304
  var valid_611305 = query.getOrDefault("Action")
  valid_611305 = validateParameter(valid_611305, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_611305 != nil:
    section.add "Action", valid_611305
  var valid_611306 = query.getOrDefault("Version")
  valid_611306 = validateParameter(valid_611306, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_611306 != nil:
    section.add "Version", valid_611306
  var valid_611307 = query.getOrDefault("SignatureVersion")
  valid_611307 = validateParameter(valid_611307, JString, required = true,
                                 default = nil)
  if valid_611307 != nil:
    section.add "SignatureVersion", valid_611307
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611308: Call_GetCreateDomain_611297; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  let valid = call_611308.validator(path, query, header, formData, body)
  let scheme = call_611308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611308.url(scheme.get, call_611308.host, call_611308.base,
                         call_611308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611308, url, valid)

proc call*(call_611309: Call_GetCreateDomain_611297; Signature: string;
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
  var query_611310 = newJObject()
  add(query_611310, "Signature", newJString(Signature))
  add(query_611310, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611310, "SignatureMethod", newJString(SignatureMethod))
  add(query_611310, "DomainName", newJString(DomainName))
  add(query_611310, "Timestamp", newJString(Timestamp))
  add(query_611310, "Action", newJString(Action))
  add(query_611310, "Version", newJString(Version))
  add(query_611310, "SignatureVersion", newJString(SignatureVersion))
  result = call_611309.call(nil, query_611310, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_611297(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_611298,
    base: "/", url: url_GetCreateDomain_611299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAttributes_611345 = ref object of OpenApiRestCall_610642
proc url_PostDeleteAttributes_611347(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteAttributes_611346(path: JsonNode; query: JsonNode;
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
  var valid_611348 = query.getOrDefault("Signature")
  valid_611348 = validateParameter(valid_611348, JString, required = true,
                                 default = nil)
  if valid_611348 != nil:
    section.add "Signature", valid_611348
  var valid_611349 = query.getOrDefault("AWSAccessKeyId")
  valid_611349 = validateParameter(valid_611349, JString, required = true,
                                 default = nil)
  if valid_611349 != nil:
    section.add "AWSAccessKeyId", valid_611349
  var valid_611350 = query.getOrDefault("SignatureMethod")
  valid_611350 = validateParameter(valid_611350, JString, required = true,
                                 default = nil)
  if valid_611350 != nil:
    section.add "SignatureMethod", valid_611350
  var valid_611351 = query.getOrDefault("Timestamp")
  valid_611351 = validateParameter(valid_611351, JString, required = true,
                                 default = nil)
  if valid_611351 != nil:
    section.add "Timestamp", valid_611351
  var valid_611352 = query.getOrDefault("Action")
  valid_611352 = validateParameter(valid_611352, JString, required = true,
                                 default = newJString("DeleteAttributes"))
  if valid_611352 != nil:
    section.add "Action", valid_611352
  var valid_611353 = query.getOrDefault("Version")
  valid_611353 = validateParameter(valid_611353, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_611353 != nil:
    section.add "Version", valid_611353
  var valid_611354 = query.getOrDefault("SignatureVersion")
  valid_611354 = validateParameter(valid_611354, JString, required = true,
                                 default = nil)
  if valid_611354 != nil:
    section.add "SignatureVersion", valid_611354
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
  var valid_611355 = formData.getOrDefault("Expected.Value")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "Expected.Value", valid_611355
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611356 = formData.getOrDefault("DomainName")
  valid_611356 = validateParameter(valid_611356, JString, required = true,
                                 default = nil)
  if valid_611356 != nil:
    section.add "DomainName", valid_611356
  var valid_611357 = formData.getOrDefault("Attributes")
  valid_611357 = validateParameter(valid_611357, JArray, required = false,
                                 default = nil)
  if valid_611357 != nil:
    section.add "Attributes", valid_611357
  var valid_611358 = formData.getOrDefault("Expected.Name")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "Expected.Name", valid_611358
  var valid_611359 = formData.getOrDefault("Expected.Exists")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "Expected.Exists", valid_611359
  var valid_611360 = formData.getOrDefault("ItemName")
  valid_611360 = validateParameter(valid_611360, JString, required = true,
                                 default = nil)
  if valid_611360 != nil:
    section.add "ItemName", valid_611360
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611361: Call_PostDeleteAttributes_611345; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  let valid = call_611361.validator(path, query, header, formData, body)
  let scheme = call_611361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611361.url(scheme.get, call_611361.host, call_611361.base,
                         call_611361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611361, url, valid)

proc call*(call_611362: Call_PostDeleteAttributes_611345; Signature: string;
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
  var query_611363 = newJObject()
  var formData_611364 = newJObject()
  add(formData_611364, "Expected.Value", newJString(ExpectedValue))
  add(query_611363, "Signature", newJString(Signature))
  add(query_611363, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611363, "SignatureMethod", newJString(SignatureMethod))
  add(formData_611364, "DomainName", newJString(DomainName))
  if Attributes != nil:
    formData_611364.add "Attributes", Attributes
  add(query_611363, "Timestamp", newJString(Timestamp))
  add(query_611363, "Action", newJString(Action))
  add(formData_611364, "Expected.Name", newJString(ExpectedName))
  add(query_611363, "Version", newJString(Version))
  add(formData_611364, "Expected.Exists", newJString(ExpectedExists))
  add(query_611363, "SignatureVersion", newJString(SignatureVersion))
  add(formData_611364, "ItemName", newJString(ItemName))
  result = call_611362.call(nil, query_611363, nil, formData_611364, nil)

var postDeleteAttributes* = Call_PostDeleteAttributes_611345(
    name: "postDeleteAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=DeleteAttributes",
    validator: validate_PostDeleteAttributes_611346, base: "/",
    url: url_PostDeleteAttributes_611347, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAttributes_611326 = ref object of OpenApiRestCall_610642
proc url_GetDeleteAttributes_611328(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteAttributes_611327(path: JsonNode; query: JsonNode;
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
  var valid_611329 = query.getOrDefault("Signature")
  valid_611329 = validateParameter(valid_611329, JString, required = true,
                                 default = nil)
  if valid_611329 != nil:
    section.add "Signature", valid_611329
  var valid_611330 = query.getOrDefault("AWSAccessKeyId")
  valid_611330 = validateParameter(valid_611330, JString, required = true,
                                 default = nil)
  if valid_611330 != nil:
    section.add "AWSAccessKeyId", valid_611330
  var valid_611331 = query.getOrDefault("Expected.Value")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "Expected.Value", valid_611331
  var valid_611332 = query.getOrDefault("SignatureMethod")
  valid_611332 = validateParameter(valid_611332, JString, required = true,
                                 default = nil)
  if valid_611332 != nil:
    section.add "SignatureMethod", valid_611332
  var valid_611333 = query.getOrDefault("DomainName")
  valid_611333 = validateParameter(valid_611333, JString, required = true,
                                 default = nil)
  if valid_611333 != nil:
    section.add "DomainName", valid_611333
  var valid_611334 = query.getOrDefault("Expected.Name")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "Expected.Name", valid_611334
  var valid_611335 = query.getOrDefault("ItemName")
  valid_611335 = validateParameter(valid_611335, JString, required = true,
                                 default = nil)
  if valid_611335 != nil:
    section.add "ItemName", valid_611335
  var valid_611336 = query.getOrDefault("Expected.Exists")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "Expected.Exists", valid_611336
  var valid_611337 = query.getOrDefault("Attributes")
  valid_611337 = validateParameter(valid_611337, JArray, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "Attributes", valid_611337
  var valid_611338 = query.getOrDefault("Timestamp")
  valid_611338 = validateParameter(valid_611338, JString, required = true,
                                 default = nil)
  if valid_611338 != nil:
    section.add "Timestamp", valid_611338
  var valid_611339 = query.getOrDefault("Action")
  valid_611339 = validateParameter(valid_611339, JString, required = true,
                                 default = newJString("DeleteAttributes"))
  if valid_611339 != nil:
    section.add "Action", valid_611339
  var valid_611340 = query.getOrDefault("Version")
  valid_611340 = validateParameter(valid_611340, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_611340 != nil:
    section.add "Version", valid_611340
  var valid_611341 = query.getOrDefault("SignatureVersion")
  valid_611341 = validateParameter(valid_611341, JString, required = true,
                                 default = nil)
  if valid_611341 != nil:
    section.add "SignatureVersion", valid_611341
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611342: Call_GetDeleteAttributes_611326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  let valid = call_611342.validator(path, query, header, formData, body)
  let scheme = call_611342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611342.url(scheme.get, call_611342.host, call_611342.base,
                         call_611342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611342, url, valid)

proc call*(call_611343: Call_GetDeleteAttributes_611326; Signature: string;
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
  var query_611344 = newJObject()
  add(query_611344, "Signature", newJString(Signature))
  add(query_611344, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611344, "Expected.Value", newJString(ExpectedValue))
  add(query_611344, "SignatureMethod", newJString(SignatureMethod))
  add(query_611344, "DomainName", newJString(DomainName))
  add(query_611344, "Expected.Name", newJString(ExpectedName))
  add(query_611344, "ItemName", newJString(ItemName))
  add(query_611344, "Expected.Exists", newJString(ExpectedExists))
  if Attributes != nil:
    query_611344.add "Attributes", Attributes
  add(query_611344, "Timestamp", newJString(Timestamp))
  add(query_611344, "Action", newJString(Action))
  add(query_611344, "Version", newJString(Version))
  add(query_611344, "SignatureVersion", newJString(SignatureVersion))
  result = call_611343.call(nil, query_611344, nil, nil, nil)

var getDeleteAttributes* = Call_GetDeleteAttributes_611326(
    name: "getDeleteAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=DeleteAttributes",
    validator: validate_GetDeleteAttributes_611327, base: "/",
    url: url_GetDeleteAttributes_611328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_611379 = ref object of OpenApiRestCall_610642
proc url_PostDeleteDomain_611381(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDomain_611380(path: JsonNode; query: JsonNode;
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
  var valid_611382 = query.getOrDefault("Signature")
  valid_611382 = validateParameter(valid_611382, JString, required = true,
                                 default = nil)
  if valid_611382 != nil:
    section.add "Signature", valid_611382
  var valid_611383 = query.getOrDefault("AWSAccessKeyId")
  valid_611383 = validateParameter(valid_611383, JString, required = true,
                                 default = nil)
  if valid_611383 != nil:
    section.add "AWSAccessKeyId", valid_611383
  var valid_611384 = query.getOrDefault("SignatureMethod")
  valid_611384 = validateParameter(valid_611384, JString, required = true,
                                 default = nil)
  if valid_611384 != nil:
    section.add "SignatureMethod", valid_611384
  var valid_611385 = query.getOrDefault("Timestamp")
  valid_611385 = validateParameter(valid_611385, JString, required = true,
                                 default = nil)
  if valid_611385 != nil:
    section.add "Timestamp", valid_611385
  var valid_611386 = query.getOrDefault("Action")
  valid_611386 = validateParameter(valid_611386, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_611386 != nil:
    section.add "Action", valid_611386
  var valid_611387 = query.getOrDefault("Version")
  valid_611387 = validateParameter(valid_611387, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_611387 != nil:
    section.add "Version", valid_611387
  var valid_611388 = query.getOrDefault("SignatureVersion")
  valid_611388 = validateParameter(valid_611388, JString, required = true,
                                 default = nil)
  if valid_611388 != nil:
    section.add "SignatureVersion", valid_611388
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611389 = formData.getOrDefault("DomainName")
  valid_611389 = validateParameter(valid_611389, JString, required = true,
                                 default = nil)
  if valid_611389 != nil:
    section.add "DomainName", valid_611389
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611390: Call_PostDeleteDomain_611379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  let valid = call_611390.validator(path, query, header, formData, body)
  let scheme = call_611390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611390.url(scheme.get, call_611390.host, call_611390.base,
                         call_611390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611390, url, valid)

proc call*(call_611391: Call_PostDeleteDomain_611379; Signature: string;
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
  var query_611392 = newJObject()
  var formData_611393 = newJObject()
  add(query_611392, "Signature", newJString(Signature))
  add(query_611392, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611392, "SignatureMethod", newJString(SignatureMethod))
  add(formData_611393, "DomainName", newJString(DomainName))
  add(query_611392, "Timestamp", newJString(Timestamp))
  add(query_611392, "Action", newJString(Action))
  add(query_611392, "Version", newJString(Version))
  add(query_611392, "SignatureVersion", newJString(SignatureVersion))
  result = call_611391.call(nil, query_611392, nil, formData_611393, nil)

var postDeleteDomain* = Call_PostDeleteDomain_611379(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_611380,
    base: "/", url: url_PostDeleteDomain_611381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_611365 = ref object of OpenApiRestCall_610642
proc url_GetDeleteDomain_611367(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDomain_611366(path: JsonNode; query: JsonNode;
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
  var valid_611368 = query.getOrDefault("Signature")
  valid_611368 = validateParameter(valid_611368, JString, required = true,
                                 default = nil)
  if valid_611368 != nil:
    section.add "Signature", valid_611368
  var valid_611369 = query.getOrDefault("AWSAccessKeyId")
  valid_611369 = validateParameter(valid_611369, JString, required = true,
                                 default = nil)
  if valid_611369 != nil:
    section.add "AWSAccessKeyId", valid_611369
  var valid_611370 = query.getOrDefault("SignatureMethod")
  valid_611370 = validateParameter(valid_611370, JString, required = true,
                                 default = nil)
  if valid_611370 != nil:
    section.add "SignatureMethod", valid_611370
  var valid_611371 = query.getOrDefault("DomainName")
  valid_611371 = validateParameter(valid_611371, JString, required = true,
                                 default = nil)
  if valid_611371 != nil:
    section.add "DomainName", valid_611371
  var valid_611372 = query.getOrDefault("Timestamp")
  valid_611372 = validateParameter(valid_611372, JString, required = true,
                                 default = nil)
  if valid_611372 != nil:
    section.add "Timestamp", valid_611372
  var valid_611373 = query.getOrDefault("Action")
  valid_611373 = validateParameter(valid_611373, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_611373 != nil:
    section.add "Action", valid_611373
  var valid_611374 = query.getOrDefault("Version")
  valid_611374 = validateParameter(valid_611374, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_611374 != nil:
    section.add "Version", valid_611374
  var valid_611375 = query.getOrDefault("SignatureVersion")
  valid_611375 = validateParameter(valid_611375, JString, required = true,
                                 default = nil)
  if valid_611375 != nil:
    section.add "SignatureVersion", valid_611375
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611376: Call_GetDeleteDomain_611365; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  let valid = call_611376.validator(path, query, header, formData, body)
  let scheme = call_611376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611376.url(scheme.get, call_611376.host, call_611376.base,
                         call_611376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611376, url, valid)

proc call*(call_611377: Call_GetDeleteDomain_611365; Signature: string;
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
  var query_611378 = newJObject()
  add(query_611378, "Signature", newJString(Signature))
  add(query_611378, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611378, "SignatureMethod", newJString(SignatureMethod))
  add(query_611378, "DomainName", newJString(DomainName))
  add(query_611378, "Timestamp", newJString(Timestamp))
  add(query_611378, "Action", newJString(Action))
  add(query_611378, "Version", newJString(Version))
  add(query_611378, "SignatureVersion", newJString(SignatureVersion))
  result = call_611377.call(nil, query_611378, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_611365(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_611366,
    base: "/", url: url_GetDeleteDomain_611367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDomainMetadata_611408 = ref object of OpenApiRestCall_610642
proc url_PostDomainMetadata_611410(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDomainMetadata_611409(path: JsonNode; query: JsonNode;
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
  var valid_611411 = query.getOrDefault("Signature")
  valid_611411 = validateParameter(valid_611411, JString, required = true,
                                 default = nil)
  if valid_611411 != nil:
    section.add "Signature", valid_611411
  var valid_611412 = query.getOrDefault("AWSAccessKeyId")
  valid_611412 = validateParameter(valid_611412, JString, required = true,
                                 default = nil)
  if valid_611412 != nil:
    section.add "AWSAccessKeyId", valid_611412
  var valid_611413 = query.getOrDefault("SignatureMethod")
  valid_611413 = validateParameter(valid_611413, JString, required = true,
                                 default = nil)
  if valid_611413 != nil:
    section.add "SignatureMethod", valid_611413
  var valid_611414 = query.getOrDefault("Timestamp")
  valid_611414 = validateParameter(valid_611414, JString, required = true,
                                 default = nil)
  if valid_611414 != nil:
    section.add "Timestamp", valid_611414
  var valid_611415 = query.getOrDefault("Action")
  valid_611415 = validateParameter(valid_611415, JString, required = true,
                                 default = newJString("DomainMetadata"))
  if valid_611415 != nil:
    section.add "Action", valid_611415
  var valid_611416 = query.getOrDefault("Version")
  valid_611416 = validateParameter(valid_611416, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_611416 != nil:
    section.add "Version", valid_611416
  var valid_611417 = query.getOrDefault("SignatureVersion")
  valid_611417 = validateParameter(valid_611417, JString, required = true,
                                 default = nil)
  if valid_611417 != nil:
    section.add "SignatureVersion", valid_611417
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain for which to display the metadata of.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611418 = formData.getOrDefault("DomainName")
  valid_611418 = validateParameter(valid_611418, JString, required = true,
                                 default = nil)
  if valid_611418 != nil:
    section.add "DomainName", valid_611418
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611419: Call_PostDomainMetadata_611408; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  let valid = call_611419.validator(path, query, header, formData, body)
  let scheme = call_611419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611419.url(scheme.get, call_611419.host, call_611419.base,
                         call_611419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611419, url, valid)

proc call*(call_611420: Call_PostDomainMetadata_611408; Signature: string;
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
  var query_611421 = newJObject()
  var formData_611422 = newJObject()
  add(query_611421, "Signature", newJString(Signature))
  add(query_611421, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611421, "SignatureMethod", newJString(SignatureMethod))
  add(formData_611422, "DomainName", newJString(DomainName))
  add(query_611421, "Timestamp", newJString(Timestamp))
  add(query_611421, "Action", newJString(Action))
  add(query_611421, "Version", newJString(Version))
  add(query_611421, "SignatureVersion", newJString(SignatureVersion))
  result = call_611420.call(nil, query_611421, nil, formData_611422, nil)

var postDomainMetadata* = Call_PostDomainMetadata_611408(
    name: "postDomainMetadata", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=DomainMetadata",
    validator: validate_PostDomainMetadata_611409, base: "/",
    url: url_PostDomainMetadata_611410, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainMetadata_611394 = ref object of OpenApiRestCall_610642
proc url_GetDomainMetadata_611396(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDomainMetadata_611395(path: JsonNode; query: JsonNode;
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
  var valid_611397 = query.getOrDefault("Signature")
  valid_611397 = validateParameter(valid_611397, JString, required = true,
                                 default = nil)
  if valid_611397 != nil:
    section.add "Signature", valid_611397
  var valid_611398 = query.getOrDefault("AWSAccessKeyId")
  valid_611398 = validateParameter(valid_611398, JString, required = true,
                                 default = nil)
  if valid_611398 != nil:
    section.add "AWSAccessKeyId", valid_611398
  var valid_611399 = query.getOrDefault("SignatureMethod")
  valid_611399 = validateParameter(valid_611399, JString, required = true,
                                 default = nil)
  if valid_611399 != nil:
    section.add "SignatureMethod", valid_611399
  var valid_611400 = query.getOrDefault("DomainName")
  valid_611400 = validateParameter(valid_611400, JString, required = true,
                                 default = nil)
  if valid_611400 != nil:
    section.add "DomainName", valid_611400
  var valid_611401 = query.getOrDefault("Timestamp")
  valid_611401 = validateParameter(valid_611401, JString, required = true,
                                 default = nil)
  if valid_611401 != nil:
    section.add "Timestamp", valid_611401
  var valid_611402 = query.getOrDefault("Action")
  valid_611402 = validateParameter(valid_611402, JString, required = true,
                                 default = newJString("DomainMetadata"))
  if valid_611402 != nil:
    section.add "Action", valid_611402
  var valid_611403 = query.getOrDefault("Version")
  valid_611403 = validateParameter(valid_611403, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_611403 != nil:
    section.add "Version", valid_611403
  var valid_611404 = query.getOrDefault("SignatureVersion")
  valid_611404 = validateParameter(valid_611404, JString, required = true,
                                 default = nil)
  if valid_611404 != nil:
    section.add "SignatureVersion", valid_611404
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611405: Call_GetDomainMetadata_611394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  let valid = call_611405.validator(path, query, header, formData, body)
  let scheme = call_611405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611405.url(scheme.get, call_611405.host, call_611405.base,
                         call_611405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611405, url, valid)

proc call*(call_611406: Call_GetDomainMetadata_611394; Signature: string;
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
  var query_611407 = newJObject()
  add(query_611407, "Signature", newJString(Signature))
  add(query_611407, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611407, "SignatureMethod", newJString(SignatureMethod))
  add(query_611407, "DomainName", newJString(DomainName))
  add(query_611407, "Timestamp", newJString(Timestamp))
  add(query_611407, "Action", newJString(Action))
  add(query_611407, "Version", newJString(Version))
  add(query_611407, "SignatureVersion", newJString(SignatureVersion))
  result = call_611406.call(nil, query_611407, nil, nil, nil)

var getDomainMetadata* = Call_GetDomainMetadata_611394(name: "getDomainMetadata",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=DomainMetadata", validator: validate_GetDomainMetadata_611395,
    base: "/", url: url_GetDomainMetadata_611396,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetAttributes_611440 = ref object of OpenApiRestCall_610642
proc url_PostGetAttributes_611442(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetAttributes_611441(path: JsonNode; query: JsonNode;
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
  var valid_611443 = query.getOrDefault("Signature")
  valid_611443 = validateParameter(valid_611443, JString, required = true,
                                 default = nil)
  if valid_611443 != nil:
    section.add "Signature", valid_611443
  var valid_611444 = query.getOrDefault("AWSAccessKeyId")
  valid_611444 = validateParameter(valid_611444, JString, required = true,
                                 default = nil)
  if valid_611444 != nil:
    section.add "AWSAccessKeyId", valid_611444
  var valid_611445 = query.getOrDefault("SignatureMethod")
  valid_611445 = validateParameter(valid_611445, JString, required = true,
                                 default = nil)
  if valid_611445 != nil:
    section.add "SignatureMethod", valid_611445
  var valid_611446 = query.getOrDefault("Timestamp")
  valid_611446 = validateParameter(valid_611446, JString, required = true,
                                 default = nil)
  if valid_611446 != nil:
    section.add "Timestamp", valid_611446
  var valid_611447 = query.getOrDefault("Action")
  valid_611447 = validateParameter(valid_611447, JString, required = true,
                                 default = newJString("GetAttributes"))
  if valid_611447 != nil:
    section.add "Action", valid_611447
  var valid_611448 = query.getOrDefault("Version")
  valid_611448 = validateParameter(valid_611448, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_611448 != nil:
    section.add "Version", valid_611448
  var valid_611449 = query.getOrDefault("SignatureVersion")
  valid_611449 = validateParameter(valid_611449, JString, required = true,
                                 default = nil)
  if valid_611449 != nil:
    section.add "SignatureVersion", valid_611449
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
  var valid_611450 = formData.getOrDefault("ConsistentRead")
  valid_611450 = validateParameter(valid_611450, JBool, required = false, default = nil)
  if valid_611450 != nil:
    section.add "ConsistentRead", valid_611450
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611451 = formData.getOrDefault("DomainName")
  valid_611451 = validateParameter(valid_611451, JString, required = true,
                                 default = nil)
  if valid_611451 != nil:
    section.add "DomainName", valid_611451
  var valid_611452 = formData.getOrDefault("AttributeNames")
  valid_611452 = validateParameter(valid_611452, JArray, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "AttributeNames", valid_611452
  var valid_611453 = formData.getOrDefault("ItemName")
  valid_611453 = validateParameter(valid_611453, JString, required = true,
                                 default = nil)
  if valid_611453 != nil:
    section.add "ItemName", valid_611453
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611454: Call_PostGetAttributes_611440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  let valid = call_611454.validator(path, query, header, formData, body)
  let scheme = call_611454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611454.url(scheme.get, call_611454.host, call_611454.base,
                         call_611454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611454, url, valid)

proc call*(call_611455: Call_PostGetAttributes_611440; Signature: string;
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
  var query_611456 = newJObject()
  var formData_611457 = newJObject()
  add(query_611456, "Signature", newJString(Signature))
  add(query_611456, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611456, "SignatureMethod", newJString(SignatureMethod))
  add(formData_611457, "ConsistentRead", newJBool(ConsistentRead))
  add(formData_611457, "DomainName", newJString(DomainName))
  if AttributeNames != nil:
    formData_611457.add "AttributeNames", AttributeNames
  add(query_611456, "Timestamp", newJString(Timestamp))
  add(query_611456, "Action", newJString(Action))
  add(query_611456, "Version", newJString(Version))
  add(query_611456, "SignatureVersion", newJString(SignatureVersion))
  add(formData_611457, "ItemName", newJString(ItemName))
  result = call_611455.call(nil, query_611456, nil, formData_611457, nil)

var postGetAttributes* = Call_PostGetAttributes_611440(name: "postGetAttributes",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=GetAttributes", validator: validate_PostGetAttributes_611441,
    base: "/", url: url_PostGetAttributes_611442,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetAttributes_611423 = ref object of OpenApiRestCall_610642
proc url_GetGetAttributes_611425(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetAttributes_611424(path: JsonNode; query: JsonNode;
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
  var valid_611426 = query.getOrDefault("Signature")
  valid_611426 = validateParameter(valid_611426, JString, required = true,
                                 default = nil)
  if valid_611426 != nil:
    section.add "Signature", valid_611426
  var valid_611427 = query.getOrDefault("AWSAccessKeyId")
  valid_611427 = validateParameter(valid_611427, JString, required = true,
                                 default = nil)
  if valid_611427 != nil:
    section.add "AWSAccessKeyId", valid_611427
  var valid_611428 = query.getOrDefault("AttributeNames")
  valid_611428 = validateParameter(valid_611428, JArray, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "AttributeNames", valid_611428
  var valid_611429 = query.getOrDefault("SignatureMethod")
  valid_611429 = validateParameter(valid_611429, JString, required = true,
                                 default = nil)
  if valid_611429 != nil:
    section.add "SignatureMethod", valid_611429
  var valid_611430 = query.getOrDefault("DomainName")
  valid_611430 = validateParameter(valid_611430, JString, required = true,
                                 default = nil)
  if valid_611430 != nil:
    section.add "DomainName", valid_611430
  var valid_611431 = query.getOrDefault("ItemName")
  valid_611431 = validateParameter(valid_611431, JString, required = true,
                                 default = nil)
  if valid_611431 != nil:
    section.add "ItemName", valid_611431
  var valid_611432 = query.getOrDefault("Timestamp")
  valid_611432 = validateParameter(valid_611432, JString, required = true,
                                 default = nil)
  if valid_611432 != nil:
    section.add "Timestamp", valid_611432
  var valid_611433 = query.getOrDefault("Action")
  valid_611433 = validateParameter(valid_611433, JString, required = true,
                                 default = newJString("GetAttributes"))
  if valid_611433 != nil:
    section.add "Action", valid_611433
  var valid_611434 = query.getOrDefault("ConsistentRead")
  valid_611434 = validateParameter(valid_611434, JBool, required = false, default = nil)
  if valid_611434 != nil:
    section.add "ConsistentRead", valid_611434
  var valid_611435 = query.getOrDefault("Version")
  valid_611435 = validateParameter(valid_611435, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_611435 != nil:
    section.add "Version", valid_611435
  var valid_611436 = query.getOrDefault("SignatureVersion")
  valid_611436 = validateParameter(valid_611436, JString, required = true,
                                 default = nil)
  if valid_611436 != nil:
    section.add "SignatureVersion", valid_611436
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611437: Call_GetGetAttributes_611423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  let valid = call_611437.validator(path, query, header, formData, body)
  let scheme = call_611437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611437.url(scheme.get, call_611437.host, call_611437.base,
                         call_611437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611437, url, valid)

proc call*(call_611438: Call_GetGetAttributes_611423; Signature: string;
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
  var query_611439 = newJObject()
  add(query_611439, "Signature", newJString(Signature))
  add(query_611439, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  if AttributeNames != nil:
    query_611439.add "AttributeNames", AttributeNames
  add(query_611439, "SignatureMethod", newJString(SignatureMethod))
  add(query_611439, "DomainName", newJString(DomainName))
  add(query_611439, "ItemName", newJString(ItemName))
  add(query_611439, "Timestamp", newJString(Timestamp))
  add(query_611439, "Action", newJString(Action))
  add(query_611439, "ConsistentRead", newJBool(ConsistentRead))
  add(query_611439, "Version", newJString(Version))
  add(query_611439, "SignatureVersion", newJString(SignatureVersion))
  result = call_611438.call(nil, query_611439, nil, nil, nil)

var getGetAttributes* = Call_GetGetAttributes_611423(name: "getGetAttributes",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=GetAttributes", validator: validate_GetGetAttributes_611424,
    base: "/", url: url_GetGetAttributes_611425,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDomains_611473 = ref object of OpenApiRestCall_610642
proc url_PostListDomains_611475(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListDomains_611474(path: JsonNode; query: JsonNode;
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
  var valid_611476 = query.getOrDefault("Signature")
  valid_611476 = validateParameter(valid_611476, JString, required = true,
                                 default = nil)
  if valid_611476 != nil:
    section.add "Signature", valid_611476
  var valid_611477 = query.getOrDefault("AWSAccessKeyId")
  valid_611477 = validateParameter(valid_611477, JString, required = true,
                                 default = nil)
  if valid_611477 != nil:
    section.add "AWSAccessKeyId", valid_611477
  var valid_611478 = query.getOrDefault("SignatureMethod")
  valid_611478 = validateParameter(valid_611478, JString, required = true,
                                 default = nil)
  if valid_611478 != nil:
    section.add "SignatureMethod", valid_611478
  var valid_611479 = query.getOrDefault("Timestamp")
  valid_611479 = validateParameter(valid_611479, JString, required = true,
                                 default = nil)
  if valid_611479 != nil:
    section.add "Timestamp", valid_611479
  var valid_611480 = query.getOrDefault("Action")
  valid_611480 = validateParameter(valid_611480, JString, required = true,
                                 default = newJString("ListDomains"))
  if valid_611480 != nil:
    section.add "Action", valid_611480
  var valid_611481 = query.getOrDefault("Version")
  valid_611481 = validateParameter(valid_611481, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_611481 != nil:
    section.add "Version", valid_611481
  var valid_611482 = query.getOrDefault("SignatureVersion")
  valid_611482 = validateParameter(valid_611482, JString, required = true,
                                 default = nil)
  if valid_611482 != nil:
    section.add "SignatureVersion", valid_611482
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : A string informing Amazon SimpleDB where to start the next list of domain names.
  ##   MaxNumberOfDomains: JInt
  ##                     : The maximum number of domain names you want returned. The range is 1 to 100. The default setting is 100.
  section = newJObject()
  var valid_611483 = formData.getOrDefault("NextToken")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "NextToken", valid_611483
  var valid_611484 = formData.getOrDefault("MaxNumberOfDomains")
  valid_611484 = validateParameter(valid_611484, JInt, required = false, default = nil)
  if valid_611484 != nil:
    section.add "MaxNumberOfDomains", valid_611484
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611485: Call_PostListDomains_611473; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  let valid = call_611485.validator(path, query, header, formData, body)
  let scheme = call_611485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611485.url(scheme.get, call_611485.host, call_611485.base,
                         call_611485.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611485, url, valid)

proc call*(call_611486: Call_PostListDomains_611473; Signature: string;
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
  var query_611487 = newJObject()
  var formData_611488 = newJObject()
  add(query_611487, "Signature", newJString(Signature))
  add(query_611487, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_611488, "NextToken", newJString(NextToken))
  add(query_611487, "SignatureMethod", newJString(SignatureMethod))
  add(formData_611488, "MaxNumberOfDomains", newJInt(MaxNumberOfDomains))
  add(query_611487, "Timestamp", newJString(Timestamp))
  add(query_611487, "Action", newJString(Action))
  add(query_611487, "Version", newJString(Version))
  add(query_611487, "SignatureVersion", newJString(SignatureVersion))
  result = call_611486.call(nil, query_611487, nil, formData_611488, nil)

var postListDomains* = Call_PostListDomains_611473(name: "postListDomains",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=ListDomains", validator: validate_PostListDomains_611474,
    base: "/", url: url_PostListDomains_611475, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDomains_611458 = ref object of OpenApiRestCall_610642
proc url_GetListDomains_611460(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListDomains_611459(path: JsonNode; query: JsonNode;
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
  var valid_611461 = query.getOrDefault("Signature")
  valid_611461 = validateParameter(valid_611461, JString, required = true,
                                 default = nil)
  if valid_611461 != nil:
    section.add "Signature", valid_611461
  var valid_611462 = query.getOrDefault("AWSAccessKeyId")
  valid_611462 = validateParameter(valid_611462, JString, required = true,
                                 default = nil)
  if valid_611462 != nil:
    section.add "AWSAccessKeyId", valid_611462
  var valid_611463 = query.getOrDefault("SignatureMethod")
  valid_611463 = validateParameter(valid_611463, JString, required = true,
                                 default = nil)
  if valid_611463 != nil:
    section.add "SignatureMethod", valid_611463
  var valid_611464 = query.getOrDefault("NextToken")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "NextToken", valid_611464
  var valid_611465 = query.getOrDefault("MaxNumberOfDomains")
  valid_611465 = validateParameter(valid_611465, JInt, required = false, default = nil)
  if valid_611465 != nil:
    section.add "MaxNumberOfDomains", valid_611465
  var valid_611466 = query.getOrDefault("Timestamp")
  valid_611466 = validateParameter(valid_611466, JString, required = true,
                                 default = nil)
  if valid_611466 != nil:
    section.add "Timestamp", valid_611466
  var valid_611467 = query.getOrDefault("Action")
  valid_611467 = validateParameter(valid_611467, JString, required = true,
                                 default = newJString("ListDomains"))
  if valid_611467 != nil:
    section.add "Action", valid_611467
  var valid_611468 = query.getOrDefault("Version")
  valid_611468 = validateParameter(valid_611468, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_611468 != nil:
    section.add "Version", valid_611468
  var valid_611469 = query.getOrDefault("SignatureVersion")
  valid_611469 = validateParameter(valid_611469, JString, required = true,
                                 default = nil)
  if valid_611469 != nil:
    section.add "SignatureVersion", valid_611469
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611470: Call_GetListDomains_611458; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  let valid = call_611470.validator(path, query, header, formData, body)
  let scheme = call_611470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611470.url(scheme.get, call_611470.host, call_611470.base,
                         call_611470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611470, url, valid)

proc call*(call_611471: Call_GetListDomains_611458; Signature: string;
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
  var query_611472 = newJObject()
  add(query_611472, "Signature", newJString(Signature))
  add(query_611472, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611472, "SignatureMethod", newJString(SignatureMethod))
  add(query_611472, "NextToken", newJString(NextToken))
  add(query_611472, "MaxNumberOfDomains", newJInt(MaxNumberOfDomains))
  add(query_611472, "Timestamp", newJString(Timestamp))
  add(query_611472, "Action", newJString(Action))
  add(query_611472, "Version", newJString(Version))
  add(query_611472, "SignatureVersion", newJString(SignatureVersion))
  result = call_611471.call(nil, query_611472, nil, nil, nil)

var getListDomains* = Call_GetListDomains_611458(name: "getListDomains",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=ListDomains", validator: validate_GetListDomains_611459,
    base: "/", url: url_GetListDomains_611460, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutAttributes_611508 = ref object of OpenApiRestCall_610642
proc url_PostPutAttributes_611510(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPutAttributes_611509(path: JsonNode; query: JsonNode;
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
  var valid_611511 = query.getOrDefault("Signature")
  valid_611511 = validateParameter(valid_611511, JString, required = true,
                                 default = nil)
  if valid_611511 != nil:
    section.add "Signature", valid_611511
  var valid_611512 = query.getOrDefault("AWSAccessKeyId")
  valid_611512 = validateParameter(valid_611512, JString, required = true,
                                 default = nil)
  if valid_611512 != nil:
    section.add "AWSAccessKeyId", valid_611512
  var valid_611513 = query.getOrDefault("SignatureMethod")
  valid_611513 = validateParameter(valid_611513, JString, required = true,
                                 default = nil)
  if valid_611513 != nil:
    section.add "SignatureMethod", valid_611513
  var valid_611514 = query.getOrDefault("Timestamp")
  valid_611514 = validateParameter(valid_611514, JString, required = true,
                                 default = nil)
  if valid_611514 != nil:
    section.add "Timestamp", valid_611514
  var valid_611515 = query.getOrDefault("Action")
  valid_611515 = validateParameter(valid_611515, JString, required = true,
                                 default = newJString("PutAttributes"))
  if valid_611515 != nil:
    section.add "Action", valid_611515
  var valid_611516 = query.getOrDefault("Version")
  valid_611516 = validateParameter(valid_611516, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_611516 != nil:
    section.add "Version", valid_611516
  var valid_611517 = query.getOrDefault("SignatureVersion")
  valid_611517 = validateParameter(valid_611517, JString, required = true,
                                 default = nil)
  if valid_611517 != nil:
    section.add "SignatureVersion", valid_611517
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
  var valid_611518 = formData.getOrDefault("Expected.Value")
  valid_611518 = validateParameter(valid_611518, JString, required = false,
                                 default = nil)
  if valid_611518 != nil:
    section.add "Expected.Value", valid_611518
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611519 = formData.getOrDefault("DomainName")
  valid_611519 = validateParameter(valid_611519, JString, required = true,
                                 default = nil)
  if valid_611519 != nil:
    section.add "DomainName", valid_611519
  var valid_611520 = formData.getOrDefault("Attributes")
  valid_611520 = validateParameter(valid_611520, JArray, required = true, default = nil)
  if valid_611520 != nil:
    section.add "Attributes", valid_611520
  var valid_611521 = formData.getOrDefault("Expected.Name")
  valid_611521 = validateParameter(valid_611521, JString, required = false,
                                 default = nil)
  if valid_611521 != nil:
    section.add "Expected.Name", valid_611521
  var valid_611522 = formData.getOrDefault("Expected.Exists")
  valid_611522 = validateParameter(valid_611522, JString, required = false,
                                 default = nil)
  if valid_611522 != nil:
    section.add "Expected.Exists", valid_611522
  var valid_611523 = formData.getOrDefault("ItemName")
  valid_611523 = validateParameter(valid_611523, JString, required = true,
                                 default = nil)
  if valid_611523 != nil:
    section.add "ItemName", valid_611523
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611524: Call_PostPutAttributes_611508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  let valid = call_611524.validator(path, query, header, formData, body)
  let scheme = call_611524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611524.url(scheme.get, call_611524.host, call_611524.base,
                         call_611524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611524, url, valid)

proc call*(call_611525: Call_PostPutAttributes_611508; Signature: string;
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
  var query_611526 = newJObject()
  var formData_611527 = newJObject()
  add(formData_611527, "Expected.Value", newJString(ExpectedValue))
  add(query_611526, "Signature", newJString(Signature))
  add(query_611526, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611526, "SignatureMethod", newJString(SignatureMethod))
  add(formData_611527, "DomainName", newJString(DomainName))
  if Attributes != nil:
    formData_611527.add "Attributes", Attributes
  add(query_611526, "Timestamp", newJString(Timestamp))
  add(query_611526, "Action", newJString(Action))
  add(formData_611527, "Expected.Name", newJString(ExpectedName))
  add(query_611526, "Version", newJString(Version))
  add(formData_611527, "Expected.Exists", newJString(ExpectedExists))
  add(query_611526, "SignatureVersion", newJString(SignatureVersion))
  add(formData_611527, "ItemName", newJString(ItemName))
  result = call_611525.call(nil, query_611526, nil, formData_611527, nil)

var postPutAttributes* = Call_PostPutAttributes_611508(name: "postPutAttributes",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=PutAttributes", validator: validate_PostPutAttributes_611509,
    base: "/", url: url_PostPutAttributes_611510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutAttributes_611489 = ref object of OpenApiRestCall_610642
proc url_GetPutAttributes_611491(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPutAttributes_611490(path: JsonNode; query: JsonNode;
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
  var valid_611492 = query.getOrDefault("Signature")
  valid_611492 = validateParameter(valid_611492, JString, required = true,
                                 default = nil)
  if valid_611492 != nil:
    section.add "Signature", valid_611492
  var valid_611493 = query.getOrDefault("AWSAccessKeyId")
  valid_611493 = validateParameter(valid_611493, JString, required = true,
                                 default = nil)
  if valid_611493 != nil:
    section.add "AWSAccessKeyId", valid_611493
  var valid_611494 = query.getOrDefault("Expected.Value")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "Expected.Value", valid_611494
  var valid_611495 = query.getOrDefault("SignatureMethod")
  valid_611495 = validateParameter(valid_611495, JString, required = true,
                                 default = nil)
  if valid_611495 != nil:
    section.add "SignatureMethod", valid_611495
  var valid_611496 = query.getOrDefault("DomainName")
  valid_611496 = validateParameter(valid_611496, JString, required = true,
                                 default = nil)
  if valid_611496 != nil:
    section.add "DomainName", valid_611496
  var valid_611497 = query.getOrDefault("Expected.Name")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "Expected.Name", valid_611497
  var valid_611498 = query.getOrDefault("ItemName")
  valid_611498 = validateParameter(valid_611498, JString, required = true,
                                 default = nil)
  if valid_611498 != nil:
    section.add "ItemName", valid_611498
  var valid_611499 = query.getOrDefault("Expected.Exists")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "Expected.Exists", valid_611499
  var valid_611500 = query.getOrDefault("Attributes")
  valid_611500 = validateParameter(valid_611500, JArray, required = true, default = nil)
  if valid_611500 != nil:
    section.add "Attributes", valid_611500
  var valid_611501 = query.getOrDefault("Timestamp")
  valid_611501 = validateParameter(valid_611501, JString, required = true,
                                 default = nil)
  if valid_611501 != nil:
    section.add "Timestamp", valid_611501
  var valid_611502 = query.getOrDefault("Action")
  valid_611502 = validateParameter(valid_611502, JString, required = true,
                                 default = newJString("PutAttributes"))
  if valid_611502 != nil:
    section.add "Action", valid_611502
  var valid_611503 = query.getOrDefault("Version")
  valid_611503 = validateParameter(valid_611503, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_611503 != nil:
    section.add "Version", valid_611503
  var valid_611504 = query.getOrDefault("SignatureVersion")
  valid_611504 = validateParameter(valid_611504, JString, required = true,
                                 default = nil)
  if valid_611504 != nil:
    section.add "SignatureVersion", valid_611504
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611505: Call_GetPutAttributes_611489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  let valid = call_611505.validator(path, query, header, formData, body)
  let scheme = call_611505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611505.url(scheme.get, call_611505.host, call_611505.base,
                         call_611505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611505, url, valid)

proc call*(call_611506: Call_GetPutAttributes_611489; Signature: string;
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
  var query_611507 = newJObject()
  add(query_611507, "Signature", newJString(Signature))
  add(query_611507, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611507, "Expected.Value", newJString(ExpectedValue))
  add(query_611507, "SignatureMethod", newJString(SignatureMethod))
  add(query_611507, "DomainName", newJString(DomainName))
  add(query_611507, "Expected.Name", newJString(ExpectedName))
  add(query_611507, "ItemName", newJString(ItemName))
  add(query_611507, "Expected.Exists", newJString(ExpectedExists))
  if Attributes != nil:
    query_611507.add "Attributes", Attributes
  add(query_611507, "Timestamp", newJString(Timestamp))
  add(query_611507, "Action", newJString(Action))
  add(query_611507, "Version", newJString(Version))
  add(query_611507, "SignatureVersion", newJString(SignatureVersion))
  result = call_611506.call(nil, query_611507, nil, nil, nil)

var getPutAttributes* = Call_GetPutAttributes_611489(name: "getPutAttributes",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=PutAttributes", validator: validate_GetPutAttributes_611490,
    base: "/", url: url_GetPutAttributes_611491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSelect_611544 = ref object of OpenApiRestCall_610642
proc url_PostSelect_611546(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSelect_611545(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611547 = query.getOrDefault("Signature")
  valid_611547 = validateParameter(valid_611547, JString, required = true,
                                 default = nil)
  if valid_611547 != nil:
    section.add "Signature", valid_611547
  var valid_611548 = query.getOrDefault("AWSAccessKeyId")
  valid_611548 = validateParameter(valid_611548, JString, required = true,
                                 default = nil)
  if valid_611548 != nil:
    section.add "AWSAccessKeyId", valid_611548
  var valid_611549 = query.getOrDefault("SignatureMethod")
  valid_611549 = validateParameter(valid_611549, JString, required = true,
                                 default = nil)
  if valid_611549 != nil:
    section.add "SignatureMethod", valid_611549
  var valid_611550 = query.getOrDefault("Timestamp")
  valid_611550 = validateParameter(valid_611550, JString, required = true,
                                 default = nil)
  if valid_611550 != nil:
    section.add "Timestamp", valid_611550
  var valid_611551 = query.getOrDefault("Action")
  valid_611551 = validateParameter(valid_611551, JString, required = true,
                                 default = newJString("Select"))
  if valid_611551 != nil:
    section.add "Action", valid_611551
  var valid_611552 = query.getOrDefault("Version")
  valid_611552 = validateParameter(valid_611552, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_611552 != nil:
    section.add "Version", valid_611552
  var valid_611553 = query.getOrDefault("SignatureVersion")
  valid_611553 = validateParameter(valid_611553, JString, required = true,
                                 default = nil)
  if valid_611553 != nil:
    section.add "SignatureVersion", valid_611553
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
  var valid_611554 = formData.getOrDefault("NextToken")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "NextToken", valid_611554
  assert formData != nil, "formData argument is necessary due to required `SelectExpression` field"
  var valid_611555 = formData.getOrDefault("SelectExpression")
  valid_611555 = validateParameter(valid_611555, JString, required = true,
                                 default = nil)
  if valid_611555 != nil:
    section.add "SelectExpression", valid_611555
  var valid_611556 = formData.getOrDefault("ConsistentRead")
  valid_611556 = validateParameter(valid_611556, JBool, required = false, default = nil)
  if valid_611556 != nil:
    section.add "ConsistentRead", valid_611556
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611557: Call_PostSelect_611544; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  let valid = call_611557.validator(path, query, header, formData, body)
  let scheme = call_611557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611557.url(scheme.get, call_611557.host, call_611557.base,
                         call_611557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611557, url, valid)

proc call*(call_611558: Call_PostSelect_611544; Signature: string;
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
  var query_611559 = newJObject()
  var formData_611560 = newJObject()
  add(query_611559, "Signature", newJString(Signature))
  add(query_611559, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_611560, "NextToken", newJString(NextToken))
  add(query_611559, "SignatureMethod", newJString(SignatureMethod))
  add(formData_611560, "SelectExpression", newJString(SelectExpression))
  add(formData_611560, "ConsistentRead", newJBool(ConsistentRead))
  add(query_611559, "Timestamp", newJString(Timestamp))
  add(query_611559, "Action", newJString(Action))
  add(query_611559, "Version", newJString(Version))
  add(query_611559, "SignatureVersion", newJString(SignatureVersion))
  result = call_611558.call(nil, query_611559, nil, formData_611560, nil)

var postSelect* = Call_PostSelect_611544(name: "postSelect",
                                      meth: HttpMethod.HttpPost,
                                      host: "sdb.amazonaws.com",
                                      route: "/#Action=Select",
                                      validator: validate_PostSelect_611545,
                                      base: "/", url: url_PostSelect_611546,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSelect_611528 = ref object of OpenApiRestCall_610642
proc url_GetSelect_611530(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSelect_611529(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611531 = query.getOrDefault("Signature")
  valid_611531 = validateParameter(valid_611531, JString, required = true,
                                 default = nil)
  if valid_611531 != nil:
    section.add "Signature", valid_611531
  var valid_611532 = query.getOrDefault("AWSAccessKeyId")
  valid_611532 = validateParameter(valid_611532, JString, required = true,
                                 default = nil)
  if valid_611532 != nil:
    section.add "AWSAccessKeyId", valid_611532
  var valid_611533 = query.getOrDefault("SignatureMethod")
  valid_611533 = validateParameter(valid_611533, JString, required = true,
                                 default = nil)
  if valid_611533 != nil:
    section.add "SignatureMethod", valid_611533
  var valid_611534 = query.getOrDefault("NextToken")
  valid_611534 = validateParameter(valid_611534, JString, required = false,
                                 default = nil)
  if valid_611534 != nil:
    section.add "NextToken", valid_611534
  var valid_611535 = query.getOrDefault("SelectExpression")
  valid_611535 = validateParameter(valid_611535, JString, required = true,
                                 default = nil)
  if valid_611535 != nil:
    section.add "SelectExpression", valid_611535
  var valid_611536 = query.getOrDefault("Timestamp")
  valid_611536 = validateParameter(valid_611536, JString, required = true,
                                 default = nil)
  if valid_611536 != nil:
    section.add "Timestamp", valid_611536
  var valid_611537 = query.getOrDefault("Action")
  valid_611537 = validateParameter(valid_611537, JString, required = true,
                                 default = newJString("Select"))
  if valid_611537 != nil:
    section.add "Action", valid_611537
  var valid_611538 = query.getOrDefault("ConsistentRead")
  valid_611538 = validateParameter(valid_611538, JBool, required = false, default = nil)
  if valid_611538 != nil:
    section.add "ConsistentRead", valid_611538
  var valid_611539 = query.getOrDefault("Version")
  valid_611539 = validateParameter(valid_611539, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_611539 != nil:
    section.add "Version", valid_611539
  var valid_611540 = query.getOrDefault("SignatureVersion")
  valid_611540 = validateParameter(valid_611540, JString, required = true,
                                 default = nil)
  if valid_611540 != nil:
    section.add "SignatureVersion", valid_611540
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611541: Call_GetSelect_611528; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  let valid = call_611541.validator(path, query, header, formData, body)
  let scheme = call_611541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611541.url(scheme.get, call_611541.host, call_611541.base,
                         call_611541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611541, url, valid)

proc call*(call_611542: Call_GetSelect_611528; Signature: string;
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
  var query_611543 = newJObject()
  add(query_611543, "Signature", newJString(Signature))
  add(query_611543, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611543, "SignatureMethod", newJString(SignatureMethod))
  add(query_611543, "NextToken", newJString(NextToken))
  add(query_611543, "SelectExpression", newJString(SelectExpression))
  add(query_611543, "Timestamp", newJString(Timestamp))
  add(query_611543, "Action", newJString(Action))
  add(query_611543, "ConsistentRead", newJBool(ConsistentRead))
  add(query_611543, "Version", newJString(Version))
  add(query_611543, "SignatureVersion", newJString(SignatureVersion))
  result = call_611542.call(nil, query_611543, nil, nil, nil)

var getSelect* = Call_GetSelect_611528(name: "getSelect", meth: HttpMethod.HttpGet,
                                    host: "sdb.amazonaws.com",
                                    route: "/#Action=Select",
                                    validator: validate_GetSelect_611529,
                                    base: "/", url: url_GetSelect_611530,
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
