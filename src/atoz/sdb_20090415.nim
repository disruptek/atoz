
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

  OpenApiRestCall_601373 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601373](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601373): Option[Scheme] {.used.} =
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
  Call_PostBatchDeleteAttributes_601981 = ref object of OpenApiRestCall_601373
proc url_PostBatchDeleteAttributes_601983(protocol: Scheme; host: string;
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

proc validate_PostBatchDeleteAttributes_601982(path: JsonNode; query: JsonNode;
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
  var valid_601984 = query.getOrDefault("Signature")
  valid_601984 = validateParameter(valid_601984, JString, required = true,
                                 default = nil)
  if valid_601984 != nil:
    section.add "Signature", valid_601984
  var valid_601985 = query.getOrDefault("AWSAccessKeyId")
  valid_601985 = validateParameter(valid_601985, JString, required = true,
                                 default = nil)
  if valid_601985 != nil:
    section.add "AWSAccessKeyId", valid_601985
  var valid_601986 = query.getOrDefault("SignatureMethod")
  valid_601986 = validateParameter(valid_601986, JString, required = true,
                                 default = nil)
  if valid_601986 != nil:
    section.add "SignatureMethod", valid_601986
  var valid_601987 = query.getOrDefault("Timestamp")
  valid_601987 = validateParameter(valid_601987, JString, required = true,
                                 default = nil)
  if valid_601987 != nil:
    section.add "Timestamp", valid_601987
  var valid_601988 = query.getOrDefault("Action")
  valid_601988 = validateParameter(valid_601988, JString, required = true,
                                 default = newJString("BatchDeleteAttributes"))
  if valid_601988 != nil:
    section.add "Action", valid_601988
  var valid_601989 = query.getOrDefault("Version")
  valid_601989 = validateParameter(valid_601989, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601989 != nil:
    section.add "Version", valid_601989
  var valid_601990 = query.getOrDefault("SignatureVersion")
  valid_601990 = validateParameter(valid_601990, JString, required = true,
                                 default = nil)
  if valid_601990 != nil:
    section.add "SignatureVersion", valid_601990
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
  var valid_601991 = formData.getOrDefault("DomainName")
  valid_601991 = validateParameter(valid_601991, JString, required = true,
                                 default = nil)
  if valid_601991 != nil:
    section.add "DomainName", valid_601991
  var valid_601992 = formData.getOrDefault("Items")
  valid_601992 = validateParameter(valid_601992, JArray, required = true, default = nil)
  if valid_601992 != nil:
    section.add "Items", valid_601992
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601993: Call_PostBatchDeleteAttributes_601981; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  let valid = call_601993.validator(path, query, header, formData, body)
  let scheme = call_601993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601993.url(scheme.get, call_601993.host, call_601993.base,
                         call_601993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601993, url, valid)

proc call*(call_601994: Call_PostBatchDeleteAttributes_601981; Signature: string;
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
  var query_601995 = newJObject()
  var formData_601996 = newJObject()
  add(query_601995, "Signature", newJString(Signature))
  add(query_601995, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601995, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601996, "DomainName", newJString(DomainName))
  add(query_601995, "Timestamp", newJString(Timestamp))
  add(query_601995, "Action", newJString(Action))
  if Items != nil:
    formData_601996.add "Items", Items
  add(query_601995, "Version", newJString(Version))
  add(query_601995, "SignatureVersion", newJString(SignatureVersion))
  result = call_601994.call(nil, query_601995, nil, formData_601996, nil)

var postBatchDeleteAttributes* = Call_PostBatchDeleteAttributes_601981(
    name: "postBatchDeleteAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=BatchDeleteAttributes",
    validator: validate_PostBatchDeleteAttributes_601982, base: "/",
    url: url_PostBatchDeleteAttributes_601983,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchDeleteAttributes_601711 = ref object of OpenApiRestCall_601373
proc url_GetBatchDeleteAttributes_601713(protocol: Scheme; host: string;
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

proc validate_GetBatchDeleteAttributes_601712(path: JsonNode; query: JsonNode;
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
  var valid_601825 = query.getOrDefault("Signature")
  valid_601825 = validateParameter(valid_601825, JString, required = true,
                                 default = nil)
  if valid_601825 != nil:
    section.add "Signature", valid_601825
  var valid_601826 = query.getOrDefault("AWSAccessKeyId")
  valid_601826 = validateParameter(valid_601826, JString, required = true,
                                 default = nil)
  if valid_601826 != nil:
    section.add "AWSAccessKeyId", valid_601826
  var valid_601827 = query.getOrDefault("SignatureMethod")
  valid_601827 = validateParameter(valid_601827, JString, required = true,
                                 default = nil)
  if valid_601827 != nil:
    section.add "SignatureMethod", valid_601827
  var valid_601828 = query.getOrDefault("DomainName")
  valid_601828 = validateParameter(valid_601828, JString, required = true,
                                 default = nil)
  if valid_601828 != nil:
    section.add "DomainName", valid_601828
  var valid_601829 = query.getOrDefault("Items")
  valid_601829 = validateParameter(valid_601829, JArray, required = true, default = nil)
  if valid_601829 != nil:
    section.add "Items", valid_601829
  var valid_601830 = query.getOrDefault("Timestamp")
  valid_601830 = validateParameter(valid_601830, JString, required = true,
                                 default = nil)
  if valid_601830 != nil:
    section.add "Timestamp", valid_601830
  var valid_601844 = query.getOrDefault("Action")
  valid_601844 = validateParameter(valid_601844, JString, required = true,
                                 default = newJString("BatchDeleteAttributes"))
  if valid_601844 != nil:
    section.add "Action", valid_601844
  var valid_601845 = query.getOrDefault("Version")
  valid_601845 = validateParameter(valid_601845, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_601845 != nil:
    section.add "Version", valid_601845
  var valid_601846 = query.getOrDefault("SignatureVersion")
  valid_601846 = validateParameter(valid_601846, JString, required = true,
                                 default = nil)
  if valid_601846 != nil:
    section.add "SignatureVersion", valid_601846
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601869: Call_GetBatchDeleteAttributes_601711; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  let valid = call_601869.validator(path, query, header, formData, body)
  let scheme = call_601869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601869.url(scheme.get, call_601869.host, call_601869.base,
                         call_601869.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601869, url, valid)

proc call*(call_601940: Call_GetBatchDeleteAttributes_601711; Signature: string;
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
  var query_601941 = newJObject()
  add(query_601941, "Signature", newJString(Signature))
  add(query_601941, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601941, "SignatureMethod", newJString(SignatureMethod))
  add(query_601941, "DomainName", newJString(DomainName))
  if Items != nil:
    query_601941.add "Items", Items
  add(query_601941, "Timestamp", newJString(Timestamp))
  add(query_601941, "Action", newJString(Action))
  add(query_601941, "Version", newJString(Version))
  add(query_601941, "SignatureVersion", newJString(SignatureVersion))
  result = call_601940.call(nil, query_601941, nil, nil, nil)

var getBatchDeleteAttributes* = Call_GetBatchDeleteAttributes_601711(
    name: "getBatchDeleteAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=BatchDeleteAttributes",
    validator: validate_GetBatchDeleteAttributes_601712, base: "/",
    url: url_GetBatchDeleteAttributes_601713, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostBatchPutAttributes_602012 = ref object of OpenApiRestCall_601373
proc url_PostBatchPutAttributes_602014(protocol: Scheme; host: string; base: string;
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

proc validate_PostBatchPutAttributes_602013(path: JsonNode; query: JsonNode;
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
  var valid_602015 = query.getOrDefault("Signature")
  valid_602015 = validateParameter(valid_602015, JString, required = true,
                                 default = nil)
  if valid_602015 != nil:
    section.add "Signature", valid_602015
  var valid_602016 = query.getOrDefault("AWSAccessKeyId")
  valid_602016 = validateParameter(valid_602016, JString, required = true,
                                 default = nil)
  if valid_602016 != nil:
    section.add "AWSAccessKeyId", valid_602016
  var valid_602017 = query.getOrDefault("SignatureMethod")
  valid_602017 = validateParameter(valid_602017, JString, required = true,
                                 default = nil)
  if valid_602017 != nil:
    section.add "SignatureMethod", valid_602017
  var valid_602018 = query.getOrDefault("Timestamp")
  valid_602018 = validateParameter(valid_602018, JString, required = true,
                                 default = nil)
  if valid_602018 != nil:
    section.add "Timestamp", valid_602018
  var valid_602019 = query.getOrDefault("Action")
  valid_602019 = validateParameter(valid_602019, JString, required = true,
                                 default = newJString("BatchPutAttributes"))
  if valid_602019 != nil:
    section.add "Action", valid_602019
  var valid_602020 = query.getOrDefault("Version")
  valid_602020 = validateParameter(valid_602020, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_602020 != nil:
    section.add "Version", valid_602020
  var valid_602021 = query.getOrDefault("SignatureVersion")
  valid_602021 = validateParameter(valid_602021, JString, required = true,
                                 default = nil)
  if valid_602021 != nil:
    section.add "SignatureVersion", valid_602021
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
  var valid_602022 = formData.getOrDefault("DomainName")
  valid_602022 = validateParameter(valid_602022, JString, required = true,
                                 default = nil)
  if valid_602022 != nil:
    section.add "DomainName", valid_602022
  var valid_602023 = formData.getOrDefault("Items")
  valid_602023 = validateParameter(valid_602023, JArray, required = true, default = nil)
  if valid_602023 != nil:
    section.add "Items", valid_602023
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602024: Call_PostBatchPutAttributes_602012; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  let valid = call_602024.validator(path, query, header, formData, body)
  let scheme = call_602024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602024.url(scheme.get, call_602024.host, call_602024.base,
                         call_602024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602024, url, valid)

proc call*(call_602025: Call_PostBatchPutAttributes_602012; Signature: string;
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
  var query_602026 = newJObject()
  var formData_602027 = newJObject()
  add(query_602026, "Signature", newJString(Signature))
  add(query_602026, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602026, "SignatureMethod", newJString(SignatureMethod))
  add(formData_602027, "DomainName", newJString(DomainName))
  add(query_602026, "Timestamp", newJString(Timestamp))
  add(query_602026, "Action", newJString(Action))
  if Items != nil:
    formData_602027.add "Items", Items
  add(query_602026, "Version", newJString(Version))
  add(query_602026, "SignatureVersion", newJString(SignatureVersion))
  result = call_602025.call(nil, query_602026, nil, formData_602027, nil)

var postBatchPutAttributes* = Call_PostBatchPutAttributes_602012(
    name: "postBatchPutAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=BatchPutAttributes",
    validator: validate_PostBatchPutAttributes_602013, base: "/",
    url: url_PostBatchPutAttributes_602014, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchPutAttributes_601997 = ref object of OpenApiRestCall_601373
proc url_GetBatchPutAttributes_601999(protocol: Scheme; host: string; base: string;
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

proc validate_GetBatchPutAttributes_601998(path: JsonNode; query: JsonNode;
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
  var valid_602000 = query.getOrDefault("Signature")
  valid_602000 = validateParameter(valid_602000, JString, required = true,
                                 default = nil)
  if valid_602000 != nil:
    section.add "Signature", valid_602000
  var valid_602001 = query.getOrDefault("AWSAccessKeyId")
  valid_602001 = validateParameter(valid_602001, JString, required = true,
                                 default = nil)
  if valid_602001 != nil:
    section.add "AWSAccessKeyId", valid_602001
  var valid_602002 = query.getOrDefault("SignatureMethod")
  valid_602002 = validateParameter(valid_602002, JString, required = true,
                                 default = nil)
  if valid_602002 != nil:
    section.add "SignatureMethod", valid_602002
  var valid_602003 = query.getOrDefault("DomainName")
  valid_602003 = validateParameter(valid_602003, JString, required = true,
                                 default = nil)
  if valid_602003 != nil:
    section.add "DomainName", valid_602003
  var valid_602004 = query.getOrDefault("Items")
  valid_602004 = validateParameter(valid_602004, JArray, required = true, default = nil)
  if valid_602004 != nil:
    section.add "Items", valid_602004
  var valid_602005 = query.getOrDefault("Timestamp")
  valid_602005 = validateParameter(valid_602005, JString, required = true,
                                 default = nil)
  if valid_602005 != nil:
    section.add "Timestamp", valid_602005
  var valid_602006 = query.getOrDefault("Action")
  valid_602006 = validateParameter(valid_602006, JString, required = true,
                                 default = newJString("BatchPutAttributes"))
  if valid_602006 != nil:
    section.add "Action", valid_602006
  var valid_602007 = query.getOrDefault("Version")
  valid_602007 = validateParameter(valid_602007, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_602007 != nil:
    section.add "Version", valid_602007
  var valid_602008 = query.getOrDefault("SignatureVersion")
  valid_602008 = validateParameter(valid_602008, JString, required = true,
                                 default = nil)
  if valid_602008 != nil:
    section.add "SignatureVersion", valid_602008
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602009: Call_GetBatchPutAttributes_601997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  let valid = call_602009.validator(path, query, header, formData, body)
  let scheme = call_602009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602009.url(scheme.get, call_602009.host, call_602009.base,
                         call_602009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602009, url, valid)

proc call*(call_602010: Call_GetBatchPutAttributes_601997; Signature: string;
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
  var query_602011 = newJObject()
  add(query_602011, "Signature", newJString(Signature))
  add(query_602011, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602011, "SignatureMethod", newJString(SignatureMethod))
  add(query_602011, "DomainName", newJString(DomainName))
  if Items != nil:
    query_602011.add "Items", Items
  add(query_602011, "Timestamp", newJString(Timestamp))
  add(query_602011, "Action", newJString(Action))
  add(query_602011, "Version", newJString(Version))
  add(query_602011, "SignatureVersion", newJString(SignatureVersion))
  result = call_602010.call(nil, query_602011, nil, nil, nil)

var getBatchPutAttributes* = Call_GetBatchPutAttributes_601997(
    name: "getBatchPutAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=BatchPutAttributes",
    validator: validate_GetBatchPutAttributes_601998, base: "/",
    url: url_GetBatchPutAttributes_601999, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDomain_602042 = ref object of OpenApiRestCall_601373
proc url_PostCreateDomain_602044(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDomain_602043(path: JsonNode; query: JsonNode;
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
  var valid_602045 = query.getOrDefault("Signature")
  valid_602045 = validateParameter(valid_602045, JString, required = true,
                                 default = nil)
  if valid_602045 != nil:
    section.add "Signature", valid_602045
  var valid_602046 = query.getOrDefault("AWSAccessKeyId")
  valid_602046 = validateParameter(valid_602046, JString, required = true,
                                 default = nil)
  if valid_602046 != nil:
    section.add "AWSAccessKeyId", valid_602046
  var valid_602047 = query.getOrDefault("SignatureMethod")
  valid_602047 = validateParameter(valid_602047, JString, required = true,
                                 default = nil)
  if valid_602047 != nil:
    section.add "SignatureMethod", valid_602047
  var valid_602048 = query.getOrDefault("Timestamp")
  valid_602048 = validateParameter(valid_602048, JString, required = true,
                                 default = nil)
  if valid_602048 != nil:
    section.add "Timestamp", valid_602048
  var valid_602049 = query.getOrDefault("Action")
  valid_602049 = validateParameter(valid_602049, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_602049 != nil:
    section.add "Action", valid_602049
  var valid_602050 = query.getOrDefault("Version")
  valid_602050 = validateParameter(valid_602050, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_602050 != nil:
    section.add "Version", valid_602050
  var valid_602051 = query.getOrDefault("SignatureVersion")
  valid_602051 = validateParameter(valid_602051, JString, required = true,
                                 default = nil)
  if valid_602051 != nil:
    section.add "SignatureVersion", valid_602051
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain to create. The name can range between 3 and 255 characters and can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602052 = formData.getOrDefault("DomainName")
  valid_602052 = validateParameter(valid_602052, JString, required = true,
                                 default = nil)
  if valid_602052 != nil:
    section.add "DomainName", valid_602052
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602053: Call_PostCreateDomain_602042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  let valid = call_602053.validator(path, query, header, formData, body)
  let scheme = call_602053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602053.url(scheme.get, call_602053.host, call_602053.base,
                         call_602053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602053, url, valid)

proc call*(call_602054: Call_PostCreateDomain_602042; Signature: string;
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
  var query_602055 = newJObject()
  var formData_602056 = newJObject()
  add(query_602055, "Signature", newJString(Signature))
  add(query_602055, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602055, "SignatureMethod", newJString(SignatureMethod))
  add(formData_602056, "DomainName", newJString(DomainName))
  add(query_602055, "Timestamp", newJString(Timestamp))
  add(query_602055, "Action", newJString(Action))
  add(query_602055, "Version", newJString(Version))
  add(query_602055, "SignatureVersion", newJString(SignatureVersion))
  result = call_602054.call(nil, query_602055, nil, formData_602056, nil)

var postCreateDomain* = Call_PostCreateDomain_602042(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_602043,
    base: "/", url: url_PostCreateDomain_602044,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_602028 = ref object of OpenApiRestCall_601373
proc url_GetCreateDomain_602030(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDomain_602029(path: JsonNode; query: JsonNode;
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
  var valid_602031 = query.getOrDefault("Signature")
  valid_602031 = validateParameter(valid_602031, JString, required = true,
                                 default = nil)
  if valid_602031 != nil:
    section.add "Signature", valid_602031
  var valid_602032 = query.getOrDefault("AWSAccessKeyId")
  valid_602032 = validateParameter(valid_602032, JString, required = true,
                                 default = nil)
  if valid_602032 != nil:
    section.add "AWSAccessKeyId", valid_602032
  var valid_602033 = query.getOrDefault("SignatureMethod")
  valid_602033 = validateParameter(valid_602033, JString, required = true,
                                 default = nil)
  if valid_602033 != nil:
    section.add "SignatureMethod", valid_602033
  var valid_602034 = query.getOrDefault("DomainName")
  valid_602034 = validateParameter(valid_602034, JString, required = true,
                                 default = nil)
  if valid_602034 != nil:
    section.add "DomainName", valid_602034
  var valid_602035 = query.getOrDefault("Timestamp")
  valid_602035 = validateParameter(valid_602035, JString, required = true,
                                 default = nil)
  if valid_602035 != nil:
    section.add "Timestamp", valid_602035
  var valid_602036 = query.getOrDefault("Action")
  valid_602036 = validateParameter(valid_602036, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_602036 != nil:
    section.add "Action", valid_602036
  var valid_602037 = query.getOrDefault("Version")
  valid_602037 = validateParameter(valid_602037, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_602037 != nil:
    section.add "Version", valid_602037
  var valid_602038 = query.getOrDefault("SignatureVersion")
  valid_602038 = validateParameter(valid_602038, JString, required = true,
                                 default = nil)
  if valid_602038 != nil:
    section.add "SignatureVersion", valid_602038
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602039: Call_GetCreateDomain_602028; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  let valid = call_602039.validator(path, query, header, formData, body)
  let scheme = call_602039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602039.url(scheme.get, call_602039.host, call_602039.base,
                         call_602039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602039, url, valid)

proc call*(call_602040: Call_GetCreateDomain_602028; Signature: string;
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
  var query_602041 = newJObject()
  add(query_602041, "Signature", newJString(Signature))
  add(query_602041, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602041, "SignatureMethod", newJString(SignatureMethod))
  add(query_602041, "DomainName", newJString(DomainName))
  add(query_602041, "Timestamp", newJString(Timestamp))
  add(query_602041, "Action", newJString(Action))
  add(query_602041, "Version", newJString(Version))
  add(query_602041, "SignatureVersion", newJString(SignatureVersion))
  result = call_602040.call(nil, query_602041, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_602028(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_602029,
    base: "/", url: url_GetCreateDomain_602030, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAttributes_602076 = ref object of OpenApiRestCall_601373
proc url_PostDeleteAttributes_602078(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteAttributes_602077(path: JsonNode; query: JsonNode;
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
  var valid_602079 = query.getOrDefault("Signature")
  valid_602079 = validateParameter(valid_602079, JString, required = true,
                                 default = nil)
  if valid_602079 != nil:
    section.add "Signature", valid_602079
  var valid_602080 = query.getOrDefault("AWSAccessKeyId")
  valid_602080 = validateParameter(valid_602080, JString, required = true,
                                 default = nil)
  if valid_602080 != nil:
    section.add "AWSAccessKeyId", valid_602080
  var valid_602081 = query.getOrDefault("SignatureMethod")
  valid_602081 = validateParameter(valid_602081, JString, required = true,
                                 default = nil)
  if valid_602081 != nil:
    section.add "SignatureMethod", valid_602081
  var valid_602082 = query.getOrDefault("Timestamp")
  valid_602082 = validateParameter(valid_602082, JString, required = true,
                                 default = nil)
  if valid_602082 != nil:
    section.add "Timestamp", valid_602082
  var valid_602083 = query.getOrDefault("Action")
  valid_602083 = validateParameter(valid_602083, JString, required = true,
                                 default = newJString("DeleteAttributes"))
  if valid_602083 != nil:
    section.add "Action", valid_602083
  var valid_602084 = query.getOrDefault("Version")
  valid_602084 = validateParameter(valid_602084, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_602084 != nil:
    section.add "Version", valid_602084
  var valid_602085 = query.getOrDefault("SignatureVersion")
  valid_602085 = validateParameter(valid_602085, JString, required = true,
                                 default = nil)
  if valid_602085 != nil:
    section.add "SignatureVersion", valid_602085
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
  var valid_602086 = formData.getOrDefault("Expected.Value")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "Expected.Value", valid_602086
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602087 = formData.getOrDefault("DomainName")
  valid_602087 = validateParameter(valid_602087, JString, required = true,
                                 default = nil)
  if valid_602087 != nil:
    section.add "DomainName", valid_602087
  var valid_602088 = formData.getOrDefault("Attributes")
  valid_602088 = validateParameter(valid_602088, JArray, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "Attributes", valid_602088
  var valid_602089 = formData.getOrDefault("Expected.Name")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "Expected.Name", valid_602089
  var valid_602090 = formData.getOrDefault("Expected.Exists")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "Expected.Exists", valid_602090
  var valid_602091 = formData.getOrDefault("ItemName")
  valid_602091 = validateParameter(valid_602091, JString, required = true,
                                 default = nil)
  if valid_602091 != nil:
    section.add "ItemName", valid_602091
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602092: Call_PostDeleteAttributes_602076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  let valid = call_602092.validator(path, query, header, formData, body)
  let scheme = call_602092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602092.url(scheme.get, call_602092.host, call_602092.base,
                         call_602092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602092, url, valid)

proc call*(call_602093: Call_PostDeleteAttributes_602076; Signature: string;
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
  var query_602094 = newJObject()
  var formData_602095 = newJObject()
  add(formData_602095, "Expected.Value", newJString(ExpectedValue))
  add(query_602094, "Signature", newJString(Signature))
  add(query_602094, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602094, "SignatureMethod", newJString(SignatureMethod))
  add(formData_602095, "DomainName", newJString(DomainName))
  if Attributes != nil:
    formData_602095.add "Attributes", Attributes
  add(query_602094, "Timestamp", newJString(Timestamp))
  add(query_602094, "Action", newJString(Action))
  add(formData_602095, "Expected.Name", newJString(ExpectedName))
  add(query_602094, "Version", newJString(Version))
  add(formData_602095, "Expected.Exists", newJString(ExpectedExists))
  add(query_602094, "SignatureVersion", newJString(SignatureVersion))
  add(formData_602095, "ItemName", newJString(ItemName))
  result = call_602093.call(nil, query_602094, nil, formData_602095, nil)

var postDeleteAttributes* = Call_PostDeleteAttributes_602076(
    name: "postDeleteAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=DeleteAttributes",
    validator: validate_PostDeleteAttributes_602077, base: "/",
    url: url_PostDeleteAttributes_602078, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAttributes_602057 = ref object of OpenApiRestCall_601373
proc url_GetDeleteAttributes_602059(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteAttributes_602058(path: JsonNode; query: JsonNode;
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
  var valid_602060 = query.getOrDefault("Signature")
  valid_602060 = validateParameter(valid_602060, JString, required = true,
                                 default = nil)
  if valid_602060 != nil:
    section.add "Signature", valid_602060
  var valid_602061 = query.getOrDefault("AWSAccessKeyId")
  valid_602061 = validateParameter(valid_602061, JString, required = true,
                                 default = nil)
  if valid_602061 != nil:
    section.add "AWSAccessKeyId", valid_602061
  var valid_602062 = query.getOrDefault("Expected.Value")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "Expected.Value", valid_602062
  var valid_602063 = query.getOrDefault("SignatureMethod")
  valid_602063 = validateParameter(valid_602063, JString, required = true,
                                 default = nil)
  if valid_602063 != nil:
    section.add "SignatureMethod", valid_602063
  var valid_602064 = query.getOrDefault("DomainName")
  valid_602064 = validateParameter(valid_602064, JString, required = true,
                                 default = nil)
  if valid_602064 != nil:
    section.add "DomainName", valid_602064
  var valid_602065 = query.getOrDefault("Expected.Name")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "Expected.Name", valid_602065
  var valid_602066 = query.getOrDefault("ItemName")
  valid_602066 = validateParameter(valid_602066, JString, required = true,
                                 default = nil)
  if valid_602066 != nil:
    section.add "ItemName", valid_602066
  var valid_602067 = query.getOrDefault("Expected.Exists")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "Expected.Exists", valid_602067
  var valid_602068 = query.getOrDefault("Attributes")
  valid_602068 = validateParameter(valid_602068, JArray, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "Attributes", valid_602068
  var valid_602069 = query.getOrDefault("Timestamp")
  valid_602069 = validateParameter(valid_602069, JString, required = true,
                                 default = nil)
  if valid_602069 != nil:
    section.add "Timestamp", valid_602069
  var valid_602070 = query.getOrDefault("Action")
  valid_602070 = validateParameter(valid_602070, JString, required = true,
                                 default = newJString("DeleteAttributes"))
  if valid_602070 != nil:
    section.add "Action", valid_602070
  var valid_602071 = query.getOrDefault("Version")
  valid_602071 = validateParameter(valid_602071, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_602071 != nil:
    section.add "Version", valid_602071
  var valid_602072 = query.getOrDefault("SignatureVersion")
  valid_602072 = validateParameter(valid_602072, JString, required = true,
                                 default = nil)
  if valid_602072 != nil:
    section.add "SignatureVersion", valid_602072
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602073: Call_GetDeleteAttributes_602057; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  let valid = call_602073.validator(path, query, header, formData, body)
  let scheme = call_602073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602073.url(scheme.get, call_602073.host, call_602073.base,
                         call_602073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602073, url, valid)

proc call*(call_602074: Call_GetDeleteAttributes_602057; Signature: string;
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
  var query_602075 = newJObject()
  add(query_602075, "Signature", newJString(Signature))
  add(query_602075, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602075, "Expected.Value", newJString(ExpectedValue))
  add(query_602075, "SignatureMethod", newJString(SignatureMethod))
  add(query_602075, "DomainName", newJString(DomainName))
  add(query_602075, "Expected.Name", newJString(ExpectedName))
  add(query_602075, "ItemName", newJString(ItemName))
  add(query_602075, "Expected.Exists", newJString(ExpectedExists))
  if Attributes != nil:
    query_602075.add "Attributes", Attributes
  add(query_602075, "Timestamp", newJString(Timestamp))
  add(query_602075, "Action", newJString(Action))
  add(query_602075, "Version", newJString(Version))
  add(query_602075, "SignatureVersion", newJString(SignatureVersion))
  result = call_602074.call(nil, query_602075, nil, nil, nil)

var getDeleteAttributes* = Call_GetDeleteAttributes_602057(
    name: "getDeleteAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=DeleteAttributes",
    validator: validate_GetDeleteAttributes_602058, base: "/",
    url: url_GetDeleteAttributes_602059, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_602110 = ref object of OpenApiRestCall_601373
proc url_PostDeleteDomain_602112(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDomain_602111(path: JsonNode; query: JsonNode;
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
  var valid_602113 = query.getOrDefault("Signature")
  valid_602113 = validateParameter(valid_602113, JString, required = true,
                                 default = nil)
  if valid_602113 != nil:
    section.add "Signature", valid_602113
  var valid_602114 = query.getOrDefault("AWSAccessKeyId")
  valid_602114 = validateParameter(valid_602114, JString, required = true,
                                 default = nil)
  if valid_602114 != nil:
    section.add "AWSAccessKeyId", valid_602114
  var valid_602115 = query.getOrDefault("SignatureMethod")
  valid_602115 = validateParameter(valid_602115, JString, required = true,
                                 default = nil)
  if valid_602115 != nil:
    section.add "SignatureMethod", valid_602115
  var valid_602116 = query.getOrDefault("Timestamp")
  valid_602116 = validateParameter(valid_602116, JString, required = true,
                                 default = nil)
  if valid_602116 != nil:
    section.add "Timestamp", valid_602116
  var valid_602117 = query.getOrDefault("Action")
  valid_602117 = validateParameter(valid_602117, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_602117 != nil:
    section.add "Action", valid_602117
  var valid_602118 = query.getOrDefault("Version")
  valid_602118 = validateParameter(valid_602118, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_602118 != nil:
    section.add "Version", valid_602118
  var valid_602119 = query.getOrDefault("SignatureVersion")
  valid_602119 = validateParameter(valid_602119, JString, required = true,
                                 default = nil)
  if valid_602119 != nil:
    section.add "SignatureVersion", valid_602119
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602120 = formData.getOrDefault("DomainName")
  valid_602120 = validateParameter(valid_602120, JString, required = true,
                                 default = nil)
  if valid_602120 != nil:
    section.add "DomainName", valid_602120
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602121: Call_PostDeleteDomain_602110; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  let valid = call_602121.validator(path, query, header, formData, body)
  let scheme = call_602121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602121.url(scheme.get, call_602121.host, call_602121.base,
                         call_602121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602121, url, valid)

proc call*(call_602122: Call_PostDeleteDomain_602110; Signature: string;
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
  var query_602123 = newJObject()
  var formData_602124 = newJObject()
  add(query_602123, "Signature", newJString(Signature))
  add(query_602123, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602123, "SignatureMethod", newJString(SignatureMethod))
  add(formData_602124, "DomainName", newJString(DomainName))
  add(query_602123, "Timestamp", newJString(Timestamp))
  add(query_602123, "Action", newJString(Action))
  add(query_602123, "Version", newJString(Version))
  add(query_602123, "SignatureVersion", newJString(SignatureVersion))
  result = call_602122.call(nil, query_602123, nil, formData_602124, nil)

var postDeleteDomain* = Call_PostDeleteDomain_602110(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_602111,
    base: "/", url: url_PostDeleteDomain_602112,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_602096 = ref object of OpenApiRestCall_601373
proc url_GetDeleteDomain_602098(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDomain_602097(path: JsonNode; query: JsonNode;
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
  var valid_602099 = query.getOrDefault("Signature")
  valid_602099 = validateParameter(valid_602099, JString, required = true,
                                 default = nil)
  if valid_602099 != nil:
    section.add "Signature", valid_602099
  var valid_602100 = query.getOrDefault("AWSAccessKeyId")
  valid_602100 = validateParameter(valid_602100, JString, required = true,
                                 default = nil)
  if valid_602100 != nil:
    section.add "AWSAccessKeyId", valid_602100
  var valid_602101 = query.getOrDefault("SignatureMethod")
  valid_602101 = validateParameter(valid_602101, JString, required = true,
                                 default = nil)
  if valid_602101 != nil:
    section.add "SignatureMethod", valid_602101
  var valid_602102 = query.getOrDefault("DomainName")
  valid_602102 = validateParameter(valid_602102, JString, required = true,
                                 default = nil)
  if valid_602102 != nil:
    section.add "DomainName", valid_602102
  var valid_602103 = query.getOrDefault("Timestamp")
  valid_602103 = validateParameter(valid_602103, JString, required = true,
                                 default = nil)
  if valid_602103 != nil:
    section.add "Timestamp", valid_602103
  var valid_602104 = query.getOrDefault("Action")
  valid_602104 = validateParameter(valid_602104, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_602104 != nil:
    section.add "Action", valid_602104
  var valid_602105 = query.getOrDefault("Version")
  valid_602105 = validateParameter(valid_602105, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_602105 != nil:
    section.add "Version", valid_602105
  var valid_602106 = query.getOrDefault("SignatureVersion")
  valid_602106 = validateParameter(valid_602106, JString, required = true,
                                 default = nil)
  if valid_602106 != nil:
    section.add "SignatureVersion", valid_602106
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602107: Call_GetDeleteDomain_602096; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  let valid = call_602107.validator(path, query, header, formData, body)
  let scheme = call_602107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602107.url(scheme.get, call_602107.host, call_602107.base,
                         call_602107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602107, url, valid)

proc call*(call_602108: Call_GetDeleteDomain_602096; Signature: string;
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
  var query_602109 = newJObject()
  add(query_602109, "Signature", newJString(Signature))
  add(query_602109, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602109, "SignatureMethod", newJString(SignatureMethod))
  add(query_602109, "DomainName", newJString(DomainName))
  add(query_602109, "Timestamp", newJString(Timestamp))
  add(query_602109, "Action", newJString(Action))
  add(query_602109, "Version", newJString(Version))
  add(query_602109, "SignatureVersion", newJString(SignatureVersion))
  result = call_602108.call(nil, query_602109, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_602096(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_602097,
    base: "/", url: url_GetDeleteDomain_602098, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDomainMetadata_602139 = ref object of OpenApiRestCall_601373
proc url_PostDomainMetadata_602141(protocol: Scheme; host: string; base: string;
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

proc validate_PostDomainMetadata_602140(path: JsonNode; query: JsonNode;
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
  var valid_602142 = query.getOrDefault("Signature")
  valid_602142 = validateParameter(valid_602142, JString, required = true,
                                 default = nil)
  if valid_602142 != nil:
    section.add "Signature", valid_602142
  var valid_602143 = query.getOrDefault("AWSAccessKeyId")
  valid_602143 = validateParameter(valid_602143, JString, required = true,
                                 default = nil)
  if valid_602143 != nil:
    section.add "AWSAccessKeyId", valid_602143
  var valid_602144 = query.getOrDefault("SignatureMethod")
  valid_602144 = validateParameter(valid_602144, JString, required = true,
                                 default = nil)
  if valid_602144 != nil:
    section.add "SignatureMethod", valid_602144
  var valid_602145 = query.getOrDefault("Timestamp")
  valid_602145 = validateParameter(valid_602145, JString, required = true,
                                 default = nil)
  if valid_602145 != nil:
    section.add "Timestamp", valid_602145
  var valid_602146 = query.getOrDefault("Action")
  valid_602146 = validateParameter(valid_602146, JString, required = true,
                                 default = newJString("DomainMetadata"))
  if valid_602146 != nil:
    section.add "Action", valid_602146
  var valid_602147 = query.getOrDefault("Version")
  valid_602147 = validateParameter(valid_602147, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_602147 != nil:
    section.add "Version", valid_602147
  var valid_602148 = query.getOrDefault("SignatureVersion")
  valid_602148 = validateParameter(valid_602148, JString, required = true,
                                 default = nil)
  if valid_602148 != nil:
    section.add "SignatureVersion", valid_602148
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain for which to display the metadata of.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602149 = formData.getOrDefault("DomainName")
  valid_602149 = validateParameter(valid_602149, JString, required = true,
                                 default = nil)
  if valid_602149 != nil:
    section.add "DomainName", valid_602149
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602150: Call_PostDomainMetadata_602139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  let valid = call_602150.validator(path, query, header, formData, body)
  let scheme = call_602150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602150.url(scheme.get, call_602150.host, call_602150.base,
                         call_602150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602150, url, valid)

proc call*(call_602151: Call_PostDomainMetadata_602139; Signature: string;
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
  var query_602152 = newJObject()
  var formData_602153 = newJObject()
  add(query_602152, "Signature", newJString(Signature))
  add(query_602152, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602152, "SignatureMethod", newJString(SignatureMethod))
  add(formData_602153, "DomainName", newJString(DomainName))
  add(query_602152, "Timestamp", newJString(Timestamp))
  add(query_602152, "Action", newJString(Action))
  add(query_602152, "Version", newJString(Version))
  add(query_602152, "SignatureVersion", newJString(SignatureVersion))
  result = call_602151.call(nil, query_602152, nil, formData_602153, nil)

var postDomainMetadata* = Call_PostDomainMetadata_602139(
    name: "postDomainMetadata", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=DomainMetadata",
    validator: validate_PostDomainMetadata_602140, base: "/",
    url: url_PostDomainMetadata_602141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainMetadata_602125 = ref object of OpenApiRestCall_601373
proc url_GetDomainMetadata_602127(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainMetadata_602126(path: JsonNode; query: JsonNode;
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
  var valid_602128 = query.getOrDefault("Signature")
  valid_602128 = validateParameter(valid_602128, JString, required = true,
                                 default = nil)
  if valid_602128 != nil:
    section.add "Signature", valid_602128
  var valid_602129 = query.getOrDefault("AWSAccessKeyId")
  valid_602129 = validateParameter(valid_602129, JString, required = true,
                                 default = nil)
  if valid_602129 != nil:
    section.add "AWSAccessKeyId", valid_602129
  var valid_602130 = query.getOrDefault("SignatureMethod")
  valid_602130 = validateParameter(valid_602130, JString, required = true,
                                 default = nil)
  if valid_602130 != nil:
    section.add "SignatureMethod", valid_602130
  var valid_602131 = query.getOrDefault("DomainName")
  valid_602131 = validateParameter(valid_602131, JString, required = true,
                                 default = nil)
  if valid_602131 != nil:
    section.add "DomainName", valid_602131
  var valid_602132 = query.getOrDefault("Timestamp")
  valid_602132 = validateParameter(valid_602132, JString, required = true,
                                 default = nil)
  if valid_602132 != nil:
    section.add "Timestamp", valid_602132
  var valid_602133 = query.getOrDefault("Action")
  valid_602133 = validateParameter(valid_602133, JString, required = true,
                                 default = newJString("DomainMetadata"))
  if valid_602133 != nil:
    section.add "Action", valid_602133
  var valid_602134 = query.getOrDefault("Version")
  valid_602134 = validateParameter(valid_602134, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_602134 != nil:
    section.add "Version", valid_602134
  var valid_602135 = query.getOrDefault("SignatureVersion")
  valid_602135 = validateParameter(valid_602135, JString, required = true,
                                 default = nil)
  if valid_602135 != nil:
    section.add "SignatureVersion", valid_602135
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602136: Call_GetDomainMetadata_602125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  let valid = call_602136.validator(path, query, header, formData, body)
  let scheme = call_602136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602136.url(scheme.get, call_602136.host, call_602136.base,
                         call_602136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602136, url, valid)

proc call*(call_602137: Call_GetDomainMetadata_602125; Signature: string;
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
  var query_602138 = newJObject()
  add(query_602138, "Signature", newJString(Signature))
  add(query_602138, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602138, "SignatureMethod", newJString(SignatureMethod))
  add(query_602138, "DomainName", newJString(DomainName))
  add(query_602138, "Timestamp", newJString(Timestamp))
  add(query_602138, "Action", newJString(Action))
  add(query_602138, "Version", newJString(Version))
  add(query_602138, "SignatureVersion", newJString(SignatureVersion))
  result = call_602137.call(nil, query_602138, nil, nil, nil)

var getDomainMetadata* = Call_GetDomainMetadata_602125(name: "getDomainMetadata",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=DomainMetadata", validator: validate_GetDomainMetadata_602126,
    base: "/", url: url_GetDomainMetadata_602127,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetAttributes_602171 = ref object of OpenApiRestCall_601373
proc url_PostGetAttributes_602173(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetAttributes_602172(path: JsonNode; query: JsonNode;
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
  var valid_602174 = query.getOrDefault("Signature")
  valid_602174 = validateParameter(valid_602174, JString, required = true,
                                 default = nil)
  if valid_602174 != nil:
    section.add "Signature", valid_602174
  var valid_602175 = query.getOrDefault("AWSAccessKeyId")
  valid_602175 = validateParameter(valid_602175, JString, required = true,
                                 default = nil)
  if valid_602175 != nil:
    section.add "AWSAccessKeyId", valid_602175
  var valid_602176 = query.getOrDefault("SignatureMethod")
  valid_602176 = validateParameter(valid_602176, JString, required = true,
                                 default = nil)
  if valid_602176 != nil:
    section.add "SignatureMethod", valid_602176
  var valid_602177 = query.getOrDefault("Timestamp")
  valid_602177 = validateParameter(valid_602177, JString, required = true,
                                 default = nil)
  if valid_602177 != nil:
    section.add "Timestamp", valid_602177
  var valid_602178 = query.getOrDefault("Action")
  valid_602178 = validateParameter(valid_602178, JString, required = true,
                                 default = newJString("GetAttributes"))
  if valid_602178 != nil:
    section.add "Action", valid_602178
  var valid_602179 = query.getOrDefault("Version")
  valid_602179 = validateParameter(valid_602179, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_602179 != nil:
    section.add "Version", valid_602179
  var valid_602180 = query.getOrDefault("SignatureVersion")
  valid_602180 = validateParameter(valid_602180, JString, required = true,
                                 default = nil)
  if valid_602180 != nil:
    section.add "SignatureVersion", valid_602180
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
  var valid_602181 = formData.getOrDefault("ConsistentRead")
  valid_602181 = validateParameter(valid_602181, JBool, required = false, default = nil)
  if valid_602181 != nil:
    section.add "ConsistentRead", valid_602181
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602182 = formData.getOrDefault("DomainName")
  valid_602182 = validateParameter(valid_602182, JString, required = true,
                                 default = nil)
  if valid_602182 != nil:
    section.add "DomainName", valid_602182
  var valid_602183 = formData.getOrDefault("AttributeNames")
  valid_602183 = validateParameter(valid_602183, JArray, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "AttributeNames", valid_602183
  var valid_602184 = formData.getOrDefault("ItemName")
  valid_602184 = validateParameter(valid_602184, JString, required = true,
                                 default = nil)
  if valid_602184 != nil:
    section.add "ItemName", valid_602184
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602185: Call_PostGetAttributes_602171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  let valid = call_602185.validator(path, query, header, formData, body)
  let scheme = call_602185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602185.url(scheme.get, call_602185.host, call_602185.base,
                         call_602185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602185, url, valid)

proc call*(call_602186: Call_PostGetAttributes_602171; Signature: string;
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
  var query_602187 = newJObject()
  var formData_602188 = newJObject()
  add(query_602187, "Signature", newJString(Signature))
  add(query_602187, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602187, "SignatureMethod", newJString(SignatureMethod))
  add(formData_602188, "ConsistentRead", newJBool(ConsistentRead))
  add(formData_602188, "DomainName", newJString(DomainName))
  if AttributeNames != nil:
    formData_602188.add "AttributeNames", AttributeNames
  add(query_602187, "Timestamp", newJString(Timestamp))
  add(query_602187, "Action", newJString(Action))
  add(query_602187, "Version", newJString(Version))
  add(query_602187, "SignatureVersion", newJString(SignatureVersion))
  add(formData_602188, "ItemName", newJString(ItemName))
  result = call_602186.call(nil, query_602187, nil, formData_602188, nil)

var postGetAttributes* = Call_PostGetAttributes_602171(name: "postGetAttributes",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=GetAttributes", validator: validate_PostGetAttributes_602172,
    base: "/", url: url_PostGetAttributes_602173,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetAttributes_602154 = ref object of OpenApiRestCall_601373
proc url_GetGetAttributes_602156(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetAttributes_602155(path: JsonNode; query: JsonNode;
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
  var valid_602157 = query.getOrDefault("Signature")
  valid_602157 = validateParameter(valid_602157, JString, required = true,
                                 default = nil)
  if valid_602157 != nil:
    section.add "Signature", valid_602157
  var valid_602158 = query.getOrDefault("AWSAccessKeyId")
  valid_602158 = validateParameter(valid_602158, JString, required = true,
                                 default = nil)
  if valid_602158 != nil:
    section.add "AWSAccessKeyId", valid_602158
  var valid_602159 = query.getOrDefault("AttributeNames")
  valid_602159 = validateParameter(valid_602159, JArray, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "AttributeNames", valid_602159
  var valid_602160 = query.getOrDefault("SignatureMethod")
  valid_602160 = validateParameter(valid_602160, JString, required = true,
                                 default = nil)
  if valid_602160 != nil:
    section.add "SignatureMethod", valid_602160
  var valid_602161 = query.getOrDefault("DomainName")
  valid_602161 = validateParameter(valid_602161, JString, required = true,
                                 default = nil)
  if valid_602161 != nil:
    section.add "DomainName", valid_602161
  var valid_602162 = query.getOrDefault("ItemName")
  valid_602162 = validateParameter(valid_602162, JString, required = true,
                                 default = nil)
  if valid_602162 != nil:
    section.add "ItemName", valid_602162
  var valid_602163 = query.getOrDefault("Timestamp")
  valid_602163 = validateParameter(valid_602163, JString, required = true,
                                 default = nil)
  if valid_602163 != nil:
    section.add "Timestamp", valid_602163
  var valid_602164 = query.getOrDefault("Action")
  valid_602164 = validateParameter(valid_602164, JString, required = true,
                                 default = newJString("GetAttributes"))
  if valid_602164 != nil:
    section.add "Action", valid_602164
  var valid_602165 = query.getOrDefault("ConsistentRead")
  valid_602165 = validateParameter(valid_602165, JBool, required = false, default = nil)
  if valid_602165 != nil:
    section.add "ConsistentRead", valid_602165
  var valid_602166 = query.getOrDefault("Version")
  valid_602166 = validateParameter(valid_602166, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_602166 != nil:
    section.add "Version", valid_602166
  var valid_602167 = query.getOrDefault("SignatureVersion")
  valid_602167 = validateParameter(valid_602167, JString, required = true,
                                 default = nil)
  if valid_602167 != nil:
    section.add "SignatureVersion", valid_602167
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602168: Call_GetGetAttributes_602154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  let valid = call_602168.validator(path, query, header, formData, body)
  let scheme = call_602168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602168.url(scheme.get, call_602168.host, call_602168.base,
                         call_602168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602168, url, valid)

proc call*(call_602169: Call_GetGetAttributes_602154; Signature: string;
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
  var query_602170 = newJObject()
  add(query_602170, "Signature", newJString(Signature))
  add(query_602170, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  if AttributeNames != nil:
    query_602170.add "AttributeNames", AttributeNames
  add(query_602170, "SignatureMethod", newJString(SignatureMethod))
  add(query_602170, "DomainName", newJString(DomainName))
  add(query_602170, "ItemName", newJString(ItemName))
  add(query_602170, "Timestamp", newJString(Timestamp))
  add(query_602170, "Action", newJString(Action))
  add(query_602170, "ConsistentRead", newJBool(ConsistentRead))
  add(query_602170, "Version", newJString(Version))
  add(query_602170, "SignatureVersion", newJString(SignatureVersion))
  result = call_602169.call(nil, query_602170, nil, nil, nil)

var getGetAttributes* = Call_GetGetAttributes_602154(name: "getGetAttributes",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=GetAttributes", validator: validate_GetGetAttributes_602155,
    base: "/", url: url_GetGetAttributes_602156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDomains_602204 = ref object of OpenApiRestCall_601373
proc url_PostListDomains_602206(protocol: Scheme; host: string; base: string;
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

proc validate_PostListDomains_602205(path: JsonNode; query: JsonNode;
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
  var valid_602207 = query.getOrDefault("Signature")
  valid_602207 = validateParameter(valid_602207, JString, required = true,
                                 default = nil)
  if valid_602207 != nil:
    section.add "Signature", valid_602207
  var valid_602208 = query.getOrDefault("AWSAccessKeyId")
  valid_602208 = validateParameter(valid_602208, JString, required = true,
                                 default = nil)
  if valid_602208 != nil:
    section.add "AWSAccessKeyId", valid_602208
  var valid_602209 = query.getOrDefault("SignatureMethod")
  valid_602209 = validateParameter(valid_602209, JString, required = true,
                                 default = nil)
  if valid_602209 != nil:
    section.add "SignatureMethod", valid_602209
  var valid_602210 = query.getOrDefault("Timestamp")
  valid_602210 = validateParameter(valid_602210, JString, required = true,
                                 default = nil)
  if valid_602210 != nil:
    section.add "Timestamp", valid_602210
  var valid_602211 = query.getOrDefault("Action")
  valid_602211 = validateParameter(valid_602211, JString, required = true,
                                 default = newJString("ListDomains"))
  if valid_602211 != nil:
    section.add "Action", valid_602211
  var valid_602212 = query.getOrDefault("Version")
  valid_602212 = validateParameter(valid_602212, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_602212 != nil:
    section.add "Version", valid_602212
  var valid_602213 = query.getOrDefault("SignatureVersion")
  valid_602213 = validateParameter(valid_602213, JString, required = true,
                                 default = nil)
  if valid_602213 != nil:
    section.add "SignatureVersion", valid_602213
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : A string informing Amazon SimpleDB where to start the next list of domain names.
  ##   MaxNumberOfDomains: JInt
  ##                     : The maximum number of domain names you want returned. The range is 1 to 100. The default setting is 100.
  section = newJObject()
  var valid_602214 = formData.getOrDefault("NextToken")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "NextToken", valid_602214
  var valid_602215 = formData.getOrDefault("MaxNumberOfDomains")
  valid_602215 = validateParameter(valid_602215, JInt, required = false, default = nil)
  if valid_602215 != nil:
    section.add "MaxNumberOfDomains", valid_602215
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602216: Call_PostListDomains_602204; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  let valid = call_602216.validator(path, query, header, formData, body)
  let scheme = call_602216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602216.url(scheme.get, call_602216.host, call_602216.base,
                         call_602216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602216, url, valid)

proc call*(call_602217: Call_PostListDomains_602204; Signature: string;
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
  var query_602218 = newJObject()
  var formData_602219 = newJObject()
  add(query_602218, "Signature", newJString(Signature))
  add(query_602218, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_602219, "NextToken", newJString(NextToken))
  add(query_602218, "SignatureMethod", newJString(SignatureMethod))
  add(formData_602219, "MaxNumberOfDomains", newJInt(MaxNumberOfDomains))
  add(query_602218, "Timestamp", newJString(Timestamp))
  add(query_602218, "Action", newJString(Action))
  add(query_602218, "Version", newJString(Version))
  add(query_602218, "SignatureVersion", newJString(SignatureVersion))
  result = call_602217.call(nil, query_602218, nil, formData_602219, nil)

var postListDomains* = Call_PostListDomains_602204(name: "postListDomains",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=ListDomains", validator: validate_PostListDomains_602205,
    base: "/", url: url_PostListDomains_602206, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDomains_602189 = ref object of OpenApiRestCall_601373
proc url_GetListDomains_602191(protocol: Scheme; host: string; base: string;
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

proc validate_GetListDomains_602190(path: JsonNode; query: JsonNode;
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
  var valid_602192 = query.getOrDefault("Signature")
  valid_602192 = validateParameter(valid_602192, JString, required = true,
                                 default = nil)
  if valid_602192 != nil:
    section.add "Signature", valid_602192
  var valid_602193 = query.getOrDefault("AWSAccessKeyId")
  valid_602193 = validateParameter(valid_602193, JString, required = true,
                                 default = nil)
  if valid_602193 != nil:
    section.add "AWSAccessKeyId", valid_602193
  var valid_602194 = query.getOrDefault("SignatureMethod")
  valid_602194 = validateParameter(valid_602194, JString, required = true,
                                 default = nil)
  if valid_602194 != nil:
    section.add "SignatureMethod", valid_602194
  var valid_602195 = query.getOrDefault("NextToken")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "NextToken", valid_602195
  var valid_602196 = query.getOrDefault("MaxNumberOfDomains")
  valid_602196 = validateParameter(valid_602196, JInt, required = false, default = nil)
  if valid_602196 != nil:
    section.add "MaxNumberOfDomains", valid_602196
  var valid_602197 = query.getOrDefault("Timestamp")
  valid_602197 = validateParameter(valid_602197, JString, required = true,
                                 default = nil)
  if valid_602197 != nil:
    section.add "Timestamp", valid_602197
  var valid_602198 = query.getOrDefault("Action")
  valid_602198 = validateParameter(valid_602198, JString, required = true,
                                 default = newJString("ListDomains"))
  if valid_602198 != nil:
    section.add "Action", valid_602198
  var valid_602199 = query.getOrDefault("Version")
  valid_602199 = validateParameter(valid_602199, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_602199 != nil:
    section.add "Version", valid_602199
  var valid_602200 = query.getOrDefault("SignatureVersion")
  valid_602200 = validateParameter(valid_602200, JString, required = true,
                                 default = nil)
  if valid_602200 != nil:
    section.add "SignatureVersion", valid_602200
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602201: Call_GetListDomains_602189; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  let valid = call_602201.validator(path, query, header, formData, body)
  let scheme = call_602201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602201.url(scheme.get, call_602201.host, call_602201.base,
                         call_602201.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602201, url, valid)

proc call*(call_602202: Call_GetListDomains_602189; Signature: string;
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
  var query_602203 = newJObject()
  add(query_602203, "Signature", newJString(Signature))
  add(query_602203, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602203, "SignatureMethod", newJString(SignatureMethod))
  add(query_602203, "NextToken", newJString(NextToken))
  add(query_602203, "MaxNumberOfDomains", newJInt(MaxNumberOfDomains))
  add(query_602203, "Timestamp", newJString(Timestamp))
  add(query_602203, "Action", newJString(Action))
  add(query_602203, "Version", newJString(Version))
  add(query_602203, "SignatureVersion", newJString(SignatureVersion))
  result = call_602202.call(nil, query_602203, nil, nil, nil)

var getListDomains* = Call_GetListDomains_602189(name: "getListDomains",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=ListDomains", validator: validate_GetListDomains_602190,
    base: "/", url: url_GetListDomains_602191, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutAttributes_602239 = ref object of OpenApiRestCall_601373
proc url_PostPutAttributes_602241(protocol: Scheme; host: string; base: string;
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

proc validate_PostPutAttributes_602240(path: JsonNode; query: JsonNode;
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
  var valid_602242 = query.getOrDefault("Signature")
  valid_602242 = validateParameter(valid_602242, JString, required = true,
                                 default = nil)
  if valid_602242 != nil:
    section.add "Signature", valid_602242
  var valid_602243 = query.getOrDefault("AWSAccessKeyId")
  valid_602243 = validateParameter(valid_602243, JString, required = true,
                                 default = nil)
  if valid_602243 != nil:
    section.add "AWSAccessKeyId", valid_602243
  var valid_602244 = query.getOrDefault("SignatureMethod")
  valid_602244 = validateParameter(valid_602244, JString, required = true,
                                 default = nil)
  if valid_602244 != nil:
    section.add "SignatureMethod", valid_602244
  var valid_602245 = query.getOrDefault("Timestamp")
  valid_602245 = validateParameter(valid_602245, JString, required = true,
                                 default = nil)
  if valid_602245 != nil:
    section.add "Timestamp", valid_602245
  var valid_602246 = query.getOrDefault("Action")
  valid_602246 = validateParameter(valid_602246, JString, required = true,
                                 default = newJString("PutAttributes"))
  if valid_602246 != nil:
    section.add "Action", valid_602246
  var valid_602247 = query.getOrDefault("Version")
  valid_602247 = validateParameter(valid_602247, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_602247 != nil:
    section.add "Version", valid_602247
  var valid_602248 = query.getOrDefault("SignatureVersion")
  valid_602248 = validateParameter(valid_602248, JString, required = true,
                                 default = nil)
  if valid_602248 != nil:
    section.add "SignatureVersion", valid_602248
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
  var valid_602249 = formData.getOrDefault("Expected.Value")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "Expected.Value", valid_602249
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602250 = formData.getOrDefault("DomainName")
  valid_602250 = validateParameter(valid_602250, JString, required = true,
                                 default = nil)
  if valid_602250 != nil:
    section.add "DomainName", valid_602250
  var valid_602251 = formData.getOrDefault("Attributes")
  valid_602251 = validateParameter(valid_602251, JArray, required = true, default = nil)
  if valid_602251 != nil:
    section.add "Attributes", valid_602251
  var valid_602252 = formData.getOrDefault("Expected.Name")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "Expected.Name", valid_602252
  var valid_602253 = formData.getOrDefault("Expected.Exists")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "Expected.Exists", valid_602253
  var valid_602254 = formData.getOrDefault("ItemName")
  valid_602254 = validateParameter(valid_602254, JString, required = true,
                                 default = nil)
  if valid_602254 != nil:
    section.add "ItemName", valid_602254
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602255: Call_PostPutAttributes_602239; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  let valid = call_602255.validator(path, query, header, formData, body)
  let scheme = call_602255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602255.url(scheme.get, call_602255.host, call_602255.base,
                         call_602255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602255, url, valid)

proc call*(call_602256: Call_PostPutAttributes_602239; Signature: string;
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
  var query_602257 = newJObject()
  var formData_602258 = newJObject()
  add(formData_602258, "Expected.Value", newJString(ExpectedValue))
  add(query_602257, "Signature", newJString(Signature))
  add(query_602257, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602257, "SignatureMethod", newJString(SignatureMethod))
  add(formData_602258, "DomainName", newJString(DomainName))
  if Attributes != nil:
    formData_602258.add "Attributes", Attributes
  add(query_602257, "Timestamp", newJString(Timestamp))
  add(query_602257, "Action", newJString(Action))
  add(formData_602258, "Expected.Name", newJString(ExpectedName))
  add(query_602257, "Version", newJString(Version))
  add(formData_602258, "Expected.Exists", newJString(ExpectedExists))
  add(query_602257, "SignatureVersion", newJString(SignatureVersion))
  add(formData_602258, "ItemName", newJString(ItemName))
  result = call_602256.call(nil, query_602257, nil, formData_602258, nil)

var postPutAttributes* = Call_PostPutAttributes_602239(name: "postPutAttributes",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=PutAttributes", validator: validate_PostPutAttributes_602240,
    base: "/", url: url_PostPutAttributes_602241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutAttributes_602220 = ref object of OpenApiRestCall_601373
proc url_GetPutAttributes_602222(protocol: Scheme; host: string; base: string;
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

proc validate_GetPutAttributes_602221(path: JsonNode; query: JsonNode;
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
  var valid_602223 = query.getOrDefault("Signature")
  valid_602223 = validateParameter(valid_602223, JString, required = true,
                                 default = nil)
  if valid_602223 != nil:
    section.add "Signature", valid_602223
  var valid_602224 = query.getOrDefault("AWSAccessKeyId")
  valid_602224 = validateParameter(valid_602224, JString, required = true,
                                 default = nil)
  if valid_602224 != nil:
    section.add "AWSAccessKeyId", valid_602224
  var valid_602225 = query.getOrDefault("Expected.Value")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "Expected.Value", valid_602225
  var valid_602226 = query.getOrDefault("SignatureMethod")
  valid_602226 = validateParameter(valid_602226, JString, required = true,
                                 default = nil)
  if valid_602226 != nil:
    section.add "SignatureMethod", valid_602226
  var valid_602227 = query.getOrDefault("DomainName")
  valid_602227 = validateParameter(valid_602227, JString, required = true,
                                 default = nil)
  if valid_602227 != nil:
    section.add "DomainName", valid_602227
  var valid_602228 = query.getOrDefault("Expected.Name")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "Expected.Name", valid_602228
  var valid_602229 = query.getOrDefault("ItemName")
  valid_602229 = validateParameter(valid_602229, JString, required = true,
                                 default = nil)
  if valid_602229 != nil:
    section.add "ItemName", valid_602229
  var valid_602230 = query.getOrDefault("Expected.Exists")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "Expected.Exists", valid_602230
  var valid_602231 = query.getOrDefault("Attributes")
  valid_602231 = validateParameter(valid_602231, JArray, required = true, default = nil)
  if valid_602231 != nil:
    section.add "Attributes", valid_602231
  var valid_602232 = query.getOrDefault("Timestamp")
  valid_602232 = validateParameter(valid_602232, JString, required = true,
                                 default = nil)
  if valid_602232 != nil:
    section.add "Timestamp", valid_602232
  var valid_602233 = query.getOrDefault("Action")
  valid_602233 = validateParameter(valid_602233, JString, required = true,
                                 default = newJString("PutAttributes"))
  if valid_602233 != nil:
    section.add "Action", valid_602233
  var valid_602234 = query.getOrDefault("Version")
  valid_602234 = validateParameter(valid_602234, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_602234 != nil:
    section.add "Version", valid_602234
  var valid_602235 = query.getOrDefault("SignatureVersion")
  valid_602235 = validateParameter(valid_602235, JString, required = true,
                                 default = nil)
  if valid_602235 != nil:
    section.add "SignatureVersion", valid_602235
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602236: Call_GetPutAttributes_602220; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  let valid = call_602236.validator(path, query, header, formData, body)
  let scheme = call_602236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602236.url(scheme.get, call_602236.host, call_602236.base,
                         call_602236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602236, url, valid)

proc call*(call_602237: Call_GetPutAttributes_602220; Signature: string;
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
  var query_602238 = newJObject()
  add(query_602238, "Signature", newJString(Signature))
  add(query_602238, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602238, "Expected.Value", newJString(ExpectedValue))
  add(query_602238, "SignatureMethod", newJString(SignatureMethod))
  add(query_602238, "DomainName", newJString(DomainName))
  add(query_602238, "Expected.Name", newJString(ExpectedName))
  add(query_602238, "ItemName", newJString(ItemName))
  add(query_602238, "Expected.Exists", newJString(ExpectedExists))
  if Attributes != nil:
    query_602238.add "Attributes", Attributes
  add(query_602238, "Timestamp", newJString(Timestamp))
  add(query_602238, "Action", newJString(Action))
  add(query_602238, "Version", newJString(Version))
  add(query_602238, "SignatureVersion", newJString(SignatureVersion))
  result = call_602237.call(nil, query_602238, nil, nil, nil)

var getPutAttributes* = Call_GetPutAttributes_602220(name: "getPutAttributes",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=PutAttributes", validator: validate_GetPutAttributes_602221,
    base: "/", url: url_GetPutAttributes_602222,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSelect_602275 = ref object of OpenApiRestCall_601373
proc url_PostSelect_602277(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PostSelect_602276(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602278 = query.getOrDefault("Signature")
  valid_602278 = validateParameter(valid_602278, JString, required = true,
                                 default = nil)
  if valid_602278 != nil:
    section.add "Signature", valid_602278
  var valid_602279 = query.getOrDefault("AWSAccessKeyId")
  valid_602279 = validateParameter(valid_602279, JString, required = true,
                                 default = nil)
  if valid_602279 != nil:
    section.add "AWSAccessKeyId", valid_602279
  var valid_602280 = query.getOrDefault("SignatureMethod")
  valid_602280 = validateParameter(valid_602280, JString, required = true,
                                 default = nil)
  if valid_602280 != nil:
    section.add "SignatureMethod", valid_602280
  var valid_602281 = query.getOrDefault("Timestamp")
  valid_602281 = validateParameter(valid_602281, JString, required = true,
                                 default = nil)
  if valid_602281 != nil:
    section.add "Timestamp", valid_602281
  var valid_602282 = query.getOrDefault("Action")
  valid_602282 = validateParameter(valid_602282, JString, required = true,
                                 default = newJString("Select"))
  if valid_602282 != nil:
    section.add "Action", valid_602282
  var valid_602283 = query.getOrDefault("Version")
  valid_602283 = validateParameter(valid_602283, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_602283 != nil:
    section.add "Version", valid_602283
  var valid_602284 = query.getOrDefault("SignatureVersion")
  valid_602284 = validateParameter(valid_602284, JString, required = true,
                                 default = nil)
  if valid_602284 != nil:
    section.add "SignatureVersion", valid_602284
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
  var valid_602285 = formData.getOrDefault("NextToken")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "NextToken", valid_602285
  assert formData != nil, "formData argument is necessary due to required `SelectExpression` field"
  var valid_602286 = formData.getOrDefault("SelectExpression")
  valid_602286 = validateParameter(valid_602286, JString, required = true,
                                 default = nil)
  if valid_602286 != nil:
    section.add "SelectExpression", valid_602286
  var valid_602287 = formData.getOrDefault("ConsistentRead")
  valid_602287 = validateParameter(valid_602287, JBool, required = false, default = nil)
  if valid_602287 != nil:
    section.add "ConsistentRead", valid_602287
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602288: Call_PostSelect_602275; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  let valid = call_602288.validator(path, query, header, formData, body)
  let scheme = call_602288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602288.url(scheme.get, call_602288.host, call_602288.base,
                         call_602288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602288, url, valid)

proc call*(call_602289: Call_PostSelect_602275; Signature: string;
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
  var query_602290 = newJObject()
  var formData_602291 = newJObject()
  add(query_602290, "Signature", newJString(Signature))
  add(query_602290, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_602291, "NextToken", newJString(NextToken))
  add(query_602290, "SignatureMethod", newJString(SignatureMethod))
  add(formData_602291, "SelectExpression", newJString(SelectExpression))
  add(formData_602291, "ConsistentRead", newJBool(ConsistentRead))
  add(query_602290, "Timestamp", newJString(Timestamp))
  add(query_602290, "Action", newJString(Action))
  add(query_602290, "Version", newJString(Version))
  add(query_602290, "SignatureVersion", newJString(SignatureVersion))
  result = call_602289.call(nil, query_602290, nil, formData_602291, nil)

var postSelect* = Call_PostSelect_602275(name: "postSelect",
                                      meth: HttpMethod.HttpPost,
                                      host: "sdb.amazonaws.com",
                                      route: "/#Action=Select",
                                      validator: validate_PostSelect_602276,
                                      base: "/", url: url_PostSelect_602277,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSelect_602259 = ref object of OpenApiRestCall_601373
proc url_GetSelect_602261(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSelect_602260(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602262 = query.getOrDefault("Signature")
  valid_602262 = validateParameter(valid_602262, JString, required = true,
                                 default = nil)
  if valid_602262 != nil:
    section.add "Signature", valid_602262
  var valid_602263 = query.getOrDefault("AWSAccessKeyId")
  valid_602263 = validateParameter(valid_602263, JString, required = true,
                                 default = nil)
  if valid_602263 != nil:
    section.add "AWSAccessKeyId", valid_602263
  var valid_602264 = query.getOrDefault("SignatureMethod")
  valid_602264 = validateParameter(valid_602264, JString, required = true,
                                 default = nil)
  if valid_602264 != nil:
    section.add "SignatureMethod", valid_602264
  var valid_602265 = query.getOrDefault("NextToken")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "NextToken", valid_602265
  var valid_602266 = query.getOrDefault("SelectExpression")
  valid_602266 = validateParameter(valid_602266, JString, required = true,
                                 default = nil)
  if valid_602266 != nil:
    section.add "SelectExpression", valid_602266
  var valid_602267 = query.getOrDefault("Timestamp")
  valid_602267 = validateParameter(valid_602267, JString, required = true,
                                 default = nil)
  if valid_602267 != nil:
    section.add "Timestamp", valid_602267
  var valid_602268 = query.getOrDefault("Action")
  valid_602268 = validateParameter(valid_602268, JString, required = true,
                                 default = newJString("Select"))
  if valid_602268 != nil:
    section.add "Action", valid_602268
  var valid_602269 = query.getOrDefault("ConsistentRead")
  valid_602269 = validateParameter(valid_602269, JBool, required = false, default = nil)
  if valid_602269 != nil:
    section.add "ConsistentRead", valid_602269
  var valid_602270 = query.getOrDefault("Version")
  valid_602270 = validateParameter(valid_602270, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_602270 != nil:
    section.add "Version", valid_602270
  var valid_602271 = query.getOrDefault("SignatureVersion")
  valid_602271 = validateParameter(valid_602271, JString, required = true,
                                 default = nil)
  if valid_602271 != nil:
    section.add "SignatureVersion", valid_602271
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602272: Call_GetSelect_602259; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  let valid = call_602272.validator(path, query, header, formData, body)
  let scheme = call_602272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602272.url(scheme.get, call_602272.host, call_602272.base,
                         call_602272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602272, url, valid)

proc call*(call_602273: Call_GetSelect_602259; Signature: string;
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
  var query_602274 = newJObject()
  add(query_602274, "Signature", newJString(Signature))
  add(query_602274, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602274, "SignatureMethod", newJString(SignatureMethod))
  add(query_602274, "NextToken", newJString(NextToken))
  add(query_602274, "SelectExpression", newJString(SelectExpression))
  add(query_602274, "Timestamp", newJString(Timestamp))
  add(query_602274, "Action", newJString(Action))
  add(query_602274, "ConsistentRead", newJBool(ConsistentRead))
  add(query_602274, "Version", newJString(Version))
  add(query_602274, "SignatureVersion", newJString(SignatureVersion))
  result = call_602273.call(nil, query_602274, nil, nil, nil)

var getSelect* = Call_GetSelect_602259(name: "getSelect", meth: HttpMethod.HttpGet,
                                    host: "sdb.amazonaws.com",
                                    route: "/#Action=Select",
                                    validator: validate_GetSelect_602260,
                                    base: "/", url: url_GetSelect_602261,
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
