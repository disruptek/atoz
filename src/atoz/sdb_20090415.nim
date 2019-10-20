
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_592348 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592348](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592348): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostBatchDeleteAttributes_592957 = ref object of OpenApiRestCall_592348
proc url_PostBatchDeleteAttributes_592959(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostBatchDeleteAttributes_592958(path: JsonNode; query: JsonNode;
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
  var valid_592960 = query.getOrDefault("Signature")
  valid_592960 = validateParameter(valid_592960, JString, required = true,
                                 default = nil)
  if valid_592960 != nil:
    section.add "Signature", valid_592960
  var valid_592961 = query.getOrDefault("AWSAccessKeyId")
  valid_592961 = validateParameter(valid_592961, JString, required = true,
                                 default = nil)
  if valid_592961 != nil:
    section.add "AWSAccessKeyId", valid_592961
  var valid_592962 = query.getOrDefault("SignatureMethod")
  valid_592962 = validateParameter(valid_592962, JString, required = true,
                                 default = nil)
  if valid_592962 != nil:
    section.add "SignatureMethod", valid_592962
  var valid_592963 = query.getOrDefault("Timestamp")
  valid_592963 = validateParameter(valid_592963, JString, required = true,
                                 default = nil)
  if valid_592963 != nil:
    section.add "Timestamp", valid_592963
  var valid_592964 = query.getOrDefault("Action")
  valid_592964 = validateParameter(valid_592964, JString, required = true,
                                 default = newJString("BatchDeleteAttributes"))
  if valid_592964 != nil:
    section.add "Action", valid_592964
  var valid_592965 = query.getOrDefault("Version")
  valid_592965 = validateParameter(valid_592965, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_592965 != nil:
    section.add "Version", valid_592965
  var valid_592966 = query.getOrDefault("SignatureVersion")
  valid_592966 = validateParameter(valid_592966, JString, required = true,
                                 default = nil)
  if valid_592966 != nil:
    section.add "SignatureVersion", valid_592966
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
  var valid_592967 = formData.getOrDefault("DomainName")
  valid_592967 = validateParameter(valid_592967, JString, required = true,
                                 default = nil)
  if valid_592967 != nil:
    section.add "DomainName", valid_592967
  var valid_592968 = formData.getOrDefault("Items")
  valid_592968 = validateParameter(valid_592968, JArray, required = true, default = nil)
  if valid_592968 != nil:
    section.add "Items", valid_592968
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592969: Call_PostBatchDeleteAttributes_592957; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  let valid = call_592969.validator(path, query, header, formData, body)
  let scheme = call_592969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592969.url(scheme.get, call_592969.host, call_592969.base,
                         call_592969.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592969, url, valid)

proc call*(call_592970: Call_PostBatchDeleteAttributes_592957; Signature: string;
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
  var query_592971 = newJObject()
  var formData_592972 = newJObject()
  add(query_592971, "Signature", newJString(Signature))
  add(query_592971, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_592971, "SignatureMethod", newJString(SignatureMethod))
  add(formData_592972, "DomainName", newJString(DomainName))
  add(query_592971, "Timestamp", newJString(Timestamp))
  add(query_592971, "Action", newJString(Action))
  if Items != nil:
    formData_592972.add "Items", Items
  add(query_592971, "Version", newJString(Version))
  add(query_592971, "SignatureVersion", newJString(SignatureVersion))
  result = call_592970.call(nil, query_592971, nil, formData_592972, nil)

var postBatchDeleteAttributes* = Call_PostBatchDeleteAttributes_592957(
    name: "postBatchDeleteAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=BatchDeleteAttributes",
    validator: validate_PostBatchDeleteAttributes_592958, base: "/",
    url: url_PostBatchDeleteAttributes_592959,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchDeleteAttributes_592687 = ref object of OpenApiRestCall_592348
proc url_GetBatchDeleteAttributes_592689(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBatchDeleteAttributes_592688(path: JsonNode; query: JsonNode;
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
  var valid_592801 = query.getOrDefault("Signature")
  valid_592801 = validateParameter(valid_592801, JString, required = true,
                                 default = nil)
  if valid_592801 != nil:
    section.add "Signature", valid_592801
  var valid_592802 = query.getOrDefault("AWSAccessKeyId")
  valid_592802 = validateParameter(valid_592802, JString, required = true,
                                 default = nil)
  if valid_592802 != nil:
    section.add "AWSAccessKeyId", valid_592802
  var valid_592803 = query.getOrDefault("SignatureMethod")
  valid_592803 = validateParameter(valid_592803, JString, required = true,
                                 default = nil)
  if valid_592803 != nil:
    section.add "SignatureMethod", valid_592803
  var valid_592804 = query.getOrDefault("DomainName")
  valid_592804 = validateParameter(valid_592804, JString, required = true,
                                 default = nil)
  if valid_592804 != nil:
    section.add "DomainName", valid_592804
  var valid_592805 = query.getOrDefault("Items")
  valid_592805 = validateParameter(valid_592805, JArray, required = true, default = nil)
  if valid_592805 != nil:
    section.add "Items", valid_592805
  var valid_592806 = query.getOrDefault("Timestamp")
  valid_592806 = validateParameter(valid_592806, JString, required = true,
                                 default = nil)
  if valid_592806 != nil:
    section.add "Timestamp", valid_592806
  var valid_592820 = query.getOrDefault("Action")
  valid_592820 = validateParameter(valid_592820, JString, required = true,
                                 default = newJString("BatchDeleteAttributes"))
  if valid_592820 != nil:
    section.add "Action", valid_592820
  var valid_592821 = query.getOrDefault("Version")
  valid_592821 = validateParameter(valid_592821, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_592821 != nil:
    section.add "Version", valid_592821
  var valid_592822 = query.getOrDefault("SignatureVersion")
  valid_592822 = validateParameter(valid_592822, JString, required = true,
                                 default = nil)
  if valid_592822 != nil:
    section.add "SignatureVersion", valid_592822
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592845: Call_GetBatchDeleteAttributes_592687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  let valid = call_592845.validator(path, query, header, formData, body)
  let scheme = call_592845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592845.url(scheme.get, call_592845.host, call_592845.base,
                         call_592845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592845, url, valid)

proc call*(call_592916: Call_GetBatchDeleteAttributes_592687; Signature: string;
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
  var query_592917 = newJObject()
  add(query_592917, "Signature", newJString(Signature))
  add(query_592917, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_592917, "SignatureMethod", newJString(SignatureMethod))
  add(query_592917, "DomainName", newJString(DomainName))
  if Items != nil:
    query_592917.add "Items", Items
  add(query_592917, "Timestamp", newJString(Timestamp))
  add(query_592917, "Action", newJString(Action))
  add(query_592917, "Version", newJString(Version))
  add(query_592917, "SignatureVersion", newJString(SignatureVersion))
  result = call_592916.call(nil, query_592917, nil, nil, nil)

var getBatchDeleteAttributes* = Call_GetBatchDeleteAttributes_592687(
    name: "getBatchDeleteAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=BatchDeleteAttributes",
    validator: validate_GetBatchDeleteAttributes_592688, base: "/",
    url: url_GetBatchDeleteAttributes_592689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostBatchPutAttributes_592988 = ref object of OpenApiRestCall_592348
proc url_PostBatchPutAttributes_592990(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostBatchPutAttributes_592989(path: JsonNode; query: JsonNode;
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
  var valid_592991 = query.getOrDefault("Signature")
  valid_592991 = validateParameter(valid_592991, JString, required = true,
                                 default = nil)
  if valid_592991 != nil:
    section.add "Signature", valid_592991
  var valid_592992 = query.getOrDefault("AWSAccessKeyId")
  valid_592992 = validateParameter(valid_592992, JString, required = true,
                                 default = nil)
  if valid_592992 != nil:
    section.add "AWSAccessKeyId", valid_592992
  var valid_592993 = query.getOrDefault("SignatureMethod")
  valid_592993 = validateParameter(valid_592993, JString, required = true,
                                 default = nil)
  if valid_592993 != nil:
    section.add "SignatureMethod", valid_592993
  var valid_592994 = query.getOrDefault("Timestamp")
  valid_592994 = validateParameter(valid_592994, JString, required = true,
                                 default = nil)
  if valid_592994 != nil:
    section.add "Timestamp", valid_592994
  var valid_592995 = query.getOrDefault("Action")
  valid_592995 = validateParameter(valid_592995, JString, required = true,
                                 default = newJString("BatchPutAttributes"))
  if valid_592995 != nil:
    section.add "Action", valid_592995
  var valid_592996 = query.getOrDefault("Version")
  valid_592996 = validateParameter(valid_592996, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_592996 != nil:
    section.add "Version", valid_592996
  var valid_592997 = query.getOrDefault("SignatureVersion")
  valid_592997 = validateParameter(valid_592997, JString, required = true,
                                 default = nil)
  if valid_592997 != nil:
    section.add "SignatureVersion", valid_592997
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
  var valid_592998 = formData.getOrDefault("DomainName")
  valid_592998 = validateParameter(valid_592998, JString, required = true,
                                 default = nil)
  if valid_592998 != nil:
    section.add "DomainName", valid_592998
  var valid_592999 = formData.getOrDefault("Items")
  valid_592999 = validateParameter(valid_592999, JArray, required = true, default = nil)
  if valid_592999 != nil:
    section.add "Items", valid_592999
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593000: Call_PostBatchPutAttributes_592988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  let valid = call_593000.validator(path, query, header, formData, body)
  let scheme = call_593000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593000.url(scheme.get, call_593000.host, call_593000.base,
                         call_593000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593000, url, valid)

proc call*(call_593001: Call_PostBatchPutAttributes_592988; Signature: string;
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
  var query_593002 = newJObject()
  var formData_593003 = newJObject()
  add(query_593002, "Signature", newJString(Signature))
  add(query_593002, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_593002, "SignatureMethod", newJString(SignatureMethod))
  add(formData_593003, "DomainName", newJString(DomainName))
  add(query_593002, "Timestamp", newJString(Timestamp))
  add(query_593002, "Action", newJString(Action))
  if Items != nil:
    formData_593003.add "Items", Items
  add(query_593002, "Version", newJString(Version))
  add(query_593002, "SignatureVersion", newJString(SignatureVersion))
  result = call_593001.call(nil, query_593002, nil, formData_593003, nil)

var postBatchPutAttributes* = Call_PostBatchPutAttributes_592988(
    name: "postBatchPutAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=BatchPutAttributes",
    validator: validate_PostBatchPutAttributes_592989, base: "/",
    url: url_PostBatchPutAttributes_592990, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchPutAttributes_592973 = ref object of OpenApiRestCall_592348
proc url_GetBatchPutAttributes_592975(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBatchPutAttributes_592974(path: JsonNode; query: JsonNode;
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
  var valid_592976 = query.getOrDefault("Signature")
  valid_592976 = validateParameter(valid_592976, JString, required = true,
                                 default = nil)
  if valid_592976 != nil:
    section.add "Signature", valid_592976
  var valid_592977 = query.getOrDefault("AWSAccessKeyId")
  valid_592977 = validateParameter(valid_592977, JString, required = true,
                                 default = nil)
  if valid_592977 != nil:
    section.add "AWSAccessKeyId", valid_592977
  var valid_592978 = query.getOrDefault("SignatureMethod")
  valid_592978 = validateParameter(valid_592978, JString, required = true,
                                 default = nil)
  if valid_592978 != nil:
    section.add "SignatureMethod", valid_592978
  var valid_592979 = query.getOrDefault("DomainName")
  valid_592979 = validateParameter(valid_592979, JString, required = true,
                                 default = nil)
  if valid_592979 != nil:
    section.add "DomainName", valid_592979
  var valid_592980 = query.getOrDefault("Items")
  valid_592980 = validateParameter(valid_592980, JArray, required = true, default = nil)
  if valid_592980 != nil:
    section.add "Items", valid_592980
  var valid_592981 = query.getOrDefault("Timestamp")
  valid_592981 = validateParameter(valid_592981, JString, required = true,
                                 default = nil)
  if valid_592981 != nil:
    section.add "Timestamp", valid_592981
  var valid_592982 = query.getOrDefault("Action")
  valid_592982 = validateParameter(valid_592982, JString, required = true,
                                 default = newJString("BatchPutAttributes"))
  if valid_592982 != nil:
    section.add "Action", valid_592982
  var valid_592983 = query.getOrDefault("Version")
  valid_592983 = validateParameter(valid_592983, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_592983 != nil:
    section.add "Version", valid_592983
  var valid_592984 = query.getOrDefault("SignatureVersion")
  valid_592984 = validateParameter(valid_592984, JString, required = true,
                                 default = nil)
  if valid_592984 != nil:
    section.add "SignatureVersion", valid_592984
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592985: Call_GetBatchPutAttributes_592973; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  let valid = call_592985.validator(path, query, header, formData, body)
  let scheme = call_592985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592985.url(scheme.get, call_592985.host, call_592985.base,
                         call_592985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592985, url, valid)

proc call*(call_592986: Call_GetBatchPutAttributes_592973; Signature: string;
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
  var query_592987 = newJObject()
  add(query_592987, "Signature", newJString(Signature))
  add(query_592987, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_592987, "SignatureMethod", newJString(SignatureMethod))
  add(query_592987, "DomainName", newJString(DomainName))
  if Items != nil:
    query_592987.add "Items", Items
  add(query_592987, "Timestamp", newJString(Timestamp))
  add(query_592987, "Action", newJString(Action))
  add(query_592987, "Version", newJString(Version))
  add(query_592987, "SignatureVersion", newJString(SignatureVersion))
  result = call_592986.call(nil, query_592987, nil, nil, nil)

var getBatchPutAttributes* = Call_GetBatchPutAttributes_592973(
    name: "getBatchPutAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=BatchPutAttributes",
    validator: validate_GetBatchPutAttributes_592974, base: "/",
    url: url_GetBatchPutAttributes_592975, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDomain_593018 = ref object of OpenApiRestCall_592348
proc url_PostCreateDomain_593020(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDomain_593019(path: JsonNode; query: JsonNode;
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
  var valid_593021 = query.getOrDefault("Signature")
  valid_593021 = validateParameter(valid_593021, JString, required = true,
                                 default = nil)
  if valid_593021 != nil:
    section.add "Signature", valid_593021
  var valid_593022 = query.getOrDefault("AWSAccessKeyId")
  valid_593022 = validateParameter(valid_593022, JString, required = true,
                                 default = nil)
  if valid_593022 != nil:
    section.add "AWSAccessKeyId", valid_593022
  var valid_593023 = query.getOrDefault("SignatureMethod")
  valid_593023 = validateParameter(valid_593023, JString, required = true,
                                 default = nil)
  if valid_593023 != nil:
    section.add "SignatureMethod", valid_593023
  var valid_593024 = query.getOrDefault("Timestamp")
  valid_593024 = validateParameter(valid_593024, JString, required = true,
                                 default = nil)
  if valid_593024 != nil:
    section.add "Timestamp", valid_593024
  var valid_593025 = query.getOrDefault("Action")
  valid_593025 = validateParameter(valid_593025, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_593025 != nil:
    section.add "Action", valid_593025
  var valid_593026 = query.getOrDefault("Version")
  valid_593026 = validateParameter(valid_593026, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_593026 != nil:
    section.add "Version", valid_593026
  var valid_593027 = query.getOrDefault("SignatureVersion")
  valid_593027 = validateParameter(valid_593027, JString, required = true,
                                 default = nil)
  if valid_593027 != nil:
    section.add "SignatureVersion", valid_593027
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain to create. The name can range between 3 and 255 characters and can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593028 = formData.getOrDefault("DomainName")
  valid_593028 = validateParameter(valid_593028, JString, required = true,
                                 default = nil)
  if valid_593028 != nil:
    section.add "DomainName", valid_593028
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593029: Call_PostCreateDomain_593018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  let valid = call_593029.validator(path, query, header, formData, body)
  let scheme = call_593029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593029.url(scheme.get, call_593029.host, call_593029.base,
                         call_593029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593029, url, valid)

proc call*(call_593030: Call_PostCreateDomain_593018; Signature: string;
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
  var query_593031 = newJObject()
  var formData_593032 = newJObject()
  add(query_593031, "Signature", newJString(Signature))
  add(query_593031, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_593031, "SignatureMethod", newJString(SignatureMethod))
  add(formData_593032, "DomainName", newJString(DomainName))
  add(query_593031, "Timestamp", newJString(Timestamp))
  add(query_593031, "Action", newJString(Action))
  add(query_593031, "Version", newJString(Version))
  add(query_593031, "SignatureVersion", newJString(SignatureVersion))
  result = call_593030.call(nil, query_593031, nil, formData_593032, nil)

var postCreateDomain* = Call_PostCreateDomain_593018(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_593019,
    base: "/", url: url_PostCreateDomain_593020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_593004 = ref object of OpenApiRestCall_592348
proc url_GetCreateDomain_593006(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDomain_593005(path: JsonNode; query: JsonNode;
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
  var valid_593007 = query.getOrDefault("Signature")
  valid_593007 = validateParameter(valid_593007, JString, required = true,
                                 default = nil)
  if valid_593007 != nil:
    section.add "Signature", valid_593007
  var valid_593008 = query.getOrDefault("AWSAccessKeyId")
  valid_593008 = validateParameter(valid_593008, JString, required = true,
                                 default = nil)
  if valid_593008 != nil:
    section.add "AWSAccessKeyId", valid_593008
  var valid_593009 = query.getOrDefault("SignatureMethod")
  valid_593009 = validateParameter(valid_593009, JString, required = true,
                                 default = nil)
  if valid_593009 != nil:
    section.add "SignatureMethod", valid_593009
  var valid_593010 = query.getOrDefault("DomainName")
  valid_593010 = validateParameter(valid_593010, JString, required = true,
                                 default = nil)
  if valid_593010 != nil:
    section.add "DomainName", valid_593010
  var valid_593011 = query.getOrDefault("Timestamp")
  valid_593011 = validateParameter(valid_593011, JString, required = true,
                                 default = nil)
  if valid_593011 != nil:
    section.add "Timestamp", valid_593011
  var valid_593012 = query.getOrDefault("Action")
  valid_593012 = validateParameter(valid_593012, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_593012 != nil:
    section.add "Action", valid_593012
  var valid_593013 = query.getOrDefault("Version")
  valid_593013 = validateParameter(valid_593013, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_593013 != nil:
    section.add "Version", valid_593013
  var valid_593014 = query.getOrDefault("SignatureVersion")
  valid_593014 = validateParameter(valid_593014, JString, required = true,
                                 default = nil)
  if valid_593014 != nil:
    section.add "SignatureVersion", valid_593014
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593015: Call_GetCreateDomain_593004; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  let valid = call_593015.validator(path, query, header, formData, body)
  let scheme = call_593015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593015.url(scheme.get, call_593015.host, call_593015.base,
                         call_593015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593015, url, valid)

proc call*(call_593016: Call_GetCreateDomain_593004; Signature: string;
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
  var query_593017 = newJObject()
  add(query_593017, "Signature", newJString(Signature))
  add(query_593017, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_593017, "SignatureMethod", newJString(SignatureMethod))
  add(query_593017, "DomainName", newJString(DomainName))
  add(query_593017, "Timestamp", newJString(Timestamp))
  add(query_593017, "Action", newJString(Action))
  add(query_593017, "Version", newJString(Version))
  add(query_593017, "SignatureVersion", newJString(SignatureVersion))
  result = call_593016.call(nil, query_593017, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_593004(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_593005,
    base: "/", url: url_GetCreateDomain_593006, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAttributes_593052 = ref object of OpenApiRestCall_592348
proc url_PostDeleteAttributes_593054(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteAttributes_593053(path: JsonNode; query: JsonNode;
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
  var valid_593055 = query.getOrDefault("Signature")
  valid_593055 = validateParameter(valid_593055, JString, required = true,
                                 default = nil)
  if valid_593055 != nil:
    section.add "Signature", valid_593055
  var valid_593056 = query.getOrDefault("AWSAccessKeyId")
  valid_593056 = validateParameter(valid_593056, JString, required = true,
                                 default = nil)
  if valid_593056 != nil:
    section.add "AWSAccessKeyId", valid_593056
  var valid_593057 = query.getOrDefault("SignatureMethod")
  valid_593057 = validateParameter(valid_593057, JString, required = true,
                                 default = nil)
  if valid_593057 != nil:
    section.add "SignatureMethod", valid_593057
  var valid_593058 = query.getOrDefault("Timestamp")
  valid_593058 = validateParameter(valid_593058, JString, required = true,
                                 default = nil)
  if valid_593058 != nil:
    section.add "Timestamp", valid_593058
  var valid_593059 = query.getOrDefault("Action")
  valid_593059 = validateParameter(valid_593059, JString, required = true,
                                 default = newJString("DeleteAttributes"))
  if valid_593059 != nil:
    section.add "Action", valid_593059
  var valid_593060 = query.getOrDefault("Version")
  valid_593060 = validateParameter(valid_593060, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_593060 != nil:
    section.add "Version", valid_593060
  var valid_593061 = query.getOrDefault("SignatureVersion")
  valid_593061 = validateParameter(valid_593061, JString, required = true,
                                 default = nil)
  if valid_593061 != nil:
    section.add "SignatureVersion", valid_593061
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
  var valid_593062 = formData.getOrDefault("Expected.Value")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "Expected.Value", valid_593062
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593063 = formData.getOrDefault("DomainName")
  valid_593063 = validateParameter(valid_593063, JString, required = true,
                                 default = nil)
  if valid_593063 != nil:
    section.add "DomainName", valid_593063
  var valid_593064 = formData.getOrDefault("Attributes")
  valid_593064 = validateParameter(valid_593064, JArray, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "Attributes", valid_593064
  var valid_593065 = formData.getOrDefault("Expected.Name")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "Expected.Name", valid_593065
  var valid_593066 = formData.getOrDefault("Expected.Exists")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "Expected.Exists", valid_593066
  var valid_593067 = formData.getOrDefault("ItemName")
  valid_593067 = validateParameter(valid_593067, JString, required = true,
                                 default = nil)
  if valid_593067 != nil:
    section.add "ItemName", valid_593067
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593068: Call_PostDeleteAttributes_593052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  let valid = call_593068.validator(path, query, header, formData, body)
  let scheme = call_593068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593068.url(scheme.get, call_593068.host, call_593068.base,
                         call_593068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593068, url, valid)

proc call*(call_593069: Call_PostDeleteAttributes_593052; Signature: string;
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
  var query_593070 = newJObject()
  var formData_593071 = newJObject()
  add(formData_593071, "Expected.Value", newJString(ExpectedValue))
  add(query_593070, "Signature", newJString(Signature))
  add(query_593070, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_593070, "SignatureMethod", newJString(SignatureMethod))
  add(formData_593071, "DomainName", newJString(DomainName))
  if Attributes != nil:
    formData_593071.add "Attributes", Attributes
  add(query_593070, "Timestamp", newJString(Timestamp))
  add(query_593070, "Action", newJString(Action))
  add(formData_593071, "Expected.Name", newJString(ExpectedName))
  add(query_593070, "Version", newJString(Version))
  add(formData_593071, "Expected.Exists", newJString(ExpectedExists))
  add(query_593070, "SignatureVersion", newJString(SignatureVersion))
  add(formData_593071, "ItemName", newJString(ItemName))
  result = call_593069.call(nil, query_593070, nil, formData_593071, nil)

var postDeleteAttributes* = Call_PostDeleteAttributes_593052(
    name: "postDeleteAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=DeleteAttributes",
    validator: validate_PostDeleteAttributes_593053, base: "/",
    url: url_PostDeleteAttributes_593054, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAttributes_593033 = ref object of OpenApiRestCall_592348
proc url_GetDeleteAttributes_593035(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteAttributes_593034(path: JsonNode; query: JsonNode;
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
  var valid_593036 = query.getOrDefault("Signature")
  valid_593036 = validateParameter(valid_593036, JString, required = true,
                                 default = nil)
  if valid_593036 != nil:
    section.add "Signature", valid_593036
  var valid_593037 = query.getOrDefault("AWSAccessKeyId")
  valid_593037 = validateParameter(valid_593037, JString, required = true,
                                 default = nil)
  if valid_593037 != nil:
    section.add "AWSAccessKeyId", valid_593037
  var valid_593038 = query.getOrDefault("Expected.Value")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "Expected.Value", valid_593038
  var valid_593039 = query.getOrDefault("SignatureMethod")
  valid_593039 = validateParameter(valid_593039, JString, required = true,
                                 default = nil)
  if valid_593039 != nil:
    section.add "SignatureMethod", valid_593039
  var valid_593040 = query.getOrDefault("DomainName")
  valid_593040 = validateParameter(valid_593040, JString, required = true,
                                 default = nil)
  if valid_593040 != nil:
    section.add "DomainName", valid_593040
  var valid_593041 = query.getOrDefault("Expected.Name")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "Expected.Name", valid_593041
  var valid_593042 = query.getOrDefault("ItemName")
  valid_593042 = validateParameter(valid_593042, JString, required = true,
                                 default = nil)
  if valid_593042 != nil:
    section.add "ItemName", valid_593042
  var valid_593043 = query.getOrDefault("Expected.Exists")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "Expected.Exists", valid_593043
  var valid_593044 = query.getOrDefault("Attributes")
  valid_593044 = validateParameter(valid_593044, JArray, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "Attributes", valid_593044
  var valid_593045 = query.getOrDefault("Timestamp")
  valid_593045 = validateParameter(valid_593045, JString, required = true,
                                 default = nil)
  if valid_593045 != nil:
    section.add "Timestamp", valid_593045
  var valid_593046 = query.getOrDefault("Action")
  valid_593046 = validateParameter(valid_593046, JString, required = true,
                                 default = newJString("DeleteAttributes"))
  if valid_593046 != nil:
    section.add "Action", valid_593046
  var valid_593047 = query.getOrDefault("Version")
  valid_593047 = validateParameter(valid_593047, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_593047 != nil:
    section.add "Version", valid_593047
  var valid_593048 = query.getOrDefault("SignatureVersion")
  valid_593048 = validateParameter(valid_593048, JString, required = true,
                                 default = nil)
  if valid_593048 != nil:
    section.add "SignatureVersion", valid_593048
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593049: Call_GetDeleteAttributes_593033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  let valid = call_593049.validator(path, query, header, formData, body)
  let scheme = call_593049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593049.url(scheme.get, call_593049.host, call_593049.base,
                         call_593049.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593049, url, valid)

proc call*(call_593050: Call_GetDeleteAttributes_593033; Signature: string;
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
  var query_593051 = newJObject()
  add(query_593051, "Signature", newJString(Signature))
  add(query_593051, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_593051, "Expected.Value", newJString(ExpectedValue))
  add(query_593051, "SignatureMethod", newJString(SignatureMethod))
  add(query_593051, "DomainName", newJString(DomainName))
  add(query_593051, "Expected.Name", newJString(ExpectedName))
  add(query_593051, "ItemName", newJString(ItemName))
  add(query_593051, "Expected.Exists", newJString(ExpectedExists))
  if Attributes != nil:
    query_593051.add "Attributes", Attributes
  add(query_593051, "Timestamp", newJString(Timestamp))
  add(query_593051, "Action", newJString(Action))
  add(query_593051, "Version", newJString(Version))
  add(query_593051, "SignatureVersion", newJString(SignatureVersion))
  result = call_593050.call(nil, query_593051, nil, nil, nil)

var getDeleteAttributes* = Call_GetDeleteAttributes_593033(
    name: "getDeleteAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=DeleteAttributes",
    validator: validate_GetDeleteAttributes_593034, base: "/",
    url: url_GetDeleteAttributes_593035, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_593086 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDomain_593088(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDomain_593087(path: JsonNode; query: JsonNode;
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
  var valid_593089 = query.getOrDefault("Signature")
  valid_593089 = validateParameter(valid_593089, JString, required = true,
                                 default = nil)
  if valid_593089 != nil:
    section.add "Signature", valid_593089
  var valid_593090 = query.getOrDefault("AWSAccessKeyId")
  valid_593090 = validateParameter(valid_593090, JString, required = true,
                                 default = nil)
  if valid_593090 != nil:
    section.add "AWSAccessKeyId", valid_593090
  var valid_593091 = query.getOrDefault("SignatureMethod")
  valid_593091 = validateParameter(valid_593091, JString, required = true,
                                 default = nil)
  if valid_593091 != nil:
    section.add "SignatureMethod", valid_593091
  var valid_593092 = query.getOrDefault("Timestamp")
  valid_593092 = validateParameter(valid_593092, JString, required = true,
                                 default = nil)
  if valid_593092 != nil:
    section.add "Timestamp", valid_593092
  var valid_593093 = query.getOrDefault("Action")
  valid_593093 = validateParameter(valid_593093, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_593093 != nil:
    section.add "Action", valid_593093
  var valid_593094 = query.getOrDefault("Version")
  valid_593094 = validateParameter(valid_593094, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_593094 != nil:
    section.add "Version", valid_593094
  var valid_593095 = query.getOrDefault("SignatureVersion")
  valid_593095 = validateParameter(valid_593095, JString, required = true,
                                 default = nil)
  if valid_593095 != nil:
    section.add "SignatureVersion", valid_593095
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593096 = formData.getOrDefault("DomainName")
  valid_593096 = validateParameter(valid_593096, JString, required = true,
                                 default = nil)
  if valid_593096 != nil:
    section.add "DomainName", valid_593096
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593097: Call_PostDeleteDomain_593086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  let valid = call_593097.validator(path, query, header, formData, body)
  let scheme = call_593097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593097.url(scheme.get, call_593097.host, call_593097.base,
                         call_593097.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593097, url, valid)

proc call*(call_593098: Call_PostDeleteDomain_593086; Signature: string;
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
  var query_593099 = newJObject()
  var formData_593100 = newJObject()
  add(query_593099, "Signature", newJString(Signature))
  add(query_593099, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_593099, "SignatureMethod", newJString(SignatureMethod))
  add(formData_593100, "DomainName", newJString(DomainName))
  add(query_593099, "Timestamp", newJString(Timestamp))
  add(query_593099, "Action", newJString(Action))
  add(query_593099, "Version", newJString(Version))
  add(query_593099, "SignatureVersion", newJString(SignatureVersion))
  result = call_593098.call(nil, query_593099, nil, formData_593100, nil)

var postDeleteDomain* = Call_PostDeleteDomain_593086(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_593087,
    base: "/", url: url_PostDeleteDomain_593088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_593072 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDomain_593074(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDomain_593073(path: JsonNode; query: JsonNode;
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
  var valid_593075 = query.getOrDefault("Signature")
  valid_593075 = validateParameter(valid_593075, JString, required = true,
                                 default = nil)
  if valid_593075 != nil:
    section.add "Signature", valid_593075
  var valid_593076 = query.getOrDefault("AWSAccessKeyId")
  valid_593076 = validateParameter(valid_593076, JString, required = true,
                                 default = nil)
  if valid_593076 != nil:
    section.add "AWSAccessKeyId", valid_593076
  var valid_593077 = query.getOrDefault("SignatureMethod")
  valid_593077 = validateParameter(valid_593077, JString, required = true,
                                 default = nil)
  if valid_593077 != nil:
    section.add "SignatureMethod", valid_593077
  var valid_593078 = query.getOrDefault("DomainName")
  valid_593078 = validateParameter(valid_593078, JString, required = true,
                                 default = nil)
  if valid_593078 != nil:
    section.add "DomainName", valid_593078
  var valid_593079 = query.getOrDefault("Timestamp")
  valid_593079 = validateParameter(valid_593079, JString, required = true,
                                 default = nil)
  if valid_593079 != nil:
    section.add "Timestamp", valid_593079
  var valid_593080 = query.getOrDefault("Action")
  valid_593080 = validateParameter(valid_593080, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_593080 != nil:
    section.add "Action", valid_593080
  var valid_593081 = query.getOrDefault("Version")
  valid_593081 = validateParameter(valid_593081, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_593081 != nil:
    section.add "Version", valid_593081
  var valid_593082 = query.getOrDefault("SignatureVersion")
  valid_593082 = validateParameter(valid_593082, JString, required = true,
                                 default = nil)
  if valid_593082 != nil:
    section.add "SignatureVersion", valid_593082
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593083: Call_GetDeleteDomain_593072; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  let valid = call_593083.validator(path, query, header, formData, body)
  let scheme = call_593083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593083.url(scheme.get, call_593083.host, call_593083.base,
                         call_593083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593083, url, valid)

proc call*(call_593084: Call_GetDeleteDomain_593072; Signature: string;
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
  var query_593085 = newJObject()
  add(query_593085, "Signature", newJString(Signature))
  add(query_593085, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_593085, "SignatureMethod", newJString(SignatureMethod))
  add(query_593085, "DomainName", newJString(DomainName))
  add(query_593085, "Timestamp", newJString(Timestamp))
  add(query_593085, "Action", newJString(Action))
  add(query_593085, "Version", newJString(Version))
  add(query_593085, "SignatureVersion", newJString(SignatureVersion))
  result = call_593084.call(nil, query_593085, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_593072(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_593073,
    base: "/", url: url_GetDeleteDomain_593074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDomainMetadata_593115 = ref object of OpenApiRestCall_592348
proc url_PostDomainMetadata_593117(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDomainMetadata_593116(path: JsonNode; query: JsonNode;
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
  var valid_593118 = query.getOrDefault("Signature")
  valid_593118 = validateParameter(valid_593118, JString, required = true,
                                 default = nil)
  if valid_593118 != nil:
    section.add "Signature", valid_593118
  var valid_593119 = query.getOrDefault("AWSAccessKeyId")
  valid_593119 = validateParameter(valid_593119, JString, required = true,
                                 default = nil)
  if valid_593119 != nil:
    section.add "AWSAccessKeyId", valid_593119
  var valid_593120 = query.getOrDefault("SignatureMethod")
  valid_593120 = validateParameter(valid_593120, JString, required = true,
                                 default = nil)
  if valid_593120 != nil:
    section.add "SignatureMethod", valid_593120
  var valid_593121 = query.getOrDefault("Timestamp")
  valid_593121 = validateParameter(valid_593121, JString, required = true,
                                 default = nil)
  if valid_593121 != nil:
    section.add "Timestamp", valid_593121
  var valid_593122 = query.getOrDefault("Action")
  valid_593122 = validateParameter(valid_593122, JString, required = true,
                                 default = newJString("DomainMetadata"))
  if valid_593122 != nil:
    section.add "Action", valid_593122
  var valid_593123 = query.getOrDefault("Version")
  valid_593123 = validateParameter(valid_593123, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_593123 != nil:
    section.add "Version", valid_593123
  var valid_593124 = query.getOrDefault("SignatureVersion")
  valid_593124 = validateParameter(valid_593124, JString, required = true,
                                 default = nil)
  if valid_593124 != nil:
    section.add "SignatureVersion", valid_593124
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain for which to display the metadata of.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593125 = formData.getOrDefault("DomainName")
  valid_593125 = validateParameter(valid_593125, JString, required = true,
                                 default = nil)
  if valid_593125 != nil:
    section.add "DomainName", valid_593125
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593126: Call_PostDomainMetadata_593115; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  let valid = call_593126.validator(path, query, header, formData, body)
  let scheme = call_593126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593126.url(scheme.get, call_593126.host, call_593126.base,
                         call_593126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593126, url, valid)

proc call*(call_593127: Call_PostDomainMetadata_593115; Signature: string;
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
  var query_593128 = newJObject()
  var formData_593129 = newJObject()
  add(query_593128, "Signature", newJString(Signature))
  add(query_593128, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_593128, "SignatureMethod", newJString(SignatureMethod))
  add(formData_593129, "DomainName", newJString(DomainName))
  add(query_593128, "Timestamp", newJString(Timestamp))
  add(query_593128, "Action", newJString(Action))
  add(query_593128, "Version", newJString(Version))
  add(query_593128, "SignatureVersion", newJString(SignatureVersion))
  result = call_593127.call(nil, query_593128, nil, formData_593129, nil)

var postDomainMetadata* = Call_PostDomainMetadata_593115(
    name: "postDomainMetadata", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=DomainMetadata",
    validator: validate_PostDomainMetadata_593116, base: "/",
    url: url_PostDomainMetadata_593117, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainMetadata_593101 = ref object of OpenApiRestCall_592348
proc url_GetDomainMetadata_593103(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDomainMetadata_593102(path: JsonNode; query: JsonNode;
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
  var valid_593104 = query.getOrDefault("Signature")
  valid_593104 = validateParameter(valid_593104, JString, required = true,
                                 default = nil)
  if valid_593104 != nil:
    section.add "Signature", valid_593104
  var valid_593105 = query.getOrDefault("AWSAccessKeyId")
  valid_593105 = validateParameter(valid_593105, JString, required = true,
                                 default = nil)
  if valid_593105 != nil:
    section.add "AWSAccessKeyId", valid_593105
  var valid_593106 = query.getOrDefault("SignatureMethod")
  valid_593106 = validateParameter(valid_593106, JString, required = true,
                                 default = nil)
  if valid_593106 != nil:
    section.add "SignatureMethod", valid_593106
  var valid_593107 = query.getOrDefault("DomainName")
  valid_593107 = validateParameter(valid_593107, JString, required = true,
                                 default = nil)
  if valid_593107 != nil:
    section.add "DomainName", valid_593107
  var valid_593108 = query.getOrDefault("Timestamp")
  valid_593108 = validateParameter(valid_593108, JString, required = true,
                                 default = nil)
  if valid_593108 != nil:
    section.add "Timestamp", valid_593108
  var valid_593109 = query.getOrDefault("Action")
  valid_593109 = validateParameter(valid_593109, JString, required = true,
                                 default = newJString("DomainMetadata"))
  if valid_593109 != nil:
    section.add "Action", valid_593109
  var valid_593110 = query.getOrDefault("Version")
  valid_593110 = validateParameter(valid_593110, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_593110 != nil:
    section.add "Version", valid_593110
  var valid_593111 = query.getOrDefault("SignatureVersion")
  valid_593111 = validateParameter(valid_593111, JString, required = true,
                                 default = nil)
  if valid_593111 != nil:
    section.add "SignatureVersion", valid_593111
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593112: Call_GetDomainMetadata_593101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  let valid = call_593112.validator(path, query, header, formData, body)
  let scheme = call_593112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593112.url(scheme.get, call_593112.host, call_593112.base,
                         call_593112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593112, url, valid)

proc call*(call_593113: Call_GetDomainMetadata_593101; Signature: string;
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
  var query_593114 = newJObject()
  add(query_593114, "Signature", newJString(Signature))
  add(query_593114, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_593114, "SignatureMethod", newJString(SignatureMethod))
  add(query_593114, "DomainName", newJString(DomainName))
  add(query_593114, "Timestamp", newJString(Timestamp))
  add(query_593114, "Action", newJString(Action))
  add(query_593114, "Version", newJString(Version))
  add(query_593114, "SignatureVersion", newJString(SignatureVersion))
  result = call_593113.call(nil, query_593114, nil, nil, nil)

var getDomainMetadata* = Call_GetDomainMetadata_593101(name: "getDomainMetadata",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=DomainMetadata", validator: validate_GetDomainMetadata_593102,
    base: "/", url: url_GetDomainMetadata_593103,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetAttributes_593147 = ref object of OpenApiRestCall_592348
proc url_PostGetAttributes_593149(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetAttributes_593148(path: JsonNode; query: JsonNode;
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
  var valid_593150 = query.getOrDefault("Signature")
  valid_593150 = validateParameter(valid_593150, JString, required = true,
                                 default = nil)
  if valid_593150 != nil:
    section.add "Signature", valid_593150
  var valid_593151 = query.getOrDefault("AWSAccessKeyId")
  valid_593151 = validateParameter(valid_593151, JString, required = true,
                                 default = nil)
  if valid_593151 != nil:
    section.add "AWSAccessKeyId", valid_593151
  var valid_593152 = query.getOrDefault("SignatureMethod")
  valid_593152 = validateParameter(valid_593152, JString, required = true,
                                 default = nil)
  if valid_593152 != nil:
    section.add "SignatureMethod", valid_593152
  var valid_593153 = query.getOrDefault("Timestamp")
  valid_593153 = validateParameter(valid_593153, JString, required = true,
                                 default = nil)
  if valid_593153 != nil:
    section.add "Timestamp", valid_593153
  var valid_593154 = query.getOrDefault("Action")
  valid_593154 = validateParameter(valid_593154, JString, required = true,
                                 default = newJString("GetAttributes"))
  if valid_593154 != nil:
    section.add "Action", valid_593154
  var valid_593155 = query.getOrDefault("Version")
  valid_593155 = validateParameter(valid_593155, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_593155 != nil:
    section.add "Version", valid_593155
  var valid_593156 = query.getOrDefault("SignatureVersion")
  valid_593156 = validateParameter(valid_593156, JString, required = true,
                                 default = nil)
  if valid_593156 != nil:
    section.add "SignatureVersion", valid_593156
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
  var valid_593157 = formData.getOrDefault("ConsistentRead")
  valid_593157 = validateParameter(valid_593157, JBool, required = false, default = nil)
  if valid_593157 != nil:
    section.add "ConsistentRead", valid_593157
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593158 = formData.getOrDefault("DomainName")
  valid_593158 = validateParameter(valid_593158, JString, required = true,
                                 default = nil)
  if valid_593158 != nil:
    section.add "DomainName", valid_593158
  var valid_593159 = formData.getOrDefault("AttributeNames")
  valid_593159 = validateParameter(valid_593159, JArray, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "AttributeNames", valid_593159
  var valid_593160 = formData.getOrDefault("ItemName")
  valid_593160 = validateParameter(valid_593160, JString, required = true,
                                 default = nil)
  if valid_593160 != nil:
    section.add "ItemName", valid_593160
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593161: Call_PostGetAttributes_593147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  let valid = call_593161.validator(path, query, header, formData, body)
  let scheme = call_593161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593161.url(scheme.get, call_593161.host, call_593161.base,
                         call_593161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593161, url, valid)

proc call*(call_593162: Call_PostGetAttributes_593147; Signature: string;
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
  var query_593163 = newJObject()
  var formData_593164 = newJObject()
  add(query_593163, "Signature", newJString(Signature))
  add(query_593163, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_593163, "SignatureMethod", newJString(SignatureMethod))
  add(formData_593164, "ConsistentRead", newJBool(ConsistentRead))
  add(formData_593164, "DomainName", newJString(DomainName))
  if AttributeNames != nil:
    formData_593164.add "AttributeNames", AttributeNames
  add(query_593163, "Timestamp", newJString(Timestamp))
  add(query_593163, "Action", newJString(Action))
  add(query_593163, "Version", newJString(Version))
  add(query_593163, "SignatureVersion", newJString(SignatureVersion))
  add(formData_593164, "ItemName", newJString(ItemName))
  result = call_593162.call(nil, query_593163, nil, formData_593164, nil)

var postGetAttributes* = Call_PostGetAttributes_593147(name: "postGetAttributes",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=GetAttributes", validator: validate_PostGetAttributes_593148,
    base: "/", url: url_PostGetAttributes_593149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetAttributes_593130 = ref object of OpenApiRestCall_592348
proc url_GetGetAttributes_593132(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetAttributes_593131(path: JsonNode; query: JsonNode;
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
  var valid_593133 = query.getOrDefault("Signature")
  valid_593133 = validateParameter(valid_593133, JString, required = true,
                                 default = nil)
  if valid_593133 != nil:
    section.add "Signature", valid_593133
  var valid_593134 = query.getOrDefault("AWSAccessKeyId")
  valid_593134 = validateParameter(valid_593134, JString, required = true,
                                 default = nil)
  if valid_593134 != nil:
    section.add "AWSAccessKeyId", valid_593134
  var valid_593135 = query.getOrDefault("AttributeNames")
  valid_593135 = validateParameter(valid_593135, JArray, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "AttributeNames", valid_593135
  var valid_593136 = query.getOrDefault("SignatureMethod")
  valid_593136 = validateParameter(valid_593136, JString, required = true,
                                 default = nil)
  if valid_593136 != nil:
    section.add "SignatureMethod", valid_593136
  var valid_593137 = query.getOrDefault("DomainName")
  valid_593137 = validateParameter(valid_593137, JString, required = true,
                                 default = nil)
  if valid_593137 != nil:
    section.add "DomainName", valid_593137
  var valid_593138 = query.getOrDefault("ItemName")
  valid_593138 = validateParameter(valid_593138, JString, required = true,
                                 default = nil)
  if valid_593138 != nil:
    section.add "ItemName", valid_593138
  var valid_593139 = query.getOrDefault("Timestamp")
  valid_593139 = validateParameter(valid_593139, JString, required = true,
                                 default = nil)
  if valid_593139 != nil:
    section.add "Timestamp", valid_593139
  var valid_593140 = query.getOrDefault("Action")
  valid_593140 = validateParameter(valid_593140, JString, required = true,
                                 default = newJString("GetAttributes"))
  if valid_593140 != nil:
    section.add "Action", valid_593140
  var valid_593141 = query.getOrDefault("ConsistentRead")
  valid_593141 = validateParameter(valid_593141, JBool, required = false, default = nil)
  if valid_593141 != nil:
    section.add "ConsistentRead", valid_593141
  var valid_593142 = query.getOrDefault("Version")
  valid_593142 = validateParameter(valid_593142, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_593142 != nil:
    section.add "Version", valid_593142
  var valid_593143 = query.getOrDefault("SignatureVersion")
  valid_593143 = validateParameter(valid_593143, JString, required = true,
                                 default = nil)
  if valid_593143 != nil:
    section.add "SignatureVersion", valid_593143
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593144: Call_GetGetAttributes_593130; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  let valid = call_593144.validator(path, query, header, formData, body)
  let scheme = call_593144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593144.url(scheme.get, call_593144.host, call_593144.base,
                         call_593144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593144, url, valid)

proc call*(call_593145: Call_GetGetAttributes_593130; Signature: string;
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
  var query_593146 = newJObject()
  add(query_593146, "Signature", newJString(Signature))
  add(query_593146, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  if AttributeNames != nil:
    query_593146.add "AttributeNames", AttributeNames
  add(query_593146, "SignatureMethod", newJString(SignatureMethod))
  add(query_593146, "DomainName", newJString(DomainName))
  add(query_593146, "ItemName", newJString(ItemName))
  add(query_593146, "Timestamp", newJString(Timestamp))
  add(query_593146, "Action", newJString(Action))
  add(query_593146, "ConsistentRead", newJBool(ConsistentRead))
  add(query_593146, "Version", newJString(Version))
  add(query_593146, "SignatureVersion", newJString(SignatureVersion))
  result = call_593145.call(nil, query_593146, nil, nil, nil)

var getGetAttributes* = Call_GetGetAttributes_593130(name: "getGetAttributes",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=GetAttributes", validator: validate_GetGetAttributes_593131,
    base: "/", url: url_GetGetAttributes_593132,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDomains_593180 = ref object of OpenApiRestCall_592348
proc url_PostListDomains_593182(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListDomains_593181(path: JsonNode; query: JsonNode;
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
  var valid_593183 = query.getOrDefault("Signature")
  valid_593183 = validateParameter(valid_593183, JString, required = true,
                                 default = nil)
  if valid_593183 != nil:
    section.add "Signature", valid_593183
  var valid_593184 = query.getOrDefault("AWSAccessKeyId")
  valid_593184 = validateParameter(valid_593184, JString, required = true,
                                 default = nil)
  if valid_593184 != nil:
    section.add "AWSAccessKeyId", valid_593184
  var valid_593185 = query.getOrDefault("SignatureMethod")
  valid_593185 = validateParameter(valid_593185, JString, required = true,
                                 default = nil)
  if valid_593185 != nil:
    section.add "SignatureMethod", valid_593185
  var valid_593186 = query.getOrDefault("Timestamp")
  valid_593186 = validateParameter(valid_593186, JString, required = true,
                                 default = nil)
  if valid_593186 != nil:
    section.add "Timestamp", valid_593186
  var valid_593187 = query.getOrDefault("Action")
  valid_593187 = validateParameter(valid_593187, JString, required = true,
                                 default = newJString("ListDomains"))
  if valid_593187 != nil:
    section.add "Action", valid_593187
  var valid_593188 = query.getOrDefault("Version")
  valid_593188 = validateParameter(valid_593188, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_593188 != nil:
    section.add "Version", valid_593188
  var valid_593189 = query.getOrDefault("SignatureVersion")
  valid_593189 = validateParameter(valid_593189, JString, required = true,
                                 default = nil)
  if valid_593189 != nil:
    section.add "SignatureVersion", valid_593189
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : A string informing Amazon SimpleDB where to start the next list of domain names.
  ##   MaxNumberOfDomains: JInt
  ##                     : The maximum number of domain names you want returned. The range is 1 to 100. The default setting is 100.
  section = newJObject()
  var valid_593190 = formData.getOrDefault("NextToken")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "NextToken", valid_593190
  var valid_593191 = formData.getOrDefault("MaxNumberOfDomains")
  valid_593191 = validateParameter(valid_593191, JInt, required = false, default = nil)
  if valid_593191 != nil:
    section.add "MaxNumberOfDomains", valid_593191
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593192: Call_PostListDomains_593180; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  let valid = call_593192.validator(path, query, header, formData, body)
  let scheme = call_593192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593192.url(scheme.get, call_593192.host, call_593192.base,
                         call_593192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593192, url, valid)

proc call*(call_593193: Call_PostListDomains_593180; Signature: string;
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
  var query_593194 = newJObject()
  var formData_593195 = newJObject()
  add(query_593194, "Signature", newJString(Signature))
  add(query_593194, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_593195, "NextToken", newJString(NextToken))
  add(query_593194, "SignatureMethod", newJString(SignatureMethod))
  add(formData_593195, "MaxNumberOfDomains", newJInt(MaxNumberOfDomains))
  add(query_593194, "Timestamp", newJString(Timestamp))
  add(query_593194, "Action", newJString(Action))
  add(query_593194, "Version", newJString(Version))
  add(query_593194, "SignatureVersion", newJString(SignatureVersion))
  result = call_593193.call(nil, query_593194, nil, formData_593195, nil)

var postListDomains* = Call_PostListDomains_593180(name: "postListDomains",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=ListDomains", validator: validate_PostListDomains_593181,
    base: "/", url: url_PostListDomains_593182, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDomains_593165 = ref object of OpenApiRestCall_592348
proc url_GetListDomains_593167(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListDomains_593166(path: JsonNode; query: JsonNode;
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
  var valid_593168 = query.getOrDefault("Signature")
  valid_593168 = validateParameter(valid_593168, JString, required = true,
                                 default = nil)
  if valid_593168 != nil:
    section.add "Signature", valid_593168
  var valid_593169 = query.getOrDefault("AWSAccessKeyId")
  valid_593169 = validateParameter(valid_593169, JString, required = true,
                                 default = nil)
  if valid_593169 != nil:
    section.add "AWSAccessKeyId", valid_593169
  var valid_593170 = query.getOrDefault("SignatureMethod")
  valid_593170 = validateParameter(valid_593170, JString, required = true,
                                 default = nil)
  if valid_593170 != nil:
    section.add "SignatureMethod", valid_593170
  var valid_593171 = query.getOrDefault("NextToken")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "NextToken", valid_593171
  var valid_593172 = query.getOrDefault("MaxNumberOfDomains")
  valid_593172 = validateParameter(valid_593172, JInt, required = false, default = nil)
  if valid_593172 != nil:
    section.add "MaxNumberOfDomains", valid_593172
  var valid_593173 = query.getOrDefault("Timestamp")
  valid_593173 = validateParameter(valid_593173, JString, required = true,
                                 default = nil)
  if valid_593173 != nil:
    section.add "Timestamp", valid_593173
  var valid_593174 = query.getOrDefault("Action")
  valid_593174 = validateParameter(valid_593174, JString, required = true,
                                 default = newJString("ListDomains"))
  if valid_593174 != nil:
    section.add "Action", valid_593174
  var valid_593175 = query.getOrDefault("Version")
  valid_593175 = validateParameter(valid_593175, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_593175 != nil:
    section.add "Version", valid_593175
  var valid_593176 = query.getOrDefault("SignatureVersion")
  valid_593176 = validateParameter(valid_593176, JString, required = true,
                                 default = nil)
  if valid_593176 != nil:
    section.add "SignatureVersion", valid_593176
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593177: Call_GetListDomains_593165; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  let valid = call_593177.validator(path, query, header, formData, body)
  let scheme = call_593177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593177.url(scheme.get, call_593177.host, call_593177.base,
                         call_593177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593177, url, valid)

proc call*(call_593178: Call_GetListDomains_593165; Signature: string;
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
  var query_593179 = newJObject()
  add(query_593179, "Signature", newJString(Signature))
  add(query_593179, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_593179, "SignatureMethod", newJString(SignatureMethod))
  add(query_593179, "NextToken", newJString(NextToken))
  add(query_593179, "MaxNumberOfDomains", newJInt(MaxNumberOfDomains))
  add(query_593179, "Timestamp", newJString(Timestamp))
  add(query_593179, "Action", newJString(Action))
  add(query_593179, "Version", newJString(Version))
  add(query_593179, "SignatureVersion", newJString(SignatureVersion))
  result = call_593178.call(nil, query_593179, nil, nil, nil)

var getListDomains* = Call_GetListDomains_593165(name: "getListDomains",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=ListDomains", validator: validate_GetListDomains_593166,
    base: "/", url: url_GetListDomains_593167, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutAttributes_593215 = ref object of OpenApiRestCall_592348
proc url_PostPutAttributes_593217(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPutAttributes_593216(path: JsonNode; query: JsonNode;
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
  var valid_593218 = query.getOrDefault("Signature")
  valid_593218 = validateParameter(valid_593218, JString, required = true,
                                 default = nil)
  if valid_593218 != nil:
    section.add "Signature", valid_593218
  var valid_593219 = query.getOrDefault("AWSAccessKeyId")
  valid_593219 = validateParameter(valid_593219, JString, required = true,
                                 default = nil)
  if valid_593219 != nil:
    section.add "AWSAccessKeyId", valid_593219
  var valid_593220 = query.getOrDefault("SignatureMethod")
  valid_593220 = validateParameter(valid_593220, JString, required = true,
                                 default = nil)
  if valid_593220 != nil:
    section.add "SignatureMethod", valid_593220
  var valid_593221 = query.getOrDefault("Timestamp")
  valid_593221 = validateParameter(valid_593221, JString, required = true,
                                 default = nil)
  if valid_593221 != nil:
    section.add "Timestamp", valid_593221
  var valid_593222 = query.getOrDefault("Action")
  valid_593222 = validateParameter(valid_593222, JString, required = true,
                                 default = newJString("PutAttributes"))
  if valid_593222 != nil:
    section.add "Action", valid_593222
  var valid_593223 = query.getOrDefault("Version")
  valid_593223 = validateParameter(valid_593223, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_593223 != nil:
    section.add "Version", valid_593223
  var valid_593224 = query.getOrDefault("SignatureVersion")
  valid_593224 = validateParameter(valid_593224, JString, required = true,
                                 default = nil)
  if valid_593224 != nil:
    section.add "SignatureVersion", valid_593224
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
  var valid_593225 = formData.getOrDefault("Expected.Value")
  valid_593225 = validateParameter(valid_593225, JString, required = false,
                                 default = nil)
  if valid_593225 != nil:
    section.add "Expected.Value", valid_593225
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593226 = formData.getOrDefault("DomainName")
  valid_593226 = validateParameter(valid_593226, JString, required = true,
                                 default = nil)
  if valid_593226 != nil:
    section.add "DomainName", valid_593226
  var valid_593227 = formData.getOrDefault("Attributes")
  valid_593227 = validateParameter(valid_593227, JArray, required = true, default = nil)
  if valid_593227 != nil:
    section.add "Attributes", valid_593227
  var valid_593228 = formData.getOrDefault("Expected.Name")
  valid_593228 = validateParameter(valid_593228, JString, required = false,
                                 default = nil)
  if valid_593228 != nil:
    section.add "Expected.Name", valid_593228
  var valid_593229 = formData.getOrDefault("Expected.Exists")
  valid_593229 = validateParameter(valid_593229, JString, required = false,
                                 default = nil)
  if valid_593229 != nil:
    section.add "Expected.Exists", valid_593229
  var valid_593230 = formData.getOrDefault("ItemName")
  valid_593230 = validateParameter(valid_593230, JString, required = true,
                                 default = nil)
  if valid_593230 != nil:
    section.add "ItemName", valid_593230
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593231: Call_PostPutAttributes_593215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  let valid = call_593231.validator(path, query, header, formData, body)
  let scheme = call_593231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593231.url(scheme.get, call_593231.host, call_593231.base,
                         call_593231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593231, url, valid)

proc call*(call_593232: Call_PostPutAttributes_593215; Signature: string;
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
  var query_593233 = newJObject()
  var formData_593234 = newJObject()
  add(formData_593234, "Expected.Value", newJString(ExpectedValue))
  add(query_593233, "Signature", newJString(Signature))
  add(query_593233, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_593233, "SignatureMethod", newJString(SignatureMethod))
  add(formData_593234, "DomainName", newJString(DomainName))
  if Attributes != nil:
    formData_593234.add "Attributes", Attributes
  add(query_593233, "Timestamp", newJString(Timestamp))
  add(query_593233, "Action", newJString(Action))
  add(formData_593234, "Expected.Name", newJString(ExpectedName))
  add(query_593233, "Version", newJString(Version))
  add(formData_593234, "Expected.Exists", newJString(ExpectedExists))
  add(query_593233, "SignatureVersion", newJString(SignatureVersion))
  add(formData_593234, "ItemName", newJString(ItemName))
  result = call_593232.call(nil, query_593233, nil, formData_593234, nil)

var postPutAttributes* = Call_PostPutAttributes_593215(name: "postPutAttributes",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=PutAttributes", validator: validate_PostPutAttributes_593216,
    base: "/", url: url_PostPutAttributes_593217,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutAttributes_593196 = ref object of OpenApiRestCall_592348
proc url_GetPutAttributes_593198(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPutAttributes_593197(path: JsonNode; query: JsonNode;
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
  var valid_593199 = query.getOrDefault("Signature")
  valid_593199 = validateParameter(valid_593199, JString, required = true,
                                 default = nil)
  if valid_593199 != nil:
    section.add "Signature", valid_593199
  var valid_593200 = query.getOrDefault("AWSAccessKeyId")
  valid_593200 = validateParameter(valid_593200, JString, required = true,
                                 default = nil)
  if valid_593200 != nil:
    section.add "AWSAccessKeyId", valid_593200
  var valid_593201 = query.getOrDefault("Expected.Value")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "Expected.Value", valid_593201
  var valid_593202 = query.getOrDefault("SignatureMethod")
  valid_593202 = validateParameter(valid_593202, JString, required = true,
                                 default = nil)
  if valid_593202 != nil:
    section.add "SignatureMethod", valid_593202
  var valid_593203 = query.getOrDefault("DomainName")
  valid_593203 = validateParameter(valid_593203, JString, required = true,
                                 default = nil)
  if valid_593203 != nil:
    section.add "DomainName", valid_593203
  var valid_593204 = query.getOrDefault("Expected.Name")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "Expected.Name", valid_593204
  var valid_593205 = query.getOrDefault("ItemName")
  valid_593205 = validateParameter(valid_593205, JString, required = true,
                                 default = nil)
  if valid_593205 != nil:
    section.add "ItemName", valid_593205
  var valid_593206 = query.getOrDefault("Expected.Exists")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "Expected.Exists", valid_593206
  var valid_593207 = query.getOrDefault("Attributes")
  valid_593207 = validateParameter(valid_593207, JArray, required = true, default = nil)
  if valid_593207 != nil:
    section.add "Attributes", valid_593207
  var valid_593208 = query.getOrDefault("Timestamp")
  valid_593208 = validateParameter(valid_593208, JString, required = true,
                                 default = nil)
  if valid_593208 != nil:
    section.add "Timestamp", valid_593208
  var valid_593209 = query.getOrDefault("Action")
  valid_593209 = validateParameter(valid_593209, JString, required = true,
                                 default = newJString("PutAttributes"))
  if valid_593209 != nil:
    section.add "Action", valid_593209
  var valid_593210 = query.getOrDefault("Version")
  valid_593210 = validateParameter(valid_593210, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_593210 != nil:
    section.add "Version", valid_593210
  var valid_593211 = query.getOrDefault("SignatureVersion")
  valid_593211 = validateParameter(valid_593211, JString, required = true,
                                 default = nil)
  if valid_593211 != nil:
    section.add "SignatureVersion", valid_593211
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593212: Call_GetPutAttributes_593196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  let valid = call_593212.validator(path, query, header, formData, body)
  let scheme = call_593212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593212.url(scheme.get, call_593212.host, call_593212.base,
                         call_593212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593212, url, valid)

proc call*(call_593213: Call_GetPutAttributes_593196; Signature: string;
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
  var query_593214 = newJObject()
  add(query_593214, "Signature", newJString(Signature))
  add(query_593214, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_593214, "Expected.Value", newJString(ExpectedValue))
  add(query_593214, "SignatureMethod", newJString(SignatureMethod))
  add(query_593214, "DomainName", newJString(DomainName))
  add(query_593214, "Expected.Name", newJString(ExpectedName))
  add(query_593214, "ItemName", newJString(ItemName))
  add(query_593214, "Expected.Exists", newJString(ExpectedExists))
  if Attributes != nil:
    query_593214.add "Attributes", Attributes
  add(query_593214, "Timestamp", newJString(Timestamp))
  add(query_593214, "Action", newJString(Action))
  add(query_593214, "Version", newJString(Version))
  add(query_593214, "SignatureVersion", newJString(SignatureVersion))
  result = call_593213.call(nil, query_593214, nil, nil, nil)

var getPutAttributes* = Call_GetPutAttributes_593196(name: "getPutAttributes",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=PutAttributes", validator: validate_GetPutAttributes_593197,
    base: "/", url: url_GetPutAttributes_593198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSelect_593251 = ref object of OpenApiRestCall_592348
proc url_PostSelect_593253(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSelect_593252(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593254 = query.getOrDefault("Signature")
  valid_593254 = validateParameter(valid_593254, JString, required = true,
                                 default = nil)
  if valid_593254 != nil:
    section.add "Signature", valid_593254
  var valid_593255 = query.getOrDefault("AWSAccessKeyId")
  valid_593255 = validateParameter(valid_593255, JString, required = true,
                                 default = nil)
  if valid_593255 != nil:
    section.add "AWSAccessKeyId", valid_593255
  var valid_593256 = query.getOrDefault("SignatureMethod")
  valid_593256 = validateParameter(valid_593256, JString, required = true,
                                 default = nil)
  if valid_593256 != nil:
    section.add "SignatureMethod", valid_593256
  var valid_593257 = query.getOrDefault("Timestamp")
  valid_593257 = validateParameter(valid_593257, JString, required = true,
                                 default = nil)
  if valid_593257 != nil:
    section.add "Timestamp", valid_593257
  var valid_593258 = query.getOrDefault("Action")
  valid_593258 = validateParameter(valid_593258, JString, required = true,
                                 default = newJString("Select"))
  if valid_593258 != nil:
    section.add "Action", valid_593258
  var valid_593259 = query.getOrDefault("Version")
  valid_593259 = validateParameter(valid_593259, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_593259 != nil:
    section.add "Version", valid_593259
  var valid_593260 = query.getOrDefault("SignatureVersion")
  valid_593260 = validateParameter(valid_593260, JString, required = true,
                                 default = nil)
  if valid_593260 != nil:
    section.add "SignatureVersion", valid_593260
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
  var valid_593261 = formData.getOrDefault("NextToken")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "NextToken", valid_593261
  assert formData != nil, "formData argument is necessary due to required `SelectExpression` field"
  var valid_593262 = formData.getOrDefault("SelectExpression")
  valid_593262 = validateParameter(valid_593262, JString, required = true,
                                 default = nil)
  if valid_593262 != nil:
    section.add "SelectExpression", valid_593262
  var valid_593263 = formData.getOrDefault("ConsistentRead")
  valid_593263 = validateParameter(valid_593263, JBool, required = false, default = nil)
  if valid_593263 != nil:
    section.add "ConsistentRead", valid_593263
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593264: Call_PostSelect_593251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  let valid = call_593264.validator(path, query, header, formData, body)
  let scheme = call_593264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593264.url(scheme.get, call_593264.host, call_593264.base,
                         call_593264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593264, url, valid)

proc call*(call_593265: Call_PostSelect_593251; Signature: string;
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
  var query_593266 = newJObject()
  var formData_593267 = newJObject()
  add(query_593266, "Signature", newJString(Signature))
  add(query_593266, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_593267, "NextToken", newJString(NextToken))
  add(query_593266, "SignatureMethod", newJString(SignatureMethod))
  add(formData_593267, "SelectExpression", newJString(SelectExpression))
  add(formData_593267, "ConsistentRead", newJBool(ConsistentRead))
  add(query_593266, "Timestamp", newJString(Timestamp))
  add(query_593266, "Action", newJString(Action))
  add(query_593266, "Version", newJString(Version))
  add(query_593266, "SignatureVersion", newJString(SignatureVersion))
  result = call_593265.call(nil, query_593266, nil, formData_593267, nil)

var postSelect* = Call_PostSelect_593251(name: "postSelect",
                                      meth: HttpMethod.HttpPost,
                                      host: "sdb.amazonaws.com",
                                      route: "/#Action=Select",
                                      validator: validate_PostSelect_593252,
                                      base: "/", url: url_PostSelect_593253,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSelect_593235 = ref object of OpenApiRestCall_592348
proc url_GetSelect_593237(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSelect_593236(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593238 = query.getOrDefault("Signature")
  valid_593238 = validateParameter(valid_593238, JString, required = true,
                                 default = nil)
  if valid_593238 != nil:
    section.add "Signature", valid_593238
  var valid_593239 = query.getOrDefault("AWSAccessKeyId")
  valid_593239 = validateParameter(valid_593239, JString, required = true,
                                 default = nil)
  if valid_593239 != nil:
    section.add "AWSAccessKeyId", valid_593239
  var valid_593240 = query.getOrDefault("SignatureMethod")
  valid_593240 = validateParameter(valid_593240, JString, required = true,
                                 default = nil)
  if valid_593240 != nil:
    section.add "SignatureMethod", valid_593240
  var valid_593241 = query.getOrDefault("NextToken")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "NextToken", valid_593241
  var valid_593242 = query.getOrDefault("SelectExpression")
  valid_593242 = validateParameter(valid_593242, JString, required = true,
                                 default = nil)
  if valid_593242 != nil:
    section.add "SelectExpression", valid_593242
  var valid_593243 = query.getOrDefault("Timestamp")
  valid_593243 = validateParameter(valid_593243, JString, required = true,
                                 default = nil)
  if valid_593243 != nil:
    section.add "Timestamp", valid_593243
  var valid_593244 = query.getOrDefault("Action")
  valid_593244 = validateParameter(valid_593244, JString, required = true,
                                 default = newJString("Select"))
  if valid_593244 != nil:
    section.add "Action", valid_593244
  var valid_593245 = query.getOrDefault("ConsistentRead")
  valid_593245 = validateParameter(valid_593245, JBool, required = false, default = nil)
  if valid_593245 != nil:
    section.add "ConsistentRead", valid_593245
  var valid_593246 = query.getOrDefault("Version")
  valid_593246 = validateParameter(valid_593246, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_593246 != nil:
    section.add "Version", valid_593246
  var valid_593247 = query.getOrDefault("SignatureVersion")
  valid_593247 = validateParameter(valid_593247, JString, required = true,
                                 default = nil)
  if valid_593247 != nil:
    section.add "SignatureVersion", valid_593247
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593248: Call_GetSelect_593235; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  let valid = call_593248.validator(path, query, header, formData, body)
  let scheme = call_593248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593248.url(scheme.get, call_593248.host, call_593248.base,
                         call_593248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593248, url, valid)

proc call*(call_593249: Call_GetSelect_593235; Signature: string;
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
  var query_593250 = newJObject()
  add(query_593250, "Signature", newJString(Signature))
  add(query_593250, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_593250, "SignatureMethod", newJString(SignatureMethod))
  add(query_593250, "NextToken", newJString(NextToken))
  add(query_593250, "SelectExpression", newJString(SelectExpression))
  add(query_593250, "Timestamp", newJString(Timestamp))
  add(query_593250, "Action", newJString(Action))
  add(query_593250, "ConsistentRead", newJBool(ConsistentRead))
  add(query_593250, "Version", newJString(Version))
  add(query_593250, "SignatureVersion", newJString(SignatureVersion))
  result = call_593249.call(nil, query_593250, nil, nil, nil)

var getSelect* = Call_GetSelect_593235(name: "getSelect", meth: HttpMethod.HttpGet,
                                    host: "sdb.amazonaws.com",
                                    route: "/#Action=Select",
                                    validator: validate_GetSelect_593236,
                                    base: "/", url: url_GetSelect_593237,
                                    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
