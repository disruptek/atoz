
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

  OpenApiRestCall_612642 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612642](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612642): Option[Scheme] {.used.} =
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
  Call_PostBatchDeleteAttributes_613250 = ref object of OpenApiRestCall_612642
proc url_PostBatchDeleteAttributes_613252(protocol: Scheme; host: string;
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

proc validate_PostBatchDeleteAttributes_613251(path: JsonNode; query: JsonNode;
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
  var valid_613253 = query.getOrDefault("Signature")
  valid_613253 = validateParameter(valid_613253, JString, required = true,
                                 default = nil)
  if valid_613253 != nil:
    section.add "Signature", valid_613253
  var valid_613254 = query.getOrDefault("AWSAccessKeyId")
  valid_613254 = validateParameter(valid_613254, JString, required = true,
                                 default = nil)
  if valid_613254 != nil:
    section.add "AWSAccessKeyId", valid_613254
  var valid_613255 = query.getOrDefault("SignatureMethod")
  valid_613255 = validateParameter(valid_613255, JString, required = true,
                                 default = nil)
  if valid_613255 != nil:
    section.add "SignatureMethod", valid_613255
  var valid_613256 = query.getOrDefault("Timestamp")
  valid_613256 = validateParameter(valid_613256, JString, required = true,
                                 default = nil)
  if valid_613256 != nil:
    section.add "Timestamp", valid_613256
  var valid_613257 = query.getOrDefault("Action")
  valid_613257 = validateParameter(valid_613257, JString, required = true,
                                 default = newJString("BatchDeleteAttributes"))
  if valid_613257 != nil:
    section.add "Action", valid_613257
  var valid_613258 = query.getOrDefault("Version")
  valid_613258 = validateParameter(valid_613258, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_613258 != nil:
    section.add "Version", valid_613258
  var valid_613259 = query.getOrDefault("SignatureVersion")
  valid_613259 = validateParameter(valid_613259, JString, required = true,
                                 default = nil)
  if valid_613259 != nil:
    section.add "SignatureVersion", valid_613259
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
  var valid_613260 = formData.getOrDefault("DomainName")
  valid_613260 = validateParameter(valid_613260, JString, required = true,
                                 default = nil)
  if valid_613260 != nil:
    section.add "DomainName", valid_613260
  var valid_613261 = formData.getOrDefault("Items")
  valid_613261 = validateParameter(valid_613261, JArray, required = true, default = nil)
  if valid_613261 != nil:
    section.add "Items", valid_613261
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613262: Call_PostBatchDeleteAttributes_613250; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  let valid = call_613262.validator(path, query, header, formData, body)
  let scheme = call_613262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613262.url(scheme.get, call_613262.host, call_613262.base,
                         call_613262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613262, url, valid)

proc call*(call_613263: Call_PostBatchDeleteAttributes_613250; Signature: string;
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
  var query_613264 = newJObject()
  var formData_613265 = newJObject()
  add(query_613264, "Signature", newJString(Signature))
  add(query_613264, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613264, "SignatureMethod", newJString(SignatureMethod))
  add(formData_613265, "DomainName", newJString(DomainName))
  add(query_613264, "Timestamp", newJString(Timestamp))
  add(query_613264, "Action", newJString(Action))
  if Items != nil:
    formData_613265.add "Items", Items
  add(query_613264, "Version", newJString(Version))
  add(query_613264, "SignatureVersion", newJString(SignatureVersion))
  result = call_613263.call(nil, query_613264, nil, formData_613265, nil)

var postBatchDeleteAttributes* = Call_PostBatchDeleteAttributes_613250(
    name: "postBatchDeleteAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=BatchDeleteAttributes",
    validator: validate_PostBatchDeleteAttributes_613251, base: "/",
    url: url_PostBatchDeleteAttributes_613252,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchDeleteAttributes_612980 = ref object of OpenApiRestCall_612642
proc url_GetBatchDeleteAttributes_612982(protocol: Scheme; host: string;
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

proc validate_GetBatchDeleteAttributes_612981(path: JsonNode; query: JsonNode;
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
  var valid_613094 = query.getOrDefault("Signature")
  valid_613094 = validateParameter(valid_613094, JString, required = true,
                                 default = nil)
  if valid_613094 != nil:
    section.add "Signature", valid_613094
  var valid_613095 = query.getOrDefault("AWSAccessKeyId")
  valid_613095 = validateParameter(valid_613095, JString, required = true,
                                 default = nil)
  if valid_613095 != nil:
    section.add "AWSAccessKeyId", valid_613095
  var valid_613096 = query.getOrDefault("SignatureMethod")
  valid_613096 = validateParameter(valid_613096, JString, required = true,
                                 default = nil)
  if valid_613096 != nil:
    section.add "SignatureMethod", valid_613096
  var valid_613097 = query.getOrDefault("DomainName")
  valid_613097 = validateParameter(valid_613097, JString, required = true,
                                 default = nil)
  if valid_613097 != nil:
    section.add "DomainName", valid_613097
  var valid_613098 = query.getOrDefault("Items")
  valid_613098 = validateParameter(valid_613098, JArray, required = true, default = nil)
  if valid_613098 != nil:
    section.add "Items", valid_613098
  var valid_613099 = query.getOrDefault("Timestamp")
  valid_613099 = validateParameter(valid_613099, JString, required = true,
                                 default = nil)
  if valid_613099 != nil:
    section.add "Timestamp", valid_613099
  var valid_613113 = query.getOrDefault("Action")
  valid_613113 = validateParameter(valid_613113, JString, required = true,
                                 default = newJString("BatchDeleteAttributes"))
  if valid_613113 != nil:
    section.add "Action", valid_613113
  var valid_613114 = query.getOrDefault("Version")
  valid_613114 = validateParameter(valid_613114, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_613114 != nil:
    section.add "Version", valid_613114
  var valid_613115 = query.getOrDefault("SignatureVersion")
  valid_613115 = validateParameter(valid_613115, JString, required = true,
                                 default = nil)
  if valid_613115 != nil:
    section.add "SignatureVersion", valid_613115
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613138: Call_GetBatchDeleteAttributes_612980; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  let valid = call_613138.validator(path, query, header, formData, body)
  let scheme = call_613138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613138.url(scheme.get, call_613138.host, call_613138.base,
                         call_613138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613138, url, valid)

proc call*(call_613209: Call_GetBatchDeleteAttributes_612980; Signature: string;
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
  var query_613210 = newJObject()
  add(query_613210, "Signature", newJString(Signature))
  add(query_613210, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613210, "SignatureMethod", newJString(SignatureMethod))
  add(query_613210, "DomainName", newJString(DomainName))
  if Items != nil:
    query_613210.add "Items", Items
  add(query_613210, "Timestamp", newJString(Timestamp))
  add(query_613210, "Action", newJString(Action))
  add(query_613210, "Version", newJString(Version))
  add(query_613210, "SignatureVersion", newJString(SignatureVersion))
  result = call_613209.call(nil, query_613210, nil, nil, nil)

var getBatchDeleteAttributes* = Call_GetBatchDeleteAttributes_612980(
    name: "getBatchDeleteAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=BatchDeleteAttributes",
    validator: validate_GetBatchDeleteAttributes_612981, base: "/",
    url: url_GetBatchDeleteAttributes_612982, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostBatchPutAttributes_613281 = ref object of OpenApiRestCall_612642
proc url_PostBatchPutAttributes_613283(protocol: Scheme; host: string; base: string;
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

proc validate_PostBatchPutAttributes_613282(path: JsonNode; query: JsonNode;
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
  var valid_613284 = query.getOrDefault("Signature")
  valid_613284 = validateParameter(valid_613284, JString, required = true,
                                 default = nil)
  if valid_613284 != nil:
    section.add "Signature", valid_613284
  var valid_613285 = query.getOrDefault("AWSAccessKeyId")
  valid_613285 = validateParameter(valid_613285, JString, required = true,
                                 default = nil)
  if valid_613285 != nil:
    section.add "AWSAccessKeyId", valid_613285
  var valid_613286 = query.getOrDefault("SignatureMethod")
  valid_613286 = validateParameter(valid_613286, JString, required = true,
                                 default = nil)
  if valid_613286 != nil:
    section.add "SignatureMethod", valid_613286
  var valid_613287 = query.getOrDefault("Timestamp")
  valid_613287 = validateParameter(valid_613287, JString, required = true,
                                 default = nil)
  if valid_613287 != nil:
    section.add "Timestamp", valid_613287
  var valid_613288 = query.getOrDefault("Action")
  valid_613288 = validateParameter(valid_613288, JString, required = true,
                                 default = newJString("BatchPutAttributes"))
  if valid_613288 != nil:
    section.add "Action", valid_613288
  var valid_613289 = query.getOrDefault("Version")
  valid_613289 = validateParameter(valid_613289, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_613289 != nil:
    section.add "Version", valid_613289
  var valid_613290 = query.getOrDefault("SignatureVersion")
  valid_613290 = validateParameter(valid_613290, JString, required = true,
                                 default = nil)
  if valid_613290 != nil:
    section.add "SignatureVersion", valid_613290
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
  var valid_613291 = formData.getOrDefault("DomainName")
  valid_613291 = validateParameter(valid_613291, JString, required = true,
                                 default = nil)
  if valid_613291 != nil:
    section.add "DomainName", valid_613291
  var valid_613292 = formData.getOrDefault("Items")
  valid_613292 = validateParameter(valid_613292, JArray, required = true, default = nil)
  if valid_613292 != nil:
    section.add "Items", valid_613292
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613293: Call_PostBatchPutAttributes_613281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  let valid = call_613293.validator(path, query, header, formData, body)
  let scheme = call_613293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613293.url(scheme.get, call_613293.host, call_613293.base,
                         call_613293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613293, url, valid)

proc call*(call_613294: Call_PostBatchPutAttributes_613281; Signature: string;
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
  var query_613295 = newJObject()
  var formData_613296 = newJObject()
  add(query_613295, "Signature", newJString(Signature))
  add(query_613295, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613295, "SignatureMethod", newJString(SignatureMethod))
  add(formData_613296, "DomainName", newJString(DomainName))
  add(query_613295, "Timestamp", newJString(Timestamp))
  add(query_613295, "Action", newJString(Action))
  if Items != nil:
    formData_613296.add "Items", Items
  add(query_613295, "Version", newJString(Version))
  add(query_613295, "SignatureVersion", newJString(SignatureVersion))
  result = call_613294.call(nil, query_613295, nil, formData_613296, nil)

var postBatchPutAttributes* = Call_PostBatchPutAttributes_613281(
    name: "postBatchPutAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=BatchPutAttributes",
    validator: validate_PostBatchPutAttributes_613282, base: "/",
    url: url_PostBatchPutAttributes_613283, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchPutAttributes_613266 = ref object of OpenApiRestCall_612642
proc url_GetBatchPutAttributes_613268(protocol: Scheme; host: string; base: string;
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

proc validate_GetBatchPutAttributes_613267(path: JsonNode; query: JsonNode;
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
  var valid_613269 = query.getOrDefault("Signature")
  valid_613269 = validateParameter(valid_613269, JString, required = true,
                                 default = nil)
  if valid_613269 != nil:
    section.add "Signature", valid_613269
  var valid_613270 = query.getOrDefault("AWSAccessKeyId")
  valid_613270 = validateParameter(valid_613270, JString, required = true,
                                 default = nil)
  if valid_613270 != nil:
    section.add "AWSAccessKeyId", valid_613270
  var valid_613271 = query.getOrDefault("SignatureMethod")
  valid_613271 = validateParameter(valid_613271, JString, required = true,
                                 default = nil)
  if valid_613271 != nil:
    section.add "SignatureMethod", valid_613271
  var valid_613272 = query.getOrDefault("DomainName")
  valid_613272 = validateParameter(valid_613272, JString, required = true,
                                 default = nil)
  if valid_613272 != nil:
    section.add "DomainName", valid_613272
  var valid_613273 = query.getOrDefault("Items")
  valid_613273 = validateParameter(valid_613273, JArray, required = true, default = nil)
  if valid_613273 != nil:
    section.add "Items", valid_613273
  var valid_613274 = query.getOrDefault("Timestamp")
  valid_613274 = validateParameter(valid_613274, JString, required = true,
                                 default = nil)
  if valid_613274 != nil:
    section.add "Timestamp", valid_613274
  var valid_613275 = query.getOrDefault("Action")
  valid_613275 = validateParameter(valid_613275, JString, required = true,
                                 default = newJString("BatchPutAttributes"))
  if valid_613275 != nil:
    section.add "Action", valid_613275
  var valid_613276 = query.getOrDefault("Version")
  valid_613276 = validateParameter(valid_613276, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_613276 != nil:
    section.add "Version", valid_613276
  var valid_613277 = query.getOrDefault("SignatureVersion")
  valid_613277 = validateParameter(valid_613277, JString, required = true,
                                 default = nil)
  if valid_613277 != nil:
    section.add "SignatureVersion", valid_613277
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613278: Call_GetBatchPutAttributes_613266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  let valid = call_613278.validator(path, query, header, formData, body)
  let scheme = call_613278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613278.url(scheme.get, call_613278.host, call_613278.base,
                         call_613278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613278, url, valid)

proc call*(call_613279: Call_GetBatchPutAttributes_613266; Signature: string;
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
  var query_613280 = newJObject()
  add(query_613280, "Signature", newJString(Signature))
  add(query_613280, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613280, "SignatureMethod", newJString(SignatureMethod))
  add(query_613280, "DomainName", newJString(DomainName))
  if Items != nil:
    query_613280.add "Items", Items
  add(query_613280, "Timestamp", newJString(Timestamp))
  add(query_613280, "Action", newJString(Action))
  add(query_613280, "Version", newJString(Version))
  add(query_613280, "SignatureVersion", newJString(SignatureVersion))
  result = call_613279.call(nil, query_613280, nil, nil, nil)

var getBatchPutAttributes* = Call_GetBatchPutAttributes_613266(
    name: "getBatchPutAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=BatchPutAttributes",
    validator: validate_GetBatchPutAttributes_613267, base: "/",
    url: url_GetBatchPutAttributes_613268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDomain_613311 = ref object of OpenApiRestCall_612642
proc url_PostCreateDomain_613313(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDomain_613312(path: JsonNode; query: JsonNode;
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
  var valid_613314 = query.getOrDefault("Signature")
  valid_613314 = validateParameter(valid_613314, JString, required = true,
                                 default = nil)
  if valid_613314 != nil:
    section.add "Signature", valid_613314
  var valid_613315 = query.getOrDefault("AWSAccessKeyId")
  valid_613315 = validateParameter(valid_613315, JString, required = true,
                                 default = nil)
  if valid_613315 != nil:
    section.add "AWSAccessKeyId", valid_613315
  var valid_613316 = query.getOrDefault("SignatureMethod")
  valid_613316 = validateParameter(valid_613316, JString, required = true,
                                 default = nil)
  if valid_613316 != nil:
    section.add "SignatureMethod", valid_613316
  var valid_613317 = query.getOrDefault("Timestamp")
  valid_613317 = validateParameter(valid_613317, JString, required = true,
                                 default = nil)
  if valid_613317 != nil:
    section.add "Timestamp", valid_613317
  var valid_613318 = query.getOrDefault("Action")
  valid_613318 = validateParameter(valid_613318, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_613318 != nil:
    section.add "Action", valid_613318
  var valid_613319 = query.getOrDefault("Version")
  valid_613319 = validateParameter(valid_613319, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_613319 != nil:
    section.add "Version", valid_613319
  var valid_613320 = query.getOrDefault("SignatureVersion")
  valid_613320 = validateParameter(valid_613320, JString, required = true,
                                 default = nil)
  if valid_613320 != nil:
    section.add "SignatureVersion", valid_613320
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain to create. The name can range between 3 and 255 characters and can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613321 = formData.getOrDefault("DomainName")
  valid_613321 = validateParameter(valid_613321, JString, required = true,
                                 default = nil)
  if valid_613321 != nil:
    section.add "DomainName", valid_613321
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613322: Call_PostCreateDomain_613311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  let valid = call_613322.validator(path, query, header, formData, body)
  let scheme = call_613322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613322.url(scheme.get, call_613322.host, call_613322.base,
                         call_613322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613322, url, valid)

proc call*(call_613323: Call_PostCreateDomain_613311; Signature: string;
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
  var query_613324 = newJObject()
  var formData_613325 = newJObject()
  add(query_613324, "Signature", newJString(Signature))
  add(query_613324, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613324, "SignatureMethod", newJString(SignatureMethod))
  add(formData_613325, "DomainName", newJString(DomainName))
  add(query_613324, "Timestamp", newJString(Timestamp))
  add(query_613324, "Action", newJString(Action))
  add(query_613324, "Version", newJString(Version))
  add(query_613324, "SignatureVersion", newJString(SignatureVersion))
  result = call_613323.call(nil, query_613324, nil, formData_613325, nil)

var postCreateDomain* = Call_PostCreateDomain_613311(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_613312,
    base: "/", url: url_PostCreateDomain_613313,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_613297 = ref object of OpenApiRestCall_612642
proc url_GetCreateDomain_613299(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDomain_613298(path: JsonNode; query: JsonNode;
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
  var valid_613300 = query.getOrDefault("Signature")
  valid_613300 = validateParameter(valid_613300, JString, required = true,
                                 default = nil)
  if valid_613300 != nil:
    section.add "Signature", valid_613300
  var valid_613301 = query.getOrDefault("AWSAccessKeyId")
  valid_613301 = validateParameter(valid_613301, JString, required = true,
                                 default = nil)
  if valid_613301 != nil:
    section.add "AWSAccessKeyId", valid_613301
  var valid_613302 = query.getOrDefault("SignatureMethod")
  valid_613302 = validateParameter(valid_613302, JString, required = true,
                                 default = nil)
  if valid_613302 != nil:
    section.add "SignatureMethod", valid_613302
  var valid_613303 = query.getOrDefault("DomainName")
  valid_613303 = validateParameter(valid_613303, JString, required = true,
                                 default = nil)
  if valid_613303 != nil:
    section.add "DomainName", valid_613303
  var valid_613304 = query.getOrDefault("Timestamp")
  valid_613304 = validateParameter(valid_613304, JString, required = true,
                                 default = nil)
  if valid_613304 != nil:
    section.add "Timestamp", valid_613304
  var valid_613305 = query.getOrDefault("Action")
  valid_613305 = validateParameter(valid_613305, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_613305 != nil:
    section.add "Action", valid_613305
  var valid_613306 = query.getOrDefault("Version")
  valid_613306 = validateParameter(valid_613306, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_613306 != nil:
    section.add "Version", valid_613306
  var valid_613307 = query.getOrDefault("SignatureVersion")
  valid_613307 = validateParameter(valid_613307, JString, required = true,
                                 default = nil)
  if valid_613307 != nil:
    section.add "SignatureVersion", valid_613307
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613308: Call_GetCreateDomain_613297; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  let valid = call_613308.validator(path, query, header, formData, body)
  let scheme = call_613308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613308.url(scheme.get, call_613308.host, call_613308.base,
                         call_613308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613308, url, valid)

proc call*(call_613309: Call_GetCreateDomain_613297; Signature: string;
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
  var query_613310 = newJObject()
  add(query_613310, "Signature", newJString(Signature))
  add(query_613310, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613310, "SignatureMethod", newJString(SignatureMethod))
  add(query_613310, "DomainName", newJString(DomainName))
  add(query_613310, "Timestamp", newJString(Timestamp))
  add(query_613310, "Action", newJString(Action))
  add(query_613310, "Version", newJString(Version))
  add(query_613310, "SignatureVersion", newJString(SignatureVersion))
  result = call_613309.call(nil, query_613310, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_613297(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_613298,
    base: "/", url: url_GetCreateDomain_613299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAttributes_613345 = ref object of OpenApiRestCall_612642
proc url_PostDeleteAttributes_613347(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteAttributes_613346(path: JsonNode; query: JsonNode;
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
  var valid_613348 = query.getOrDefault("Signature")
  valid_613348 = validateParameter(valid_613348, JString, required = true,
                                 default = nil)
  if valid_613348 != nil:
    section.add "Signature", valid_613348
  var valid_613349 = query.getOrDefault("AWSAccessKeyId")
  valid_613349 = validateParameter(valid_613349, JString, required = true,
                                 default = nil)
  if valid_613349 != nil:
    section.add "AWSAccessKeyId", valid_613349
  var valid_613350 = query.getOrDefault("SignatureMethod")
  valid_613350 = validateParameter(valid_613350, JString, required = true,
                                 default = nil)
  if valid_613350 != nil:
    section.add "SignatureMethod", valid_613350
  var valid_613351 = query.getOrDefault("Timestamp")
  valid_613351 = validateParameter(valid_613351, JString, required = true,
                                 default = nil)
  if valid_613351 != nil:
    section.add "Timestamp", valid_613351
  var valid_613352 = query.getOrDefault("Action")
  valid_613352 = validateParameter(valid_613352, JString, required = true,
                                 default = newJString("DeleteAttributes"))
  if valid_613352 != nil:
    section.add "Action", valid_613352
  var valid_613353 = query.getOrDefault("Version")
  valid_613353 = validateParameter(valid_613353, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_613353 != nil:
    section.add "Version", valid_613353
  var valid_613354 = query.getOrDefault("SignatureVersion")
  valid_613354 = validateParameter(valid_613354, JString, required = true,
                                 default = nil)
  if valid_613354 != nil:
    section.add "SignatureVersion", valid_613354
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
  var valid_613355 = formData.getOrDefault("Expected.Value")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "Expected.Value", valid_613355
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613356 = formData.getOrDefault("DomainName")
  valid_613356 = validateParameter(valid_613356, JString, required = true,
                                 default = nil)
  if valid_613356 != nil:
    section.add "DomainName", valid_613356
  var valid_613357 = formData.getOrDefault("Attributes")
  valid_613357 = validateParameter(valid_613357, JArray, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "Attributes", valid_613357
  var valid_613358 = formData.getOrDefault("Expected.Name")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "Expected.Name", valid_613358
  var valid_613359 = formData.getOrDefault("Expected.Exists")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "Expected.Exists", valid_613359
  var valid_613360 = formData.getOrDefault("ItemName")
  valid_613360 = validateParameter(valid_613360, JString, required = true,
                                 default = nil)
  if valid_613360 != nil:
    section.add "ItemName", valid_613360
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613361: Call_PostDeleteAttributes_613345; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  let valid = call_613361.validator(path, query, header, formData, body)
  let scheme = call_613361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613361.url(scheme.get, call_613361.host, call_613361.base,
                         call_613361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613361, url, valid)

proc call*(call_613362: Call_PostDeleteAttributes_613345; Signature: string;
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
  var query_613363 = newJObject()
  var formData_613364 = newJObject()
  add(formData_613364, "Expected.Value", newJString(ExpectedValue))
  add(query_613363, "Signature", newJString(Signature))
  add(query_613363, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613363, "SignatureMethod", newJString(SignatureMethod))
  add(formData_613364, "DomainName", newJString(DomainName))
  if Attributes != nil:
    formData_613364.add "Attributes", Attributes
  add(query_613363, "Timestamp", newJString(Timestamp))
  add(query_613363, "Action", newJString(Action))
  add(formData_613364, "Expected.Name", newJString(ExpectedName))
  add(query_613363, "Version", newJString(Version))
  add(formData_613364, "Expected.Exists", newJString(ExpectedExists))
  add(query_613363, "SignatureVersion", newJString(SignatureVersion))
  add(formData_613364, "ItemName", newJString(ItemName))
  result = call_613362.call(nil, query_613363, nil, formData_613364, nil)

var postDeleteAttributes* = Call_PostDeleteAttributes_613345(
    name: "postDeleteAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=DeleteAttributes",
    validator: validate_PostDeleteAttributes_613346, base: "/",
    url: url_PostDeleteAttributes_613347, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAttributes_613326 = ref object of OpenApiRestCall_612642
proc url_GetDeleteAttributes_613328(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteAttributes_613327(path: JsonNode; query: JsonNode;
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
  var valid_613329 = query.getOrDefault("Signature")
  valid_613329 = validateParameter(valid_613329, JString, required = true,
                                 default = nil)
  if valid_613329 != nil:
    section.add "Signature", valid_613329
  var valid_613330 = query.getOrDefault("AWSAccessKeyId")
  valid_613330 = validateParameter(valid_613330, JString, required = true,
                                 default = nil)
  if valid_613330 != nil:
    section.add "AWSAccessKeyId", valid_613330
  var valid_613331 = query.getOrDefault("Expected.Value")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "Expected.Value", valid_613331
  var valid_613332 = query.getOrDefault("SignatureMethod")
  valid_613332 = validateParameter(valid_613332, JString, required = true,
                                 default = nil)
  if valid_613332 != nil:
    section.add "SignatureMethod", valid_613332
  var valid_613333 = query.getOrDefault("DomainName")
  valid_613333 = validateParameter(valid_613333, JString, required = true,
                                 default = nil)
  if valid_613333 != nil:
    section.add "DomainName", valid_613333
  var valid_613334 = query.getOrDefault("Expected.Name")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "Expected.Name", valid_613334
  var valid_613335 = query.getOrDefault("ItemName")
  valid_613335 = validateParameter(valid_613335, JString, required = true,
                                 default = nil)
  if valid_613335 != nil:
    section.add "ItemName", valid_613335
  var valid_613336 = query.getOrDefault("Expected.Exists")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "Expected.Exists", valid_613336
  var valid_613337 = query.getOrDefault("Attributes")
  valid_613337 = validateParameter(valid_613337, JArray, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "Attributes", valid_613337
  var valid_613338 = query.getOrDefault("Timestamp")
  valid_613338 = validateParameter(valid_613338, JString, required = true,
                                 default = nil)
  if valid_613338 != nil:
    section.add "Timestamp", valid_613338
  var valid_613339 = query.getOrDefault("Action")
  valid_613339 = validateParameter(valid_613339, JString, required = true,
                                 default = newJString("DeleteAttributes"))
  if valid_613339 != nil:
    section.add "Action", valid_613339
  var valid_613340 = query.getOrDefault("Version")
  valid_613340 = validateParameter(valid_613340, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_613340 != nil:
    section.add "Version", valid_613340
  var valid_613341 = query.getOrDefault("SignatureVersion")
  valid_613341 = validateParameter(valid_613341, JString, required = true,
                                 default = nil)
  if valid_613341 != nil:
    section.add "SignatureVersion", valid_613341
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613342: Call_GetDeleteAttributes_613326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  let valid = call_613342.validator(path, query, header, formData, body)
  let scheme = call_613342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613342.url(scheme.get, call_613342.host, call_613342.base,
                         call_613342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613342, url, valid)

proc call*(call_613343: Call_GetDeleteAttributes_613326; Signature: string;
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
  var query_613344 = newJObject()
  add(query_613344, "Signature", newJString(Signature))
  add(query_613344, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613344, "Expected.Value", newJString(ExpectedValue))
  add(query_613344, "SignatureMethod", newJString(SignatureMethod))
  add(query_613344, "DomainName", newJString(DomainName))
  add(query_613344, "Expected.Name", newJString(ExpectedName))
  add(query_613344, "ItemName", newJString(ItemName))
  add(query_613344, "Expected.Exists", newJString(ExpectedExists))
  if Attributes != nil:
    query_613344.add "Attributes", Attributes
  add(query_613344, "Timestamp", newJString(Timestamp))
  add(query_613344, "Action", newJString(Action))
  add(query_613344, "Version", newJString(Version))
  add(query_613344, "SignatureVersion", newJString(SignatureVersion))
  result = call_613343.call(nil, query_613344, nil, nil, nil)

var getDeleteAttributes* = Call_GetDeleteAttributes_613326(
    name: "getDeleteAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=DeleteAttributes",
    validator: validate_GetDeleteAttributes_613327, base: "/",
    url: url_GetDeleteAttributes_613328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_613379 = ref object of OpenApiRestCall_612642
proc url_PostDeleteDomain_613381(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDomain_613380(path: JsonNode; query: JsonNode;
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
  var valid_613382 = query.getOrDefault("Signature")
  valid_613382 = validateParameter(valid_613382, JString, required = true,
                                 default = nil)
  if valid_613382 != nil:
    section.add "Signature", valid_613382
  var valid_613383 = query.getOrDefault("AWSAccessKeyId")
  valid_613383 = validateParameter(valid_613383, JString, required = true,
                                 default = nil)
  if valid_613383 != nil:
    section.add "AWSAccessKeyId", valid_613383
  var valid_613384 = query.getOrDefault("SignatureMethod")
  valid_613384 = validateParameter(valid_613384, JString, required = true,
                                 default = nil)
  if valid_613384 != nil:
    section.add "SignatureMethod", valid_613384
  var valid_613385 = query.getOrDefault("Timestamp")
  valid_613385 = validateParameter(valid_613385, JString, required = true,
                                 default = nil)
  if valid_613385 != nil:
    section.add "Timestamp", valid_613385
  var valid_613386 = query.getOrDefault("Action")
  valid_613386 = validateParameter(valid_613386, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_613386 != nil:
    section.add "Action", valid_613386
  var valid_613387 = query.getOrDefault("Version")
  valid_613387 = validateParameter(valid_613387, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_613387 != nil:
    section.add "Version", valid_613387
  var valid_613388 = query.getOrDefault("SignatureVersion")
  valid_613388 = validateParameter(valid_613388, JString, required = true,
                                 default = nil)
  if valid_613388 != nil:
    section.add "SignatureVersion", valid_613388
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613389 = formData.getOrDefault("DomainName")
  valid_613389 = validateParameter(valid_613389, JString, required = true,
                                 default = nil)
  if valid_613389 != nil:
    section.add "DomainName", valid_613389
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613390: Call_PostDeleteDomain_613379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  let valid = call_613390.validator(path, query, header, formData, body)
  let scheme = call_613390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613390.url(scheme.get, call_613390.host, call_613390.base,
                         call_613390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613390, url, valid)

proc call*(call_613391: Call_PostDeleteDomain_613379; Signature: string;
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
  var query_613392 = newJObject()
  var formData_613393 = newJObject()
  add(query_613392, "Signature", newJString(Signature))
  add(query_613392, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613392, "SignatureMethod", newJString(SignatureMethod))
  add(formData_613393, "DomainName", newJString(DomainName))
  add(query_613392, "Timestamp", newJString(Timestamp))
  add(query_613392, "Action", newJString(Action))
  add(query_613392, "Version", newJString(Version))
  add(query_613392, "SignatureVersion", newJString(SignatureVersion))
  result = call_613391.call(nil, query_613392, nil, formData_613393, nil)

var postDeleteDomain* = Call_PostDeleteDomain_613379(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_613380,
    base: "/", url: url_PostDeleteDomain_613381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_613365 = ref object of OpenApiRestCall_612642
proc url_GetDeleteDomain_613367(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDomain_613366(path: JsonNode; query: JsonNode;
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
  var valid_613368 = query.getOrDefault("Signature")
  valid_613368 = validateParameter(valid_613368, JString, required = true,
                                 default = nil)
  if valid_613368 != nil:
    section.add "Signature", valid_613368
  var valid_613369 = query.getOrDefault("AWSAccessKeyId")
  valid_613369 = validateParameter(valid_613369, JString, required = true,
                                 default = nil)
  if valid_613369 != nil:
    section.add "AWSAccessKeyId", valid_613369
  var valid_613370 = query.getOrDefault("SignatureMethod")
  valid_613370 = validateParameter(valid_613370, JString, required = true,
                                 default = nil)
  if valid_613370 != nil:
    section.add "SignatureMethod", valid_613370
  var valid_613371 = query.getOrDefault("DomainName")
  valid_613371 = validateParameter(valid_613371, JString, required = true,
                                 default = nil)
  if valid_613371 != nil:
    section.add "DomainName", valid_613371
  var valid_613372 = query.getOrDefault("Timestamp")
  valid_613372 = validateParameter(valid_613372, JString, required = true,
                                 default = nil)
  if valid_613372 != nil:
    section.add "Timestamp", valid_613372
  var valid_613373 = query.getOrDefault("Action")
  valid_613373 = validateParameter(valid_613373, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_613373 != nil:
    section.add "Action", valid_613373
  var valid_613374 = query.getOrDefault("Version")
  valid_613374 = validateParameter(valid_613374, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_613374 != nil:
    section.add "Version", valid_613374
  var valid_613375 = query.getOrDefault("SignatureVersion")
  valid_613375 = validateParameter(valid_613375, JString, required = true,
                                 default = nil)
  if valid_613375 != nil:
    section.add "SignatureVersion", valid_613375
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613376: Call_GetDeleteDomain_613365; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  let valid = call_613376.validator(path, query, header, formData, body)
  let scheme = call_613376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613376.url(scheme.get, call_613376.host, call_613376.base,
                         call_613376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613376, url, valid)

proc call*(call_613377: Call_GetDeleteDomain_613365; Signature: string;
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
  var query_613378 = newJObject()
  add(query_613378, "Signature", newJString(Signature))
  add(query_613378, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613378, "SignatureMethod", newJString(SignatureMethod))
  add(query_613378, "DomainName", newJString(DomainName))
  add(query_613378, "Timestamp", newJString(Timestamp))
  add(query_613378, "Action", newJString(Action))
  add(query_613378, "Version", newJString(Version))
  add(query_613378, "SignatureVersion", newJString(SignatureVersion))
  result = call_613377.call(nil, query_613378, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_613365(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_613366,
    base: "/", url: url_GetDeleteDomain_613367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDomainMetadata_613408 = ref object of OpenApiRestCall_612642
proc url_PostDomainMetadata_613410(protocol: Scheme; host: string; base: string;
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

proc validate_PostDomainMetadata_613409(path: JsonNode; query: JsonNode;
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
  var valid_613411 = query.getOrDefault("Signature")
  valid_613411 = validateParameter(valid_613411, JString, required = true,
                                 default = nil)
  if valid_613411 != nil:
    section.add "Signature", valid_613411
  var valid_613412 = query.getOrDefault("AWSAccessKeyId")
  valid_613412 = validateParameter(valid_613412, JString, required = true,
                                 default = nil)
  if valid_613412 != nil:
    section.add "AWSAccessKeyId", valid_613412
  var valid_613413 = query.getOrDefault("SignatureMethod")
  valid_613413 = validateParameter(valid_613413, JString, required = true,
                                 default = nil)
  if valid_613413 != nil:
    section.add "SignatureMethod", valid_613413
  var valid_613414 = query.getOrDefault("Timestamp")
  valid_613414 = validateParameter(valid_613414, JString, required = true,
                                 default = nil)
  if valid_613414 != nil:
    section.add "Timestamp", valid_613414
  var valid_613415 = query.getOrDefault("Action")
  valid_613415 = validateParameter(valid_613415, JString, required = true,
                                 default = newJString("DomainMetadata"))
  if valid_613415 != nil:
    section.add "Action", valid_613415
  var valid_613416 = query.getOrDefault("Version")
  valid_613416 = validateParameter(valid_613416, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_613416 != nil:
    section.add "Version", valid_613416
  var valid_613417 = query.getOrDefault("SignatureVersion")
  valid_613417 = validateParameter(valid_613417, JString, required = true,
                                 default = nil)
  if valid_613417 != nil:
    section.add "SignatureVersion", valid_613417
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain for which to display the metadata of.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613418 = formData.getOrDefault("DomainName")
  valid_613418 = validateParameter(valid_613418, JString, required = true,
                                 default = nil)
  if valid_613418 != nil:
    section.add "DomainName", valid_613418
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613419: Call_PostDomainMetadata_613408; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  let valid = call_613419.validator(path, query, header, formData, body)
  let scheme = call_613419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613419.url(scheme.get, call_613419.host, call_613419.base,
                         call_613419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613419, url, valid)

proc call*(call_613420: Call_PostDomainMetadata_613408; Signature: string;
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
  var query_613421 = newJObject()
  var formData_613422 = newJObject()
  add(query_613421, "Signature", newJString(Signature))
  add(query_613421, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613421, "SignatureMethod", newJString(SignatureMethod))
  add(formData_613422, "DomainName", newJString(DomainName))
  add(query_613421, "Timestamp", newJString(Timestamp))
  add(query_613421, "Action", newJString(Action))
  add(query_613421, "Version", newJString(Version))
  add(query_613421, "SignatureVersion", newJString(SignatureVersion))
  result = call_613420.call(nil, query_613421, nil, formData_613422, nil)

var postDomainMetadata* = Call_PostDomainMetadata_613408(
    name: "postDomainMetadata", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=DomainMetadata",
    validator: validate_PostDomainMetadata_613409, base: "/",
    url: url_PostDomainMetadata_613410, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainMetadata_613394 = ref object of OpenApiRestCall_612642
proc url_GetDomainMetadata_613396(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainMetadata_613395(path: JsonNode; query: JsonNode;
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
  var valid_613397 = query.getOrDefault("Signature")
  valid_613397 = validateParameter(valid_613397, JString, required = true,
                                 default = nil)
  if valid_613397 != nil:
    section.add "Signature", valid_613397
  var valid_613398 = query.getOrDefault("AWSAccessKeyId")
  valid_613398 = validateParameter(valid_613398, JString, required = true,
                                 default = nil)
  if valid_613398 != nil:
    section.add "AWSAccessKeyId", valid_613398
  var valid_613399 = query.getOrDefault("SignatureMethod")
  valid_613399 = validateParameter(valid_613399, JString, required = true,
                                 default = nil)
  if valid_613399 != nil:
    section.add "SignatureMethod", valid_613399
  var valid_613400 = query.getOrDefault("DomainName")
  valid_613400 = validateParameter(valid_613400, JString, required = true,
                                 default = nil)
  if valid_613400 != nil:
    section.add "DomainName", valid_613400
  var valid_613401 = query.getOrDefault("Timestamp")
  valid_613401 = validateParameter(valid_613401, JString, required = true,
                                 default = nil)
  if valid_613401 != nil:
    section.add "Timestamp", valid_613401
  var valid_613402 = query.getOrDefault("Action")
  valid_613402 = validateParameter(valid_613402, JString, required = true,
                                 default = newJString("DomainMetadata"))
  if valid_613402 != nil:
    section.add "Action", valid_613402
  var valid_613403 = query.getOrDefault("Version")
  valid_613403 = validateParameter(valid_613403, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_613403 != nil:
    section.add "Version", valid_613403
  var valid_613404 = query.getOrDefault("SignatureVersion")
  valid_613404 = validateParameter(valid_613404, JString, required = true,
                                 default = nil)
  if valid_613404 != nil:
    section.add "SignatureVersion", valid_613404
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613405: Call_GetDomainMetadata_613394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  let valid = call_613405.validator(path, query, header, formData, body)
  let scheme = call_613405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613405.url(scheme.get, call_613405.host, call_613405.base,
                         call_613405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613405, url, valid)

proc call*(call_613406: Call_GetDomainMetadata_613394; Signature: string;
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
  var query_613407 = newJObject()
  add(query_613407, "Signature", newJString(Signature))
  add(query_613407, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613407, "SignatureMethod", newJString(SignatureMethod))
  add(query_613407, "DomainName", newJString(DomainName))
  add(query_613407, "Timestamp", newJString(Timestamp))
  add(query_613407, "Action", newJString(Action))
  add(query_613407, "Version", newJString(Version))
  add(query_613407, "SignatureVersion", newJString(SignatureVersion))
  result = call_613406.call(nil, query_613407, nil, nil, nil)

var getDomainMetadata* = Call_GetDomainMetadata_613394(name: "getDomainMetadata",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=DomainMetadata", validator: validate_GetDomainMetadata_613395,
    base: "/", url: url_GetDomainMetadata_613396,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetAttributes_613440 = ref object of OpenApiRestCall_612642
proc url_PostGetAttributes_613442(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetAttributes_613441(path: JsonNode; query: JsonNode;
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
  var valid_613443 = query.getOrDefault("Signature")
  valid_613443 = validateParameter(valid_613443, JString, required = true,
                                 default = nil)
  if valid_613443 != nil:
    section.add "Signature", valid_613443
  var valid_613444 = query.getOrDefault("AWSAccessKeyId")
  valid_613444 = validateParameter(valid_613444, JString, required = true,
                                 default = nil)
  if valid_613444 != nil:
    section.add "AWSAccessKeyId", valid_613444
  var valid_613445 = query.getOrDefault("SignatureMethod")
  valid_613445 = validateParameter(valid_613445, JString, required = true,
                                 default = nil)
  if valid_613445 != nil:
    section.add "SignatureMethod", valid_613445
  var valid_613446 = query.getOrDefault("Timestamp")
  valid_613446 = validateParameter(valid_613446, JString, required = true,
                                 default = nil)
  if valid_613446 != nil:
    section.add "Timestamp", valid_613446
  var valid_613447 = query.getOrDefault("Action")
  valid_613447 = validateParameter(valid_613447, JString, required = true,
                                 default = newJString("GetAttributes"))
  if valid_613447 != nil:
    section.add "Action", valid_613447
  var valid_613448 = query.getOrDefault("Version")
  valid_613448 = validateParameter(valid_613448, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_613448 != nil:
    section.add "Version", valid_613448
  var valid_613449 = query.getOrDefault("SignatureVersion")
  valid_613449 = validateParameter(valid_613449, JString, required = true,
                                 default = nil)
  if valid_613449 != nil:
    section.add "SignatureVersion", valid_613449
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
  var valid_613450 = formData.getOrDefault("ConsistentRead")
  valid_613450 = validateParameter(valid_613450, JBool, required = false, default = nil)
  if valid_613450 != nil:
    section.add "ConsistentRead", valid_613450
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613451 = formData.getOrDefault("DomainName")
  valid_613451 = validateParameter(valid_613451, JString, required = true,
                                 default = nil)
  if valid_613451 != nil:
    section.add "DomainName", valid_613451
  var valid_613452 = formData.getOrDefault("AttributeNames")
  valid_613452 = validateParameter(valid_613452, JArray, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "AttributeNames", valid_613452
  var valid_613453 = formData.getOrDefault("ItemName")
  valid_613453 = validateParameter(valid_613453, JString, required = true,
                                 default = nil)
  if valid_613453 != nil:
    section.add "ItemName", valid_613453
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613454: Call_PostGetAttributes_613440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  let valid = call_613454.validator(path, query, header, formData, body)
  let scheme = call_613454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613454.url(scheme.get, call_613454.host, call_613454.base,
                         call_613454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613454, url, valid)

proc call*(call_613455: Call_PostGetAttributes_613440; Signature: string;
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
  var query_613456 = newJObject()
  var formData_613457 = newJObject()
  add(query_613456, "Signature", newJString(Signature))
  add(query_613456, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613456, "SignatureMethod", newJString(SignatureMethod))
  add(formData_613457, "ConsistentRead", newJBool(ConsistentRead))
  add(formData_613457, "DomainName", newJString(DomainName))
  if AttributeNames != nil:
    formData_613457.add "AttributeNames", AttributeNames
  add(query_613456, "Timestamp", newJString(Timestamp))
  add(query_613456, "Action", newJString(Action))
  add(query_613456, "Version", newJString(Version))
  add(query_613456, "SignatureVersion", newJString(SignatureVersion))
  add(formData_613457, "ItemName", newJString(ItemName))
  result = call_613455.call(nil, query_613456, nil, formData_613457, nil)

var postGetAttributes* = Call_PostGetAttributes_613440(name: "postGetAttributes",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=GetAttributes", validator: validate_PostGetAttributes_613441,
    base: "/", url: url_PostGetAttributes_613442,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetAttributes_613423 = ref object of OpenApiRestCall_612642
proc url_GetGetAttributes_613425(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetAttributes_613424(path: JsonNode; query: JsonNode;
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
  var valid_613426 = query.getOrDefault("Signature")
  valid_613426 = validateParameter(valid_613426, JString, required = true,
                                 default = nil)
  if valid_613426 != nil:
    section.add "Signature", valid_613426
  var valid_613427 = query.getOrDefault("AWSAccessKeyId")
  valid_613427 = validateParameter(valid_613427, JString, required = true,
                                 default = nil)
  if valid_613427 != nil:
    section.add "AWSAccessKeyId", valid_613427
  var valid_613428 = query.getOrDefault("AttributeNames")
  valid_613428 = validateParameter(valid_613428, JArray, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "AttributeNames", valid_613428
  var valid_613429 = query.getOrDefault("SignatureMethod")
  valid_613429 = validateParameter(valid_613429, JString, required = true,
                                 default = nil)
  if valid_613429 != nil:
    section.add "SignatureMethod", valid_613429
  var valid_613430 = query.getOrDefault("DomainName")
  valid_613430 = validateParameter(valid_613430, JString, required = true,
                                 default = nil)
  if valid_613430 != nil:
    section.add "DomainName", valid_613430
  var valid_613431 = query.getOrDefault("ItemName")
  valid_613431 = validateParameter(valid_613431, JString, required = true,
                                 default = nil)
  if valid_613431 != nil:
    section.add "ItemName", valid_613431
  var valid_613432 = query.getOrDefault("Timestamp")
  valid_613432 = validateParameter(valid_613432, JString, required = true,
                                 default = nil)
  if valid_613432 != nil:
    section.add "Timestamp", valid_613432
  var valid_613433 = query.getOrDefault("Action")
  valid_613433 = validateParameter(valid_613433, JString, required = true,
                                 default = newJString("GetAttributes"))
  if valid_613433 != nil:
    section.add "Action", valid_613433
  var valid_613434 = query.getOrDefault("ConsistentRead")
  valid_613434 = validateParameter(valid_613434, JBool, required = false, default = nil)
  if valid_613434 != nil:
    section.add "ConsistentRead", valid_613434
  var valid_613435 = query.getOrDefault("Version")
  valid_613435 = validateParameter(valid_613435, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_613435 != nil:
    section.add "Version", valid_613435
  var valid_613436 = query.getOrDefault("SignatureVersion")
  valid_613436 = validateParameter(valid_613436, JString, required = true,
                                 default = nil)
  if valid_613436 != nil:
    section.add "SignatureVersion", valid_613436
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613437: Call_GetGetAttributes_613423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  let valid = call_613437.validator(path, query, header, formData, body)
  let scheme = call_613437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613437.url(scheme.get, call_613437.host, call_613437.base,
                         call_613437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613437, url, valid)

proc call*(call_613438: Call_GetGetAttributes_613423; Signature: string;
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
  var query_613439 = newJObject()
  add(query_613439, "Signature", newJString(Signature))
  add(query_613439, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  if AttributeNames != nil:
    query_613439.add "AttributeNames", AttributeNames
  add(query_613439, "SignatureMethod", newJString(SignatureMethod))
  add(query_613439, "DomainName", newJString(DomainName))
  add(query_613439, "ItemName", newJString(ItemName))
  add(query_613439, "Timestamp", newJString(Timestamp))
  add(query_613439, "Action", newJString(Action))
  add(query_613439, "ConsistentRead", newJBool(ConsistentRead))
  add(query_613439, "Version", newJString(Version))
  add(query_613439, "SignatureVersion", newJString(SignatureVersion))
  result = call_613438.call(nil, query_613439, nil, nil, nil)

var getGetAttributes* = Call_GetGetAttributes_613423(name: "getGetAttributes",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=GetAttributes", validator: validate_GetGetAttributes_613424,
    base: "/", url: url_GetGetAttributes_613425,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDomains_613473 = ref object of OpenApiRestCall_612642
proc url_PostListDomains_613475(protocol: Scheme; host: string; base: string;
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

proc validate_PostListDomains_613474(path: JsonNode; query: JsonNode;
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
  var valid_613476 = query.getOrDefault("Signature")
  valid_613476 = validateParameter(valid_613476, JString, required = true,
                                 default = nil)
  if valid_613476 != nil:
    section.add "Signature", valid_613476
  var valid_613477 = query.getOrDefault("AWSAccessKeyId")
  valid_613477 = validateParameter(valid_613477, JString, required = true,
                                 default = nil)
  if valid_613477 != nil:
    section.add "AWSAccessKeyId", valid_613477
  var valid_613478 = query.getOrDefault("SignatureMethod")
  valid_613478 = validateParameter(valid_613478, JString, required = true,
                                 default = nil)
  if valid_613478 != nil:
    section.add "SignatureMethod", valid_613478
  var valid_613479 = query.getOrDefault("Timestamp")
  valid_613479 = validateParameter(valid_613479, JString, required = true,
                                 default = nil)
  if valid_613479 != nil:
    section.add "Timestamp", valid_613479
  var valid_613480 = query.getOrDefault("Action")
  valid_613480 = validateParameter(valid_613480, JString, required = true,
                                 default = newJString("ListDomains"))
  if valid_613480 != nil:
    section.add "Action", valid_613480
  var valid_613481 = query.getOrDefault("Version")
  valid_613481 = validateParameter(valid_613481, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_613481 != nil:
    section.add "Version", valid_613481
  var valid_613482 = query.getOrDefault("SignatureVersion")
  valid_613482 = validateParameter(valid_613482, JString, required = true,
                                 default = nil)
  if valid_613482 != nil:
    section.add "SignatureVersion", valid_613482
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : A string informing Amazon SimpleDB where to start the next list of domain names.
  ##   MaxNumberOfDomains: JInt
  ##                     : The maximum number of domain names you want returned. The range is 1 to 100. The default setting is 100.
  section = newJObject()
  var valid_613483 = formData.getOrDefault("NextToken")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "NextToken", valid_613483
  var valid_613484 = formData.getOrDefault("MaxNumberOfDomains")
  valid_613484 = validateParameter(valid_613484, JInt, required = false, default = nil)
  if valid_613484 != nil:
    section.add "MaxNumberOfDomains", valid_613484
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613485: Call_PostListDomains_613473; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  let valid = call_613485.validator(path, query, header, formData, body)
  let scheme = call_613485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613485.url(scheme.get, call_613485.host, call_613485.base,
                         call_613485.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613485, url, valid)

proc call*(call_613486: Call_PostListDomains_613473; Signature: string;
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
  var query_613487 = newJObject()
  var formData_613488 = newJObject()
  add(query_613487, "Signature", newJString(Signature))
  add(query_613487, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_613488, "NextToken", newJString(NextToken))
  add(query_613487, "SignatureMethod", newJString(SignatureMethod))
  add(formData_613488, "MaxNumberOfDomains", newJInt(MaxNumberOfDomains))
  add(query_613487, "Timestamp", newJString(Timestamp))
  add(query_613487, "Action", newJString(Action))
  add(query_613487, "Version", newJString(Version))
  add(query_613487, "SignatureVersion", newJString(SignatureVersion))
  result = call_613486.call(nil, query_613487, nil, formData_613488, nil)

var postListDomains* = Call_PostListDomains_613473(name: "postListDomains",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=ListDomains", validator: validate_PostListDomains_613474,
    base: "/", url: url_PostListDomains_613475, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDomains_613458 = ref object of OpenApiRestCall_612642
proc url_GetListDomains_613460(protocol: Scheme; host: string; base: string;
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

proc validate_GetListDomains_613459(path: JsonNode; query: JsonNode;
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
  var valid_613461 = query.getOrDefault("Signature")
  valid_613461 = validateParameter(valid_613461, JString, required = true,
                                 default = nil)
  if valid_613461 != nil:
    section.add "Signature", valid_613461
  var valid_613462 = query.getOrDefault("AWSAccessKeyId")
  valid_613462 = validateParameter(valid_613462, JString, required = true,
                                 default = nil)
  if valid_613462 != nil:
    section.add "AWSAccessKeyId", valid_613462
  var valid_613463 = query.getOrDefault("SignatureMethod")
  valid_613463 = validateParameter(valid_613463, JString, required = true,
                                 default = nil)
  if valid_613463 != nil:
    section.add "SignatureMethod", valid_613463
  var valid_613464 = query.getOrDefault("NextToken")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "NextToken", valid_613464
  var valid_613465 = query.getOrDefault("MaxNumberOfDomains")
  valid_613465 = validateParameter(valid_613465, JInt, required = false, default = nil)
  if valid_613465 != nil:
    section.add "MaxNumberOfDomains", valid_613465
  var valid_613466 = query.getOrDefault("Timestamp")
  valid_613466 = validateParameter(valid_613466, JString, required = true,
                                 default = nil)
  if valid_613466 != nil:
    section.add "Timestamp", valid_613466
  var valid_613467 = query.getOrDefault("Action")
  valid_613467 = validateParameter(valid_613467, JString, required = true,
                                 default = newJString("ListDomains"))
  if valid_613467 != nil:
    section.add "Action", valid_613467
  var valid_613468 = query.getOrDefault("Version")
  valid_613468 = validateParameter(valid_613468, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_613468 != nil:
    section.add "Version", valid_613468
  var valid_613469 = query.getOrDefault("SignatureVersion")
  valid_613469 = validateParameter(valid_613469, JString, required = true,
                                 default = nil)
  if valid_613469 != nil:
    section.add "SignatureVersion", valid_613469
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613470: Call_GetListDomains_613458; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  let valid = call_613470.validator(path, query, header, formData, body)
  let scheme = call_613470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613470.url(scheme.get, call_613470.host, call_613470.base,
                         call_613470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613470, url, valid)

proc call*(call_613471: Call_GetListDomains_613458; Signature: string;
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
  var query_613472 = newJObject()
  add(query_613472, "Signature", newJString(Signature))
  add(query_613472, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613472, "SignatureMethod", newJString(SignatureMethod))
  add(query_613472, "NextToken", newJString(NextToken))
  add(query_613472, "MaxNumberOfDomains", newJInt(MaxNumberOfDomains))
  add(query_613472, "Timestamp", newJString(Timestamp))
  add(query_613472, "Action", newJString(Action))
  add(query_613472, "Version", newJString(Version))
  add(query_613472, "SignatureVersion", newJString(SignatureVersion))
  result = call_613471.call(nil, query_613472, nil, nil, nil)

var getListDomains* = Call_GetListDomains_613458(name: "getListDomains",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=ListDomains", validator: validate_GetListDomains_613459,
    base: "/", url: url_GetListDomains_613460, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutAttributes_613508 = ref object of OpenApiRestCall_612642
proc url_PostPutAttributes_613510(protocol: Scheme; host: string; base: string;
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

proc validate_PostPutAttributes_613509(path: JsonNode; query: JsonNode;
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
  var valid_613511 = query.getOrDefault("Signature")
  valid_613511 = validateParameter(valid_613511, JString, required = true,
                                 default = nil)
  if valid_613511 != nil:
    section.add "Signature", valid_613511
  var valid_613512 = query.getOrDefault("AWSAccessKeyId")
  valid_613512 = validateParameter(valid_613512, JString, required = true,
                                 default = nil)
  if valid_613512 != nil:
    section.add "AWSAccessKeyId", valid_613512
  var valid_613513 = query.getOrDefault("SignatureMethod")
  valid_613513 = validateParameter(valid_613513, JString, required = true,
                                 default = nil)
  if valid_613513 != nil:
    section.add "SignatureMethod", valid_613513
  var valid_613514 = query.getOrDefault("Timestamp")
  valid_613514 = validateParameter(valid_613514, JString, required = true,
                                 default = nil)
  if valid_613514 != nil:
    section.add "Timestamp", valid_613514
  var valid_613515 = query.getOrDefault("Action")
  valid_613515 = validateParameter(valid_613515, JString, required = true,
                                 default = newJString("PutAttributes"))
  if valid_613515 != nil:
    section.add "Action", valid_613515
  var valid_613516 = query.getOrDefault("Version")
  valid_613516 = validateParameter(valid_613516, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_613516 != nil:
    section.add "Version", valid_613516
  var valid_613517 = query.getOrDefault("SignatureVersion")
  valid_613517 = validateParameter(valid_613517, JString, required = true,
                                 default = nil)
  if valid_613517 != nil:
    section.add "SignatureVersion", valid_613517
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
  var valid_613518 = formData.getOrDefault("Expected.Value")
  valid_613518 = validateParameter(valid_613518, JString, required = false,
                                 default = nil)
  if valid_613518 != nil:
    section.add "Expected.Value", valid_613518
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613519 = formData.getOrDefault("DomainName")
  valid_613519 = validateParameter(valid_613519, JString, required = true,
                                 default = nil)
  if valid_613519 != nil:
    section.add "DomainName", valid_613519
  var valid_613520 = formData.getOrDefault("Attributes")
  valid_613520 = validateParameter(valid_613520, JArray, required = true, default = nil)
  if valid_613520 != nil:
    section.add "Attributes", valid_613520
  var valid_613521 = formData.getOrDefault("Expected.Name")
  valid_613521 = validateParameter(valid_613521, JString, required = false,
                                 default = nil)
  if valid_613521 != nil:
    section.add "Expected.Name", valid_613521
  var valid_613522 = formData.getOrDefault("Expected.Exists")
  valid_613522 = validateParameter(valid_613522, JString, required = false,
                                 default = nil)
  if valid_613522 != nil:
    section.add "Expected.Exists", valid_613522
  var valid_613523 = formData.getOrDefault("ItemName")
  valid_613523 = validateParameter(valid_613523, JString, required = true,
                                 default = nil)
  if valid_613523 != nil:
    section.add "ItemName", valid_613523
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613524: Call_PostPutAttributes_613508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  let valid = call_613524.validator(path, query, header, formData, body)
  let scheme = call_613524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613524.url(scheme.get, call_613524.host, call_613524.base,
                         call_613524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613524, url, valid)

proc call*(call_613525: Call_PostPutAttributes_613508; Signature: string;
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
  var query_613526 = newJObject()
  var formData_613527 = newJObject()
  add(formData_613527, "Expected.Value", newJString(ExpectedValue))
  add(query_613526, "Signature", newJString(Signature))
  add(query_613526, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613526, "SignatureMethod", newJString(SignatureMethod))
  add(formData_613527, "DomainName", newJString(DomainName))
  if Attributes != nil:
    formData_613527.add "Attributes", Attributes
  add(query_613526, "Timestamp", newJString(Timestamp))
  add(query_613526, "Action", newJString(Action))
  add(formData_613527, "Expected.Name", newJString(ExpectedName))
  add(query_613526, "Version", newJString(Version))
  add(formData_613527, "Expected.Exists", newJString(ExpectedExists))
  add(query_613526, "SignatureVersion", newJString(SignatureVersion))
  add(formData_613527, "ItemName", newJString(ItemName))
  result = call_613525.call(nil, query_613526, nil, formData_613527, nil)

var postPutAttributes* = Call_PostPutAttributes_613508(name: "postPutAttributes",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=PutAttributes", validator: validate_PostPutAttributes_613509,
    base: "/", url: url_PostPutAttributes_613510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutAttributes_613489 = ref object of OpenApiRestCall_612642
proc url_GetPutAttributes_613491(protocol: Scheme; host: string; base: string;
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

proc validate_GetPutAttributes_613490(path: JsonNode; query: JsonNode;
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
  var valid_613492 = query.getOrDefault("Signature")
  valid_613492 = validateParameter(valid_613492, JString, required = true,
                                 default = nil)
  if valid_613492 != nil:
    section.add "Signature", valid_613492
  var valid_613493 = query.getOrDefault("AWSAccessKeyId")
  valid_613493 = validateParameter(valid_613493, JString, required = true,
                                 default = nil)
  if valid_613493 != nil:
    section.add "AWSAccessKeyId", valid_613493
  var valid_613494 = query.getOrDefault("Expected.Value")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "Expected.Value", valid_613494
  var valid_613495 = query.getOrDefault("SignatureMethod")
  valid_613495 = validateParameter(valid_613495, JString, required = true,
                                 default = nil)
  if valid_613495 != nil:
    section.add "SignatureMethod", valid_613495
  var valid_613496 = query.getOrDefault("DomainName")
  valid_613496 = validateParameter(valid_613496, JString, required = true,
                                 default = nil)
  if valid_613496 != nil:
    section.add "DomainName", valid_613496
  var valid_613497 = query.getOrDefault("Expected.Name")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "Expected.Name", valid_613497
  var valid_613498 = query.getOrDefault("ItemName")
  valid_613498 = validateParameter(valid_613498, JString, required = true,
                                 default = nil)
  if valid_613498 != nil:
    section.add "ItemName", valid_613498
  var valid_613499 = query.getOrDefault("Expected.Exists")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "Expected.Exists", valid_613499
  var valid_613500 = query.getOrDefault("Attributes")
  valid_613500 = validateParameter(valid_613500, JArray, required = true, default = nil)
  if valid_613500 != nil:
    section.add "Attributes", valid_613500
  var valid_613501 = query.getOrDefault("Timestamp")
  valid_613501 = validateParameter(valid_613501, JString, required = true,
                                 default = nil)
  if valid_613501 != nil:
    section.add "Timestamp", valid_613501
  var valid_613502 = query.getOrDefault("Action")
  valid_613502 = validateParameter(valid_613502, JString, required = true,
                                 default = newJString("PutAttributes"))
  if valid_613502 != nil:
    section.add "Action", valid_613502
  var valid_613503 = query.getOrDefault("Version")
  valid_613503 = validateParameter(valid_613503, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_613503 != nil:
    section.add "Version", valid_613503
  var valid_613504 = query.getOrDefault("SignatureVersion")
  valid_613504 = validateParameter(valid_613504, JString, required = true,
                                 default = nil)
  if valid_613504 != nil:
    section.add "SignatureVersion", valid_613504
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613505: Call_GetPutAttributes_613489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  let valid = call_613505.validator(path, query, header, formData, body)
  let scheme = call_613505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613505.url(scheme.get, call_613505.host, call_613505.base,
                         call_613505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613505, url, valid)

proc call*(call_613506: Call_GetPutAttributes_613489; Signature: string;
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
  var query_613507 = newJObject()
  add(query_613507, "Signature", newJString(Signature))
  add(query_613507, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613507, "Expected.Value", newJString(ExpectedValue))
  add(query_613507, "SignatureMethod", newJString(SignatureMethod))
  add(query_613507, "DomainName", newJString(DomainName))
  add(query_613507, "Expected.Name", newJString(ExpectedName))
  add(query_613507, "ItemName", newJString(ItemName))
  add(query_613507, "Expected.Exists", newJString(ExpectedExists))
  if Attributes != nil:
    query_613507.add "Attributes", Attributes
  add(query_613507, "Timestamp", newJString(Timestamp))
  add(query_613507, "Action", newJString(Action))
  add(query_613507, "Version", newJString(Version))
  add(query_613507, "SignatureVersion", newJString(SignatureVersion))
  result = call_613506.call(nil, query_613507, nil, nil, nil)

var getPutAttributes* = Call_GetPutAttributes_613489(name: "getPutAttributes",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=PutAttributes", validator: validate_GetPutAttributes_613490,
    base: "/", url: url_GetPutAttributes_613491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSelect_613544 = ref object of OpenApiRestCall_612642
proc url_PostSelect_613546(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PostSelect_613545(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613547 = query.getOrDefault("Signature")
  valid_613547 = validateParameter(valid_613547, JString, required = true,
                                 default = nil)
  if valid_613547 != nil:
    section.add "Signature", valid_613547
  var valid_613548 = query.getOrDefault("AWSAccessKeyId")
  valid_613548 = validateParameter(valid_613548, JString, required = true,
                                 default = nil)
  if valid_613548 != nil:
    section.add "AWSAccessKeyId", valid_613548
  var valid_613549 = query.getOrDefault("SignatureMethod")
  valid_613549 = validateParameter(valid_613549, JString, required = true,
                                 default = nil)
  if valid_613549 != nil:
    section.add "SignatureMethod", valid_613549
  var valid_613550 = query.getOrDefault("Timestamp")
  valid_613550 = validateParameter(valid_613550, JString, required = true,
                                 default = nil)
  if valid_613550 != nil:
    section.add "Timestamp", valid_613550
  var valid_613551 = query.getOrDefault("Action")
  valid_613551 = validateParameter(valid_613551, JString, required = true,
                                 default = newJString("Select"))
  if valid_613551 != nil:
    section.add "Action", valid_613551
  var valid_613552 = query.getOrDefault("Version")
  valid_613552 = validateParameter(valid_613552, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_613552 != nil:
    section.add "Version", valid_613552
  var valid_613553 = query.getOrDefault("SignatureVersion")
  valid_613553 = validateParameter(valid_613553, JString, required = true,
                                 default = nil)
  if valid_613553 != nil:
    section.add "SignatureVersion", valid_613553
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
  var valid_613554 = formData.getOrDefault("NextToken")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "NextToken", valid_613554
  assert formData != nil, "formData argument is necessary due to required `SelectExpression` field"
  var valid_613555 = formData.getOrDefault("SelectExpression")
  valid_613555 = validateParameter(valid_613555, JString, required = true,
                                 default = nil)
  if valid_613555 != nil:
    section.add "SelectExpression", valid_613555
  var valid_613556 = formData.getOrDefault("ConsistentRead")
  valid_613556 = validateParameter(valid_613556, JBool, required = false, default = nil)
  if valid_613556 != nil:
    section.add "ConsistentRead", valid_613556
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613557: Call_PostSelect_613544; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  let valid = call_613557.validator(path, query, header, formData, body)
  let scheme = call_613557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613557.url(scheme.get, call_613557.host, call_613557.base,
                         call_613557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613557, url, valid)

proc call*(call_613558: Call_PostSelect_613544; Signature: string;
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
  var query_613559 = newJObject()
  var formData_613560 = newJObject()
  add(query_613559, "Signature", newJString(Signature))
  add(query_613559, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_613560, "NextToken", newJString(NextToken))
  add(query_613559, "SignatureMethod", newJString(SignatureMethod))
  add(formData_613560, "SelectExpression", newJString(SelectExpression))
  add(formData_613560, "ConsistentRead", newJBool(ConsistentRead))
  add(query_613559, "Timestamp", newJString(Timestamp))
  add(query_613559, "Action", newJString(Action))
  add(query_613559, "Version", newJString(Version))
  add(query_613559, "SignatureVersion", newJString(SignatureVersion))
  result = call_613558.call(nil, query_613559, nil, formData_613560, nil)

var postSelect* = Call_PostSelect_613544(name: "postSelect",
                                      meth: HttpMethod.HttpPost,
                                      host: "sdb.amazonaws.com",
                                      route: "/#Action=Select",
                                      validator: validate_PostSelect_613545,
                                      base: "/", url: url_PostSelect_613546,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSelect_613528 = ref object of OpenApiRestCall_612642
proc url_GetSelect_613530(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSelect_613529(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613531 = query.getOrDefault("Signature")
  valid_613531 = validateParameter(valid_613531, JString, required = true,
                                 default = nil)
  if valid_613531 != nil:
    section.add "Signature", valid_613531
  var valid_613532 = query.getOrDefault("AWSAccessKeyId")
  valid_613532 = validateParameter(valid_613532, JString, required = true,
                                 default = nil)
  if valid_613532 != nil:
    section.add "AWSAccessKeyId", valid_613532
  var valid_613533 = query.getOrDefault("SignatureMethod")
  valid_613533 = validateParameter(valid_613533, JString, required = true,
                                 default = nil)
  if valid_613533 != nil:
    section.add "SignatureMethod", valid_613533
  var valid_613534 = query.getOrDefault("NextToken")
  valid_613534 = validateParameter(valid_613534, JString, required = false,
                                 default = nil)
  if valid_613534 != nil:
    section.add "NextToken", valid_613534
  var valid_613535 = query.getOrDefault("SelectExpression")
  valid_613535 = validateParameter(valid_613535, JString, required = true,
                                 default = nil)
  if valid_613535 != nil:
    section.add "SelectExpression", valid_613535
  var valid_613536 = query.getOrDefault("Timestamp")
  valid_613536 = validateParameter(valid_613536, JString, required = true,
                                 default = nil)
  if valid_613536 != nil:
    section.add "Timestamp", valid_613536
  var valid_613537 = query.getOrDefault("Action")
  valid_613537 = validateParameter(valid_613537, JString, required = true,
                                 default = newJString("Select"))
  if valid_613537 != nil:
    section.add "Action", valid_613537
  var valid_613538 = query.getOrDefault("ConsistentRead")
  valid_613538 = validateParameter(valid_613538, JBool, required = false, default = nil)
  if valid_613538 != nil:
    section.add "ConsistentRead", valid_613538
  var valid_613539 = query.getOrDefault("Version")
  valid_613539 = validateParameter(valid_613539, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_613539 != nil:
    section.add "Version", valid_613539
  var valid_613540 = query.getOrDefault("SignatureVersion")
  valid_613540 = validateParameter(valid_613540, JString, required = true,
                                 default = nil)
  if valid_613540 != nil:
    section.add "SignatureVersion", valid_613540
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613541: Call_GetSelect_613528; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  let valid = call_613541.validator(path, query, header, formData, body)
  let scheme = call_613541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613541.url(scheme.get, call_613541.host, call_613541.base,
                         call_613541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613541, url, valid)

proc call*(call_613542: Call_GetSelect_613528; Signature: string;
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
  var query_613543 = newJObject()
  add(query_613543, "Signature", newJString(Signature))
  add(query_613543, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613543, "SignatureMethod", newJString(SignatureMethod))
  add(query_613543, "NextToken", newJString(NextToken))
  add(query_613543, "SelectExpression", newJString(SelectExpression))
  add(query_613543, "Timestamp", newJString(Timestamp))
  add(query_613543, "Action", newJString(Action))
  add(query_613543, "ConsistentRead", newJBool(ConsistentRead))
  add(query_613543, "Version", newJString(Version))
  add(query_613543, "SignatureVersion", newJString(SignatureVersion))
  result = call_613542.call(nil, query_613543, nil, nil, nil)

var getSelect* = Call_GetSelect_613528(name: "getSelect", meth: HttpMethod.HttpGet,
                                    host: "sdb.amazonaws.com",
                                    route: "/#Action=Select",
                                    validator: validate_GetSelect_613529,
                                    base: "/", url: url_GetSelect_613530,
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
