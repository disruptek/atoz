
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

  OpenApiRestCall_602450 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602450](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602450): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
  Call_PostBatchDeleteAttributes_603057 = ref object of OpenApiRestCall_602450
proc url_PostBatchDeleteAttributes_603059(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostBatchDeleteAttributes_603058(path: JsonNode; query: JsonNode;
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
  var valid_603060 = query.getOrDefault("SignatureMethod")
  valid_603060 = validateParameter(valid_603060, JString, required = true,
                                 default = nil)
  if valid_603060 != nil:
    section.add "SignatureMethod", valid_603060
  var valid_603061 = query.getOrDefault("Signature")
  valid_603061 = validateParameter(valid_603061, JString, required = true,
                                 default = nil)
  if valid_603061 != nil:
    section.add "Signature", valid_603061
  var valid_603062 = query.getOrDefault("Action")
  valid_603062 = validateParameter(valid_603062, JString, required = true,
                                 default = newJString("BatchDeleteAttributes"))
  if valid_603062 != nil:
    section.add "Action", valid_603062
  var valid_603063 = query.getOrDefault("Timestamp")
  valid_603063 = validateParameter(valid_603063, JString, required = true,
                                 default = nil)
  if valid_603063 != nil:
    section.add "Timestamp", valid_603063
  var valid_603064 = query.getOrDefault("SignatureVersion")
  valid_603064 = validateParameter(valid_603064, JString, required = true,
                                 default = nil)
  if valid_603064 != nil:
    section.add "SignatureVersion", valid_603064
  var valid_603065 = query.getOrDefault("AWSAccessKeyId")
  valid_603065 = validateParameter(valid_603065, JString, required = true,
                                 default = nil)
  if valid_603065 != nil:
    section.add "AWSAccessKeyId", valid_603065
  var valid_603066 = query.getOrDefault("Version")
  valid_603066 = validateParameter(valid_603066, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_603066 != nil:
    section.add "Version", valid_603066
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
  var valid_603067 = formData.getOrDefault("DomainName")
  valid_603067 = validateParameter(valid_603067, JString, required = true,
                                 default = nil)
  if valid_603067 != nil:
    section.add "DomainName", valid_603067
  var valid_603068 = formData.getOrDefault("Items")
  valid_603068 = validateParameter(valid_603068, JArray, required = true, default = nil)
  if valid_603068 != nil:
    section.add "Items", valid_603068
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603069: Call_PostBatchDeleteAttributes_603057; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  let valid = call_603069.validator(path, query, header, formData, body)
  let scheme = call_603069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603069.url(scheme.get, call_603069.host, call_603069.base,
                         call_603069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603069, url, valid)

proc call*(call_603070: Call_PostBatchDeleteAttributes_603057;
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
  var query_603071 = newJObject()
  var formData_603072 = newJObject()
  add(query_603071, "SignatureMethod", newJString(SignatureMethod))
  add(formData_603072, "DomainName", newJString(DomainName))
  add(query_603071, "Signature", newJString(Signature))
  add(query_603071, "Action", newJString(Action))
  add(query_603071, "Timestamp", newJString(Timestamp))
  if Items != nil:
    formData_603072.add "Items", Items
  add(query_603071, "SignatureVersion", newJString(SignatureVersion))
  add(query_603071, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603071, "Version", newJString(Version))
  result = call_603070.call(nil, query_603071, nil, formData_603072, nil)

var postBatchDeleteAttributes* = Call_PostBatchDeleteAttributes_603057(
    name: "postBatchDeleteAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=BatchDeleteAttributes",
    validator: validate_PostBatchDeleteAttributes_603058, base: "/",
    url: url_PostBatchDeleteAttributes_603059,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchDeleteAttributes_602787 = ref object of OpenApiRestCall_602450
proc url_GetBatchDeleteAttributes_602789(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBatchDeleteAttributes_602788(path: JsonNode; query: JsonNode;
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
  var valid_602901 = query.getOrDefault("SignatureMethod")
  valid_602901 = validateParameter(valid_602901, JString, required = true,
                                 default = nil)
  if valid_602901 != nil:
    section.add "SignatureMethod", valid_602901
  var valid_602902 = query.getOrDefault("Signature")
  valid_602902 = validateParameter(valid_602902, JString, required = true,
                                 default = nil)
  if valid_602902 != nil:
    section.add "Signature", valid_602902
  var valid_602916 = query.getOrDefault("Action")
  valid_602916 = validateParameter(valid_602916, JString, required = true,
                                 default = newJString("BatchDeleteAttributes"))
  if valid_602916 != nil:
    section.add "Action", valid_602916
  var valid_602917 = query.getOrDefault("Timestamp")
  valid_602917 = validateParameter(valid_602917, JString, required = true,
                                 default = nil)
  if valid_602917 != nil:
    section.add "Timestamp", valid_602917
  var valid_602918 = query.getOrDefault("Items")
  valid_602918 = validateParameter(valid_602918, JArray, required = true, default = nil)
  if valid_602918 != nil:
    section.add "Items", valid_602918
  var valid_602919 = query.getOrDefault("SignatureVersion")
  valid_602919 = validateParameter(valid_602919, JString, required = true,
                                 default = nil)
  if valid_602919 != nil:
    section.add "SignatureVersion", valid_602919
  var valid_602920 = query.getOrDefault("AWSAccessKeyId")
  valid_602920 = validateParameter(valid_602920, JString, required = true,
                                 default = nil)
  if valid_602920 != nil:
    section.add "AWSAccessKeyId", valid_602920
  var valid_602921 = query.getOrDefault("DomainName")
  valid_602921 = validateParameter(valid_602921, JString, required = true,
                                 default = nil)
  if valid_602921 != nil:
    section.add "DomainName", valid_602921
  var valid_602922 = query.getOrDefault("Version")
  valid_602922 = validateParameter(valid_602922, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_602922 != nil:
    section.add "Version", valid_602922
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602945: Call_GetBatchDeleteAttributes_602787; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  let valid = call_602945.validator(path, query, header, formData, body)
  let scheme = call_602945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602945.url(scheme.get, call_602945.host, call_602945.base,
                         call_602945.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602945, url, valid)

proc call*(call_603016: Call_GetBatchDeleteAttributes_602787;
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
  var query_603017 = newJObject()
  add(query_603017, "SignatureMethod", newJString(SignatureMethod))
  add(query_603017, "Signature", newJString(Signature))
  add(query_603017, "Action", newJString(Action))
  add(query_603017, "Timestamp", newJString(Timestamp))
  if Items != nil:
    query_603017.add "Items", Items
  add(query_603017, "SignatureVersion", newJString(SignatureVersion))
  add(query_603017, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603017, "DomainName", newJString(DomainName))
  add(query_603017, "Version", newJString(Version))
  result = call_603016.call(nil, query_603017, nil, nil, nil)

var getBatchDeleteAttributes* = Call_GetBatchDeleteAttributes_602787(
    name: "getBatchDeleteAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=BatchDeleteAttributes",
    validator: validate_GetBatchDeleteAttributes_602788, base: "/",
    url: url_GetBatchDeleteAttributes_602789, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostBatchPutAttributes_603088 = ref object of OpenApiRestCall_602450
proc url_PostBatchPutAttributes_603090(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostBatchPutAttributes_603089(path: JsonNode; query: JsonNode;
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
  var valid_603091 = query.getOrDefault("SignatureMethod")
  valid_603091 = validateParameter(valid_603091, JString, required = true,
                                 default = nil)
  if valid_603091 != nil:
    section.add "SignatureMethod", valid_603091
  var valid_603092 = query.getOrDefault("Signature")
  valid_603092 = validateParameter(valid_603092, JString, required = true,
                                 default = nil)
  if valid_603092 != nil:
    section.add "Signature", valid_603092
  var valid_603093 = query.getOrDefault("Action")
  valid_603093 = validateParameter(valid_603093, JString, required = true,
                                 default = newJString("BatchPutAttributes"))
  if valid_603093 != nil:
    section.add "Action", valid_603093
  var valid_603094 = query.getOrDefault("Timestamp")
  valid_603094 = validateParameter(valid_603094, JString, required = true,
                                 default = nil)
  if valid_603094 != nil:
    section.add "Timestamp", valid_603094
  var valid_603095 = query.getOrDefault("SignatureVersion")
  valid_603095 = validateParameter(valid_603095, JString, required = true,
                                 default = nil)
  if valid_603095 != nil:
    section.add "SignatureVersion", valid_603095
  var valid_603096 = query.getOrDefault("AWSAccessKeyId")
  valid_603096 = validateParameter(valid_603096, JString, required = true,
                                 default = nil)
  if valid_603096 != nil:
    section.add "AWSAccessKeyId", valid_603096
  var valid_603097 = query.getOrDefault("Version")
  valid_603097 = validateParameter(valid_603097, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_603097 != nil:
    section.add "Version", valid_603097
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
  var valid_603098 = formData.getOrDefault("DomainName")
  valid_603098 = validateParameter(valid_603098, JString, required = true,
                                 default = nil)
  if valid_603098 != nil:
    section.add "DomainName", valid_603098
  var valid_603099 = formData.getOrDefault("Items")
  valid_603099 = validateParameter(valid_603099, JArray, required = true, default = nil)
  if valid_603099 != nil:
    section.add "Items", valid_603099
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603100: Call_PostBatchPutAttributes_603088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  let valid = call_603100.validator(path, query, header, formData, body)
  let scheme = call_603100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603100.url(scheme.get, call_603100.host, call_603100.base,
                         call_603100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603100, url, valid)

proc call*(call_603101: Call_PostBatchPutAttributes_603088;
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
  var query_603102 = newJObject()
  var formData_603103 = newJObject()
  add(query_603102, "SignatureMethod", newJString(SignatureMethod))
  add(formData_603103, "DomainName", newJString(DomainName))
  add(query_603102, "Signature", newJString(Signature))
  add(query_603102, "Action", newJString(Action))
  add(query_603102, "Timestamp", newJString(Timestamp))
  if Items != nil:
    formData_603103.add "Items", Items
  add(query_603102, "SignatureVersion", newJString(SignatureVersion))
  add(query_603102, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603102, "Version", newJString(Version))
  result = call_603101.call(nil, query_603102, nil, formData_603103, nil)

var postBatchPutAttributes* = Call_PostBatchPutAttributes_603088(
    name: "postBatchPutAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=BatchPutAttributes",
    validator: validate_PostBatchPutAttributes_603089, base: "/",
    url: url_PostBatchPutAttributes_603090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchPutAttributes_603073 = ref object of OpenApiRestCall_602450
proc url_GetBatchPutAttributes_603075(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBatchPutAttributes_603074(path: JsonNode; query: JsonNode;
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
  var valid_603076 = query.getOrDefault("SignatureMethod")
  valid_603076 = validateParameter(valid_603076, JString, required = true,
                                 default = nil)
  if valid_603076 != nil:
    section.add "SignatureMethod", valid_603076
  var valid_603077 = query.getOrDefault("Signature")
  valid_603077 = validateParameter(valid_603077, JString, required = true,
                                 default = nil)
  if valid_603077 != nil:
    section.add "Signature", valid_603077
  var valid_603078 = query.getOrDefault("Action")
  valid_603078 = validateParameter(valid_603078, JString, required = true,
                                 default = newJString("BatchPutAttributes"))
  if valid_603078 != nil:
    section.add "Action", valid_603078
  var valid_603079 = query.getOrDefault("Timestamp")
  valid_603079 = validateParameter(valid_603079, JString, required = true,
                                 default = nil)
  if valid_603079 != nil:
    section.add "Timestamp", valid_603079
  var valid_603080 = query.getOrDefault("Items")
  valid_603080 = validateParameter(valid_603080, JArray, required = true, default = nil)
  if valid_603080 != nil:
    section.add "Items", valid_603080
  var valid_603081 = query.getOrDefault("SignatureVersion")
  valid_603081 = validateParameter(valid_603081, JString, required = true,
                                 default = nil)
  if valid_603081 != nil:
    section.add "SignatureVersion", valid_603081
  var valid_603082 = query.getOrDefault("AWSAccessKeyId")
  valid_603082 = validateParameter(valid_603082, JString, required = true,
                                 default = nil)
  if valid_603082 != nil:
    section.add "AWSAccessKeyId", valid_603082
  var valid_603083 = query.getOrDefault("DomainName")
  valid_603083 = validateParameter(valid_603083, JString, required = true,
                                 default = nil)
  if valid_603083 != nil:
    section.add "DomainName", valid_603083
  var valid_603084 = query.getOrDefault("Version")
  valid_603084 = validateParameter(valid_603084, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_603084 != nil:
    section.add "Version", valid_603084
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603085: Call_GetBatchPutAttributes_603073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  let valid = call_603085.validator(path, query, header, formData, body)
  let scheme = call_603085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603085.url(scheme.get, call_603085.host, call_603085.base,
                         call_603085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603085, url, valid)

proc call*(call_603086: Call_GetBatchPutAttributes_603073; SignatureMethod: string;
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
  var query_603087 = newJObject()
  add(query_603087, "SignatureMethod", newJString(SignatureMethod))
  add(query_603087, "Signature", newJString(Signature))
  add(query_603087, "Action", newJString(Action))
  add(query_603087, "Timestamp", newJString(Timestamp))
  if Items != nil:
    query_603087.add "Items", Items
  add(query_603087, "SignatureVersion", newJString(SignatureVersion))
  add(query_603087, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603087, "DomainName", newJString(DomainName))
  add(query_603087, "Version", newJString(Version))
  result = call_603086.call(nil, query_603087, nil, nil, nil)

var getBatchPutAttributes* = Call_GetBatchPutAttributes_603073(
    name: "getBatchPutAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=BatchPutAttributes",
    validator: validate_GetBatchPutAttributes_603074, base: "/",
    url: url_GetBatchPutAttributes_603075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDomain_603118 = ref object of OpenApiRestCall_602450
proc url_PostCreateDomain_603120(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDomain_603119(path: JsonNode; query: JsonNode;
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
  var valid_603121 = query.getOrDefault("SignatureMethod")
  valid_603121 = validateParameter(valid_603121, JString, required = true,
                                 default = nil)
  if valid_603121 != nil:
    section.add "SignatureMethod", valid_603121
  var valid_603122 = query.getOrDefault("Signature")
  valid_603122 = validateParameter(valid_603122, JString, required = true,
                                 default = nil)
  if valid_603122 != nil:
    section.add "Signature", valid_603122
  var valid_603123 = query.getOrDefault("Action")
  valid_603123 = validateParameter(valid_603123, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_603123 != nil:
    section.add "Action", valid_603123
  var valid_603124 = query.getOrDefault("Timestamp")
  valid_603124 = validateParameter(valid_603124, JString, required = true,
                                 default = nil)
  if valid_603124 != nil:
    section.add "Timestamp", valid_603124
  var valid_603125 = query.getOrDefault("SignatureVersion")
  valid_603125 = validateParameter(valid_603125, JString, required = true,
                                 default = nil)
  if valid_603125 != nil:
    section.add "SignatureVersion", valid_603125
  var valid_603126 = query.getOrDefault("AWSAccessKeyId")
  valid_603126 = validateParameter(valid_603126, JString, required = true,
                                 default = nil)
  if valid_603126 != nil:
    section.add "AWSAccessKeyId", valid_603126
  var valid_603127 = query.getOrDefault("Version")
  valid_603127 = validateParameter(valid_603127, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_603127 != nil:
    section.add "Version", valid_603127
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain to create. The name can range between 3 and 255 characters and can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603128 = formData.getOrDefault("DomainName")
  valid_603128 = validateParameter(valid_603128, JString, required = true,
                                 default = nil)
  if valid_603128 != nil:
    section.add "DomainName", valid_603128
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_PostCreateDomain_603118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_PostCreateDomain_603118; SignatureMethod: string;
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
  var query_603131 = newJObject()
  var formData_603132 = newJObject()
  add(query_603131, "SignatureMethod", newJString(SignatureMethod))
  add(formData_603132, "DomainName", newJString(DomainName))
  add(query_603131, "Signature", newJString(Signature))
  add(query_603131, "Action", newJString(Action))
  add(query_603131, "Timestamp", newJString(Timestamp))
  add(query_603131, "SignatureVersion", newJString(SignatureVersion))
  add(query_603131, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603131, "Version", newJString(Version))
  result = call_603130.call(nil, query_603131, nil, formData_603132, nil)

var postCreateDomain* = Call_PostCreateDomain_603118(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_603119,
    base: "/", url: url_PostCreateDomain_603120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_603104 = ref object of OpenApiRestCall_602450
proc url_GetCreateDomain_603106(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDomain_603105(path: JsonNode; query: JsonNode;
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
  var valid_603107 = query.getOrDefault("SignatureMethod")
  valid_603107 = validateParameter(valid_603107, JString, required = true,
                                 default = nil)
  if valid_603107 != nil:
    section.add "SignatureMethod", valid_603107
  var valid_603108 = query.getOrDefault("Signature")
  valid_603108 = validateParameter(valid_603108, JString, required = true,
                                 default = nil)
  if valid_603108 != nil:
    section.add "Signature", valid_603108
  var valid_603109 = query.getOrDefault("Action")
  valid_603109 = validateParameter(valid_603109, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_603109 != nil:
    section.add "Action", valid_603109
  var valid_603110 = query.getOrDefault("Timestamp")
  valid_603110 = validateParameter(valid_603110, JString, required = true,
                                 default = nil)
  if valid_603110 != nil:
    section.add "Timestamp", valid_603110
  var valid_603111 = query.getOrDefault("SignatureVersion")
  valid_603111 = validateParameter(valid_603111, JString, required = true,
                                 default = nil)
  if valid_603111 != nil:
    section.add "SignatureVersion", valid_603111
  var valid_603112 = query.getOrDefault("AWSAccessKeyId")
  valid_603112 = validateParameter(valid_603112, JString, required = true,
                                 default = nil)
  if valid_603112 != nil:
    section.add "AWSAccessKeyId", valid_603112
  var valid_603113 = query.getOrDefault("DomainName")
  valid_603113 = validateParameter(valid_603113, JString, required = true,
                                 default = nil)
  if valid_603113 != nil:
    section.add "DomainName", valid_603113
  var valid_603114 = query.getOrDefault("Version")
  valid_603114 = validateParameter(valid_603114, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_603114 != nil:
    section.add "Version", valid_603114
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603115: Call_GetCreateDomain_603104; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  let valid = call_603115.validator(path, query, header, formData, body)
  let scheme = call_603115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603115.url(scheme.get, call_603115.host, call_603115.base,
                         call_603115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603115, url, valid)

proc call*(call_603116: Call_GetCreateDomain_603104; SignatureMethod: string;
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
  var query_603117 = newJObject()
  add(query_603117, "SignatureMethod", newJString(SignatureMethod))
  add(query_603117, "Signature", newJString(Signature))
  add(query_603117, "Action", newJString(Action))
  add(query_603117, "Timestamp", newJString(Timestamp))
  add(query_603117, "SignatureVersion", newJString(SignatureVersion))
  add(query_603117, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603117, "DomainName", newJString(DomainName))
  add(query_603117, "Version", newJString(Version))
  result = call_603116.call(nil, query_603117, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_603104(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_603105,
    base: "/", url: url_GetCreateDomain_603106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAttributes_603152 = ref object of OpenApiRestCall_602450
proc url_PostDeleteAttributes_603154(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteAttributes_603153(path: JsonNode; query: JsonNode;
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
  var valid_603155 = query.getOrDefault("SignatureMethod")
  valid_603155 = validateParameter(valid_603155, JString, required = true,
                                 default = nil)
  if valid_603155 != nil:
    section.add "SignatureMethod", valid_603155
  var valid_603156 = query.getOrDefault("Signature")
  valid_603156 = validateParameter(valid_603156, JString, required = true,
                                 default = nil)
  if valid_603156 != nil:
    section.add "Signature", valid_603156
  var valid_603157 = query.getOrDefault("Action")
  valid_603157 = validateParameter(valid_603157, JString, required = true,
                                 default = newJString("DeleteAttributes"))
  if valid_603157 != nil:
    section.add "Action", valid_603157
  var valid_603158 = query.getOrDefault("Timestamp")
  valid_603158 = validateParameter(valid_603158, JString, required = true,
                                 default = nil)
  if valid_603158 != nil:
    section.add "Timestamp", valid_603158
  var valid_603159 = query.getOrDefault("SignatureVersion")
  valid_603159 = validateParameter(valid_603159, JString, required = true,
                                 default = nil)
  if valid_603159 != nil:
    section.add "SignatureVersion", valid_603159
  var valid_603160 = query.getOrDefault("AWSAccessKeyId")
  valid_603160 = validateParameter(valid_603160, JString, required = true,
                                 default = nil)
  if valid_603160 != nil:
    section.add "AWSAccessKeyId", valid_603160
  var valid_603161 = query.getOrDefault("Version")
  valid_603161 = validateParameter(valid_603161, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_603161 != nil:
    section.add "Version", valid_603161
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
  var valid_603162 = formData.getOrDefault("DomainName")
  valid_603162 = validateParameter(valid_603162, JString, required = true,
                                 default = nil)
  if valid_603162 != nil:
    section.add "DomainName", valid_603162
  var valid_603163 = formData.getOrDefault("ItemName")
  valid_603163 = validateParameter(valid_603163, JString, required = true,
                                 default = nil)
  if valid_603163 != nil:
    section.add "ItemName", valid_603163
  var valid_603164 = formData.getOrDefault("Expected.Exists")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "Expected.Exists", valid_603164
  var valid_603165 = formData.getOrDefault("Attributes")
  valid_603165 = validateParameter(valid_603165, JArray, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "Attributes", valid_603165
  var valid_603166 = formData.getOrDefault("Expected.Value")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "Expected.Value", valid_603166
  var valid_603167 = formData.getOrDefault("Expected.Name")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "Expected.Name", valid_603167
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603168: Call_PostDeleteAttributes_603152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  let valid = call_603168.validator(path, query, header, formData, body)
  let scheme = call_603168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603168.url(scheme.get, call_603168.host, call_603168.base,
                         call_603168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603168, url, valid)

proc call*(call_603169: Call_PostDeleteAttributes_603152; SignatureMethod: string;
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
  var query_603170 = newJObject()
  var formData_603171 = newJObject()
  add(query_603170, "SignatureMethod", newJString(SignatureMethod))
  add(formData_603171, "DomainName", newJString(DomainName))
  add(formData_603171, "ItemName", newJString(ItemName))
  add(formData_603171, "Expected.Exists", newJString(ExpectedExists))
  add(query_603170, "Signature", newJString(Signature))
  if Attributes != nil:
    formData_603171.add "Attributes", Attributes
  add(query_603170, "Action", newJString(Action))
  add(query_603170, "Timestamp", newJString(Timestamp))
  add(formData_603171, "Expected.Value", newJString(ExpectedValue))
  add(formData_603171, "Expected.Name", newJString(ExpectedName))
  add(query_603170, "SignatureVersion", newJString(SignatureVersion))
  add(query_603170, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603170, "Version", newJString(Version))
  result = call_603169.call(nil, query_603170, nil, formData_603171, nil)

var postDeleteAttributes* = Call_PostDeleteAttributes_603152(
    name: "postDeleteAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=DeleteAttributes",
    validator: validate_PostDeleteAttributes_603153, base: "/",
    url: url_PostDeleteAttributes_603154, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAttributes_603133 = ref object of OpenApiRestCall_602450
proc url_GetDeleteAttributes_603135(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteAttributes_603134(path: JsonNode; query: JsonNode;
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
  var valid_603136 = query.getOrDefault("SignatureMethod")
  valid_603136 = validateParameter(valid_603136, JString, required = true,
                                 default = nil)
  if valid_603136 != nil:
    section.add "SignatureMethod", valid_603136
  var valid_603137 = query.getOrDefault("Expected.Exists")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "Expected.Exists", valid_603137
  var valid_603138 = query.getOrDefault("Attributes")
  valid_603138 = validateParameter(valid_603138, JArray, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "Attributes", valid_603138
  var valid_603139 = query.getOrDefault("Signature")
  valid_603139 = validateParameter(valid_603139, JString, required = true,
                                 default = nil)
  if valid_603139 != nil:
    section.add "Signature", valid_603139
  var valid_603140 = query.getOrDefault("ItemName")
  valid_603140 = validateParameter(valid_603140, JString, required = true,
                                 default = nil)
  if valid_603140 != nil:
    section.add "ItemName", valid_603140
  var valid_603141 = query.getOrDefault("Action")
  valid_603141 = validateParameter(valid_603141, JString, required = true,
                                 default = newJString("DeleteAttributes"))
  if valid_603141 != nil:
    section.add "Action", valid_603141
  var valid_603142 = query.getOrDefault("Expected.Value")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "Expected.Value", valid_603142
  var valid_603143 = query.getOrDefault("Timestamp")
  valid_603143 = validateParameter(valid_603143, JString, required = true,
                                 default = nil)
  if valid_603143 != nil:
    section.add "Timestamp", valid_603143
  var valid_603144 = query.getOrDefault("SignatureVersion")
  valid_603144 = validateParameter(valid_603144, JString, required = true,
                                 default = nil)
  if valid_603144 != nil:
    section.add "SignatureVersion", valid_603144
  var valid_603145 = query.getOrDefault("AWSAccessKeyId")
  valid_603145 = validateParameter(valid_603145, JString, required = true,
                                 default = nil)
  if valid_603145 != nil:
    section.add "AWSAccessKeyId", valid_603145
  var valid_603146 = query.getOrDefault("Expected.Name")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "Expected.Name", valid_603146
  var valid_603147 = query.getOrDefault("DomainName")
  valid_603147 = validateParameter(valid_603147, JString, required = true,
                                 default = nil)
  if valid_603147 != nil:
    section.add "DomainName", valid_603147
  var valid_603148 = query.getOrDefault("Version")
  valid_603148 = validateParameter(valid_603148, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_603148 != nil:
    section.add "Version", valid_603148
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603149: Call_GetDeleteAttributes_603133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  let valid = call_603149.validator(path, query, header, formData, body)
  let scheme = call_603149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603149.url(scheme.get, call_603149.host, call_603149.base,
                         call_603149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603149, url, valid)

proc call*(call_603150: Call_GetDeleteAttributes_603133; SignatureMethod: string;
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
  var query_603151 = newJObject()
  add(query_603151, "SignatureMethod", newJString(SignatureMethod))
  add(query_603151, "Expected.Exists", newJString(ExpectedExists))
  if Attributes != nil:
    query_603151.add "Attributes", Attributes
  add(query_603151, "Signature", newJString(Signature))
  add(query_603151, "ItemName", newJString(ItemName))
  add(query_603151, "Action", newJString(Action))
  add(query_603151, "Expected.Value", newJString(ExpectedValue))
  add(query_603151, "Timestamp", newJString(Timestamp))
  add(query_603151, "SignatureVersion", newJString(SignatureVersion))
  add(query_603151, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603151, "Expected.Name", newJString(ExpectedName))
  add(query_603151, "DomainName", newJString(DomainName))
  add(query_603151, "Version", newJString(Version))
  result = call_603150.call(nil, query_603151, nil, nil, nil)

var getDeleteAttributes* = Call_GetDeleteAttributes_603133(
    name: "getDeleteAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=DeleteAttributes",
    validator: validate_GetDeleteAttributes_603134, base: "/",
    url: url_GetDeleteAttributes_603135, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_603186 = ref object of OpenApiRestCall_602450
proc url_PostDeleteDomain_603188(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDomain_603187(path: JsonNode; query: JsonNode;
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
  var valid_603189 = query.getOrDefault("SignatureMethod")
  valid_603189 = validateParameter(valid_603189, JString, required = true,
                                 default = nil)
  if valid_603189 != nil:
    section.add "SignatureMethod", valid_603189
  var valid_603190 = query.getOrDefault("Signature")
  valid_603190 = validateParameter(valid_603190, JString, required = true,
                                 default = nil)
  if valid_603190 != nil:
    section.add "Signature", valid_603190
  var valid_603191 = query.getOrDefault("Action")
  valid_603191 = validateParameter(valid_603191, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_603191 != nil:
    section.add "Action", valid_603191
  var valid_603192 = query.getOrDefault("Timestamp")
  valid_603192 = validateParameter(valid_603192, JString, required = true,
                                 default = nil)
  if valid_603192 != nil:
    section.add "Timestamp", valid_603192
  var valid_603193 = query.getOrDefault("SignatureVersion")
  valid_603193 = validateParameter(valid_603193, JString, required = true,
                                 default = nil)
  if valid_603193 != nil:
    section.add "SignatureVersion", valid_603193
  var valid_603194 = query.getOrDefault("AWSAccessKeyId")
  valid_603194 = validateParameter(valid_603194, JString, required = true,
                                 default = nil)
  if valid_603194 != nil:
    section.add "AWSAccessKeyId", valid_603194
  var valid_603195 = query.getOrDefault("Version")
  valid_603195 = validateParameter(valid_603195, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_603195 != nil:
    section.add "Version", valid_603195
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603196 = formData.getOrDefault("DomainName")
  valid_603196 = validateParameter(valid_603196, JString, required = true,
                                 default = nil)
  if valid_603196 != nil:
    section.add "DomainName", valid_603196
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603197: Call_PostDeleteDomain_603186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  let valid = call_603197.validator(path, query, header, formData, body)
  let scheme = call_603197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603197.url(scheme.get, call_603197.host, call_603197.base,
                         call_603197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603197, url, valid)

proc call*(call_603198: Call_PostDeleteDomain_603186; SignatureMethod: string;
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
  var query_603199 = newJObject()
  var formData_603200 = newJObject()
  add(query_603199, "SignatureMethod", newJString(SignatureMethod))
  add(formData_603200, "DomainName", newJString(DomainName))
  add(query_603199, "Signature", newJString(Signature))
  add(query_603199, "Action", newJString(Action))
  add(query_603199, "Timestamp", newJString(Timestamp))
  add(query_603199, "SignatureVersion", newJString(SignatureVersion))
  add(query_603199, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603199, "Version", newJString(Version))
  result = call_603198.call(nil, query_603199, nil, formData_603200, nil)

var postDeleteDomain* = Call_PostDeleteDomain_603186(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_603187,
    base: "/", url: url_PostDeleteDomain_603188,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_603172 = ref object of OpenApiRestCall_602450
proc url_GetDeleteDomain_603174(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDomain_603173(path: JsonNode; query: JsonNode;
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
  var valid_603175 = query.getOrDefault("SignatureMethod")
  valid_603175 = validateParameter(valid_603175, JString, required = true,
                                 default = nil)
  if valid_603175 != nil:
    section.add "SignatureMethod", valid_603175
  var valid_603176 = query.getOrDefault("Signature")
  valid_603176 = validateParameter(valid_603176, JString, required = true,
                                 default = nil)
  if valid_603176 != nil:
    section.add "Signature", valid_603176
  var valid_603177 = query.getOrDefault("Action")
  valid_603177 = validateParameter(valid_603177, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_603177 != nil:
    section.add "Action", valid_603177
  var valid_603178 = query.getOrDefault("Timestamp")
  valid_603178 = validateParameter(valid_603178, JString, required = true,
                                 default = nil)
  if valid_603178 != nil:
    section.add "Timestamp", valid_603178
  var valid_603179 = query.getOrDefault("SignatureVersion")
  valid_603179 = validateParameter(valid_603179, JString, required = true,
                                 default = nil)
  if valid_603179 != nil:
    section.add "SignatureVersion", valid_603179
  var valid_603180 = query.getOrDefault("AWSAccessKeyId")
  valid_603180 = validateParameter(valid_603180, JString, required = true,
                                 default = nil)
  if valid_603180 != nil:
    section.add "AWSAccessKeyId", valid_603180
  var valid_603181 = query.getOrDefault("DomainName")
  valid_603181 = validateParameter(valid_603181, JString, required = true,
                                 default = nil)
  if valid_603181 != nil:
    section.add "DomainName", valid_603181
  var valid_603182 = query.getOrDefault("Version")
  valid_603182 = validateParameter(valid_603182, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_603182 != nil:
    section.add "Version", valid_603182
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603183: Call_GetDeleteDomain_603172; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  let valid = call_603183.validator(path, query, header, formData, body)
  let scheme = call_603183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603183.url(scheme.get, call_603183.host, call_603183.base,
                         call_603183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603183, url, valid)

proc call*(call_603184: Call_GetDeleteDomain_603172; SignatureMethod: string;
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
  var query_603185 = newJObject()
  add(query_603185, "SignatureMethod", newJString(SignatureMethod))
  add(query_603185, "Signature", newJString(Signature))
  add(query_603185, "Action", newJString(Action))
  add(query_603185, "Timestamp", newJString(Timestamp))
  add(query_603185, "SignatureVersion", newJString(SignatureVersion))
  add(query_603185, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603185, "DomainName", newJString(DomainName))
  add(query_603185, "Version", newJString(Version))
  result = call_603184.call(nil, query_603185, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_603172(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_603173,
    base: "/", url: url_GetDeleteDomain_603174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDomainMetadata_603215 = ref object of OpenApiRestCall_602450
proc url_PostDomainMetadata_603217(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDomainMetadata_603216(path: JsonNode; query: JsonNode;
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
  var valid_603218 = query.getOrDefault("SignatureMethod")
  valid_603218 = validateParameter(valid_603218, JString, required = true,
                                 default = nil)
  if valid_603218 != nil:
    section.add "SignatureMethod", valid_603218
  var valid_603219 = query.getOrDefault("Signature")
  valid_603219 = validateParameter(valid_603219, JString, required = true,
                                 default = nil)
  if valid_603219 != nil:
    section.add "Signature", valid_603219
  var valid_603220 = query.getOrDefault("Action")
  valid_603220 = validateParameter(valid_603220, JString, required = true,
                                 default = newJString("DomainMetadata"))
  if valid_603220 != nil:
    section.add "Action", valid_603220
  var valid_603221 = query.getOrDefault("Timestamp")
  valid_603221 = validateParameter(valid_603221, JString, required = true,
                                 default = nil)
  if valid_603221 != nil:
    section.add "Timestamp", valid_603221
  var valid_603222 = query.getOrDefault("SignatureVersion")
  valid_603222 = validateParameter(valid_603222, JString, required = true,
                                 default = nil)
  if valid_603222 != nil:
    section.add "SignatureVersion", valid_603222
  var valid_603223 = query.getOrDefault("AWSAccessKeyId")
  valid_603223 = validateParameter(valid_603223, JString, required = true,
                                 default = nil)
  if valid_603223 != nil:
    section.add "AWSAccessKeyId", valid_603223
  var valid_603224 = query.getOrDefault("Version")
  valid_603224 = validateParameter(valid_603224, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_603224 != nil:
    section.add "Version", valid_603224
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain for which to display the metadata of.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603225 = formData.getOrDefault("DomainName")
  valid_603225 = validateParameter(valid_603225, JString, required = true,
                                 default = nil)
  if valid_603225 != nil:
    section.add "DomainName", valid_603225
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603226: Call_PostDomainMetadata_603215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  let valid = call_603226.validator(path, query, header, formData, body)
  let scheme = call_603226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603226.url(scheme.get, call_603226.host, call_603226.base,
                         call_603226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603226, url, valid)

proc call*(call_603227: Call_PostDomainMetadata_603215; SignatureMethod: string;
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
  var query_603228 = newJObject()
  var formData_603229 = newJObject()
  add(query_603228, "SignatureMethod", newJString(SignatureMethod))
  add(formData_603229, "DomainName", newJString(DomainName))
  add(query_603228, "Signature", newJString(Signature))
  add(query_603228, "Action", newJString(Action))
  add(query_603228, "Timestamp", newJString(Timestamp))
  add(query_603228, "SignatureVersion", newJString(SignatureVersion))
  add(query_603228, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603228, "Version", newJString(Version))
  result = call_603227.call(nil, query_603228, nil, formData_603229, nil)

var postDomainMetadata* = Call_PostDomainMetadata_603215(
    name: "postDomainMetadata", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=DomainMetadata",
    validator: validate_PostDomainMetadata_603216, base: "/",
    url: url_PostDomainMetadata_603217, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainMetadata_603201 = ref object of OpenApiRestCall_602450
proc url_GetDomainMetadata_603203(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDomainMetadata_603202(path: JsonNode; query: JsonNode;
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
  var valid_603204 = query.getOrDefault("SignatureMethod")
  valid_603204 = validateParameter(valid_603204, JString, required = true,
                                 default = nil)
  if valid_603204 != nil:
    section.add "SignatureMethod", valid_603204
  var valid_603205 = query.getOrDefault("Signature")
  valid_603205 = validateParameter(valid_603205, JString, required = true,
                                 default = nil)
  if valid_603205 != nil:
    section.add "Signature", valid_603205
  var valid_603206 = query.getOrDefault("Action")
  valid_603206 = validateParameter(valid_603206, JString, required = true,
                                 default = newJString("DomainMetadata"))
  if valid_603206 != nil:
    section.add "Action", valid_603206
  var valid_603207 = query.getOrDefault("Timestamp")
  valid_603207 = validateParameter(valid_603207, JString, required = true,
                                 default = nil)
  if valid_603207 != nil:
    section.add "Timestamp", valid_603207
  var valid_603208 = query.getOrDefault("SignatureVersion")
  valid_603208 = validateParameter(valid_603208, JString, required = true,
                                 default = nil)
  if valid_603208 != nil:
    section.add "SignatureVersion", valid_603208
  var valid_603209 = query.getOrDefault("AWSAccessKeyId")
  valid_603209 = validateParameter(valid_603209, JString, required = true,
                                 default = nil)
  if valid_603209 != nil:
    section.add "AWSAccessKeyId", valid_603209
  var valid_603210 = query.getOrDefault("DomainName")
  valid_603210 = validateParameter(valid_603210, JString, required = true,
                                 default = nil)
  if valid_603210 != nil:
    section.add "DomainName", valid_603210
  var valid_603211 = query.getOrDefault("Version")
  valid_603211 = validateParameter(valid_603211, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_603211 != nil:
    section.add "Version", valid_603211
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603212: Call_GetDomainMetadata_603201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  let valid = call_603212.validator(path, query, header, formData, body)
  let scheme = call_603212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603212.url(scheme.get, call_603212.host, call_603212.base,
                         call_603212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603212, url, valid)

proc call*(call_603213: Call_GetDomainMetadata_603201; SignatureMethod: string;
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
  var query_603214 = newJObject()
  add(query_603214, "SignatureMethod", newJString(SignatureMethod))
  add(query_603214, "Signature", newJString(Signature))
  add(query_603214, "Action", newJString(Action))
  add(query_603214, "Timestamp", newJString(Timestamp))
  add(query_603214, "SignatureVersion", newJString(SignatureVersion))
  add(query_603214, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603214, "DomainName", newJString(DomainName))
  add(query_603214, "Version", newJString(Version))
  result = call_603213.call(nil, query_603214, nil, nil, nil)

var getDomainMetadata* = Call_GetDomainMetadata_603201(name: "getDomainMetadata",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=DomainMetadata", validator: validate_GetDomainMetadata_603202,
    base: "/", url: url_GetDomainMetadata_603203,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetAttributes_603247 = ref object of OpenApiRestCall_602450
proc url_PostGetAttributes_603249(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetAttributes_603248(path: JsonNode; query: JsonNode;
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
  var valid_603250 = query.getOrDefault("SignatureMethod")
  valid_603250 = validateParameter(valid_603250, JString, required = true,
                                 default = nil)
  if valid_603250 != nil:
    section.add "SignatureMethod", valid_603250
  var valid_603251 = query.getOrDefault("Signature")
  valid_603251 = validateParameter(valid_603251, JString, required = true,
                                 default = nil)
  if valid_603251 != nil:
    section.add "Signature", valid_603251
  var valid_603252 = query.getOrDefault("Action")
  valid_603252 = validateParameter(valid_603252, JString, required = true,
                                 default = newJString("GetAttributes"))
  if valid_603252 != nil:
    section.add "Action", valid_603252
  var valid_603253 = query.getOrDefault("Timestamp")
  valid_603253 = validateParameter(valid_603253, JString, required = true,
                                 default = nil)
  if valid_603253 != nil:
    section.add "Timestamp", valid_603253
  var valid_603254 = query.getOrDefault("SignatureVersion")
  valid_603254 = validateParameter(valid_603254, JString, required = true,
                                 default = nil)
  if valid_603254 != nil:
    section.add "SignatureVersion", valid_603254
  var valid_603255 = query.getOrDefault("AWSAccessKeyId")
  valid_603255 = validateParameter(valid_603255, JString, required = true,
                                 default = nil)
  if valid_603255 != nil:
    section.add "AWSAccessKeyId", valid_603255
  var valid_603256 = query.getOrDefault("Version")
  valid_603256 = validateParameter(valid_603256, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_603256 != nil:
    section.add "Version", valid_603256
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
  var valid_603257 = formData.getOrDefault("DomainName")
  valid_603257 = validateParameter(valid_603257, JString, required = true,
                                 default = nil)
  if valid_603257 != nil:
    section.add "DomainName", valid_603257
  var valid_603258 = formData.getOrDefault("ItemName")
  valid_603258 = validateParameter(valid_603258, JString, required = true,
                                 default = nil)
  if valid_603258 != nil:
    section.add "ItemName", valid_603258
  var valid_603259 = formData.getOrDefault("ConsistentRead")
  valid_603259 = validateParameter(valid_603259, JBool, required = false, default = nil)
  if valid_603259 != nil:
    section.add "ConsistentRead", valid_603259
  var valid_603260 = formData.getOrDefault("AttributeNames")
  valid_603260 = validateParameter(valid_603260, JArray, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "AttributeNames", valid_603260
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603261: Call_PostGetAttributes_603247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  let valid = call_603261.validator(path, query, header, formData, body)
  let scheme = call_603261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603261.url(scheme.get, call_603261.host, call_603261.base,
                         call_603261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603261, url, valid)

proc call*(call_603262: Call_PostGetAttributes_603247; SignatureMethod: string;
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
  var query_603263 = newJObject()
  var formData_603264 = newJObject()
  add(query_603263, "SignatureMethod", newJString(SignatureMethod))
  add(formData_603264, "DomainName", newJString(DomainName))
  add(formData_603264, "ItemName", newJString(ItemName))
  add(formData_603264, "ConsistentRead", newJBool(ConsistentRead))
  add(query_603263, "Signature", newJString(Signature))
  add(query_603263, "Action", newJString(Action))
  add(query_603263, "Timestamp", newJString(Timestamp))
  if AttributeNames != nil:
    formData_603264.add "AttributeNames", AttributeNames
  add(query_603263, "SignatureVersion", newJString(SignatureVersion))
  add(query_603263, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603263, "Version", newJString(Version))
  result = call_603262.call(nil, query_603263, nil, formData_603264, nil)

var postGetAttributes* = Call_PostGetAttributes_603247(name: "postGetAttributes",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=GetAttributes", validator: validate_PostGetAttributes_603248,
    base: "/", url: url_PostGetAttributes_603249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetAttributes_603230 = ref object of OpenApiRestCall_602450
proc url_GetGetAttributes_603232(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetAttributes_603231(path: JsonNode; query: JsonNode;
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
  var valid_603233 = query.getOrDefault("SignatureMethod")
  valid_603233 = validateParameter(valid_603233, JString, required = true,
                                 default = nil)
  if valid_603233 != nil:
    section.add "SignatureMethod", valid_603233
  var valid_603234 = query.getOrDefault("AttributeNames")
  valid_603234 = validateParameter(valid_603234, JArray, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "AttributeNames", valid_603234
  var valid_603235 = query.getOrDefault("Signature")
  valid_603235 = validateParameter(valid_603235, JString, required = true,
                                 default = nil)
  if valid_603235 != nil:
    section.add "Signature", valid_603235
  var valid_603236 = query.getOrDefault("ItemName")
  valid_603236 = validateParameter(valid_603236, JString, required = true,
                                 default = nil)
  if valid_603236 != nil:
    section.add "ItemName", valid_603236
  var valid_603237 = query.getOrDefault("Action")
  valid_603237 = validateParameter(valid_603237, JString, required = true,
                                 default = newJString("GetAttributes"))
  if valid_603237 != nil:
    section.add "Action", valid_603237
  var valid_603238 = query.getOrDefault("Timestamp")
  valid_603238 = validateParameter(valid_603238, JString, required = true,
                                 default = nil)
  if valid_603238 != nil:
    section.add "Timestamp", valid_603238
  var valid_603239 = query.getOrDefault("ConsistentRead")
  valid_603239 = validateParameter(valid_603239, JBool, required = false, default = nil)
  if valid_603239 != nil:
    section.add "ConsistentRead", valid_603239
  var valid_603240 = query.getOrDefault("SignatureVersion")
  valid_603240 = validateParameter(valid_603240, JString, required = true,
                                 default = nil)
  if valid_603240 != nil:
    section.add "SignatureVersion", valid_603240
  var valid_603241 = query.getOrDefault("AWSAccessKeyId")
  valid_603241 = validateParameter(valid_603241, JString, required = true,
                                 default = nil)
  if valid_603241 != nil:
    section.add "AWSAccessKeyId", valid_603241
  var valid_603242 = query.getOrDefault("DomainName")
  valid_603242 = validateParameter(valid_603242, JString, required = true,
                                 default = nil)
  if valid_603242 != nil:
    section.add "DomainName", valid_603242
  var valid_603243 = query.getOrDefault("Version")
  valid_603243 = validateParameter(valid_603243, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_603243 != nil:
    section.add "Version", valid_603243
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603244: Call_GetGetAttributes_603230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  let valid = call_603244.validator(path, query, header, formData, body)
  let scheme = call_603244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603244.url(scheme.get, call_603244.host, call_603244.base,
                         call_603244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603244, url, valid)

proc call*(call_603245: Call_GetGetAttributes_603230; SignatureMethod: string;
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
  var query_603246 = newJObject()
  add(query_603246, "SignatureMethod", newJString(SignatureMethod))
  if AttributeNames != nil:
    query_603246.add "AttributeNames", AttributeNames
  add(query_603246, "Signature", newJString(Signature))
  add(query_603246, "ItemName", newJString(ItemName))
  add(query_603246, "Action", newJString(Action))
  add(query_603246, "Timestamp", newJString(Timestamp))
  add(query_603246, "ConsistentRead", newJBool(ConsistentRead))
  add(query_603246, "SignatureVersion", newJString(SignatureVersion))
  add(query_603246, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603246, "DomainName", newJString(DomainName))
  add(query_603246, "Version", newJString(Version))
  result = call_603245.call(nil, query_603246, nil, nil, nil)

var getGetAttributes* = Call_GetGetAttributes_603230(name: "getGetAttributes",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=GetAttributes", validator: validate_GetGetAttributes_603231,
    base: "/", url: url_GetGetAttributes_603232,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDomains_603280 = ref object of OpenApiRestCall_602450
proc url_PostListDomains_603282(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListDomains_603281(path: JsonNode; query: JsonNode;
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
  var valid_603283 = query.getOrDefault("SignatureMethod")
  valid_603283 = validateParameter(valid_603283, JString, required = true,
                                 default = nil)
  if valid_603283 != nil:
    section.add "SignatureMethod", valid_603283
  var valid_603284 = query.getOrDefault("Signature")
  valid_603284 = validateParameter(valid_603284, JString, required = true,
                                 default = nil)
  if valid_603284 != nil:
    section.add "Signature", valid_603284
  var valid_603285 = query.getOrDefault("Action")
  valid_603285 = validateParameter(valid_603285, JString, required = true,
                                 default = newJString("ListDomains"))
  if valid_603285 != nil:
    section.add "Action", valid_603285
  var valid_603286 = query.getOrDefault("Timestamp")
  valid_603286 = validateParameter(valid_603286, JString, required = true,
                                 default = nil)
  if valid_603286 != nil:
    section.add "Timestamp", valid_603286
  var valid_603287 = query.getOrDefault("SignatureVersion")
  valid_603287 = validateParameter(valid_603287, JString, required = true,
                                 default = nil)
  if valid_603287 != nil:
    section.add "SignatureVersion", valid_603287
  var valid_603288 = query.getOrDefault("AWSAccessKeyId")
  valid_603288 = validateParameter(valid_603288, JString, required = true,
                                 default = nil)
  if valid_603288 != nil:
    section.add "AWSAccessKeyId", valid_603288
  var valid_603289 = query.getOrDefault("Version")
  valid_603289 = validateParameter(valid_603289, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_603289 != nil:
    section.add "Version", valid_603289
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : A string informing Amazon SimpleDB where to start the next list of domain names.
  ##   MaxNumberOfDomains: JInt
  ##                     : The maximum number of domain names you want returned. The range is 1 to 100. The default setting is 100.
  section = newJObject()
  var valid_603290 = formData.getOrDefault("NextToken")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "NextToken", valid_603290
  var valid_603291 = formData.getOrDefault("MaxNumberOfDomains")
  valid_603291 = validateParameter(valid_603291, JInt, required = false, default = nil)
  if valid_603291 != nil:
    section.add "MaxNumberOfDomains", valid_603291
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603292: Call_PostListDomains_603280; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  let valid = call_603292.validator(path, query, header, formData, body)
  let scheme = call_603292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603292.url(scheme.get, call_603292.host, call_603292.base,
                         call_603292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603292, url, valid)

proc call*(call_603293: Call_PostListDomains_603280; SignatureMethod: string;
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
  var query_603294 = newJObject()
  var formData_603295 = newJObject()
  add(formData_603295, "NextToken", newJString(NextToken))
  add(query_603294, "SignatureMethod", newJString(SignatureMethod))
  add(query_603294, "Signature", newJString(Signature))
  add(query_603294, "Action", newJString(Action))
  add(query_603294, "Timestamp", newJString(Timestamp))
  add(query_603294, "SignatureVersion", newJString(SignatureVersion))
  add(query_603294, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_603295, "MaxNumberOfDomains", newJInt(MaxNumberOfDomains))
  add(query_603294, "Version", newJString(Version))
  result = call_603293.call(nil, query_603294, nil, formData_603295, nil)

var postListDomains* = Call_PostListDomains_603280(name: "postListDomains",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=ListDomains", validator: validate_PostListDomains_603281,
    base: "/", url: url_PostListDomains_603282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDomains_603265 = ref object of OpenApiRestCall_602450
proc url_GetListDomains_603267(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListDomains_603266(path: JsonNode; query: JsonNode;
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
  var valid_603268 = query.getOrDefault("SignatureMethod")
  valid_603268 = validateParameter(valid_603268, JString, required = true,
                                 default = nil)
  if valid_603268 != nil:
    section.add "SignatureMethod", valid_603268
  var valid_603269 = query.getOrDefault("Signature")
  valid_603269 = validateParameter(valid_603269, JString, required = true,
                                 default = nil)
  if valid_603269 != nil:
    section.add "Signature", valid_603269
  var valid_603270 = query.getOrDefault("NextToken")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "NextToken", valid_603270
  var valid_603271 = query.getOrDefault("Action")
  valid_603271 = validateParameter(valid_603271, JString, required = true,
                                 default = newJString("ListDomains"))
  if valid_603271 != nil:
    section.add "Action", valid_603271
  var valid_603272 = query.getOrDefault("Timestamp")
  valid_603272 = validateParameter(valid_603272, JString, required = true,
                                 default = nil)
  if valid_603272 != nil:
    section.add "Timestamp", valid_603272
  var valid_603273 = query.getOrDefault("SignatureVersion")
  valid_603273 = validateParameter(valid_603273, JString, required = true,
                                 default = nil)
  if valid_603273 != nil:
    section.add "SignatureVersion", valid_603273
  var valid_603274 = query.getOrDefault("AWSAccessKeyId")
  valid_603274 = validateParameter(valid_603274, JString, required = true,
                                 default = nil)
  if valid_603274 != nil:
    section.add "AWSAccessKeyId", valid_603274
  var valid_603275 = query.getOrDefault("Version")
  valid_603275 = validateParameter(valid_603275, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_603275 != nil:
    section.add "Version", valid_603275
  var valid_603276 = query.getOrDefault("MaxNumberOfDomains")
  valid_603276 = validateParameter(valid_603276, JInt, required = false, default = nil)
  if valid_603276 != nil:
    section.add "MaxNumberOfDomains", valid_603276
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603277: Call_GetListDomains_603265; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  let valid = call_603277.validator(path, query, header, formData, body)
  let scheme = call_603277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603277.url(scheme.get, call_603277.host, call_603277.base,
                         call_603277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603277, url, valid)

proc call*(call_603278: Call_GetListDomains_603265; SignatureMethod: string;
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
  var query_603279 = newJObject()
  add(query_603279, "SignatureMethod", newJString(SignatureMethod))
  add(query_603279, "Signature", newJString(Signature))
  add(query_603279, "NextToken", newJString(NextToken))
  add(query_603279, "Action", newJString(Action))
  add(query_603279, "Timestamp", newJString(Timestamp))
  add(query_603279, "SignatureVersion", newJString(SignatureVersion))
  add(query_603279, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603279, "Version", newJString(Version))
  add(query_603279, "MaxNumberOfDomains", newJInt(MaxNumberOfDomains))
  result = call_603278.call(nil, query_603279, nil, nil, nil)

var getListDomains* = Call_GetListDomains_603265(name: "getListDomains",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=ListDomains", validator: validate_GetListDomains_603266,
    base: "/", url: url_GetListDomains_603267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutAttributes_603315 = ref object of OpenApiRestCall_602450
proc url_PostPutAttributes_603317(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPutAttributes_603316(path: JsonNode; query: JsonNode;
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
  var valid_603318 = query.getOrDefault("SignatureMethod")
  valid_603318 = validateParameter(valid_603318, JString, required = true,
                                 default = nil)
  if valid_603318 != nil:
    section.add "SignatureMethod", valid_603318
  var valid_603319 = query.getOrDefault("Signature")
  valid_603319 = validateParameter(valid_603319, JString, required = true,
                                 default = nil)
  if valid_603319 != nil:
    section.add "Signature", valid_603319
  var valid_603320 = query.getOrDefault("Action")
  valid_603320 = validateParameter(valid_603320, JString, required = true,
                                 default = newJString("PutAttributes"))
  if valid_603320 != nil:
    section.add "Action", valid_603320
  var valid_603321 = query.getOrDefault("Timestamp")
  valid_603321 = validateParameter(valid_603321, JString, required = true,
                                 default = nil)
  if valid_603321 != nil:
    section.add "Timestamp", valid_603321
  var valid_603322 = query.getOrDefault("SignatureVersion")
  valid_603322 = validateParameter(valid_603322, JString, required = true,
                                 default = nil)
  if valid_603322 != nil:
    section.add "SignatureVersion", valid_603322
  var valid_603323 = query.getOrDefault("AWSAccessKeyId")
  valid_603323 = validateParameter(valid_603323, JString, required = true,
                                 default = nil)
  if valid_603323 != nil:
    section.add "AWSAccessKeyId", valid_603323
  var valid_603324 = query.getOrDefault("Version")
  valid_603324 = validateParameter(valid_603324, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_603324 != nil:
    section.add "Version", valid_603324
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
  var valid_603325 = formData.getOrDefault("DomainName")
  valid_603325 = validateParameter(valid_603325, JString, required = true,
                                 default = nil)
  if valid_603325 != nil:
    section.add "DomainName", valid_603325
  var valid_603326 = formData.getOrDefault("ItemName")
  valid_603326 = validateParameter(valid_603326, JString, required = true,
                                 default = nil)
  if valid_603326 != nil:
    section.add "ItemName", valid_603326
  var valid_603327 = formData.getOrDefault("Expected.Exists")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "Expected.Exists", valid_603327
  var valid_603328 = formData.getOrDefault("Attributes")
  valid_603328 = validateParameter(valid_603328, JArray, required = true, default = nil)
  if valid_603328 != nil:
    section.add "Attributes", valid_603328
  var valid_603329 = formData.getOrDefault("Expected.Value")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "Expected.Value", valid_603329
  var valid_603330 = formData.getOrDefault("Expected.Name")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "Expected.Name", valid_603330
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603331: Call_PostPutAttributes_603315; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  let valid = call_603331.validator(path, query, header, formData, body)
  let scheme = call_603331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603331.url(scheme.get, call_603331.host, call_603331.base,
                         call_603331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603331, url, valid)

proc call*(call_603332: Call_PostPutAttributes_603315; SignatureMethod: string;
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
  var query_603333 = newJObject()
  var formData_603334 = newJObject()
  add(query_603333, "SignatureMethod", newJString(SignatureMethod))
  add(formData_603334, "DomainName", newJString(DomainName))
  add(formData_603334, "ItemName", newJString(ItemName))
  add(formData_603334, "Expected.Exists", newJString(ExpectedExists))
  add(query_603333, "Signature", newJString(Signature))
  if Attributes != nil:
    formData_603334.add "Attributes", Attributes
  add(query_603333, "Action", newJString(Action))
  add(query_603333, "Timestamp", newJString(Timestamp))
  add(formData_603334, "Expected.Value", newJString(ExpectedValue))
  add(formData_603334, "Expected.Name", newJString(ExpectedName))
  add(query_603333, "SignatureVersion", newJString(SignatureVersion))
  add(query_603333, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603333, "Version", newJString(Version))
  result = call_603332.call(nil, query_603333, nil, formData_603334, nil)

var postPutAttributes* = Call_PostPutAttributes_603315(name: "postPutAttributes",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=PutAttributes", validator: validate_PostPutAttributes_603316,
    base: "/", url: url_PostPutAttributes_603317,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutAttributes_603296 = ref object of OpenApiRestCall_602450
proc url_GetPutAttributes_603298(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPutAttributes_603297(path: JsonNode; query: JsonNode;
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
  var valid_603299 = query.getOrDefault("SignatureMethod")
  valid_603299 = validateParameter(valid_603299, JString, required = true,
                                 default = nil)
  if valid_603299 != nil:
    section.add "SignatureMethod", valid_603299
  var valid_603300 = query.getOrDefault("Expected.Exists")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "Expected.Exists", valid_603300
  var valid_603301 = query.getOrDefault("Attributes")
  valid_603301 = validateParameter(valid_603301, JArray, required = true, default = nil)
  if valid_603301 != nil:
    section.add "Attributes", valid_603301
  var valid_603302 = query.getOrDefault("Signature")
  valid_603302 = validateParameter(valid_603302, JString, required = true,
                                 default = nil)
  if valid_603302 != nil:
    section.add "Signature", valid_603302
  var valid_603303 = query.getOrDefault("ItemName")
  valid_603303 = validateParameter(valid_603303, JString, required = true,
                                 default = nil)
  if valid_603303 != nil:
    section.add "ItemName", valid_603303
  var valid_603304 = query.getOrDefault("Action")
  valid_603304 = validateParameter(valid_603304, JString, required = true,
                                 default = newJString("PutAttributes"))
  if valid_603304 != nil:
    section.add "Action", valid_603304
  var valid_603305 = query.getOrDefault("Expected.Value")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "Expected.Value", valid_603305
  var valid_603306 = query.getOrDefault("Timestamp")
  valid_603306 = validateParameter(valid_603306, JString, required = true,
                                 default = nil)
  if valid_603306 != nil:
    section.add "Timestamp", valid_603306
  var valid_603307 = query.getOrDefault("SignatureVersion")
  valid_603307 = validateParameter(valid_603307, JString, required = true,
                                 default = nil)
  if valid_603307 != nil:
    section.add "SignatureVersion", valid_603307
  var valid_603308 = query.getOrDefault("AWSAccessKeyId")
  valid_603308 = validateParameter(valid_603308, JString, required = true,
                                 default = nil)
  if valid_603308 != nil:
    section.add "AWSAccessKeyId", valid_603308
  var valid_603309 = query.getOrDefault("Expected.Name")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "Expected.Name", valid_603309
  var valid_603310 = query.getOrDefault("DomainName")
  valid_603310 = validateParameter(valid_603310, JString, required = true,
                                 default = nil)
  if valid_603310 != nil:
    section.add "DomainName", valid_603310
  var valid_603311 = query.getOrDefault("Version")
  valid_603311 = validateParameter(valid_603311, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_603311 != nil:
    section.add "Version", valid_603311
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603312: Call_GetPutAttributes_603296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  let valid = call_603312.validator(path, query, header, formData, body)
  let scheme = call_603312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603312.url(scheme.get, call_603312.host, call_603312.base,
                         call_603312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603312, url, valid)

proc call*(call_603313: Call_GetPutAttributes_603296; SignatureMethod: string;
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
  var query_603314 = newJObject()
  add(query_603314, "SignatureMethod", newJString(SignatureMethod))
  add(query_603314, "Expected.Exists", newJString(ExpectedExists))
  if Attributes != nil:
    query_603314.add "Attributes", Attributes
  add(query_603314, "Signature", newJString(Signature))
  add(query_603314, "ItemName", newJString(ItemName))
  add(query_603314, "Action", newJString(Action))
  add(query_603314, "Expected.Value", newJString(ExpectedValue))
  add(query_603314, "Timestamp", newJString(Timestamp))
  add(query_603314, "SignatureVersion", newJString(SignatureVersion))
  add(query_603314, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603314, "Expected.Name", newJString(ExpectedName))
  add(query_603314, "DomainName", newJString(DomainName))
  add(query_603314, "Version", newJString(Version))
  result = call_603313.call(nil, query_603314, nil, nil, nil)

var getPutAttributes* = Call_GetPutAttributes_603296(name: "getPutAttributes",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=PutAttributes", validator: validate_GetPutAttributes_603297,
    base: "/", url: url_GetPutAttributes_603298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSelect_603351 = ref object of OpenApiRestCall_602450
proc url_PostSelect_603353(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSelect_603352(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603354 = query.getOrDefault("SignatureMethod")
  valid_603354 = validateParameter(valid_603354, JString, required = true,
                                 default = nil)
  if valid_603354 != nil:
    section.add "SignatureMethod", valid_603354
  var valid_603355 = query.getOrDefault("Signature")
  valid_603355 = validateParameter(valid_603355, JString, required = true,
                                 default = nil)
  if valid_603355 != nil:
    section.add "Signature", valid_603355
  var valid_603356 = query.getOrDefault("Action")
  valid_603356 = validateParameter(valid_603356, JString, required = true,
                                 default = newJString("Select"))
  if valid_603356 != nil:
    section.add "Action", valid_603356
  var valid_603357 = query.getOrDefault("Timestamp")
  valid_603357 = validateParameter(valid_603357, JString, required = true,
                                 default = nil)
  if valid_603357 != nil:
    section.add "Timestamp", valid_603357
  var valid_603358 = query.getOrDefault("SignatureVersion")
  valid_603358 = validateParameter(valid_603358, JString, required = true,
                                 default = nil)
  if valid_603358 != nil:
    section.add "SignatureVersion", valid_603358
  var valid_603359 = query.getOrDefault("AWSAccessKeyId")
  valid_603359 = validateParameter(valid_603359, JString, required = true,
                                 default = nil)
  if valid_603359 != nil:
    section.add "AWSAccessKeyId", valid_603359
  var valid_603360 = query.getOrDefault("Version")
  valid_603360 = validateParameter(valid_603360, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_603360 != nil:
    section.add "Version", valid_603360
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
  var valid_603361 = formData.getOrDefault("NextToken")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "NextToken", valid_603361
  var valid_603362 = formData.getOrDefault("ConsistentRead")
  valid_603362 = validateParameter(valid_603362, JBool, required = false, default = nil)
  if valid_603362 != nil:
    section.add "ConsistentRead", valid_603362
  assert formData != nil, "formData argument is necessary due to required `SelectExpression` field"
  var valid_603363 = formData.getOrDefault("SelectExpression")
  valid_603363 = validateParameter(valid_603363, JString, required = true,
                                 default = nil)
  if valid_603363 != nil:
    section.add "SelectExpression", valid_603363
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603364: Call_PostSelect_603351; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  let valid = call_603364.validator(path, query, header, formData, body)
  let scheme = call_603364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603364.url(scheme.get, call_603364.host, call_603364.base,
                         call_603364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603364, url, valid)

proc call*(call_603365: Call_PostSelect_603351; SignatureMethod: string;
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
  var query_603366 = newJObject()
  var formData_603367 = newJObject()
  add(formData_603367, "NextToken", newJString(NextToken))
  add(query_603366, "SignatureMethod", newJString(SignatureMethod))
  add(formData_603367, "ConsistentRead", newJBool(ConsistentRead))
  add(query_603366, "Signature", newJString(Signature))
  add(query_603366, "Action", newJString(Action))
  add(query_603366, "Timestamp", newJString(Timestamp))
  add(query_603366, "SignatureVersion", newJString(SignatureVersion))
  add(query_603366, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_603367, "SelectExpression", newJString(SelectExpression))
  add(query_603366, "Version", newJString(Version))
  result = call_603365.call(nil, query_603366, nil, formData_603367, nil)

var postSelect* = Call_PostSelect_603351(name: "postSelect",
                                      meth: HttpMethod.HttpPost,
                                      host: "sdb.amazonaws.com",
                                      route: "/#Action=Select",
                                      validator: validate_PostSelect_603352,
                                      base: "/", url: url_PostSelect_603353,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSelect_603335 = ref object of OpenApiRestCall_602450
proc url_GetSelect_603337(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSelect_603336(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603338 = query.getOrDefault("SignatureMethod")
  valid_603338 = validateParameter(valid_603338, JString, required = true,
                                 default = nil)
  if valid_603338 != nil:
    section.add "SignatureMethod", valid_603338
  var valid_603339 = query.getOrDefault("Signature")
  valid_603339 = validateParameter(valid_603339, JString, required = true,
                                 default = nil)
  if valid_603339 != nil:
    section.add "Signature", valid_603339
  var valid_603340 = query.getOrDefault("NextToken")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "NextToken", valid_603340
  var valid_603341 = query.getOrDefault("SelectExpression")
  valid_603341 = validateParameter(valid_603341, JString, required = true,
                                 default = nil)
  if valid_603341 != nil:
    section.add "SelectExpression", valid_603341
  var valid_603342 = query.getOrDefault("Action")
  valid_603342 = validateParameter(valid_603342, JString, required = true,
                                 default = newJString("Select"))
  if valid_603342 != nil:
    section.add "Action", valid_603342
  var valid_603343 = query.getOrDefault("Timestamp")
  valid_603343 = validateParameter(valid_603343, JString, required = true,
                                 default = nil)
  if valid_603343 != nil:
    section.add "Timestamp", valid_603343
  var valid_603344 = query.getOrDefault("ConsistentRead")
  valid_603344 = validateParameter(valid_603344, JBool, required = false, default = nil)
  if valid_603344 != nil:
    section.add "ConsistentRead", valid_603344
  var valid_603345 = query.getOrDefault("SignatureVersion")
  valid_603345 = validateParameter(valid_603345, JString, required = true,
                                 default = nil)
  if valid_603345 != nil:
    section.add "SignatureVersion", valid_603345
  var valid_603346 = query.getOrDefault("AWSAccessKeyId")
  valid_603346 = validateParameter(valid_603346, JString, required = true,
                                 default = nil)
  if valid_603346 != nil:
    section.add "AWSAccessKeyId", valid_603346
  var valid_603347 = query.getOrDefault("Version")
  valid_603347 = validateParameter(valid_603347, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_603347 != nil:
    section.add "Version", valid_603347
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603348: Call_GetSelect_603335; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  let valid = call_603348.validator(path, query, header, formData, body)
  let scheme = call_603348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603348.url(scheme.get, call_603348.host, call_603348.base,
                         call_603348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603348, url, valid)

proc call*(call_603349: Call_GetSelect_603335; SignatureMethod: string;
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
  var query_603350 = newJObject()
  add(query_603350, "SignatureMethod", newJString(SignatureMethod))
  add(query_603350, "Signature", newJString(Signature))
  add(query_603350, "NextToken", newJString(NextToken))
  add(query_603350, "SelectExpression", newJString(SelectExpression))
  add(query_603350, "Action", newJString(Action))
  add(query_603350, "Timestamp", newJString(Timestamp))
  add(query_603350, "ConsistentRead", newJBool(ConsistentRead))
  add(query_603350, "SignatureVersion", newJString(SignatureVersion))
  add(query_603350, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603350, "Version", newJString(Version))
  result = call_603349.call(nil, query_603350, nil, nil, nil)

var getSelect* = Call_GetSelect_603335(name: "getSelect", meth: HttpMethod.HttpGet,
                                    host: "sdb.amazonaws.com",
                                    route: "/#Action=Select",
                                    validator: validate_GetSelect_603336,
                                    base: "/", url: url_GetSelect_603337,
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
