
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

  OpenApiRestCall_599352 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599352](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599352): Option[Scheme] {.used.} =
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
  Call_PostBatchDeleteAttributes_599959 = ref object of OpenApiRestCall_599352
proc url_PostBatchDeleteAttributes_599961(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostBatchDeleteAttributes_599960(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_599962 = query.getOrDefault("SignatureMethod")
  valid_599962 = validateParameter(valid_599962, JString, required = true,
                                 default = nil)
  if valid_599962 != nil:
    section.add "SignatureMethod", valid_599962
  var valid_599963 = query.getOrDefault("Signature")
  valid_599963 = validateParameter(valid_599963, JString, required = true,
                                 default = nil)
  if valid_599963 != nil:
    section.add "Signature", valid_599963
  var valid_599964 = query.getOrDefault("Action")
  valid_599964 = validateParameter(valid_599964, JString, required = true,
                                 default = newJString("BatchDeleteAttributes"))
  if valid_599964 != nil:
    section.add "Action", valid_599964
  var valid_599965 = query.getOrDefault("Timestamp")
  valid_599965 = validateParameter(valid_599965, JString, required = true,
                                 default = nil)
  if valid_599965 != nil:
    section.add "Timestamp", valid_599965
  var valid_599966 = query.getOrDefault("SignatureVersion")
  valid_599966 = validateParameter(valid_599966, JString, required = true,
                                 default = nil)
  if valid_599966 != nil:
    section.add "SignatureVersion", valid_599966
  var valid_599967 = query.getOrDefault("AWSAccessKeyId")
  valid_599967 = validateParameter(valid_599967, JString, required = true,
                                 default = nil)
  if valid_599967 != nil:
    section.add "AWSAccessKeyId", valid_599967
  var valid_599968 = query.getOrDefault("Version")
  valid_599968 = validateParameter(valid_599968, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_599968 != nil:
    section.add "Version", valid_599968
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
  var valid_599969 = formData.getOrDefault("DomainName")
  valid_599969 = validateParameter(valid_599969, JString, required = true,
                                 default = nil)
  if valid_599969 != nil:
    section.add "DomainName", valid_599969
  var valid_599970 = formData.getOrDefault("Items")
  valid_599970 = validateParameter(valid_599970, JArray, required = true, default = nil)
  if valid_599970 != nil:
    section.add "Items", valid_599970
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599971: Call_PostBatchDeleteAttributes_599959; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  let valid = call_599971.validator(path, query, header, formData, body)
  let scheme = call_599971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599971.url(scheme.get, call_599971.host, call_599971.base,
                         call_599971.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599971, url, valid)

proc call*(call_599972: Call_PostBatchDeleteAttributes_599959;
          SignatureMethod: string; DomainName: string; Signature: string;
          Timestamp: string; Items: JsonNode; SignatureVersion: string;
          AWSAccessKeyId: string; Action: string = "BatchDeleteAttributes";
          Version: string = "2009-04-15"): Recallable =
  ## postBatchDeleteAttributes
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which the attributes are being deleted.
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   Items: JArray (required)
  ##        : A list of items on which to perform the operation.
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_599973 = newJObject()
  var formData_599974 = newJObject()
  add(query_599973, "SignatureMethod", newJString(SignatureMethod))
  add(formData_599974, "DomainName", newJString(DomainName))
  add(query_599973, "Signature", newJString(Signature))
  add(query_599973, "Action", newJString(Action))
  add(query_599973, "Timestamp", newJString(Timestamp))
  if Items != nil:
    formData_599974.add "Items", Items
  add(query_599973, "SignatureVersion", newJString(SignatureVersion))
  add(query_599973, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_599973, "Version", newJString(Version))
  result = call_599972.call(nil, query_599973, nil, formData_599974, nil)

var postBatchDeleteAttributes* = Call_PostBatchDeleteAttributes_599959(
    name: "postBatchDeleteAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=BatchDeleteAttributes",
    validator: validate_PostBatchDeleteAttributes_599960, base: "/",
    url: url_PostBatchDeleteAttributes_599961,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchDeleteAttributes_599689 = ref object of OpenApiRestCall_599352
proc url_GetBatchDeleteAttributes_599691(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBatchDeleteAttributes_599690(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   Items: JArray (required)
  ##        : A list of items on which to perform the operation.
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   DomainName: JString (required)
  ##             : The name of the domain in which the attributes are being deleted.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_599803 = query.getOrDefault("SignatureMethod")
  valid_599803 = validateParameter(valid_599803, JString, required = true,
                                 default = nil)
  if valid_599803 != nil:
    section.add "SignatureMethod", valid_599803
  var valid_599804 = query.getOrDefault("Signature")
  valid_599804 = validateParameter(valid_599804, JString, required = true,
                                 default = nil)
  if valid_599804 != nil:
    section.add "Signature", valid_599804
  var valid_599818 = query.getOrDefault("Action")
  valid_599818 = validateParameter(valid_599818, JString, required = true,
                                 default = newJString("BatchDeleteAttributes"))
  if valid_599818 != nil:
    section.add "Action", valid_599818
  var valid_599819 = query.getOrDefault("Timestamp")
  valid_599819 = validateParameter(valid_599819, JString, required = true,
                                 default = nil)
  if valid_599819 != nil:
    section.add "Timestamp", valid_599819
  var valid_599820 = query.getOrDefault("Items")
  valid_599820 = validateParameter(valid_599820, JArray, required = true, default = nil)
  if valid_599820 != nil:
    section.add "Items", valid_599820
  var valid_599821 = query.getOrDefault("SignatureVersion")
  valid_599821 = validateParameter(valid_599821, JString, required = true,
                                 default = nil)
  if valid_599821 != nil:
    section.add "SignatureVersion", valid_599821
  var valid_599822 = query.getOrDefault("AWSAccessKeyId")
  valid_599822 = validateParameter(valid_599822, JString, required = true,
                                 default = nil)
  if valid_599822 != nil:
    section.add "AWSAccessKeyId", valid_599822
  var valid_599823 = query.getOrDefault("DomainName")
  valid_599823 = validateParameter(valid_599823, JString, required = true,
                                 default = nil)
  if valid_599823 != nil:
    section.add "DomainName", valid_599823
  var valid_599824 = query.getOrDefault("Version")
  valid_599824 = validateParameter(valid_599824, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_599824 != nil:
    section.add "Version", valid_599824
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599847: Call_GetBatchDeleteAttributes_599689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  let valid = call_599847.validator(path, query, header, formData, body)
  let scheme = call_599847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599847.url(scheme.get, call_599847.host, call_599847.base,
                         call_599847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599847, url, valid)

proc call*(call_599918: Call_GetBatchDeleteAttributes_599689;
          SignatureMethod: string; Signature: string; Timestamp: string;
          Items: JsonNode; SignatureVersion: string; AWSAccessKeyId: string;
          DomainName: string; Action: string = "BatchDeleteAttributes";
          Version: string = "2009-04-15"): Recallable =
  ## getBatchDeleteAttributes
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   Items: JArray (required)
  ##        : A list of items on which to perform the operation.
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which the attributes are being deleted.
  ##   Version: string (required)
  var query_599919 = newJObject()
  add(query_599919, "SignatureMethod", newJString(SignatureMethod))
  add(query_599919, "Signature", newJString(Signature))
  add(query_599919, "Action", newJString(Action))
  add(query_599919, "Timestamp", newJString(Timestamp))
  if Items != nil:
    query_599919.add "Items", Items
  add(query_599919, "SignatureVersion", newJString(SignatureVersion))
  add(query_599919, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_599919, "DomainName", newJString(DomainName))
  add(query_599919, "Version", newJString(Version))
  result = call_599918.call(nil, query_599919, nil, nil, nil)

var getBatchDeleteAttributes* = Call_GetBatchDeleteAttributes_599689(
    name: "getBatchDeleteAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=BatchDeleteAttributes",
    validator: validate_GetBatchDeleteAttributes_599690, base: "/",
    url: url_GetBatchDeleteAttributes_599691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostBatchPutAttributes_599990 = ref object of OpenApiRestCall_599352
proc url_PostBatchPutAttributes_599992(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostBatchPutAttributes_599991(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_599993 = query.getOrDefault("SignatureMethod")
  valid_599993 = validateParameter(valid_599993, JString, required = true,
                                 default = nil)
  if valid_599993 != nil:
    section.add "SignatureMethod", valid_599993
  var valid_599994 = query.getOrDefault("Signature")
  valid_599994 = validateParameter(valid_599994, JString, required = true,
                                 default = nil)
  if valid_599994 != nil:
    section.add "Signature", valid_599994
  var valid_599995 = query.getOrDefault("Action")
  valid_599995 = validateParameter(valid_599995, JString, required = true,
                                 default = newJString("BatchPutAttributes"))
  if valid_599995 != nil:
    section.add "Action", valid_599995
  var valid_599996 = query.getOrDefault("Timestamp")
  valid_599996 = validateParameter(valid_599996, JString, required = true,
                                 default = nil)
  if valid_599996 != nil:
    section.add "Timestamp", valid_599996
  var valid_599997 = query.getOrDefault("SignatureVersion")
  valid_599997 = validateParameter(valid_599997, JString, required = true,
                                 default = nil)
  if valid_599997 != nil:
    section.add "SignatureVersion", valid_599997
  var valid_599998 = query.getOrDefault("AWSAccessKeyId")
  valid_599998 = validateParameter(valid_599998, JString, required = true,
                                 default = nil)
  if valid_599998 != nil:
    section.add "AWSAccessKeyId", valid_599998
  var valid_599999 = query.getOrDefault("Version")
  valid_599999 = validateParameter(valid_599999, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_599999 != nil:
    section.add "Version", valid_599999
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
  var valid_600000 = formData.getOrDefault("DomainName")
  valid_600000 = validateParameter(valid_600000, JString, required = true,
                                 default = nil)
  if valid_600000 != nil:
    section.add "DomainName", valid_600000
  var valid_600001 = formData.getOrDefault("Items")
  valid_600001 = validateParameter(valid_600001, JArray, required = true, default = nil)
  if valid_600001 != nil:
    section.add "Items", valid_600001
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600002: Call_PostBatchPutAttributes_599990; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  let valid = call_600002.validator(path, query, header, formData, body)
  let scheme = call_600002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600002.url(scheme.get, call_600002.host, call_600002.base,
                         call_600002.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600002, url, valid)

proc call*(call_600003: Call_PostBatchPutAttributes_599990;
          SignatureMethod: string; DomainName: string; Signature: string;
          Timestamp: string; Items: JsonNode; SignatureVersion: string;
          AWSAccessKeyId: string; Action: string = "BatchPutAttributes";
          Version: string = "2009-04-15"): Recallable =
  ## postBatchPutAttributes
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which the attributes are being stored.
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   Items: JArray (required)
  ##        : A list of items on which to perform the operation.
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_600004 = newJObject()
  var formData_600005 = newJObject()
  add(query_600004, "SignatureMethod", newJString(SignatureMethod))
  add(formData_600005, "DomainName", newJString(DomainName))
  add(query_600004, "Signature", newJString(Signature))
  add(query_600004, "Action", newJString(Action))
  add(query_600004, "Timestamp", newJString(Timestamp))
  if Items != nil:
    formData_600005.add "Items", Items
  add(query_600004, "SignatureVersion", newJString(SignatureVersion))
  add(query_600004, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600004, "Version", newJString(Version))
  result = call_600003.call(nil, query_600004, nil, formData_600005, nil)

var postBatchPutAttributes* = Call_PostBatchPutAttributes_599990(
    name: "postBatchPutAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=BatchPutAttributes",
    validator: validate_PostBatchPutAttributes_599991, base: "/",
    url: url_PostBatchPutAttributes_599992, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchPutAttributes_599975 = ref object of OpenApiRestCall_599352
proc url_GetBatchPutAttributes_599977(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBatchPutAttributes_599976(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   Items: JArray (required)
  ##        : A list of items on which to perform the operation.
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   DomainName: JString (required)
  ##             : The name of the domain in which the attributes are being stored.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_599978 = query.getOrDefault("SignatureMethod")
  valid_599978 = validateParameter(valid_599978, JString, required = true,
                                 default = nil)
  if valid_599978 != nil:
    section.add "SignatureMethod", valid_599978
  var valid_599979 = query.getOrDefault("Signature")
  valid_599979 = validateParameter(valid_599979, JString, required = true,
                                 default = nil)
  if valid_599979 != nil:
    section.add "Signature", valid_599979
  var valid_599980 = query.getOrDefault("Action")
  valid_599980 = validateParameter(valid_599980, JString, required = true,
                                 default = newJString("BatchPutAttributes"))
  if valid_599980 != nil:
    section.add "Action", valid_599980
  var valid_599981 = query.getOrDefault("Timestamp")
  valid_599981 = validateParameter(valid_599981, JString, required = true,
                                 default = nil)
  if valid_599981 != nil:
    section.add "Timestamp", valid_599981
  var valid_599982 = query.getOrDefault("Items")
  valid_599982 = validateParameter(valid_599982, JArray, required = true, default = nil)
  if valid_599982 != nil:
    section.add "Items", valid_599982
  var valid_599983 = query.getOrDefault("SignatureVersion")
  valid_599983 = validateParameter(valid_599983, JString, required = true,
                                 default = nil)
  if valid_599983 != nil:
    section.add "SignatureVersion", valid_599983
  var valid_599984 = query.getOrDefault("AWSAccessKeyId")
  valid_599984 = validateParameter(valid_599984, JString, required = true,
                                 default = nil)
  if valid_599984 != nil:
    section.add "AWSAccessKeyId", valid_599984
  var valid_599985 = query.getOrDefault("DomainName")
  valid_599985 = validateParameter(valid_599985, JString, required = true,
                                 default = nil)
  if valid_599985 != nil:
    section.add "DomainName", valid_599985
  var valid_599986 = query.getOrDefault("Version")
  valid_599986 = validateParameter(valid_599986, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_599986 != nil:
    section.add "Version", valid_599986
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599987: Call_GetBatchPutAttributes_599975; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  let valid = call_599987.validator(path, query, header, formData, body)
  let scheme = call_599987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599987.url(scheme.get, call_599987.host, call_599987.base,
                         call_599987.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599987, url, valid)

proc call*(call_599988: Call_GetBatchPutAttributes_599975; SignatureMethod: string;
          Signature: string; Timestamp: string; Items: JsonNode;
          SignatureVersion: string; AWSAccessKeyId: string; DomainName: string;
          Action: string = "BatchPutAttributes"; Version: string = "2009-04-15"): Recallable =
  ## getBatchPutAttributes
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   Items: JArray (required)
  ##        : A list of items on which to perform the operation.
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which the attributes are being stored.
  ##   Version: string (required)
  var query_599989 = newJObject()
  add(query_599989, "SignatureMethod", newJString(SignatureMethod))
  add(query_599989, "Signature", newJString(Signature))
  add(query_599989, "Action", newJString(Action))
  add(query_599989, "Timestamp", newJString(Timestamp))
  if Items != nil:
    query_599989.add "Items", Items
  add(query_599989, "SignatureVersion", newJString(SignatureVersion))
  add(query_599989, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_599989, "DomainName", newJString(DomainName))
  add(query_599989, "Version", newJString(Version))
  result = call_599988.call(nil, query_599989, nil, nil, nil)

var getBatchPutAttributes* = Call_GetBatchPutAttributes_599975(
    name: "getBatchPutAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=BatchPutAttributes",
    validator: validate_GetBatchPutAttributes_599976, base: "/",
    url: url_GetBatchPutAttributes_599977, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDomain_600020 = ref object of OpenApiRestCall_599352
proc url_PostCreateDomain_600022(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDomain_600021(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_600023 = query.getOrDefault("SignatureMethod")
  valid_600023 = validateParameter(valid_600023, JString, required = true,
                                 default = nil)
  if valid_600023 != nil:
    section.add "SignatureMethod", valid_600023
  var valid_600024 = query.getOrDefault("Signature")
  valid_600024 = validateParameter(valid_600024, JString, required = true,
                                 default = nil)
  if valid_600024 != nil:
    section.add "Signature", valid_600024
  var valid_600025 = query.getOrDefault("Action")
  valid_600025 = validateParameter(valid_600025, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_600025 != nil:
    section.add "Action", valid_600025
  var valid_600026 = query.getOrDefault("Timestamp")
  valid_600026 = validateParameter(valid_600026, JString, required = true,
                                 default = nil)
  if valid_600026 != nil:
    section.add "Timestamp", valid_600026
  var valid_600027 = query.getOrDefault("SignatureVersion")
  valid_600027 = validateParameter(valid_600027, JString, required = true,
                                 default = nil)
  if valid_600027 != nil:
    section.add "SignatureVersion", valid_600027
  var valid_600028 = query.getOrDefault("AWSAccessKeyId")
  valid_600028 = validateParameter(valid_600028, JString, required = true,
                                 default = nil)
  if valid_600028 != nil:
    section.add "AWSAccessKeyId", valid_600028
  var valid_600029 = query.getOrDefault("Version")
  valid_600029 = validateParameter(valid_600029, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_600029 != nil:
    section.add "Version", valid_600029
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain to create. The name can range between 3 and 255 characters and can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600030 = formData.getOrDefault("DomainName")
  valid_600030 = validateParameter(valid_600030, JString, required = true,
                                 default = nil)
  if valid_600030 != nil:
    section.add "DomainName", valid_600030
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600031: Call_PostCreateDomain_600020; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  let valid = call_600031.validator(path, query, header, formData, body)
  let scheme = call_600031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600031.url(scheme.get, call_600031.host, call_600031.base,
                         call_600031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600031, url, valid)

proc call*(call_600032: Call_PostCreateDomain_600020; SignatureMethod: string;
          DomainName: string; Signature: string; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string;
          Action: string = "CreateDomain"; Version: string = "2009-04-15"): Recallable =
  ## postCreateDomain
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain to create. The name can range between 3 and 255 characters and can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'.
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_600033 = newJObject()
  var formData_600034 = newJObject()
  add(query_600033, "SignatureMethod", newJString(SignatureMethod))
  add(formData_600034, "DomainName", newJString(DomainName))
  add(query_600033, "Signature", newJString(Signature))
  add(query_600033, "Action", newJString(Action))
  add(query_600033, "Timestamp", newJString(Timestamp))
  add(query_600033, "SignatureVersion", newJString(SignatureVersion))
  add(query_600033, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600033, "Version", newJString(Version))
  result = call_600032.call(nil, query_600033, nil, formData_600034, nil)

var postCreateDomain* = Call_PostCreateDomain_600020(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_600021,
    base: "/", url: url_PostCreateDomain_600022,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_600006 = ref object of OpenApiRestCall_599352
proc url_GetCreateDomain_600008(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDomain_600007(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   DomainName: JString (required)
  ##             : The name of the domain to create. The name can range between 3 and 255 characters and can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_600009 = query.getOrDefault("SignatureMethod")
  valid_600009 = validateParameter(valid_600009, JString, required = true,
                                 default = nil)
  if valid_600009 != nil:
    section.add "SignatureMethod", valid_600009
  var valid_600010 = query.getOrDefault("Signature")
  valid_600010 = validateParameter(valid_600010, JString, required = true,
                                 default = nil)
  if valid_600010 != nil:
    section.add "Signature", valid_600010
  var valid_600011 = query.getOrDefault("Action")
  valid_600011 = validateParameter(valid_600011, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_600011 != nil:
    section.add "Action", valid_600011
  var valid_600012 = query.getOrDefault("Timestamp")
  valid_600012 = validateParameter(valid_600012, JString, required = true,
                                 default = nil)
  if valid_600012 != nil:
    section.add "Timestamp", valid_600012
  var valid_600013 = query.getOrDefault("SignatureVersion")
  valid_600013 = validateParameter(valid_600013, JString, required = true,
                                 default = nil)
  if valid_600013 != nil:
    section.add "SignatureVersion", valid_600013
  var valid_600014 = query.getOrDefault("AWSAccessKeyId")
  valid_600014 = validateParameter(valid_600014, JString, required = true,
                                 default = nil)
  if valid_600014 != nil:
    section.add "AWSAccessKeyId", valid_600014
  var valid_600015 = query.getOrDefault("DomainName")
  valid_600015 = validateParameter(valid_600015, JString, required = true,
                                 default = nil)
  if valid_600015 != nil:
    section.add "DomainName", valid_600015
  var valid_600016 = query.getOrDefault("Version")
  valid_600016 = validateParameter(valid_600016, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_600016 != nil:
    section.add "Version", valid_600016
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600017: Call_GetCreateDomain_600006; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  let valid = call_600017.validator(path, query, header, formData, body)
  let scheme = call_600017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600017.url(scheme.get, call_600017.host, call_600017.base,
                         call_600017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600017, url, valid)

proc call*(call_600018: Call_GetCreateDomain_600006; SignatureMethod: string;
          Signature: string; Timestamp: string; SignatureVersion: string;
          AWSAccessKeyId: string; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2009-04-15"): Recallable =
  ## getCreateDomain
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain to create. The name can range between 3 and 255 characters and can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'.
  ##   Version: string (required)
  var query_600019 = newJObject()
  add(query_600019, "SignatureMethod", newJString(SignatureMethod))
  add(query_600019, "Signature", newJString(Signature))
  add(query_600019, "Action", newJString(Action))
  add(query_600019, "Timestamp", newJString(Timestamp))
  add(query_600019, "SignatureVersion", newJString(SignatureVersion))
  add(query_600019, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600019, "DomainName", newJString(DomainName))
  add(query_600019, "Version", newJString(Version))
  result = call_600018.call(nil, query_600019, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_600006(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_600007,
    base: "/", url: url_GetCreateDomain_600008, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAttributes_600054 = ref object of OpenApiRestCall_599352
proc url_PostDeleteAttributes_600056(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteAttributes_600055(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_600057 = query.getOrDefault("SignatureMethod")
  valid_600057 = validateParameter(valid_600057, JString, required = true,
                                 default = nil)
  if valid_600057 != nil:
    section.add "SignatureMethod", valid_600057
  var valid_600058 = query.getOrDefault("Signature")
  valid_600058 = validateParameter(valid_600058, JString, required = true,
                                 default = nil)
  if valid_600058 != nil:
    section.add "Signature", valid_600058
  var valid_600059 = query.getOrDefault("Action")
  valid_600059 = validateParameter(valid_600059, JString, required = true,
                                 default = newJString("DeleteAttributes"))
  if valid_600059 != nil:
    section.add "Action", valid_600059
  var valid_600060 = query.getOrDefault("Timestamp")
  valid_600060 = validateParameter(valid_600060, JString, required = true,
                                 default = nil)
  if valid_600060 != nil:
    section.add "Timestamp", valid_600060
  var valid_600061 = query.getOrDefault("SignatureVersion")
  valid_600061 = validateParameter(valid_600061, JString, required = true,
                                 default = nil)
  if valid_600061 != nil:
    section.add "SignatureVersion", valid_600061
  var valid_600062 = query.getOrDefault("AWSAccessKeyId")
  valid_600062 = validateParameter(valid_600062, JString, required = true,
                                 default = nil)
  if valid_600062 != nil:
    section.add "AWSAccessKeyId", valid_600062
  var valid_600063 = query.getOrDefault("Version")
  valid_600063 = validateParameter(valid_600063, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_600063 != nil:
    section.add "Version", valid_600063
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain in which to perform the operation.
  ##   ItemName: JString (required)
  ##           : The name of the item. Similar to rows on a spreadsheet, items represent individual objects that contain one or more value-attribute pairs.
  ##   Expected.Exists: JString
  ##                  :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   Attributes: JArray
  ##             : A list of Attributes. Similar to columns on a spreadsheet, attributes represent categories of data that can be assigned to items.
  ##   Expected.Value: JString
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   Expected.Name: JString
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600064 = formData.getOrDefault("DomainName")
  valid_600064 = validateParameter(valid_600064, JString, required = true,
                                 default = nil)
  if valid_600064 != nil:
    section.add "DomainName", valid_600064
  var valid_600065 = formData.getOrDefault("ItemName")
  valid_600065 = validateParameter(valid_600065, JString, required = true,
                                 default = nil)
  if valid_600065 != nil:
    section.add "ItemName", valid_600065
  var valid_600066 = formData.getOrDefault("Expected.Exists")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "Expected.Exists", valid_600066
  var valid_600067 = formData.getOrDefault("Attributes")
  valid_600067 = validateParameter(valid_600067, JArray, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "Attributes", valid_600067
  var valid_600068 = formData.getOrDefault("Expected.Value")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "Expected.Value", valid_600068
  var valid_600069 = formData.getOrDefault("Expected.Name")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "Expected.Name", valid_600069
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600070: Call_PostDeleteAttributes_600054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  let valid = call_600070.validator(path, query, header, formData, body)
  let scheme = call_600070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600070.url(scheme.get, call_600070.host, call_600070.base,
                         call_600070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600070, url, valid)

proc call*(call_600071: Call_PostDeleteAttributes_600054; SignatureMethod: string;
          DomainName: string; ItemName: string; Signature: string; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string;
          ExpectedExists: string = ""; Attributes: JsonNode = nil;
          Action: string = "DeleteAttributes"; ExpectedValue: string = "";
          ExpectedName: string = ""; Version: string = "2009-04-15"): Recallable =
  ## postDeleteAttributes
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which to perform the operation.
  ##   ItemName: string (required)
  ##           : The name of the item. Similar to rows on a spreadsheet, items represent individual objects that contain one or more value-attribute pairs.
  ##   ExpectedExists: string
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   Signature: string (required)
  ##   Attributes: JArray
  ##             : A list of Attributes. Similar to columns on a spreadsheet, attributes represent categories of data that can be assigned to items.
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   ExpectedValue: string
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   ExpectedName: string
  ##               :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_600072 = newJObject()
  var formData_600073 = newJObject()
  add(query_600072, "SignatureMethod", newJString(SignatureMethod))
  add(formData_600073, "DomainName", newJString(DomainName))
  add(formData_600073, "ItemName", newJString(ItemName))
  add(formData_600073, "Expected.Exists", newJString(ExpectedExists))
  add(query_600072, "Signature", newJString(Signature))
  if Attributes != nil:
    formData_600073.add "Attributes", Attributes
  add(query_600072, "Action", newJString(Action))
  add(query_600072, "Timestamp", newJString(Timestamp))
  add(formData_600073, "Expected.Value", newJString(ExpectedValue))
  add(formData_600073, "Expected.Name", newJString(ExpectedName))
  add(query_600072, "SignatureVersion", newJString(SignatureVersion))
  add(query_600072, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600072, "Version", newJString(Version))
  result = call_600071.call(nil, query_600072, nil, formData_600073, nil)

var postDeleteAttributes* = Call_PostDeleteAttributes_600054(
    name: "postDeleteAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=DeleteAttributes",
    validator: validate_PostDeleteAttributes_600055, base: "/",
    url: url_PostDeleteAttributes_600056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAttributes_600035 = ref object of OpenApiRestCall_599352
proc url_GetDeleteAttributes_600037(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteAttributes_600036(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Expected.Exists: JString
  ##                  :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   Attributes: JArray
  ##             : A list of Attributes. Similar to columns on a spreadsheet, attributes represent categories of data that can be assigned to items.
  ##   Signature: JString (required)
  ##   ItemName: JString (required)
  ##           : The name of the item. Similar to rows on a spreadsheet, items represent individual objects that contain one or more value-attribute pairs.
  ##   Action: JString (required)
  ##   Expected.Value: JString
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Expected.Name: JString
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  ##   DomainName: JString (required)
  ##             : The name of the domain in which to perform the operation.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_600038 = query.getOrDefault("SignatureMethod")
  valid_600038 = validateParameter(valid_600038, JString, required = true,
                                 default = nil)
  if valid_600038 != nil:
    section.add "SignatureMethod", valid_600038
  var valid_600039 = query.getOrDefault("Expected.Exists")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "Expected.Exists", valid_600039
  var valid_600040 = query.getOrDefault("Attributes")
  valid_600040 = validateParameter(valid_600040, JArray, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "Attributes", valid_600040
  var valid_600041 = query.getOrDefault("Signature")
  valid_600041 = validateParameter(valid_600041, JString, required = true,
                                 default = nil)
  if valid_600041 != nil:
    section.add "Signature", valid_600041
  var valid_600042 = query.getOrDefault("ItemName")
  valid_600042 = validateParameter(valid_600042, JString, required = true,
                                 default = nil)
  if valid_600042 != nil:
    section.add "ItemName", valid_600042
  var valid_600043 = query.getOrDefault("Action")
  valid_600043 = validateParameter(valid_600043, JString, required = true,
                                 default = newJString("DeleteAttributes"))
  if valid_600043 != nil:
    section.add "Action", valid_600043
  var valid_600044 = query.getOrDefault("Expected.Value")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "Expected.Value", valid_600044
  var valid_600045 = query.getOrDefault("Timestamp")
  valid_600045 = validateParameter(valid_600045, JString, required = true,
                                 default = nil)
  if valid_600045 != nil:
    section.add "Timestamp", valid_600045
  var valid_600046 = query.getOrDefault("SignatureVersion")
  valid_600046 = validateParameter(valid_600046, JString, required = true,
                                 default = nil)
  if valid_600046 != nil:
    section.add "SignatureVersion", valid_600046
  var valid_600047 = query.getOrDefault("AWSAccessKeyId")
  valid_600047 = validateParameter(valid_600047, JString, required = true,
                                 default = nil)
  if valid_600047 != nil:
    section.add "AWSAccessKeyId", valid_600047
  var valid_600048 = query.getOrDefault("Expected.Name")
  valid_600048 = validateParameter(valid_600048, JString, required = false,
                                 default = nil)
  if valid_600048 != nil:
    section.add "Expected.Name", valid_600048
  var valid_600049 = query.getOrDefault("DomainName")
  valid_600049 = validateParameter(valid_600049, JString, required = true,
                                 default = nil)
  if valid_600049 != nil:
    section.add "DomainName", valid_600049
  var valid_600050 = query.getOrDefault("Version")
  valid_600050 = validateParameter(valid_600050, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_600050 != nil:
    section.add "Version", valid_600050
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600051: Call_GetDeleteAttributes_600035; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  let valid = call_600051.validator(path, query, header, formData, body)
  let scheme = call_600051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600051.url(scheme.get, call_600051.host, call_600051.base,
                         call_600051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600051, url, valid)

proc call*(call_600052: Call_GetDeleteAttributes_600035; SignatureMethod: string;
          Signature: string; ItemName: string; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string; DomainName: string;
          ExpectedExists: string = ""; Attributes: JsonNode = nil;
          Action: string = "DeleteAttributes"; ExpectedValue: string = "";
          ExpectedName: string = ""; Version: string = "2009-04-15"): Recallable =
  ## getDeleteAttributes
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ##   SignatureMethod: string (required)
  ##   ExpectedExists: string
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   Attributes: JArray
  ##             : A list of Attributes. Similar to columns on a spreadsheet, attributes represent categories of data that can be assigned to items.
  ##   Signature: string (required)
  ##   ItemName: string (required)
  ##           : The name of the item. Similar to rows on a spreadsheet, items represent individual objects that contain one or more value-attribute pairs.
  ##   Action: string (required)
  ##   ExpectedValue: string
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   Timestamp: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   ExpectedName: string
  ##               :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  ##   DomainName: string (required)
  ##             : The name of the domain in which to perform the operation.
  ##   Version: string (required)
  var query_600053 = newJObject()
  add(query_600053, "SignatureMethod", newJString(SignatureMethod))
  add(query_600053, "Expected.Exists", newJString(ExpectedExists))
  if Attributes != nil:
    query_600053.add "Attributes", Attributes
  add(query_600053, "Signature", newJString(Signature))
  add(query_600053, "ItemName", newJString(ItemName))
  add(query_600053, "Action", newJString(Action))
  add(query_600053, "Expected.Value", newJString(ExpectedValue))
  add(query_600053, "Timestamp", newJString(Timestamp))
  add(query_600053, "SignatureVersion", newJString(SignatureVersion))
  add(query_600053, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600053, "Expected.Name", newJString(ExpectedName))
  add(query_600053, "DomainName", newJString(DomainName))
  add(query_600053, "Version", newJString(Version))
  result = call_600052.call(nil, query_600053, nil, nil, nil)

var getDeleteAttributes* = Call_GetDeleteAttributes_600035(
    name: "getDeleteAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=DeleteAttributes",
    validator: validate_GetDeleteAttributes_600036, base: "/",
    url: url_GetDeleteAttributes_600037, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_600088 = ref object of OpenApiRestCall_599352
proc url_PostDeleteDomain_600090(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDomain_600089(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_600091 = query.getOrDefault("SignatureMethod")
  valid_600091 = validateParameter(valid_600091, JString, required = true,
                                 default = nil)
  if valid_600091 != nil:
    section.add "SignatureMethod", valid_600091
  var valid_600092 = query.getOrDefault("Signature")
  valid_600092 = validateParameter(valid_600092, JString, required = true,
                                 default = nil)
  if valid_600092 != nil:
    section.add "Signature", valid_600092
  var valid_600093 = query.getOrDefault("Action")
  valid_600093 = validateParameter(valid_600093, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_600093 != nil:
    section.add "Action", valid_600093
  var valid_600094 = query.getOrDefault("Timestamp")
  valid_600094 = validateParameter(valid_600094, JString, required = true,
                                 default = nil)
  if valid_600094 != nil:
    section.add "Timestamp", valid_600094
  var valid_600095 = query.getOrDefault("SignatureVersion")
  valid_600095 = validateParameter(valid_600095, JString, required = true,
                                 default = nil)
  if valid_600095 != nil:
    section.add "SignatureVersion", valid_600095
  var valid_600096 = query.getOrDefault("AWSAccessKeyId")
  valid_600096 = validateParameter(valid_600096, JString, required = true,
                                 default = nil)
  if valid_600096 != nil:
    section.add "AWSAccessKeyId", valid_600096
  var valid_600097 = query.getOrDefault("Version")
  valid_600097 = validateParameter(valid_600097, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_600097 != nil:
    section.add "Version", valid_600097
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600098 = formData.getOrDefault("DomainName")
  valid_600098 = validateParameter(valid_600098, JString, required = true,
                                 default = nil)
  if valid_600098 != nil:
    section.add "DomainName", valid_600098
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600099: Call_PostDeleteDomain_600088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  let valid = call_600099.validator(path, query, header, formData, body)
  let scheme = call_600099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600099.url(scheme.get, call_600099.host, call_600099.base,
                         call_600099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600099, url, valid)

proc call*(call_600100: Call_PostDeleteDomain_600088; SignatureMethod: string;
          DomainName: string; Signature: string; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string;
          Action: string = "DeleteDomain"; Version: string = "2009-04-15"): Recallable =
  ## postDeleteDomain
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain to delete.
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_600101 = newJObject()
  var formData_600102 = newJObject()
  add(query_600101, "SignatureMethod", newJString(SignatureMethod))
  add(formData_600102, "DomainName", newJString(DomainName))
  add(query_600101, "Signature", newJString(Signature))
  add(query_600101, "Action", newJString(Action))
  add(query_600101, "Timestamp", newJString(Timestamp))
  add(query_600101, "SignatureVersion", newJString(SignatureVersion))
  add(query_600101, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600101, "Version", newJString(Version))
  result = call_600100.call(nil, query_600101, nil, formData_600102, nil)

var postDeleteDomain* = Call_PostDeleteDomain_600088(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_600089,
    base: "/", url: url_PostDeleteDomain_600090,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_600074 = ref object of OpenApiRestCall_599352
proc url_GetDeleteDomain_600076(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDomain_600075(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   DomainName: JString (required)
  ##             : The name of the domain to delete.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_600077 = query.getOrDefault("SignatureMethod")
  valid_600077 = validateParameter(valid_600077, JString, required = true,
                                 default = nil)
  if valid_600077 != nil:
    section.add "SignatureMethod", valid_600077
  var valid_600078 = query.getOrDefault("Signature")
  valid_600078 = validateParameter(valid_600078, JString, required = true,
                                 default = nil)
  if valid_600078 != nil:
    section.add "Signature", valid_600078
  var valid_600079 = query.getOrDefault("Action")
  valid_600079 = validateParameter(valid_600079, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_600079 != nil:
    section.add "Action", valid_600079
  var valid_600080 = query.getOrDefault("Timestamp")
  valid_600080 = validateParameter(valid_600080, JString, required = true,
                                 default = nil)
  if valid_600080 != nil:
    section.add "Timestamp", valid_600080
  var valid_600081 = query.getOrDefault("SignatureVersion")
  valid_600081 = validateParameter(valid_600081, JString, required = true,
                                 default = nil)
  if valid_600081 != nil:
    section.add "SignatureVersion", valid_600081
  var valid_600082 = query.getOrDefault("AWSAccessKeyId")
  valid_600082 = validateParameter(valid_600082, JString, required = true,
                                 default = nil)
  if valid_600082 != nil:
    section.add "AWSAccessKeyId", valid_600082
  var valid_600083 = query.getOrDefault("DomainName")
  valid_600083 = validateParameter(valid_600083, JString, required = true,
                                 default = nil)
  if valid_600083 != nil:
    section.add "DomainName", valid_600083
  var valid_600084 = query.getOrDefault("Version")
  valid_600084 = validateParameter(valid_600084, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_600084 != nil:
    section.add "Version", valid_600084
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600085: Call_GetDeleteDomain_600074; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  let valid = call_600085.validator(path, query, header, formData, body)
  let scheme = call_600085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600085.url(scheme.get, call_600085.host, call_600085.base,
                         call_600085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600085, url, valid)

proc call*(call_600086: Call_GetDeleteDomain_600074; SignatureMethod: string;
          Signature: string; Timestamp: string; SignatureVersion: string;
          AWSAccessKeyId: string; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2009-04-15"): Recallable =
  ## getDeleteDomain
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain to delete.
  ##   Version: string (required)
  var query_600087 = newJObject()
  add(query_600087, "SignatureMethod", newJString(SignatureMethod))
  add(query_600087, "Signature", newJString(Signature))
  add(query_600087, "Action", newJString(Action))
  add(query_600087, "Timestamp", newJString(Timestamp))
  add(query_600087, "SignatureVersion", newJString(SignatureVersion))
  add(query_600087, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600087, "DomainName", newJString(DomainName))
  add(query_600087, "Version", newJString(Version))
  result = call_600086.call(nil, query_600087, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_600074(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_600075,
    base: "/", url: url_GetDeleteDomain_600076, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDomainMetadata_600117 = ref object of OpenApiRestCall_599352
proc url_PostDomainMetadata_600119(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDomainMetadata_600118(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_600120 = query.getOrDefault("SignatureMethod")
  valid_600120 = validateParameter(valid_600120, JString, required = true,
                                 default = nil)
  if valid_600120 != nil:
    section.add "SignatureMethod", valid_600120
  var valid_600121 = query.getOrDefault("Signature")
  valid_600121 = validateParameter(valid_600121, JString, required = true,
                                 default = nil)
  if valid_600121 != nil:
    section.add "Signature", valid_600121
  var valid_600122 = query.getOrDefault("Action")
  valid_600122 = validateParameter(valid_600122, JString, required = true,
                                 default = newJString("DomainMetadata"))
  if valid_600122 != nil:
    section.add "Action", valid_600122
  var valid_600123 = query.getOrDefault("Timestamp")
  valid_600123 = validateParameter(valid_600123, JString, required = true,
                                 default = nil)
  if valid_600123 != nil:
    section.add "Timestamp", valid_600123
  var valid_600124 = query.getOrDefault("SignatureVersion")
  valid_600124 = validateParameter(valid_600124, JString, required = true,
                                 default = nil)
  if valid_600124 != nil:
    section.add "SignatureVersion", valid_600124
  var valid_600125 = query.getOrDefault("AWSAccessKeyId")
  valid_600125 = validateParameter(valid_600125, JString, required = true,
                                 default = nil)
  if valid_600125 != nil:
    section.add "AWSAccessKeyId", valid_600125
  var valid_600126 = query.getOrDefault("Version")
  valid_600126 = validateParameter(valid_600126, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_600126 != nil:
    section.add "Version", valid_600126
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain for which to display the metadata of.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600127 = formData.getOrDefault("DomainName")
  valid_600127 = validateParameter(valid_600127, JString, required = true,
                                 default = nil)
  if valid_600127 != nil:
    section.add "DomainName", valid_600127
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600128: Call_PostDomainMetadata_600117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  let valid = call_600128.validator(path, query, header, formData, body)
  let scheme = call_600128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600128.url(scheme.get, call_600128.host, call_600128.base,
                         call_600128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600128, url, valid)

proc call*(call_600129: Call_PostDomainMetadata_600117; SignatureMethod: string;
          DomainName: string; Signature: string; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string;
          Action: string = "DomainMetadata"; Version: string = "2009-04-15"): Recallable =
  ## postDomainMetadata
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain for which to display the metadata of.
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_600130 = newJObject()
  var formData_600131 = newJObject()
  add(query_600130, "SignatureMethod", newJString(SignatureMethod))
  add(formData_600131, "DomainName", newJString(DomainName))
  add(query_600130, "Signature", newJString(Signature))
  add(query_600130, "Action", newJString(Action))
  add(query_600130, "Timestamp", newJString(Timestamp))
  add(query_600130, "SignatureVersion", newJString(SignatureVersion))
  add(query_600130, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600130, "Version", newJString(Version))
  result = call_600129.call(nil, query_600130, nil, formData_600131, nil)

var postDomainMetadata* = Call_PostDomainMetadata_600117(
    name: "postDomainMetadata", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=DomainMetadata",
    validator: validate_PostDomainMetadata_600118, base: "/",
    url: url_PostDomainMetadata_600119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainMetadata_600103 = ref object of OpenApiRestCall_599352
proc url_GetDomainMetadata_600105(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDomainMetadata_600104(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   DomainName: JString (required)
  ##             : The name of the domain for which to display the metadata of.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_600106 = query.getOrDefault("SignatureMethod")
  valid_600106 = validateParameter(valid_600106, JString, required = true,
                                 default = nil)
  if valid_600106 != nil:
    section.add "SignatureMethod", valid_600106
  var valid_600107 = query.getOrDefault("Signature")
  valid_600107 = validateParameter(valid_600107, JString, required = true,
                                 default = nil)
  if valid_600107 != nil:
    section.add "Signature", valid_600107
  var valid_600108 = query.getOrDefault("Action")
  valid_600108 = validateParameter(valid_600108, JString, required = true,
                                 default = newJString("DomainMetadata"))
  if valid_600108 != nil:
    section.add "Action", valid_600108
  var valid_600109 = query.getOrDefault("Timestamp")
  valid_600109 = validateParameter(valid_600109, JString, required = true,
                                 default = nil)
  if valid_600109 != nil:
    section.add "Timestamp", valid_600109
  var valid_600110 = query.getOrDefault("SignatureVersion")
  valid_600110 = validateParameter(valid_600110, JString, required = true,
                                 default = nil)
  if valid_600110 != nil:
    section.add "SignatureVersion", valid_600110
  var valid_600111 = query.getOrDefault("AWSAccessKeyId")
  valid_600111 = validateParameter(valid_600111, JString, required = true,
                                 default = nil)
  if valid_600111 != nil:
    section.add "AWSAccessKeyId", valid_600111
  var valid_600112 = query.getOrDefault("DomainName")
  valid_600112 = validateParameter(valid_600112, JString, required = true,
                                 default = nil)
  if valid_600112 != nil:
    section.add "DomainName", valid_600112
  var valid_600113 = query.getOrDefault("Version")
  valid_600113 = validateParameter(valid_600113, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_600113 != nil:
    section.add "Version", valid_600113
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600114: Call_GetDomainMetadata_600103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  let valid = call_600114.validator(path, query, header, formData, body)
  let scheme = call_600114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600114.url(scheme.get, call_600114.host, call_600114.base,
                         call_600114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600114, url, valid)

proc call*(call_600115: Call_GetDomainMetadata_600103; SignatureMethod: string;
          Signature: string; Timestamp: string; SignatureVersion: string;
          AWSAccessKeyId: string; DomainName: string;
          Action: string = "DomainMetadata"; Version: string = "2009-04-15"): Recallable =
  ## getDomainMetadata
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain for which to display the metadata of.
  ##   Version: string (required)
  var query_600116 = newJObject()
  add(query_600116, "SignatureMethod", newJString(SignatureMethod))
  add(query_600116, "Signature", newJString(Signature))
  add(query_600116, "Action", newJString(Action))
  add(query_600116, "Timestamp", newJString(Timestamp))
  add(query_600116, "SignatureVersion", newJString(SignatureVersion))
  add(query_600116, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600116, "DomainName", newJString(DomainName))
  add(query_600116, "Version", newJString(Version))
  result = call_600115.call(nil, query_600116, nil, nil, nil)

var getDomainMetadata* = Call_GetDomainMetadata_600103(name: "getDomainMetadata",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=DomainMetadata", validator: validate_GetDomainMetadata_600104,
    base: "/", url: url_GetDomainMetadata_600105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetAttributes_600149 = ref object of OpenApiRestCall_599352
proc url_PostGetAttributes_600151(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetAttributes_600150(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_600152 = query.getOrDefault("SignatureMethod")
  valid_600152 = validateParameter(valid_600152, JString, required = true,
                                 default = nil)
  if valid_600152 != nil:
    section.add "SignatureMethod", valid_600152
  var valid_600153 = query.getOrDefault("Signature")
  valid_600153 = validateParameter(valid_600153, JString, required = true,
                                 default = nil)
  if valid_600153 != nil:
    section.add "Signature", valid_600153
  var valid_600154 = query.getOrDefault("Action")
  valid_600154 = validateParameter(valid_600154, JString, required = true,
                                 default = newJString("GetAttributes"))
  if valid_600154 != nil:
    section.add "Action", valid_600154
  var valid_600155 = query.getOrDefault("Timestamp")
  valid_600155 = validateParameter(valid_600155, JString, required = true,
                                 default = nil)
  if valid_600155 != nil:
    section.add "Timestamp", valid_600155
  var valid_600156 = query.getOrDefault("SignatureVersion")
  valid_600156 = validateParameter(valid_600156, JString, required = true,
                                 default = nil)
  if valid_600156 != nil:
    section.add "SignatureVersion", valid_600156
  var valid_600157 = query.getOrDefault("AWSAccessKeyId")
  valid_600157 = validateParameter(valid_600157, JString, required = true,
                                 default = nil)
  if valid_600157 != nil:
    section.add "AWSAccessKeyId", valid_600157
  var valid_600158 = query.getOrDefault("Version")
  valid_600158 = validateParameter(valid_600158, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_600158 != nil:
    section.add "Version", valid_600158
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain in which to perform the operation.
  ##   ItemName: JString (required)
  ##           : The name of the item.
  ##   ConsistentRead: JBool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  ##   AttributeNames: JArray
  ##                 : The names of the attributes.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600159 = formData.getOrDefault("DomainName")
  valid_600159 = validateParameter(valid_600159, JString, required = true,
                                 default = nil)
  if valid_600159 != nil:
    section.add "DomainName", valid_600159
  var valid_600160 = formData.getOrDefault("ItemName")
  valid_600160 = validateParameter(valid_600160, JString, required = true,
                                 default = nil)
  if valid_600160 != nil:
    section.add "ItemName", valid_600160
  var valid_600161 = formData.getOrDefault("ConsistentRead")
  valid_600161 = validateParameter(valid_600161, JBool, required = false, default = nil)
  if valid_600161 != nil:
    section.add "ConsistentRead", valid_600161
  var valid_600162 = formData.getOrDefault("AttributeNames")
  valid_600162 = validateParameter(valid_600162, JArray, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "AttributeNames", valid_600162
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600163: Call_PostGetAttributes_600149; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  let valid = call_600163.validator(path, query, header, formData, body)
  let scheme = call_600163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600163.url(scheme.get, call_600163.host, call_600163.base,
                         call_600163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600163, url, valid)

proc call*(call_600164: Call_PostGetAttributes_600149; SignatureMethod: string;
          DomainName: string; ItemName: string; Signature: string; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string;
          ConsistentRead: bool = false; Action: string = "GetAttributes";
          AttributeNames: JsonNode = nil; Version: string = "2009-04-15"): Recallable =
  ## postGetAttributes
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which to perform the operation.
  ##   ItemName: string (required)
  ##           : The name of the item.
  ##   ConsistentRead: bool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   AttributeNames: JArray
  ##                 : The names of the attributes.
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_600165 = newJObject()
  var formData_600166 = newJObject()
  add(query_600165, "SignatureMethod", newJString(SignatureMethod))
  add(formData_600166, "DomainName", newJString(DomainName))
  add(formData_600166, "ItemName", newJString(ItemName))
  add(formData_600166, "ConsistentRead", newJBool(ConsistentRead))
  add(query_600165, "Signature", newJString(Signature))
  add(query_600165, "Action", newJString(Action))
  add(query_600165, "Timestamp", newJString(Timestamp))
  if AttributeNames != nil:
    formData_600166.add "AttributeNames", AttributeNames
  add(query_600165, "SignatureVersion", newJString(SignatureVersion))
  add(query_600165, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600165, "Version", newJString(Version))
  result = call_600164.call(nil, query_600165, nil, formData_600166, nil)

var postGetAttributes* = Call_PostGetAttributes_600149(name: "postGetAttributes",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=GetAttributes", validator: validate_PostGetAttributes_600150,
    base: "/", url: url_PostGetAttributes_600151,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetAttributes_600132 = ref object of OpenApiRestCall_599352
proc url_GetGetAttributes_600134(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetAttributes_600133(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   AttributeNames: JArray
  ##                 : The names of the attributes.
  ##   Signature: JString (required)
  ##   ItemName: JString (required)
  ##           : The name of the item.
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   ConsistentRead: JBool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   DomainName: JString (required)
  ##             : The name of the domain in which to perform the operation.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_600135 = query.getOrDefault("SignatureMethod")
  valid_600135 = validateParameter(valid_600135, JString, required = true,
                                 default = nil)
  if valid_600135 != nil:
    section.add "SignatureMethod", valid_600135
  var valid_600136 = query.getOrDefault("AttributeNames")
  valid_600136 = validateParameter(valid_600136, JArray, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "AttributeNames", valid_600136
  var valid_600137 = query.getOrDefault("Signature")
  valid_600137 = validateParameter(valid_600137, JString, required = true,
                                 default = nil)
  if valid_600137 != nil:
    section.add "Signature", valid_600137
  var valid_600138 = query.getOrDefault("ItemName")
  valid_600138 = validateParameter(valid_600138, JString, required = true,
                                 default = nil)
  if valid_600138 != nil:
    section.add "ItemName", valid_600138
  var valid_600139 = query.getOrDefault("Action")
  valid_600139 = validateParameter(valid_600139, JString, required = true,
                                 default = newJString("GetAttributes"))
  if valid_600139 != nil:
    section.add "Action", valid_600139
  var valid_600140 = query.getOrDefault("Timestamp")
  valid_600140 = validateParameter(valid_600140, JString, required = true,
                                 default = nil)
  if valid_600140 != nil:
    section.add "Timestamp", valid_600140
  var valid_600141 = query.getOrDefault("ConsistentRead")
  valid_600141 = validateParameter(valid_600141, JBool, required = false, default = nil)
  if valid_600141 != nil:
    section.add "ConsistentRead", valid_600141
  var valid_600142 = query.getOrDefault("SignatureVersion")
  valid_600142 = validateParameter(valid_600142, JString, required = true,
                                 default = nil)
  if valid_600142 != nil:
    section.add "SignatureVersion", valid_600142
  var valid_600143 = query.getOrDefault("AWSAccessKeyId")
  valid_600143 = validateParameter(valid_600143, JString, required = true,
                                 default = nil)
  if valid_600143 != nil:
    section.add "AWSAccessKeyId", valid_600143
  var valid_600144 = query.getOrDefault("DomainName")
  valid_600144 = validateParameter(valid_600144, JString, required = true,
                                 default = nil)
  if valid_600144 != nil:
    section.add "DomainName", valid_600144
  var valid_600145 = query.getOrDefault("Version")
  valid_600145 = validateParameter(valid_600145, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_600145 != nil:
    section.add "Version", valid_600145
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600146: Call_GetGetAttributes_600132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  let valid = call_600146.validator(path, query, header, formData, body)
  let scheme = call_600146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600146.url(scheme.get, call_600146.host, call_600146.base,
                         call_600146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600146, url, valid)

proc call*(call_600147: Call_GetGetAttributes_600132; SignatureMethod: string;
          Signature: string; ItemName: string; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string; DomainName: string;
          AttributeNames: JsonNode = nil; Action: string = "GetAttributes";
          ConsistentRead: bool = false; Version: string = "2009-04-15"): Recallable =
  ## getGetAttributes
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ##   SignatureMethod: string (required)
  ##   AttributeNames: JArray
  ##                 : The names of the attributes.
  ##   Signature: string (required)
  ##   ItemName: string (required)
  ##           : The name of the item.
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   ConsistentRead: bool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which to perform the operation.
  ##   Version: string (required)
  var query_600148 = newJObject()
  add(query_600148, "SignatureMethod", newJString(SignatureMethod))
  if AttributeNames != nil:
    query_600148.add "AttributeNames", AttributeNames
  add(query_600148, "Signature", newJString(Signature))
  add(query_600148, "ItemName", newJString(ItemName))
  add(query_600148, "Action", newJString(Action))
  add(query_600148, "Timestamp", newJString(Timestamp))
  add(query_600148, "ConsistentRead", newJBool(ConsistentRead))
  add(query_600148, "SignatureVersion", newJString(SignatureVersion))
  add(query_600148, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600148, "DomainName", newJString(DomainName))
  add(query_600148, "Version", newJString(Version))
  result = call_600147.call(nil, query_600148, nil, nil, nil)

var getGetAttributes* = Call_GetGetAttributes_600132(name: "getGetAttributes",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=GetAttributes", validator: validate_GetGetAttributes_600133,
    base: "/", url: url_GetGetAttributes_600134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDomains_600182 = ref object of OpenApiRestCall_599352
proc url_PostListDomains_600184(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListDomains_600183(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_600185 = query.getOrDefault("SignatureMethod")
  valid_600185 = validateParameter(valid_600185, JString, required = true,
                                 default = nil)
  if valid_600185 != nil:
    section.add "SignatureMethod", valid_600185
  var valid_600186 = query.getOrDefault("Signature")
  valid_600186 = validateParameter(valid_600186, JString, required = true,
                                 default = nil)
  if valid_600186 != nil:
    section.add "Signature", valid_600186
  var valid_600187 = query.getOrDefault("Action")
  valid_600187 = validateParameter(valid_600187, JString, required = true,
                                 default = newJString("ListDomains"))
  if valid_600187 != nil:
    section.add "Action", valid_600187
  var valid_600188 = query.getOrDefault("Timestamp")
  valid_600188 = validateParameter(valid_600188, JString, required = true,
                                 default = nil)
  if valid_600188 != nil:
    section.add "Timestamp", valid_600188
  var valid_600189 = query.getOrDefault("SignatureVersion")
  valid_600189 = validateParameter(valid_600189, JString, required = true,
                                 default = nil)
  if valid_600189 != nil:
    section.add "SignatureVersion", valid_600189
  var valid_600190 = query.getOrDefault("AWSAccessKeyId")
  valid_600190 = validateParameter(valid_600190, JString, required = true,
                                 default = nil)
  if valid_600190 != nil:
    section.add "AWSAccessKeyId", valid_600190
  var valid_600191 = query.getOrDefault("Version")
  valid_600191 = validateParameter(valid_600191, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_600191 != nil:
    section.add "Version", valid_600191
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : A string informing Amazon SimpleDB where to start the next list of domain names.
  ##   MaxNumberOfDomains: JInt
  ##                     : The maximum number of domain names you want returned. The range is 1 to 100. The default setting is 100.
  section = newJObject()
  var valid_600192 = formData.getOrDefault("NextToken")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "NextToken", valid_600192
  var valid_600193 = formData.getOrDefault("MaxNumberOfDomains")
  valid_600193 = validateParameter(valid_600193, JInt, required = false, default = nil)
  if valid_600193 != nil:
    section.add "MaxNumberOfDomains", valid_600193
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600194: Call_PostListDomains_600182; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  let valid = call_600194.validator(path, query, header, formData, body)
  let scheme = call_600194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600194.url(scheme.get, call_600194.host, call_600194.base,
                         call_600194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600194, url, valid)

proc call*(call_600195: Call_PostListDomains_600182; SignatureMethod: string;
          Signature: string; Timestamp: string; SignatureVersion: string;
          AWSAccessKeyId: string; NextToken: string = "";
          Action: string = "ListDomains"; MaxNumberOfDomains: int = 0;
          Version: string = "2009-04-15"): Recallable =
  ## postListDomains
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ##   NextToken: string
  ##            : A string informing Amazon SimpleDB where to start the next list of domain names.
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   MaxNumberOfDomains: int
  ##                     : The maximum number of domain names you want returned. The range is 1 to 100. The default setting is 100.
  ##   Version: string (required)
  var query_600196 = newJObject()
  var formData_600197 = newJObject()
  add(formData_600197, "NextToken", newJString(NextToken))
  add(query_600196, "SignatureMethod", newJString(SignatureMethod))
  add(query_600196, "Signature", newJString(Signature))
  add(query_600196, "Action", newJString(Action))
  add(query_600196, "Timestamp", newJString(Timestamp))
  add(query_600196, "SignatureVersion", newJString(SignatureVersion))
  add(query_600196, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_600197, "MaxNumberOfDomains", newJInt(MaxNumberOfDomains))
  add(query_600196, "Version", newJString(Version))
  result = call_600195.call(nil, query_600196, nil, formData_600197, nil)

var postListDomains* = Call_PostListDomains_600182(name: "postListDomains",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=ListDomains", validator: validate_PostListDomains_600183,
    base: "/", url: url_PostListDomains_600184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDomains_600167 = ref object of OpenApiRestCall_599352
proc url_GetListDomains_600169(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListDomains_600168(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   NextToken: JString
  ##            : A string informing Amazon SimpleDB where to start the next list of domain names.
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  ##   MaxNumberOfDomains: JInt
  ##                     : The maximum number of domain names you want returned. The range is 1 to 100. The default setting is 100.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_600170 = query.getOrDefault("SignatureMethod")
  valid_600170 = validateParameter(valid_600170, JString, required = true,
                                 default = nil)
  if valid_600170 != nil:
    section.add "SignatureMethod", valid_600170
  var valid_600171 = query.getOrDefault("Signature")
  valid_600171 = validateParameter(valid_600171, JString, required = true,
                                 default = nil)
  if valid_600171 != nil:
    section.add "Signature", valid_600171
  var valid_600172 = query.getOrDefault("NextToken")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "NextToken", valid_600172
  var valid_600173 = query.getOrDefault("Action")
  valid_600173 = validateParameter(valid_600173, JString, required = true,
                                 default = newJString("ListDomains"))
  if valid_600173 != nil:
    section.add "Action", valid_600173
  var valid_600174 = query.getOrDefault("Timestamp")
  valid_600174 = validateParameter(valid_600174, JString, required = true,
                                 default = nil)
  if valid_600174 != nil:
    section.add "Timestamp", valid_600174
  var valid_600175 = query.getOrDefault("SignatureVersion")
  valid_600175 = validateParameter(valid_600175, JString, required = true,
                                 default = nil)
  if valid_600175 != nil:
    section.add "SignatureVersion", valid_600175
  var valid_600176 = query.getOrDefault("AWSAccessKeyId")
  valid_600176 = validateParameter(valid_600176, JString, required = true,
                                 default = nil)
  if valid_600176 != nil:
    section.add "AWSAccessKeyId", valid_600176
  var valid_600177 = query.getOrDefault("Version")
  valid_600177 = validateParameter(valid_600177, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_600177 != nil:
    section.add "Version", valid_600177
  var valid_600178 = query.getOrDefault("MaxNumberOfDomains")
  valid_600178 = validateParameter(valid_600178, JInt, required = false, default = nil)
  if valid_600178 != nil:
    section.add "MaxNumberOfDomains", valid_600178
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600179: Call_GetListDomains_600167; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  let valid = call_600179.validator(path, query, header, formData, body)
  let scheme = call_600179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600179.url(scheme.get, call_600179.host, call_600179.base,
                         call_600179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600179, url, valid)

proc call*(call_600180: Call_GetListDomains_600167; SignatureMethod: string;
          Signature: string; Timestamp: string; SignatureVersion: string;
          AWSAccessKeyId: string; NextToken: string = "";
          Action: string = "ListDomains"; Version: string = "2009-04-15";
          MaxNumberOfDomains: int = 0): Recallable =
  ## getListDomains
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   NextToken: string
  ##            : A string informing Amazon SimpleDB where to start the next list of domain names.
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  ##   MaxNumberOfDomains: int
  ##                     : The maximum number of domain names you want returned. The range is 1 to 100. The default setting is 100.
  var query_600181 = newJObject()
  add(query_600181, "SignatureMethod", newJString(SignatureMethod))
  add(query_600181, "Signature", newJString(Signature))
  add(query_600181, "NextToken", newJString(NextToken))
  add(query_600181, "Action", newJString(Action))
  add(query_600181, "Timestamp", newJString(Timestamp))
  add(query_600181, "SignatureVersion", newJString(SignatureVersion))
  add(query_600181, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600181, "Version", newJString(Version))
  add(query_600181, "MaxNumberOfDomains", newJInt(MaxNumberOfDomains))
  result = call_600180.call(nil, query_600181, nil, nil, nil)

var getListDomains* = Call_GetListDomains_600167(name: "getListDomains",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=ListDomains", validator: validate_GetListDomains_600168,
    base: "/", url: url_GetListDomains_600169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutAttributes_600217 = ref object of OpenApiRestCall_599352
proc url_PostPutAttributes_600219(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPutAttributes_600218(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_600220 = query.getOrDefault("SignatureMethod")
  valid_600220 = validateParameter(valid_600220, JString, required = true,
                                 default = nil)
  if valid_600220 != nil:
    section.add "SignatureMethod", valid_600220
  var valid_600221 = query.getOrDefault("Signature")
  valid_600221 = validateParameter(valid_600221, JString, required = true,
                                 default = nil)
  if valid_600221 != nil:
    section.add "Signature", valid_600221
  var valid_600222 = query.getOrDefault("Action")
  valid_600222 = validateParameter(valid_600222, JString, required = true,
                                 default = newJString("PutAttributes"))
  if valid_600222 != nil:
    section.add "Action", valid_600222
  var valid_600223 = query.getOrDefault("Timestamp")
  valid_600223 = validateParameter(valid_600223, JString, required = true,
                                 default = nil)
  if valid_600223 != nil:
    section.add "Timestamp", valid_600223
  var valid_600224 = query.getOrDefault("SignatureVersion")
  valid_600224 = validateParameter(valid_600224, JString, required = true,
                                 default = nil)
  if valid_600224 != nil:
    section.add "SignatureVersion", valid_600224
  var valid_600225 = query.getOrDefault("AWSAccessKeyId")
  valid_600225 = validateParameter(valid_600225, JString, required = true,
                                 default = nil)
  if valid_600225 != nil:
    section.add "AWSAccessKeyId", valid_600225
  var valid_600226 = query.getOrDefault("Version")
  valid_600226 = validateParameter(valid_600226, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_600226 != nil:
    section.add "Version", valid_600226
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain in which to perform the operation.
  ##   ItemName: JString (required)
  ##           : The name of the item.
  ##   Expected.Exists: JString
  ##                  :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   Attributes: JArray (required)
  ##             : The list of attributes.
  ##   Expected.Value: JString
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   Expected.Name: JString
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600227 = formData.getOrDefault("DomainName")
  valid_600227 = validateParameter(valid_600227, JString, required = true,
                                 default = nil)
  if valid_600227 != nil:
    section.add "DomainName", valid_600227
  var valid_600228 = formData.getOrDefault("ItemName")
  valid_600228 = validateParameter(valid_600228, JString, required = true,
                                 default = nil)
  if valid_600228 != nil:
    section.add "ItemName", valid_600228
  var valid_600229 = formData.getOrDefault("Expected.Exists")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "Expected.Exists", valid_600229
  var valid_600230 = formData.getOrDefault("Attributes")
  valid_600230 = validateParameter(valid_600230, JArray, required = true, default = nil)
  if valid_600230 != nil:
    section.add "Attributes", valid_600230
  var valid_600231 = formData.getOrDefault("Expected.Value")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "Expected.Value", valid_600231
  var valid_600232 = formData.getOrDefault("Expected.Name")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "Expected.Name", valid_600232
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600233: Call_PostPutAttributes_600217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  let valid = call_600233.validator(path, query, header, formData, body)
  let scheme = call_600233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600233.url(scheme.get, call_600233.host, call_600233.base,
                         call_600233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600233, url, valid)

proc call*(call_600234: Call_PostPutAttributes_600217; SignatureMethod: string;
          DomainName: string; ItemName: string; Signature: string;
          Attributes: JsonNode; Timestamp: string; SignatureVersion: string;
          AWSAccessKeyId: string; ExpectedExists: string = "";
          Action: string = "PutAttributes"; ExpectedValue: string = "";
          ExpectedName: string = ""; Version: string = "2009-04-15"): Recallable =
  ## postPutAttributes
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ##   SignatureMethod: string (required)
  ##   DomainName: string (required)
  ##             : The name of the domain in which to perform the operation.
  ##   ItemName: string (required)
  ##           : The name of the item.
  ##   ExpectedExists: string
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   Signature: string (required)
  ##   Attributes: JArray (required)
  ##             : The list of attributes.
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   ExpectedValue: string
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   ExpectedName: string
  ##               :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_600235 = newJObject()
  var formData_600236 = newJObject()
  add(query_600235, "SignatureMethod", newJString(SignatureMethod))
  add(formData_600236, "DomainName", newJString(DomainName))
  add(formData_600236, "ItemName", newJString(ItemName))
  add(formData_600236, "Expected.Exists", newJString(ExpectedExists))
  add(query_600235, "Signature", newJString(Signature))
  if Attributes != nil:
    formData_600236.add "Attributes", Attributes
  add(query_600235, "Action", newJString(Action))
  add(query_600235, "Timestamp", newJString(Timestamp))
  add(formData_600236, "Expected.Value", newJString(ExpectedValue))
  add(formData_600236, "Expected.Name", newJString(ExpectedName))
  add(query_600235, "SignatureVersion", newJString(SignatureVersion))
  add(query_600235, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600235, "Version", newJString(Version))
  result = call_600234.call(nil, query_600235, nil, formData_600236, nil)

var postPutAttributes* = Call_PostPutAttributes_600217(name: "postPutAttributes",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=PutAttributes", validator: validate_PostPutAttributes_600218,
    base: "/", url: url_PostPutAttributes_600219,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutAttributes_600198 = ref object of OpenApiRestCall_599352
proc url_GetPutAttributes_600200(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPutAttributes_600199(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Expected.Exists: JString
  ##                  :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   Attributes: JArray (required)
  ##             : The list of attributes.
  ##   Signature: JString (required)
  ##   ItemName: JString (required)
  ##           : The name of the item.
  ##   Action: JString (required)
  ##   Expected.Value: JString
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Expected.Name: JString
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  ##   DomainName: JString (required)
  ##             : The name of the domain in which to perform the operation.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_600201 = query.getOrDefault("SignatureMethod")
  valid_600201 = validateParameter(valid_600201, JString, required = true,
                                 default = nil)
  if valid_600201 != nil:
    section.add "SignatureMethod", valid_600201
  var valid_600202 = query.getOrDefault("Expected.Exists")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "Expected.Exists", valid_600202
  var valid_600203 = query.getOrDefault("Attributes")
  valid_600203 = validateParameter(valid_600203, JArray, required = true, default = nil)
  if valid_600203 != nil:
    section.add "Attributes", valid_600203
  var valid_600204 = query.getOrDefault("Signature")
  valid_600204 = validateParameter(valid_600204, JString, required = true,
                                 default = nil)
  if valid_600204 != nil:
    section.add "Signature", valid_600204
  var valid_600205 = query.getOrDefault("ItemName")
  valid_600205 = validateParameter(valid_600205, JString, required = true,
                                 default = nil)
  if valid_600205 != nil:
    section.add "ItemName", valid_600205
  var valid_600206 = query.getOrDefault("Action")
  valid_600206 = validateParameter(valid_600206, JString, required = true,
                                 default = newJString("PutAttributes"))
  if valid_600206 != nil:
    section.add "Action", valid_600206
  var valid_600207 = query.getOrDefault("Expected.Value")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "Expected.Value", valid_600207
  var valid_600208 = query.getOrDefault("Timestamp")
  valid_600208 = validateParameter(valid_600208, JString, required = true,
                                 default = nil)
  if valid_600208 != nil:
    section.add "Timestamp", valid_600208
  var valid_600209 = query.getOrDefault("SignatureVersion")
  valid_600209 = validateParameter(valid_600209, JString, required = true,
                                 default = nil)
  if valid_600209 != nil:
    section.add "SignatureVersion", valid_600209
  var valid_600210 = query.getOrDefault("AWSAccessKeyId")
  valid_600210 = validateParameter(valid_600210, JString, required = true,
                                 default = nil)
  if valid_600210 != nil:
    section.add "AWSAccessKeyId", valid_600210
  var valid_600211 = query.getOrDefault("Expected.Name")
  valid_600211 = validateParameter(valid_600211, JString, required = false,
                                 default = nil)
  if valid_600211 != nil:
    section.add "Expected.Name", valid_600211
  var valid_600212 = query.getOrDefault("DomainName")
  valid_600212 = validateParameter(valid_600212, JString, required = true,
                                 default = nil)
  if valid_600212 != nil:
    section.add "DomainName", valid_600212
  var valid_600213 = query.getOrDefault("Version")
  valid_600213 = validateParameter(valid_600213, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_600213 != nil:
    section.add "Version", valid_600213
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600214: Call_GetPutAttributes_600198; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  let valid = call_600214.validator(path, query, header, formData, body)
  let scheme = call_600214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600214.url(scheme.get, call_600214.host, call_600214.base,
                         call_600214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600214, url, valid)

proc call*(call_600215: Call_GetPutAttributes_600198; SignatureMethod: string;
          Attributes: JsonNode; Signature: string; ItemName: string;
          Timestamp: string; SignatureVersion: string; AWSAccessKeyId: string;
          DomainName: string; ExpectedExists: string = "";
          Action: string = "PutAttributes"; ExpectedValue: string = "";
          ExpectedName: string = ""; Version: string = "2009-04-15"): Recallable =
  ## getPutAttributes
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ##   SignatureMethod: string (required)
  ##   ExpectedExists: string
  ##                 :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## A value specifying whether or not the specified attribute must exist with the specified value in order for the update condition to be satisfied. Specify <code>true</code> if the attribute must exist for the update condition to be satisfied. Specify <code>false</code> if the attribute should not exist in order for the update condition to be satisfied.
  ##   Attributes: JArray (required)
  ##             : The list of attributes.
  ##   Signature: string (required)
  ##   ItemName: string (required)
  ##           : The name of the item.
  ##   Action: string (required)
  ##   ExpectedValue: string
  ##                :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The value of an attribute. This value can only be specified when the <code>Exists</code> parameter is equal to <code>true</code>.
  ##   Timestamp: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   ExpectedName: string
  ##               :  Specifies the conditions under which data should be updated. If an update condition is specified for a request, the data will only be updated if the condition is satisfied. For example, if an attribute with a specific name and value exists, or if a specific attribute doesn't exist. 
  ## The name of the attribute involved in the condition.
  ##   DomainName: string (required)
  ##             : The name of the domain in which to perform the operation.
  ##   Version: string (required)
  var query_600216 = newJObject()
  add(query_600216, "SignatureMethod", newJString(SignatureMethod))
  add(query_600216, "Expected.Exists", newJString(ExpectedExists))
  if Attributes != nil:
    query_600216.add "Attributes", Attributes
  add(query_600216, "Signature", newJString(Signature))
  add(query_600216, "ItemName", newJString(ItemName))
  add(query_600216, "Action", newJString(Action))
  add(query_600216, "Expected.Value", newJString(ExpectedValue))
  add(query_600216, "Timestamp", newJString(Timestamp))
  add(query_600216, "SignatureVersion", newJString(SignatureVersion))
  add(query_600216, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600216, "Expected.Name", newJString(ExpectedName))
  add(query_600216, "DomainName", newJString(DomainName))
  add(query_600216, "Version", newJString(Version))
  result = call_600215.call(nil, query_600216, nil, nil, nil)

var getPutAttributes* = Call_GetPutAttributes_600198(name: "getPutAttributes",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=PutAttributes", validator: validate_GetPutAttributes_600199,
    base: "/", url: url_GetPutAttributes_600200,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSelect_600253 = ref object of OpenApiRestCall_599352
proc url_PostSelect_600255(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSelect_600254(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_600256 = query.getOrDefault("SignatureMethod")
  valid_600256 = validateParameter(valid_600256, JString, required = true,
                                 default = nil)
  if valid_600256 != nil:
    section.add "SignatureMethod", valid_600256
  var valid_600257 = query.getOrDefault("Signature")
  valid_600257 = validateParameter(valid_600257, JString, required = true,
                                 default = nil)
  if valid_600257 != nil:
    section.add "Signature", valid_600257
  var valid_600258 = query.getOrDefault("Action")
  valid_600258 = validateParameter(valid_600258, JString, required = true,
                                 default = newJString("Select"))
  if valid_600258 != nil:
    section.add "Action", valid_600258
  var valid_600259 = query.getOrDefault("Timestamp")
  valid_600259 = validateParameter(valid_600259, JString, required = true,
                                 default = nil)
  if valid_600259 != nil:
    section.add "Timestamp", valid_600259
  var valid_600260 = query.getOrDefault("SignatureVersion")
  valid_600260 = validateParameter(valid_600260, JString, required = true,
                                 default = nil)
  if valid_600260 != nil:
    section.add "SignatureVersion", valid_600260
  var valid_600261 = query.getOrDefault("AWSAccessKeyId")
  valid_600261 = validateParameter(valid_600261, JString, required = true,
                                 default = nil)
  if valid_600261 != nil:
    section.add "AWSAccessKeyId", valid_600261
  var valid_600262 = query.getOrDefault("Version")
  valid_600262 = validateParameter(valid_600262, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_600262 != nil:
    section.add "Version", valid_600262
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : A string informing Amazon SimpleDB where to start the next list of <code>ItemNames</code>.
  ##   ConsistentRead: JBool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  ##   SelectExpression: JString (required)
  ##                   : The expression used to query the domain.
  section = newJObject()
  var valid_600263 = formData.getOrDefault("NextToken")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "NextToken", valid_600263
  var valid_600264 = formData.getOrDefault("ConsistentRead")
  valid_600264 = validateParameter(valid_600264, JBool, required = false, default = nil)
  if valid_600264 != nil:
    section.add "ConsistentRead", valid_600264
  assert formData != nil, "formData argument is necessary due to required `SelectExpression` field"
  var valid_600265 = formData.getOrDefault("SelectExpression")
  valid_600265 = validateParameter(valid_600265, JString, required = true,
                                 default = nil)
  if valid_600265 != nil:
    section.add "SelectExpression", valid_600265
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600266: Call_PostSelect_600253; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  let valid = call_600266.validator(path, query, header, formData, body)
  let scheme = call_600266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600266.url(scheme.get, call_600266.host, call_600266.base,
                         call_600266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600266, url, valid)

proc call*(call_600267: Call_PostSelect_600253; SignatureMethod: string;
          Signature: string; Timestamp: string; SignatureVersion: string;
          AWSAccessKeyId: string; SelectExpression: string; NextToken: string = "";
          ConsistentRead: bool = false; Action: string = "Select";
          Version: string = "2009-04-15"): Recallable =
  ## postSelect
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ##   NextToken: string
  ##            : A string informing Amazon SimpleDB where to start the next list of <code>ItemNames</code>.
  ##   SignatureMethod: string (required)
  ##   ConsistentRead: bool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SelectExpression: string (required)
  ##                   : The expression used to query the domain.
  ##   Version: string (required)
  var query_600268 = newJObject()
  var formData_600269 = newJObject()
  add(formData_600269, "NextToken", newJString(NextToken))
  add(query_600268, "SignatureMethod", newJString(SignatureMethod))
  add(formData_600269, "ConsistentRead", newJBool(ConsistentRead))
  add(query_600268, "Signature", newJString(Signature))
  add(query_600268, "Action", newJString(Action))
  add(query_600268, "Timestamp", newJString(Timestamp))
  add(query_600268, "SignatureVersion", newJString(SignatureVersion))
  add(query_600268, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_600269, "SelectExpression", newJString(SelectExpression))
  add(query_600268, "Version", newJString(Version))
  result = call_600267.call(nil, query_600268, nil, formData_600269, nil)

var postSelect* = Call_PostSelect_600253(name: "postSelect",
                                      meth: HttpMethod.HttpPost,
                                      host: "sdb.amazonaws.com",
                                      route: "/#Action=Select",
                                      validator: validate_PostSelect_600254,
                                      base: "/", url: url_PostSelect_600255,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSelect_600237 = ref object of OpenApiRestCall_599352
proc url_GetSelect_600239(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSelect_600238(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   NextToken: JString
  ##            : A string informing Amazon SimpleDB where to start the next list of <code>ItemNames</code>.
  ##   SelectExpression: JString (required)
  ##                   : The expression used to query the domain.
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   ConsistentRead: JBool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_600240 = query.getOrDefault("SignatureMethod")
  valid_600240 = validateParameter(valid_600240, JString, required = true,
                                 default = nil)
  if valid_600240 != nil:
    section.add "SignatureMethod", valid_600240
  var valid_600241 = query.getOrDefault("Signature")
  valid_600241 = validateParameter(valid_600241, JString, required = true,
                                 default = nil)
  if valid_600241 != nil:
    section.add "Signature", valid_600241
  var valid_600242 = query.getOrDefault("NextToken")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "NextToken", valid_600242
  var valid_600243 = query.getOrDefault("SelectExpression")
  valid_600243 = validateParameter(valid_600243, JString, required = true,
                                 default = nil)
  if valid_600243 != nil:
    section.add "SelectExpression", valid_600243
  var valid_600244 = query.getOrDefault("Action")
  valid_600244 = validateParameter(valid_600244, JString, required = true,
                                 default = newJString("Select"))
  if valid_600244 != nil:
    section.add "Action", valid_600244
  var valid_600245 = query.getOrDefault("Timestamp")
  valid_600245 = validateParameter(valid_600245, JString, required = true,
                                 default = nil)
  if valid_600245 != nil:
    section.add "Timestamp", valid_600245
  var valid_600246 = query.getOrDefault("ConsistentRead")
  valid_600246 = validateParameter(valid_600246, JBool, required = false, default = nil)
  if valid_600246 != nil:
    section.add "ConsistentRead", valid_600246
  var valid_600247 = query.getOrDefault("SignatureVersion")
  valid_600247 = validateParameter(valid_600247, JString, required = true,
                                 default = nil)
  if valid_600247 != nil:
    section.add "SignatureVersion", valid_600247
  var valid_600248 = query.getOrDefault("AWSAccessKeyId")
  valid_600248 = validateParameter(valid_600248, JString, required = true,
                                 default = nil)
  if valid_600248 != nil:
    section.add "AWSAccessKeyId", valid_600248
  var valid_600249 = query.getOrDefault("Version")
  valid_600249 = validateParameter(valid_600249, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_600249 != nil:
    section.add "Version", valid_600249
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600250: Call_GetSelect_600237; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  let valid = call_600250.validator(path, query, header, formData, body)
  let scheme = call_600250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600250.url(scheme.get, call_600250.host, call_600250.base,
                         call_600250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600250, url, valid)

proc call*(call_600251: Call_GetSelect_600237; SignatureMethod: string;
          Signature: string; SelectExpression: string; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string; NextToken: string = "";
          Action: string = "Select"; ConsistentRead: bool = false;
          Version: string = "2009-04-15"): Recallable =
  ## getSelect
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   NextToken: string
  ##            : A string informing Amazon SimpleDB where to start the next list of <code>ItemNames</code>.
  ##   SelectExpression: string (required)
  ##                   : The expression used to query the domain.
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   ConsistentRead: bool
  ##                 : Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_600252 = newJObject()
  add(query_600252, "SignatureMethod", newJString(SignatureMethod))
  add(query_600252, "Signature", newJString(Signature))
  add(query_600252, "NextToken", newJString(NextToken))
  add(query_600252, "SelectExpression", newJString(SelectExpression))
  add(query_600252, "Action", newJString(Action))
  add(query_600252, "Timestamp", newJString(Timestamp))
  add(query_600252, "ConsistentRead", newJBool(ConsistentRead))
  add(query_600252, "SignatureVersion", newJString(SignatureVersion))
  add(query_600252, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600252, "Version", newJString(Version))
  result = call_600251.call(nil, query_600252, nil, nil, nil)

var getSelect* = Call_GetSelect_600237(name: "getSelect", meth: HttpMethod.HttpGet,
                                    host: "sdb.amazonaws.com",
                                    route: "/#Action=Select",
                                    validator: validate_GetSelect_600238,
                                    base: "/", url: url_GetSelect_600239,
                                    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
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
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
