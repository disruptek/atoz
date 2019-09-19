
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_772581 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772581](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772581): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_PostBatchDeleteAttributes_773187 = ref object of OpenApiRestCall_772581
proc url_PostBatchDeleteAttributes_773189(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostBatchDeleteAttributes_773188(path: JsonNode; query: JsonNode;
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
  var valid_773190 = query.getOrDefault("SignatureMethod")
  valid_773190 = validateParameter(valid_773190, JString, required = true,
                                 default = nil)
  if valid_773190 != nil:
    section.add "SignatureMethod", valid_773190
  var valid_773191 = query.getOrDefault("Signature")
  valid_773191 = validateParameter(valid_773191, JString, required = true,
                                 default = nil)
  if valid_773191 != nil:
    section.add "Signature", valid_773191
  var valid_773192 = query.getOrDefault("Action")
  valid_773192 = validateParameter(valid_773192, JString, required = true,
                                 default = newJString("BatchDeleteAttributes"))
  if valid_773192 != nil:
    section.add "Action", valid_773192
  var valid_773193 = query.getOrDefault("Timestamp")
  valid_773193 = validateParameter(valid_773193, JString, required = true,
                                 default = nil)
  if valid_773193 != nil:
    section.add "Timestamp", valid_773193
  var valid_773194 = query.getOrDefault("SignatureVersion")
  valid_773194 = validateParameter(valid_773194, JString, required = true,
                                 default = nil)
  if valid_773194 != nil:
    section.add "SignatureVersion", valid_773194
  var valid_773195 = query.getOrDefault("AWSAccessKeyId")
  valid_773195 = validateParameter(valid_773195, JString, required = true,
                                 default = nil)
  if valid_773195 != nil:
    section.add "AWSAccessKeyId", valid_773195
  var valid_773196 = query.getOrDefault("Version")
  valid_773196 = validateParameter(valid_773196, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_773196 != nil:
    section.add "Version", valid_773196
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
  var valid_773197 = formData.getOrDefault("DomainName")
  valid_773197 = validateParameter(valid_773197, JString, required = true,
                                 default = nil)
  if valid_773197 != nil:
    section.add "DomainName", valid_773197
  var valid_773198 = formData.getOrDefault("Items")
  valid_773198 = validateParameter(valid_773198, JArray, required = true, default = nil)
  if valid_773198 != nil:
    section.add "Items", valid_773198
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773199: Call_PostBatchDeleteAttributes_773187; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  let valid = call_773199.validator(path, query, header, formData, body)
  let scheme = call_773199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773199.url(scheme.get, call_773199.host, call_773199.base,
                         call_773199.route, valid.getOrDefault("path"))
  result = hook(call_773199, url, valid)

proc call*(call_773200: Call_PostBatchDeleteAttributes_773187;
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
  var query_773201 = newJObject()
  var formData_773202 = newJObject()
  add(query_773201, "SignatureMethod", newJString(SignatureMethod))
  add(formData_773202, "DomainName", newJString(DomainName))
  add(query_773201, "Signature", newJString(Signature))
  add(query_773201, "Action", newJString(Action))
  add(query_773201, "Timestamp", newJString(Timestamp))
  if Items != nil:
    formData_773202.add "Items", Items
  add(query_773201, "SignatureVersion", newJString(SignatureVersion))
  add(query_773201, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773201, "Version", newJString(Version))
  result = call_773200.call(nil, query_773201, nil, formData_773202, nil)

var postBatchDeleteAttributes* = Call_PostBatchDeleteAttributes_773187(
    name: "postBatchDeleteAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=BatchDeleteAttributes",
    validator: validate_PostBatchDeleteAttributes_773188, base: "/",
    url: url_PostBatchDeleteAttributes_773189,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchDeleteAttributes_772917 = ref object of OpenApiRestCall_772581
proc url_GetBatchDeleteAttributes_772919(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetBatchDeleteAttributes_772918(path: JsonNode; query: JsonNode;
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
  var valid_773031 = query.getOrDefault("SignatureMethod")
  valid_773031 = validateParameter(valid_773031, JString, required = true,
                                 default = nil)
  if valid_773031 != nil:
    section.add "SignatureMethod", valid_773031
  var valid_773032 = query.getOrDefault("Signature")
  valid_773032 = validateParameter(valid_773032, JString, required = true,
                                 default = nil)
  if valid_773032 != nil:
    section.add "Signature", valid_773032
  var valid_773046 = query.getOrDefault("Action")
  valid_773046 = validateParameter(valid_773046, JString, required = true,
                                 default = newJString("BatchDeleteAttributes"))
  if valid_773046 != nil:
    section.add "Action", valid_773046
  var valid_773047 = query.getOrDefault("Timestamp")
  valid_773047 = validateParameter(valid_773047, JString, required = true,
                                 default = nil)
  if valid_773047 != nil:
    section.add "Timestamp", valid_773047
  var valid_773048 = query.getOrDefault("Items")
  valid_773048 = validateParameter(valid_773048, JArray, required = true, default = nil)
  if valid_773048 != nil:
    section.add "Items", valid_773048
  var valid_773049 = query.getOrDefault("SignatureVersion")
  valid_773049 = validateParameter(valid_773049, JString, required = true,
                                 default = nil)
  if valid_773049 != nil:
    section.add "SignatureVersion", valid_773049
  var valid_773050 = query.getOrDefault("AWSAccessKeyId")
  valid_773050 = validateParameter(valid_773050, JString, required = true,
                                 default = nil)
  if valid_773050 != nil:
    section.add "AWSAccessKeyId", valid_773050
  var valid_773051 = query.getOrDefault("DomainName")
  valid_773051 = validateParameter(valid_773051, JString, required = true,
                                 default = nil)
  if valid_773051 != nil:
    section.add "DomainName", valid_773051
  var valid_773052 = query.getOrDefault("Version")
  valid_773052 = validateParameter(valid_773052, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_773052 != nil:
    section.add "Version", valid_773052
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773075: Call_GetBatchDeleteAttributes_772917; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  let valid = call_773075.validator(path, query, header, formData, body)
  let scheme = call_773075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773075.url(scheme.get, call_773075.host, call_773075.base,
                         call_773075.route, valid.getOrDefault("path"))
  result = hook(call_773075, url, valid)

proc call*(call_773146: Call_GetBatchDeleteAttributes_772917;
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
  var query_773147 = newJObject()
  add(query_773147, "SignatureMethod", newJString(SignatureMethod))
  add(query_773147, "Signature", newJString(Signature))
  add(query_773147, "Action", newJString(Action))
  add(query_773147, "Timestamp", newJString(Timestamp))
  if Items != nil:
    query_773147.add "Items", Items
  add(query_773147, "SignatureVersion", newJString(SignatureVersion))
  add(query_773147, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773147, "DomainName", newJString(DomainName))
  add(query_773147, "Version", newJString(Version))
  result = call_773146.call(nil, query_773147, nil, nil, nil)

var getBatchDeleteAttributes* = Call_GetBatchDeleteAttributes_772917(
    name: "getBatchDeleteAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=BatchDeleteAttributes",
    validator: validate_GetBatchDeleteAttributes_772918, base: "/",
    url: url_GetBatchDeleteAttributes_772919, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostBatchPutAttributes_773218 = ref object of OpenApiRestCall_772581
proc url_PostBatchPutAttributes_773220(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostBatchPutAttributes_773219(path: JsonNode; query: JsonNode;
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
  var valid_773221 = query.getOrDefault("SignatureMethod")
  valid_773221 = validateParameter(valid_773221, JString, required = true,
                                 default = nil)
  if valid_773221 != nil:
    section.add "SignatureMethod", valid_773221
  var valid_773222 = query.getOrDefault("Signature")
  valid_773222 = validateParameter(valid_773222, JString, required = true,
                                 default = nil)
  if valid_773222 != nil:
    section.add "Signature", valid_773222
  var valid_773223 = query.getOrDefault("Action")
  valid_773223 = validateParameter(valid_773223, JString, required = true,
                                 default = newJString("BatchPutAttributes"))
  if valid_773223 != nil:
    section.add "Action", valid_773223
  var valid_773224 = query.getOrDefault("Timestamp")
  valid_773224 = validateParameter(valid_773224, JString, required = true,
                                 default = nil)
  if valid_773224 != nil:
    section.add "Timestamp", valid_773224
  var valid_773225 = query.getOrDefault("SignatureVersion")
  valid_773225 = validateParameter(valid_773225, JString, required = true,
                                 default = nil)
  if valid_773225 != nil:
    section.add "SignatureVersion", valid_773225
  var valid_773226 = query.getOrDefault("AWSAccessKeyId")
  valid_773226 = validateParameter(valid_773226, JString, required = true,
                                 default = nil)
  if valid_773226 != nil:
    section.add "AWSAccessKeyId", valid_773226
  var valid_773227 = query.getOrDefault("Version")
  valid_773227 = validateParameter(valid_773227, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_773227 != nil:
    section.add "Version", valid_773227
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
  var valid_773228 = formData.getOrDefault("DomainName")
  valid_773228 = validateParameter(valid_773228, JString, required = true,
                                 default = nil)
  if valid_773228 != nil:
    section.add "DomainName", valid_773228
  var valid_773229 = formData.getOrDefault("Items")
  valid_773229 = validateParameter(valid_773229, JArray, required = true, default = nil)
  if valid_773229 != nil:
    section.add "Items", valid_773229
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773230: Call_PostBatchPutAttributes_773218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  let valid = call_773230.validator(path, query, header, formData, body)
  let scheme = call_773230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773230.url(scheme.get, call_773230.host, call_773230.base,
                         call_773230.route, valid.getOrDefault("path"))
  result = hook(call_773230, url, valid)

proc call*(call_773231: Call_PostBatchPutAttributes_773218;
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
  var query_773232 = newJObject()
  var formData_773233 = newJObject()
  add(query_773232, "SignatureMethod", newJString(SignatureMethod))
  add(formData_773233, "DomainName", newJString(DomainName))
  add(query_773232, "Signature", newJString(Signature))
  add(query_773232, "Action", newJString(Action))
  add(query_773232, "Timestamp", newJString(Timestamp))
  if Items != nil:
    formData_773233.add "Items", Items
  add(query_773232, "SignatureVersion", newJString(SignatureVersion))
  add(query_773232, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773232, "Version", newJString(Version))
  result = call_773231.call(nil, query_773232, nil, formData_773233, nil)

var postBatchPutAttributes* = Call_PostBatchPutAttributes_773218(
    name: "postBatchPutAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=BatchPutAttributes",
    validator: validate_PostBatchPutAttributes_773219, base: "/",
    url: url_PostBatchPutAttributes_773220, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchPutAttributes_773203 = ref object of OpenApiRestCall_772581
proc url_GetBatchPutAttributes_773205(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetBatchPutAttributes_773204(path: JsonNode; query: JsonNode;
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
  var valid_773206 = query.getOrDefault("SignatureMethod")
  valid_773206 = validateParameter(valid_773206, JString, required = true,
                                 default = nil)
  if valid_773206 != nil:
    section.add "SignatureMethod", valid_773206
  var valid_773207 = query.getOrDefault("Signature")
  valid_773207 = validateParameter(valid_773207, JString, required = true,
                                 default = nil)
  if valid_773207 != nil:
    section.add "Signature", valid_773207
  var valid_773208 = query.getOrDefault("Action")
  valid_773208 = validateParameter(valid_773208, JString, required = true,
                                 default = newJString("BatchPutAttributes"))
  if valid_773208 != nil:
    section.add "Action", valid_773208
  var valid_773209 = query.getOrDefault("Timestamp")
  valid_773209 = validateParameter(valid_773209, JString, required = true,
                                 default = nil)
  if valid_773209 != nil:
    section.add "Timestamp", valid_773209
  var valid_773210 = query.getOrDefault("Items")
  valid_773210 = validateParameter(valid_773210, JArray, required = true, default = nil)
  if valid_773210 != nil:
    section.add "Items", valid_773210
  var valid_773211 = query.getOrDefault("SignatureVersion")
  valid_773211 = validateParameter(valid_773211, JString, required = true,
                                 default = nil)
  if valid_773211 != nil:
    section.add "SignatureVersion", valid_773211
  var valid_773212 = query.getOrDefault("AWSAccessKeyId")
  valid_773212 = validateParameter(valid_773212, JString, required = true,
                                 default = nil)
  if valid_773212 != nil:
    section.add "AWSAccessKeyId", valid_773212
  var valid_773213 = query.getOrDefault("DomainName")
  valid_773213 = validateParameter(valid_773213, JString, required = true,
                                 default = nil)
  if valid_773213 != nil:
    section.add "DomainName", valid_773213
  var valid_773214 = query.getOrDefault("Version")
  valid_773214 = validateParameter(valid_773214, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_773214 != nil:
    section.add "Version", valid_773214
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773215: Call_GetBatchPutAttributes_773203; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  let valid = call_773215.validator(path, query, header, formData, body)
  let scheme = call_773215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773215.url(scheme.get, call_773215.host, call_773215.base,
                         call_773215.route, valid.getOrDefault("path"))
  result = hook(call_773215, url, valid)

proc call*(call_773216: Call_GetBatchPutAttributes_773203; SignatureMethod: string;
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
  var query_773217 = newJObject()
  add(query_773217, "SignatureMethod", newJString(SignatureMethod))
  add(query_773217, "Signature", newJString(Signature))
  add(query_773217, "Action", newJString(Action))
  add(query_773217, "Timestamp", newJString(Timestamp))
  if Items != nil:
    query_773217.add "Items", Items
  add(query_773217, "SignatureVersion", newJString(SignatureVersion))
  add(query_773217, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773217, "DomainName", newJString(DomainName))
  add(query_773217, "Version", newJString(Version))
  result = call_773216.call(nil, query_773217, nil, nil, nil)

var getBatchPutAttributes* = Call_GetBatchPutAttributes_773203(
    name: "getBatchPutAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=BatchPutAttributes",
    validator: validate_GetBatchPutAttributes_773204, base: "/",
    url: url_GetBatchPutAttributes_773205, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDomain_773248 = ref object of OpenApiRestCall_772581
proc url_PostCreateDomain_773250(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDomain_773249(path: JsonNode; query: JsonNode;
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
  var valid_773251 = query.getOrDefault("SignatureMethod")
  valid_773251 = validateParameter(valid_773251, JString, required = true,
                                 default = nil)
  if valid_773251 != nil:
    section.add "SignatureMethod", valid_773251
  var valid_773252 = query.getOrDefault("Signature")
  valid_773252 = validateParameter(valid_773252, JString, required = true,
                                 default = nil)
  if valid_773252 != nil:
    section.add "Signature", valid_773252
  var valid_773253 = query.getOrDefault("Action")
  valid_773253 = validateParameter(valid_773253, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_773253 != nil:
    section.add "Action", valid_773253
  var valid_773254 = query.getOrDefault("Timestamp")
  valid_773254 = validateParameter(valid_773254, JString, required = true,
                                 default = nil)
  if valid_773254 != nil:
    section.add "Timestamp", valid_773254
  var valid_773255 = query.getOrDefault("SignatureVersion")
  valid_773255 = validateParameter(valid_773255, JString, required = true,
                                 default = nil)
  if valid_773255 != nil:
    section.add "SignatureVersion", valid_773255
  var valid_773256 = query.getOrDefault("AWSAccessKeyId")
  valid_773256 = validateParameter(valid_773256, JString, required = true,
                                 default = nil)
  if valid_773256 != nil:
    section.add "AWSAccessKeyId", valid_773256
  var valid_773257 = query.getOrDefault("Version")
  valid_773257 = validateParameter(valid_773257, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_773257 != nil:
    section.add "Version", valid_773257
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain to create. The name can range between 3 and 255 characters and can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773258 = formData.getOrDefault("DomainName")
  valid_773258 = validateParameter(valid_773258, JString, required = true,
                                 default = nil)
  if valid_773258 != nil:
    section.add "DomainName", valid_773258
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773259: Call_PostCreateDomain_773248; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  let valid = call_773259.validator(path, query, header, formData, body)
  let scheme = call_773259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773259.url(scheme.get, call_773259.host, call_773259.base,
                         call_773259.route, valid.getOrDefault("path"))
  result = hook(call_773259, url, valid)

proc call*(call_773260: Call_PostCreateDomain_773248; SignatureMethod: string;
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
  var query_773261 = newJObject()
  var formData_773262 = newJObject()
  add(query_773261, "SignatureMethod", newJString(SignatureMethod))
  add(formData_773262, "DomainName", newJString(DomainName))
  add(query_773261, "Signature", newJString(Signature))
  add(query_773261, "Action", newJString(Action))
  add(query_773261, "Timestamp", newJString(Timestamp))
  add(query_773261, "SignatureVersion", newJString(SignatureVersion))
  add(query_773261, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773261, "Version", newJString(Version))
  result = call_773260.call(nil, query_773261, nil, formData_773262, nil)

var postCreateDomain* = Call_PostCreateDomain_773248(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_773249,
    base: "/", url: url_PostCreateDomain_773250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_773234 = ref object of OpenApiRestCall_772581
proc url_GetCreateDomain_773236(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDomain_773235(path: JsonNode; query: JsonNode;
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
  var valid_773237 = query.getOrDefault("SignatureMethod")
  valid_773237 = validateParameter(valid_773237, JString, required = true,
                                 default = nil)
  if valid_773237 != nil:
    section.add "SignatureMethod", valid_773237
  var valid_773238 = query.getOrDefault("Signature")
  valid_773238 = validateParameter(valid_773238, JString, required = true,
                                 default = nil)
  if valid_773238 != nil:
    section.add "Signature", valid_773238
  var valid_773239 = query.getOrDefault("Action")
  valid_773239 = validateParameter(valid_773239, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_773239 != nil:
    section.add "Action", valid_773239
  var valid_773240 = query.getOrDefault("Timestamp")
  valid_773240 = validateParameter(valid_773240, JString, required = true,
                                 default = nil)
  if valid_773240 != nil:
    section.add "Timestamp", valid_773240
  var valid_773241 = query.getOrDefault("SignatureVersion")
  valid_773241 = validateParameter(valid_773241, JString, required = true,
                                 default = nil)
  if valid_773241 != nil:
    section.add "SignatureVersion", valid_773241
  var valid_773242 = query.getOrDefault("AWSAccessKeyId")
  valid_773242 = validateParameter(valid_773242, JString, required = true,
                                 default = nil)
  if valid_773242 != nil:
    section.add "AWSAccessKeyId", valid_773242
  var valid_773243 = query.getOrDefault("DomainName")
  valid_773243 = validateParameter(valid_773243, JString, required = true,
                                 default = nil)
  if valid_773243 != nil:
    section.add "DomainName", valid_773243
  var valid_773244 = query.getOrDefault("Version")
  valid_773244 = validateParameter(valid_773244, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_773244 != nil:
    section.add "Version", valid_773244
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773245: Call_GetCreateDomain_773234; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  let valid = call_773245.validator(path, query, header, formData, body)
  let scheme = call_773245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773245.url(scheme.get, call_773245.host, call_773245.base,
                         call_773245.route, valid.getOrDefault("path"))
  result = hook(call_773245, url, valid)

proc call*(call_773246: Call_GetCreateDomain_773234; SignatureMethod: string;
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
  var query_773247 = newJObject()
  add(query_773247, "SignatureMethod", newJString(SignatureMethod))
  add(query_773247, "Signature", newJString(Signature))
  add(query_773247, "Action", newJString(Action))
  add(query_773247, "Timestamp", newJString(Timestamp))
  add(query_773247, "SignatureVersion", newJString(SignatureVersion))
  add(query_773247, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773247, "DomainName", newJString(DomainName))
  add(query_773247, "Version", newJString(Version))
  result = call_773246.call(nil, query_773247, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_773234(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_773235,
    base: "/", url: url_GetCreateDomain_773236, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAttributes_773282 = ref object of OpenApiRestCall_772581
proc url_PostDeleteAttributes_773284(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteAttributes_773283(path: JsonNode; query: JsonNode;
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
  var valid_773285 = query.getOrDefault("SignatureMethod")
  valid_773285 = validateParameter(valid_773285, JString, required = true,
                                 default = nil)
  if valid_773285 != nil:
    section.add "SignatureMethod", valid_773285
  var valid_773286 = query.getOrDefault("Signature")
  valid_773286 = validateParameter(valid_773286, JString, required = true,
                                 default = nil)
  if valid_773286 != nil:
    section.add "Signature", valid_773286
  var valid_773287 = query.getOrDefault("Action")
  valid_773287 = validateParameter(valid_773287, JString, required = true,
                                 default = newJString("DeleteAttributes"))
  if valid_773287 != nil:
    section.add "Action", valid_773287
  var valid_773288 = query.getOrDefault("Timestamp")
  valid_773288 = validateParameter(valid_773288, JString, required = true,
                                 default = nil)
  if valid_773288 != nil:
    section.add "Timestamp", valid_773288
  var valid_773289 = query.getOrDefault("SignatureVersion")
  valid_773289 = validateParameter(valid_773289, JString, required = true,
                                 default = nil)
  if valid_773289 != nil:
    section.add "SignatureVersion", valid_773289
  var valid_773290 = query.getOrDefault("AWSAccessKeyId")
  valid_773290 = validateParameter(valid_773290, JString, required = true,
                                 default = nil)
  if valid_773290 != nil:
    section.add "AWSAccessKeyId", valid_773290
  var valid_773291 = query.getOrDefault("Version")
  valid_773291 = validateParameter(valid_773291, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_773291 != nil:
    section.add "Version", valid_773291
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
  var valid_773292 = formData.getOrDefault("DomainName")
  valid_773292 = validateParameter(valid_773292, JString, required = true,
                                 default = nil)
  if valid_773292 != nil:
    section.add "DomainName", valid_773292
  var valid_773293 = formData.getOrDefault("ItemName")
  valid_773293 = validateParameter(valid_773293, JString, required = true,
                                 default = nil)
  if valid_773293 != nil:
    section.add "ItemName", valid_773293
  var valid_773294 = formData.getOrDefault("Expected.Exists")
  valid_773294 = validateParameter(valid_773294, JString, required = false,
                                 default = nil)
  if valid_773294 != nil:
    section.add "Expected.Exists", valid_773294
  var valid_773295 = formData.getOrDefault("Attributes")
  valid_773295 = validateParameter(valid_773295, JArray, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "Attributes", valid_773295
  var valid_773296 = formData.getOrDefault("Expected.Value")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "Expected.Value", valid_773296
  var valid_773297 = formData.getOrDefault("Expected.Name")
  valid_773297 = validateParameter(valid_773297, JString, required = false,
                                 default = nil)
  if valid_773297 != nil:
    section.add "Expected.Name", valid_773297
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773298: Call_PostDeleteAttributes_773282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  let valid = call_773298.validator(path, query, header, formData, body)
  let scheme = call_773298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773298.url(scheme.get, call_773298.host, call_773298.base,
                         call_773298.route, valid.getOrDefault("path"))
  result = hook(call_773298, url, valid)

proc call*(call_773299: Call_PostDeleteAttributes_773282; SignatureMethod: string;
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
  var query_773300 = newJObject()
  var formData_773301 = newJObject()
  add(query_773300, "SignatureMethod", newJString(SignatureMethod))
  add(formData_773301, "DomainName", newJString(DomainName))
  add(formData_773301, "ItemName", newJString(ItemName))
  add(formData_773301, "Expected.Exists", newJString(ExpectedExists))
  add(query_773300, "Signature", newJString(Signature))
  if Attributes != nil:
    formData_773301.add "Attributes", Attributes
  add(query_773300, "Action", newJString(Action))
  add(query_773300, "Timestamp", newJString(Timestamp))
  add(formData_773301, "Expected.Value", newJString(ExpectedValue))
  add(formData_773301, "Expected.Name", newJString(ExpectedName))
  add(query_773300, "SignatureVersion", newJString(SignatureVersion))
  add(query_773300, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773300, "Version", newJString(Version))
  result = call_773299.call(nil, query_773300, nil, formData_773301, nil)

var postDeleteAttributes* = Call_PostDeleteAttributes_773282(
    name: "postDeleteAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=DeleteAttributes",
    validator: validate_PostDeleteAttributes_773283, base: "/",
    url: url_PostDeleteAttributes_773284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAttributes_773263 = ref object of OpenApiRestCall_772581
proc url_GetDeleteAttributes_773265(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteAttributes_773264(path: JsonNode; query: JsonNode;
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
  var valid_773266 = query.getOrDefault("SignatureMethod")
  valid_773266 = validateParameter(valid_773266, JString, required = true,
                                 default = nil)
  if valid_773266 != nil:
    section.add "SignatureMethod", valid_773266
  var valid_773267 = query.getOrDefault("Expected.Exists")
  valid_773267 = validateParameter(valid_773267, JString, required = false,
                                 default = nil)
  if valid_773267 != nil:
    section.add "Expected.Exists", valid_773267
  var valid_773268 = query.getOrDefault("Attributes")
  valid_773268 = validateParameter(valid_773268, JArray, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "Attributes", valid_773268
  var valid_773269 = query.getOrDefault("Signature")
  valid_773269 = validateParameter(valid_773269, JString, required = true,
                                 default = nil)
  if valid_773269 != nil:
    section.add "Signature", valid_773269
  var valid_773270 = query.getOrDefault("ItemName")
  valid_773270 = validateParameter(valid_773270, JString, required = true,
                                 default = nil)
  if valid_773270 != nil:
    section.add "ItemName", valid_773270
  var valid_773271 = query.getOrDefault("Action")
  valid_773271 = validateParameter(valid_773271, JString, required = true,
                                 default = newJString("DeleteAttributes"))
  if valid_773271 != nil:
    section.add "Action", valid_773271
  var valid_773272 = query.getOrDefault("Expected.Value")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "Expected.Value", valid_773272
  var valid_773273 = query.getOrDefault("Timestamp")
  valid_773273 = validateParameter(valid_773273, JString, required = true,
                                 default = nil)
  if valid_773273 != nil:
    section.add "Timestamp", valid_773273
  var valid_773274 = query.getOrDefault("SignatureVersion")
  valid_773274 = validateParameter(valid_773274, JString, required = true,
                                 default = nil)
  if valid_773274 != nil:
    section.add "SignatureVersion", valid_773274
  var valid_773275 = query.getOrDefault("AWSAccessKeyId")
  valid_773275 = validateParameter(valid_773275, JString, required = true,
                                 default = nil)
  if valid_773275 != nil:
    section.add "AWSAccessKeyId", valid_773275
  var valid_773276 = query.getOrDefault("Expected.Name")
  valid_773276 = validateParameter(valid_773276, JString, required = false,
                                 default = nil)
  if valid_773276 != nil:
    section.add "Expected.Name", valid_773276
  var valid_773277 = query.getOrDefault("DomainName")
  valid_773277 = validateParameter(valid_773277, JString, required = true,
                                 default = nil)
  if valid_773277 != nil:
    section.add "DomainName", valid_773277
  var valid_773278 = query.getOrDefault("Version")
  valid_773278 = validateParameter(valid_773278, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_773278 != nil:
    section.add "Version", valid_773278
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773279: Call_GetDeleteAttributes_773263; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  let valid = call_773279.validator(path, query, header, formData, body)
  let scheme = call_773279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773279.url(scheme.get, call_773279.host, call_773279.base,
                         call_773279.route, valid.getOrDefault("path"))
  result = hook(call_773279, url, valid)

proc call*(call_773280: Call_GetDeleteAttributes_773263; SignatureMethod: string;
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
  var query_773281 = newJObject()
  add(query_773281, "SignatureMethod", newJString(SignatureMethod))
  add(query_773281, "Expected.Exists", newJString(ExpectedExists))
  if Attributes != nil:
    query_773281.add "Attributes", Attributes
  add(query_773281, "Signature", newJString(Signature))
  add(query_773281, "ItemName", newJString(ItemName))
  add(query_773281, "Action", newJString(Action))
  add(query_773281, "Expected.Value", newJString(ExpectedValue))
  add(query_773281, "Timestamp", newJString(Timestamp))
  add(query_773281, "SignatureVersion", newJString(SignatureVersion))
  add(query_773281, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773281, "Expected.Name", newJString(ExpectedName))
  add(query_773281, "DomainName", newJString(DomainName))
  add(query_773281, "Version", newJString(Version))
  result = call_773280.call(nil, query_773281, nil, nil, nil)

var getDeleteAttributes* = Call_GetDeleteAttributes_773263(
    name: "getDeleteAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=DeleteAttributes",
    validator: validate_GetDeleteAttributes_773264, base: "/",
    url: url_GetDeleteAttributes_773265, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_773316 = ref object of OpenApiRestCall_772581
proc url_PostDeleteDomain_773318(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDomain_773317(path: JsonNode; query: JsonNode;
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
  var valid_773319 = query.getOrDefault("SignatureMethod")
  valid_773319 = validateParameter(valid_773319, JString, required = true,
                                 default = nil)
  if valid_773319 != nil:
    section.add "SignatureMethod", valid_773319
  var valid_773320 = query.getOrDefault("Signature")
  valid_773320 = validateParameter(valid_773320, JString, required = true,
                                 default = nil)
  if valid_773320 != nil:
    section.add "Signature", valid_773320
  var valid_773321 = query.getOrDefault("Action")
  valid_773321 = validateParameter(valid_773321, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_773321 != nil:
    section.add "Action", valid_773321
  var valid_773322 = query.getOrDefault("Timestamp")
  valid_773322 = validateParameter(valid_773322, JString, required = true,
                                 default = nil)
  if valid_773322 != nil:
    section.add "Timestamp", valid_773322
  var valid_773323 = query.getOrDefault("SignatureVersion")
  valid_773323 = validateParameter(valid_773323, JString, required = true,
                                 default = nil)
  if valid_773323 != nil:
    section.add "SignatureVersion", valid_773323
  var valid_773324 = query.getOrDefault("AWSAccessKeyId")
  valid_773324 = validateParameter(valid_773324, JString, required = true,
                                 default = nil)
  if valid_773324 != nil:
    section.add "AWSAccessKeyId", valid_773324
  var valid_773325 = query.getOrDefault("Version")
  valid_773325 = validateParameter(valid_773325, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_773325 != nil:
    section.add "Version", valid_773325
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773326 = formData.getOrDefault("DomainName")
  valid_773326 = validateParameter(valid_773326, JString, required = true,
                                 default = nil)
  if valid_773326 != nil:
    section.add "DomainName", valid_773326
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773327: Call_PostDeleteDomain_773316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  let valid = call_773327.validator(path, query, header, formData, body)
  let scheme = call_773327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773327.url(scheme.get, call_773327.host, call_773327.base,
                         call_773327.route, valid.getOrDefault("path"))
  result = hook(call_773327, url, valid)

proc call*(call_773328: Call_PostDeleteDomain_773316; SignatureMethod: string;
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
  var query_773329 = newJObject()
  var formData_773330 = newJObject()
  add(query_773329, "SignatureMethod", newJString(SignatureMethod))
  add(formData_773330, "DomainName", newJString(DomainName))
  add(query_773329, "Signature", newJString(Signature))
  add(query_773329, "Action", newJString(Action))
  add(query_773329, "Timestamp", newJString(Timestamp))
  add(query_773329, "SignatureVersion", newJString(SignatureVersion))
  add(query_773329, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773329, "Version", newJString(Version))
  result = call_773328.call(nil, query_773329, nil, formData_773330, nil)

var postDeleteDomain* = Call_PostDeleteDomain_773316(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_773317,
    base: "/", url: url_PostDeleteDomain_773318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_773302 = ref object of OpenApiRestCall_772581
proc url_GetDeleteDomain_773304(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDomain_773303(path: JsonNode; query: JsonNode;
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
  var valid_773305 = query.getOrDefault("SignatureMethod")
  valid_773305 = validateParameter(valid_773305, JString, required = true,
                                 default = nil)
  if valid_773305 != nil:
    section.add "SignatureMethod", valid_773305
  var valid_773306 = query.getOrDefault("Signature")
  valid_773306 = validateParameter(valid_773306, JString, required = true,
                                 default = nil)
  if valid_773306 != nil:
    section.add "Signature", valid_773306
  var valid_773307 = query.getOrDefault("Action")
  valid_773307 = validateParameter(valid_773307, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_773307 != nil:
    section.add "Action", valid_773307
  var valid_773308 = query.getOrDefault("Timestamp")
  valid_773308 = validateParameter(valid_773308, JString, required = true,
                                 default = nil)
  if valid_773308 != nil:
    section.add "Timestamp", valid_773308
  var valid_773309 = query.getOrDefault("SignatureVersion")
  valid_773309 = validateParameter(valid_773309, JString, required = true,
                                 default = nil)
  if valid_773309 != nil:
    section.add "SignatureVersion", valid_773309
  var valid_773310 = query.getOrDefault("AWSAccessKeyId")
  valid_773310 = validateParameter(valid_773310, JString, required = true,
                                 default = nil)
  if valid_773310 != nil:
    section.add "AWSAccessKeyId", valid_773310
  var valid_773311 = query.getOrDefault("DomainName")
  valid_773311 = validateParameter(valid_773311, JString, required = true,
                                 default = nil)
  if valid_773311 != nil:
    section.add "DomainName", valid_773311
  var valid_773312 = query.getOrDefault("Version")
  valid_773312 = validateParameter(valid_773312, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_773312 != nil:
    section.add "Version", valid_773312
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773313: Call_GetDeleteDomain_773302; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  let valid = call_773313.validator(path, query, header, formData, body)
  let scheme = call_773313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773313.url(scheme.get, call_773313.host, call_773313.base,
                         call_773313.route, valid.getOrDefault("path"))
  result = hook(call_773313, url, valid)

proc call*(call_773314: Call_GetDeleteDomain_773302; SignatureMethod: string;
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
  var query_773315 = newJObject()
  add(query_773315, "SignatureMethod", newJString(SignatureMethod))
  add(query_773315, "Signature", newJString(Signature))
  add(query_773315, "Action", newJString(Action))
  add(query_773315, "Timestamp", newJString(Timestamp))
  add(query_773315, "SignatureVersion", newJString(SignatureVersion))
  add(query_773315, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773315, "DomainName", newJString(DomainName))
  add(query_773315, "Version", newJString(Version))
  result = call_773314.call(nil, query_773315, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_773302(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_773303,
    base: "/", url: url_GetDeleteDomain_773304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDomainMetadata_773345 = ref object of OpenApiRestCall_772581
proc url_PostDomainMetadata_773347(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDomainMetadata_773346(path: JsonNode; query: JsonNode;
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
  var valid_773348 = query.getOrDefault("SignatureMethod")
  valid_773348 = validateParameter(valid_773348, JString, required = true,
                                 default = nil)
  if valid_773348 != nil:
    section.add "SignatureMethod", valid_773348
  var valid_773349 = query.getOrDefault("Signature")
  valid_773349 = validateParameter(valid_773349, JString, required = true,
                                 default = nil)
  if valid_773349 != nil:
    section.add "Signature", valid_773349
  var valid_773350 = query.getOrDefault("Action")
  valid_773350 = validateParameter(valid_773350, JString, required = true,
                                 default = newJString("DomainMetadata"))
  if valid_773350 != nil:
    section.add "Action", valid_773350
  var valid_773351 = query.getOrDefault("Timestamp")
  valid_773351 = validateParameter(valid_773351, JString, required = true,
                                 default = nil)
  if valid_773351 != nil:
    section.add "Timestamp", valid_773351
  var valid_773352 = query.getOrDefault("SignatureVersion")
  valid_773352 = validateParameter(valid_773352, JString, required = true,
                                 default = nil)
  if valid_773352 != nil:
    section.add "SignatureVersion", valid_773352
  var valid_773353 = query.getOrDefault("AWSAccessKeyId")
  valid_773353 = validateParameter(valid_773353, JString, required = true,
                                 default = nil)
  if valid_773353 != nil:
    section.add "AWSAccessKeyId", valid_773353
  var valid_773354 = query.getOrDefault("Version")
  valid_773354 = validateParameter(valid_773354, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_773354 != nil:
    section.add "Version", valid_773354
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain for which to display the metadata of.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773355 = formData.getOrDefault("DomainName")
  valid_773355 = validateParameter(valid_773355, JString, required = true,
                                 default = nil)
  if valid_773355 != nil:
    section.add "DomainName", valid_773355
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773356: Call_PostDomainMetadata_773345; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  let valid = call_773356.validator(path, query, header, formData, body)
  let scheme = call_773356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773356.url(scheme.get, call_773356.host, call_773356.base,
                         call_773356.route, valid.getOrDefault("path"))
  result = hook(call_773356, url, valid)

proc call*(call_773357: Call_PostDomainMetadata_773345; SignatureMethod: string;
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
  var query_773358 = newJObject()
  var formData_773359 = newJObject()
  add(query_773358, "SignatureMethod", newJString(SignatureMethod))
  add(formData_773359, "DomainName", newJString(DomainName))
  add(query_773358, "Signature", newJString(Signature))
  add(query_773358, "Action", newJString(Action))
  add(query_773358, "Timestamp", newJString(Timestamp))
  add(query_773358, "SignatureVersion", newJString(SignatureVersion))
  add(query_773358, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773358, "Version", newJString(Version))
  result = call_773357.call(nil, query_773358, nil, formData_773359, nil)

var postDomainMetadata* = Call_PostDomainMetadata_773345(
    name: "postDomainMetadata", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=DomainMetadata",
    validator: validate_PostDomainMetadata_773346, base: "/",
    url: url_PostDomainMetadata_773347, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainMetadata_773331 = ref object of OpenApiRestCall_772581
proc url_GetDomainMetadata_773333(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDomainMetadata_773332(path: JsonNode; query: JsonNode;
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
  var valid_773334 = query.getOrDefault("SignatureMethod")
  valid_773334 = validateParameter(valid_773334, JString, required = true,
                                 default = nil)
  if valid_773334 != nil:
    section.add "SignatureMethod", valid_773334
  var valid_773335 = query.getOrDefault("Signature")
  valid_773335 = validateParameter(valid_773335, JString, required = true,
                                 default = nil)
  if valid_773335 != nil:
    section.add "Signature", valid_773335
  var valid_773336 = query.getOrDefault("Action")
  valid_773336 = validateParameter(valid_773336, JString, required = true,
                                 default = newJString("DomainMetadata"))
  if valid_773336 != nil:
    section.add "Action", valid_773336
  var valid_773337 = query.getOrDefault("Timestamp")
  valid_773337 = validateParameter(valid_773337, JString, required = true,
                                 default = nil)
  if valid_773337 != nil:
    section.add "Timestamp", valid_773337
  var valid_773338 = query.getOrDefault("SignatureVersion")
  valid_773338 = validateParameter(valid_773338, JString, required = true,
                                 default = nil)
  if valid_773338 != nil:
    section.add "SignatureVersion", valid_773338
  var valid_773339 = query.getOrDefault("AWSAccessKeyId")
  valid_773339 = validateParameter(valid_773339, JString, required = true,
                                 default = nil)
  if valid_773339 != nil:
    section.add "AWSAccessKeyId", valid_773339
  var valid_773340 = query.getOrDefault("DomainName")
  valid_773340 = validateParameter(valid_773340, JString, required = true,
                                 default = nil)
  if valid_773340 != nil:
    section.add "DomainName", valid_773340
  var valid_773341 = query.getOrDefault("Version")
  valid_773341 = validateParameter(valid_773341, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_773341 != nil:
    section.add "Version", valid_773341
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773342: Call_GetDomainMetadata_773331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  let valid = call_773342.validator(path, query, header, formData, body)
  let scheme = call_773342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773342.url(scheme.get, call_773342.host, call_773342.base,
                         call_773342.route, valid.getOrDefault("path"))
  result = hook(call_773342, url, valid)

proc call*(call_773343: Call_GetDomainMetadata_773331; SignatureMethod: string;
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
  var query_773344 = newJObject()
  add(query_773344, "SignatureMethod", newJString(SignatureMethod))
  add(query_773344, "Signature", newJString(Signature))
  add(query_773344, "Action", newJString(Action))
  add(query_773344, "Timestamp", newJString(Timestamp))
  add(query_773344, "SignatureVersion", newJString(SignatureVersion))
  add(query_773344, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773344, "DomainName", newJString(DomainName))
  add(query_773344, "Version", newJString(Version))
  result = call_773343.call(nil, query_773344, nil, nil, nil)

var getDomainMetadata* = Call_GetDomainMetadata_773331(name: "getDomainMetadata",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=DomainMetadata", validator: validate_GetDomainMetadata_773332,
    base: "/", url: url_GetDomainMetadata_773333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetAttributes_773377 = ref object of OpenApiRestCall_772581
proc url_PostGetAttributes_773379(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetAttributes_773378(path: JsonNode; query: JsonNode;
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
  var valid_773380 = query.getOrDefault("SignatureMethod")
  valid_773380 = validateParameter(valid_773380, JString, required = true,
                                 default = nil)
  if valid_773380 != nil:
    section.add "SignatureMethod", valid_773380
  var valid_773381 = query.getOrDefault("Signature")
  valid_773381 = validateParameter(valid_773381, JString, required = true,
                                 default = nil)
  if valid_773381 != nil:
    section.add "Signature", valid_773381
  var valid_773382 = query.getOrDefault("Action")
  valid_773382 = validateParameter(valid_773382, JString, required = true,
                                 default = newJString("GetAttributes"))
  if valid_773382 != nil:
    section.add "Action", valid_773382
  var valid_773383 = query.getOrDefault("Timestamp")
  valid_773383 = validateParameter(valid_773383, JString, required = true,
                                 default = nil)
  if valid_773383 != nil:
    section.add "Timestamp", valid_773383
  var valid_773384 = query.getOrDefault("SignatureVersion")
  valid_773384 = validateParameter(valid_773384, JString, required = true,
                                 default = nil)
  if valid_773384 != nil:
    section.add "SignatureVersion", valid_773384
  var valid_773385 = query.getOrDefault("AWSAccessKeyId")
  valid_773385 = validateParameter(valid_773385, JString, required = true,
                                 default = nil)
  if valid_773385 != nil:
    section.add "AWSAccessKeyId", valid_773385
  var valid_773386 = query.getOrDefault("Version")
  valid_773386 = validateParameter(valid_773386, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_773386 != nil:
    section.add "Version", valid_773386
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
  var valid_773387 = formData.getOrDefault("DomainName")
  valid_773387 = validateParameter(valid_773387, JString, required = true,
                                 default = nil)
  if valid_773387 != nil:
    section.add "DomainName", valid_773387
  var valid_773388 = formData.getOrDefault("ItemName")
  valid_773388 = validateParameter(valid_773388, JString, required = true,
                                 default = nil)
  if valid_773388 != nil:
    section.add "ItemName", valid_773388
  var valid_773389 = formData.getOrDefault("ConsistentRead")
  valid_773389 = validateParameter(valid_773389, JBool, required = false, default = nil)
  if valid_773389 != nil:
    section.add "ConsistentRead", valid_773389
  var valid_773390 = formData.getOrDefault("AttributeNames")
  valid_773390 = validateParameter(valid_773390, JArray, required = false,
                                 default = nil)
  if valid_773390 != nil:
    section.add "AttributeNames", valid_773390
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773391: Call_PostGetAttributes_773377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  let valid = call_773391.validator(path, query, header, formData, body)
  let scheme = call_773391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773391.url(scheme.get, call_773391.host, call_773391.base,
                         call_773391.route, valid.getOrDefault("path"))
  result = hook(call_773391, url, valid)

proc call*(call_773392: Call_PostGetAttributes_773377; SignatureMethod: string;
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
  var query_773393 = newJObject()
  var formData_773394 = newJObject()
  add(query_773393, "SignatureMethod", newJString(SignatureMethod))
  add(formData_773394, "DomainName", newJString(DomainName))
  add(formData_773394, "ItemName", newJString(ItemName))
  add(formData_773394, "ConsistentRead", newJBool(ConsistentRead))
  add(query_773393, "Signature", newJString(Signature))
  add(query_773393, "Action", newJString(Action))
  add(query_773393, "Timestamp", newJString(Timestamp))
  if AttributeNames != nil:
    formData_773394.add "AttributeNames", AttributeNames
  add(query_773393, "SignatureVersion", newJString(SignatureVersion))
  add(query_773393, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773393, "Version", newJString(Version))
  result = call_773392.call(nil, query_773393, nil, formData_773394, nil)

var postGetAttributes* = Call_PostGetAttributes_773377(name: "postGetAttributes",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=GetAttributes", validator: validate_PostGetAttributes_773378,
    base: "/", url: url_PostGetAttributes_773379,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetAttributes_773360 = ref object of OpenApiRestCall_772581
proc url_GetGetAttributes_773362(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetAttributes_773361(path: JsonNode; query: JsonNode;
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
  var valid_773363 = query.getOrDefault("SignatureMethod")
  valid_773363 = validateParameter(valid_773363, JString, required = true,
                                 default = nil)
  if valid_773363 != nil:
    section.add "SignatureMethod", valid_773363
  var valid_773364 = query.getOrDefault("AttributeNames")
  valid_773364 = validateParameter(valid_773364, JArray, required = false,
                                 default = nil)
  if valid_773364 != nil:
    section.add "AttributeNames", valid_773364
  var valid_773365 = query.getOrDefault("Signature")
  valid_773365 = validateParameter(valid_773365, JString, required = true,
                                 default = nil)
  if valid_773365 != nil:
    section.add "Signature", valid_773365
  var valid_773366 = query.getOrDefault("ItemName")
  valid_773366 = validateParameter(valid_773366, JString, required = true,
                                 default = nil)
  if valid_773366 != nil:
    section.add "ItemName", valid_773366
  var valid_773367 = query.getOrDefault("Action")
  valid_773367 = validateParameter(valid_773367, JString, required = true,
                                 default = newJString("GetAttributes"))
  if valid_773367 != nil:
    section.add "Action", valid_773367
  var valid_773368 = query.getOrDefault("Timestamp")
  valid_773368 = validateParameter(valid_773368, JString, required = true,
                                 default = nil)
  if valid_773368 != nil:
    section.add "Timestamp", valid_773368
  var valid_773369 = query.getOrDefault("ConsistentRead")
  valid_773369 = validateParameter(valid_773369, JBool, required = false, default = nil)
  if valid_773369 != nil:
    section.add "ConsistentRead", valid_773369
  var valid_773370 = query.getOrDefault("SignatureVersion")
  valid_773370 = validateParameter(valid_773370, JString, required = true,
                                 default = nil)
  if valid_773370 != nil:
    section.add "SignatureVersion", valid_773370
  var valid_773371 = query.getOrDefault("AWSAccessKeyId")
  valid_773371 = validateParameter(valid_773371, JString, required = true,
                                 default = nil)
  if valid_773371 != nil:
    section.add "AWSAccessKeyId", valid_773371
  var valid_773372 = query.getOrDefault("DomainName")
  valid_773372 = validateParameter(valid_773372, JString, required = true,
                                 default = nil)
  if valid_773372 != nil:
    section.add "DomainName", valid_773372
  var valid_773373 = query.getOrDefault("Version")
  valid_773373 = validateParameter(valid_773373, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_773373 != nil:
    section.add "Version", valid_773373
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773374: Call_GetGetAttributes_773360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  let valid = call_773374.validator(path, query, header, formData, body)
  let scheme = call_773374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773374.url(scheme.get, call_773374.host, call_773374.base,
                         call_773374.route, valid.getOrDefault("path"))
  result = hook(call_773374, url, valid)

proc call*(call_773375: Call_GetGetAttributes_773360; SignatureMethod: string;
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
  var query_773376 = newJObject()
  add(query_773376, "SignatureMethod", newJString(SignatureMethod))
  if AttributeNames != nil:
    query_773376.add "AttributeNames", AttributeNames
  add(query_773376, "Signature", newJString(Signature))
  add(query_773376, "ItemName", newJString(ItemName))
  add(query_773376, "Action", newJString(Action))
  add(query_773376, "Timestamp", newJString(Timestamp))
  add(query_773376, "ConsistentRead", newJBool(ConsistentRead))
  add(query_773376, "SignatureVersion", newJString(SignatureVersion))
  add(query_773376, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773376, "DomainName", newJString(DomainName))
  add(query_773376, "Version", newJString(Version))
  result = call_773375.call(nil, query_773376, nil, nil, nil)

var getGetAttributes* = Call_GetGetAttributes_773360(name: "getGetAttributes",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=GetAttributes", validator: validate_GetGetAttributes_773361,
    base: "/", url: url_GetGetAttributes_773362,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDomains_773410 = ref object of OpenApiRestCall_772581
proc url_PostListDomains_773412(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListDomains_773411(path: JsonNode; query: JsonNode;
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
  var valid_773413 = query.getOrDefault("SignatureMethod")
  valid_773413 = validateParameter(valid_773413, JString, required = true,
                                 default = nil)
  if valid_773413 != nil:
    section.add "SignatureMethod", valid_773413
  var valid_773414 = query.getOrDefault("Signature")
  valid_773414 = validateParameter(valid_773414, JString, required = true,
                                 default = nil)
  if valid_773414 != nil:
    section.add "Signature", valid_773414
  var valid_773415 = query.getOrDefault("Action")
  valid_773415 = validateParameter(valid_773415, JString, required = true,
                                 default = newJString("ListDomains"))
  if valid_773415 != nil:
    section.add "Action", valid_773415
  var valid_773416 = query.getOrDefault("Timestamp")
  valid_773416 = validateParameter(valid_773416, JString, required = true,
                                 default = nil)
  if valid_773416 != nil:
    section.add "Timestamp", valid_773416
  var valid_773417 = query.getOrDefault("SignatureVersion")
  valid_773417 = validateParameter(valid_773417, JString, required = true,
                                 default = nil)
  if valid_773417 != nil:
    section.add "SignatureVersion", valid_773417
  var valid_773418 = query.getOrDefault("AWSAccessKeyId")
  valid_773418 = validateParameter(valid_773418, JString, required = true,
                                 default = nil)
  if valid_773418 != nil:
    section.add "AWSAccessKeyId", valid_773418
  var valid_773419 = query.getOrDefault("Version")
  valid_773419 = validateParameter(valid_773419, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_773419 != nil:
    section.add "Version", valid_773419
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : A string informing Amazon SimpleDB where to start the next list of domain names.
  ##   MaxNumberOfDomains: JInt
  ##                     : The maximum number of domain names you want returned. The range is 1 to 100. The default setting is 100.
  section = newJObject()
  var valid_773420 = formData.getOrDefault("NextToken")
  valid_773420 = validateParameter(valid_773420, JString, required = false,
                                 default = nil)
  if valid_773420 != nil:
    section.add "NextToken", valid_773420
  var valid_773421 = formData.getOrDefault("MaxNumberOfDomains")
  valid_773421 = validateParameter(valid_773421, JInt, required = false, default = nil)
  if valid_773421 != nil:
    section.add "MaxNumberOfDomains", valid_773421
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773422: Call_PostListDomains_773410; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  let valid = call_773422.validator(path, query, header, formData, body)
  let scheme = call_773422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773422.url(scheme.get, call_773422.host, call_773422.base,
                         call_773422.route, valid.getOrDefault("path"))
  result = hook(call_773422, url, valid)

proc call*(call_773423: Call_PostListDomains_773410; SignatureMethod: string;
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
  var query_773424 = newJObject()
  var formData_773425 = newJObject()
  add(formData_773425, "NextToken", newJString(NextToken))
  add(query_773424, "SignatureMethod", newJString(SignatureMethod))
  add(query_773424, "Signature", newJString(Signature))
  add(query_773424, "Action", newJString(Action))
  add(query_773424, "Timestamp", newJString(Timestamp))
  add(query_773424, "SignatureVersion", newJString(SignatureVersion))
  add(query_773424, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_773425, "MaxNumberOfDomains", newJInt(MaxNumberOfDomains))
  add(query_773424, "Version", newJString(Version))
  result = call_773423.call(nil, query_773424, nil, formData_773425, nil)

var postListDomains* = Call_PostListDomains_773410(name: "postListDomains",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=ListDomains", validator: validate_PostListDomains_773411,
    base: "/", url: url_PostListDomains_773412, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDomains_773395 = ref object of OpenApiRestCall_772581
proc url_GetListDomains_773397(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListDomains_773396(path: JsonNode; query: JsonNode;
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
  var valid_773398 = query.getOrDefault("SignatureMethod")
  valid_773398 = validateParameter(valid_773398, JString, required = true,
                                 default = nil)
  if valid_773398 != nil:
    section.add "SignatureMethod", valid_773398
  var valid_773399 = query.getOrDefault("Signature")
  valid_773399 = validateParameter(valid_773399, JString, required = true,
                                 default = nil)
  if valid_773399 != nil:
    section.add "Signature", valid_773399
  var valid_773400 = query.getOrDefault("NextToken")
  valid_773400 = validateParameter(valid_773400, JString, required = false,
                                 default = nil)
  if valid_773400 != nil:
    section.add "NextToken", valid_773400
  var valid_773401 = query.getOrDefault("Action")
  valid_773401 = validateParameter(valid_773401, JString, required = true,
                                 default = newJString("ListDomains"))
  if valid_773401 != nil:
    section.add "Action", valid_773401
  var valid_773402 = query.getOrDefault("Timestamp")
  valid_773402 = validateParameter(valid_773402, JString, required = true,
                                 default = nil)
  if valid_773402 != nil:
    section.add "Timestamp", valid_773402
  var valid_773403 = query.getOrDefault("SignatureVersion")
  valid_773403 = validateParameter(valid_773403, JString, required = true,
                                 default = nil)
  if valid_773403 != nil:
    section.add "SignatureVersion", valid_773403
  var valid_773404 = query.getOrDefault("AWSAccessKeyId")
  valid_773404 = validateParameter(valid_773404, JString, required = true,
                                 default = nil)
  if valid_773404 != nil:
    section.add "AWSAccessKeyId", valid_773404
  var valid_773405 = query.getOrDefault("Version")
  valid_773405 = validateParameter(valid_773405, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_773405 != nil:
    section.add "Version", valid_773405
  var valid_773406 = query.getOrDefault("MaxNumberOfDomains")
  valid_773406 = validateParameter(valid_773406, JInt, required = false, default = nil)
  if valid_773406 != nil:
    section.add "MaxNumberOfDomains", valid_773406
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773407: Call_GetListDomains_773395; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  let valid = call_773407.validator(path, query, header, formData, body)
  let scheme = call_773407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773407.url(scheme.get, call_773407.host, call_773407.base,
                         call_773407.route, valid.getOrDefault("path"))
  result = hook(call_773407, url, valid)

proc call*(call_773408: Call_GetListDomains_773395; SignatureMethod: string;
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
  var query_773409 = newJObject()
  add(query_773409, "SignatureMethod", newJString(SignatureMethod))
  add(query_773409, "Signature", newJString(Signature))
  add(query_773409, "NextToken", newJString(NextToken))
  add(query_773409, "Action", newJString(Action))
  add(query_773409, "Timestamp", newJString(Timestamp))
  add(query_773409, "SignatureVersion", newJString(SignatureVersion))
  add(query_773409, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773409, "Version", newJString(Version))
  add(query_773409, "MaxNumberOfDomains", newJInt(MaxNumberOfDomains))
  result = call_773408.call(nil, query_773409, nil, nil, nil)

var getListDomains* = Call_GetListDomains_773395(name: "getListDomains",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=ListDomains", validator: validate_GetListDomains_773396,
    base: "/", url: url_GetListDomains_773397, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutAttributes_773445 = ref object of OpenApiRestCall_772581
proc url_PostPutAttributes_773447(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPutAttributes_773446(path: JsonNode; query: JsonNode;
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
  var valid_773448 = query.getOrDefault("SignatureMethod")
  valid_773448 = validateParameter(valid_773448, JString, required = true,
                                 default = nil)
  if valid_773448 != nil:
    section.add "SignatureMethod", valid_773448
  var valid_773449 = query.getOrDefault("Signature")
  valid_773449 = validateParameter(valid_773449, JString, required = true,
                                 default = nil)
  if valid_773449 != nil:
    section.add "Signature", valid_773449
  var valid_773450 = query.getOrDefault("Action")
  valid_773450 = validateParameter(valid_773450, JString, required = true,
                                 default = newJString("PutAttributes"))
  if valid_773450 != nil:
    section.add "Action", valid_773450
  var valid_773451 = query.getOrDefault("Timestamp")
  valid_773451 = validateParameter(valid_773451, JString, required = true,
                                 default = nil)
  if valid_773451 != nil:
    section.add "Timestamp", valid_773451
  var valid_773452 = query.getOrDefault("SignatureVersion")
  valid_773452 = validateParameter(valid_773452, JString, required = true,
                                 default = nil)
  if valid_773452 != nil:
    section.add "SignatureVersion", valid_773452
  var valid_773453 = query.getOrDefault("AWSAccessKeyId")
  valid_773453 = validateParameter(valid_773453, JString, required = true,
                                 default = nil)
  if valid_773453 != nil:
    section.add "AWSAccessKeyId", valid_773453
  var valid_773454 = query.getOrDefault("Version")
  valid_773454 = validateParameter(valid_773454, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_773454 != nil:
    section.add "Version", valid_773454
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
  var valid_773455 = formData.getOrDefault("DomainName")
  valid_773455 = validateParameter(valid_773455, JString, required = true,
                                 default = nil)
  if valid_773455 != nil:
    section.add "DomainName", valid_773455
  var valid_773456 = formData.getOrDefault("ItemName")
  valid_773456 = validateParameter(valid_773456, JString, required = true,
                                 default = nil)
  if valid_773456 != nil:
    section.add "ItemName", valid_773456
  var valid_773457 = formData.getOrDefault("Expected.Exists")
  valid_773457 = validateParameter(valid_773457, JString, required = false,
                                 default = nil)
  if valid_773457 != nil:
    section.add "Expected.Exists", valid_773457
  var valid_773458 = formData.getOrDefault("Attributes")
  valid_773458 = validateParameter(valid_773458, JArray, required = true, default = nil)
  if valid_773458 != nil:
    section.add "Attributes", valid_773458
  var valid_773459 = formData.getOrDefault("Expected.Value")
  valid_773459 = validateParameter(valid_773459, JString, required = false,
                                 default = nil)
  if valid_773459 != nil:
    section.add "Expected.Value", valid_773459
  var valid_773460 = formData.getOrDefault("Expected.Name")
  valid_773460 = validateParameter(valid_773460, JString, required = false,
                                 default = nil)
  if valid_773460 != nil:
    section.add "Expected.Name", valid_773460
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773461: Call_PostPutAttributes_773445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  let valid = call_773461.validator(path, query, header, formData, body)
  let scheme = call_773461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773461.url(scheme.get, call_773461.host, call_773461.base,
                         call_773461.route, valid.getOrDefault("path"))
  result = hook(call_773461, url, valid)

proc call*(call_773462: Call_PostPutAttributes_773445; SignatureMethod: string;
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
  var query_773463 = newJObject()
  var formData_773464 = newJObject()
  add(query_773463, "SignatureMethod", newJString(SignatureMethod))
  add(formData_773464, "DomainName", newJString(DomainName))
  add(formData_773464, "ItemName", newJString(ItemName))
  add(formData_773464, "Expected.Exists", newJString(ExpectedExists))
  add(query_773463, "Signature", newJString(Signature))
  if Attributes != nil:
    formData_773464.add "Attributes", Attributes
  add(query_773463, "Action", newJString(Action))
  add(query_773463, "Timestamp", newJString(Timestamp))
  add(formData_773464, "Expected.Value", newJString(ExpectedValue))
  add(formData_773464, "Expected.Name", newJString(ExpectedName))
  add(query_773463, "SignatureVersion", newJString(SignatureVersion))
  add(query_773463, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773463, "Version", newJString(Version))
  result = call_773462.call(nil, query_773463, nil, formData_773464, nil)

var postPutAttributes* = Call_PostPutAttributes_773445(name: "postPutAttributes",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=PutAttributes", validator: validate_PostPutAttributes_773446,
    base: "/", url: url_PostPutAttributes_773447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutAttributes_773426 = ref object of OpenApiRestCall_772581
proc url_GetPutAttributes_773428(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPutAttributes_773427(path: JsonNode; query: JsonNode;
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
  var valid_773429 = query.getOrDefault("SignatureMethod")
  valid_773429 = validateParameter(valid_773429, JString, required = true,
                                 default = nil)
  if valid_773429 != nil:
    section.add "SignatureMethod", valid_773429
  var valid_773430 = query.getOrDefault("Expected.Exists")
  valid_773430 = validateParameter(valid_773430, JString, required = false,
                                 default = nil)
  if valid_773430 != nil:
    section.add "Expected.Exists", valid_773430
  var valid_773431 = query.getOrDefault("Attributes")
  valid_773431 = validateParameter(valid_773431, JArray, required = true, default = nil)
  if valid_773431 != nil:
    section.add "Attributes", valid_773431
  var valid_773432 = query.getOrDefault("Signature")
  valid_773432 = validateParameter(valid_773432, JString, required = true,
                                 default = nil)
  if valid_773432 != nil:
    section.add "Signature", valid_773432
  var valid_773433 = query.getOrDefault("ItemName")
  valid_773433 = validateParameter(valid_773433, JString, required = true,
                                 default = nil)
  if valid_773433 != nil:
    section.add "ItemName", valid_773433
  var valid_773434 = query.getOrDefault("Action")
  valid_773434 = validateParameter(valid_773434, JString, required = true,
                                 default = newJString("PutAttributes"))
  if valid_773434 != nil:
    section.add "Action", valid_773434
  var valid_773435 = query.getOrDefault("Expected.Value")
  valid_773435 = validateParameter(valid_773435, JString, required = false,
                                 default = nil)
  if valid_773435 != nil:
    section.add "Expected.Value", valid_773435
  var valid_773436 = query.getOrDefault("Timestamp")
  valid_773436 = validateParameter(valid_773436, JString, required = true,
                                 default = nil)
  if valid_773436 != nil:
    section.add "Timestamp", valid_773436
  var valid_773437 = query.getOrDefault("SignatureVersion")
  valid_773437 = validateParameter(valid_773437, JString, required = true,
                                 default = nil)
  if valid_773437 != nil:
    section.add "SignatureVersion", valid_773437
  var valid_773438 = query.getOrDefault("AWSAccessKeyId")
  valid_773438 = validateParameter(valid_773438, JString, required = true,
                                 default = nil)
  if valid_773438 != nil:
    section.add "AWSAccessKeyId", valid_773438
  var valid_773439 = query.getOrDefault("Expected.Name")
  valid_773439 = validateParameter(valid_773439, JString, required = false,
                                 default = nil)
  if valid_773439 != nil:
    section.add "Expected.Name", valid_773439
  var valid_773440 = query.getOrDefault("DomainName")
  valid_773440 = validateParameter(valid_773440, JString, required = true,
                                 default = nil)
  if valid_773440 != nil:
    section.add "DomainName", valid_773440
  var valid_773441 = query.getOrDefault("Version")
  valid_773441 = validateParameter(valid_773441, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_773441 != nil:
    section.add "Version", valid_773441
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773442: Call_GetPutAttributes_773426; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  let valid = call_773442.validator(path, query, header, formData, body)
  let scheme = call_773442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773442.url(scheme.get, call_773442.host, call_773442.base,
                         call_773442.route, valid.getOrDefault("path"))
  result = hook(call_773442, url, valid)

proc call*(call_773443: Call_GetPutAttributes_773426; SignatureMethod: string;
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
  var query_773444 = newJObject()
  add(query_773444, "SignatureMethod", newJString(SignatureMethod))
  add(query_773444, "Expected.Exists", newJString(ExpectedExists))
  if Attributes != nil:
    query_773444.add "Attributes", Attributes
  add(query_773444, "Signature", newJString(Signature))
  add(query_773444, "ItemName", newJString(ItemName))
  add(query_773444, "Action", newJString(Action))
  add(query_773444, "Expected.Value", newJString(ExpectedValue))
  add(query_773444, "Timestamp", newJString(Timestamp))
  add(query_773444, "SignatureVersion", newJString(SignatureVersion))
  add(query_773444, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773444, "Expected.Name", newJString(ExpectedName))
  add(query_773444, "DomainName", newJString(DomainName))
  add(query_773444, "Version", newJString(Version))
  result = call_773443.call(nil, query_773444, nil, nil, nil)

var getPutAttributes* = Call_GetPutAttributes_773426(name: "getPutAttributes",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=PutAttributes", validator: validate_GetPutAttributes_773427,
    base: "/", url: url_GetPutAttributes_773428,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSelect_773481 = ref object of OpenApiRestCall_772581
proc url_PostSelect_773483(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSelect_773482(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773484 = query.getOrDefault("SignatureMethod")
  valid_773484 = validateParameter(valid_773484, JString, required = true,
                                 default = nil)
  if valid_773484 != nil:
    section.add "SignatureMethod", valid_773484
  var valid_773485 = query.getOrDefault("Signature")
  valid_773485 = validateParameter(valid_773485, JString, required = true,
                                 default = nil)
  if valid_773485 != nil:
    section.add "Signature", valid_773485
  var valid_773486 = query.getOrDefault("Action")
  valid_773486 = validateParameter(valid_773486, JString, required = true,
                                 default = newJString("Select"))
  if valid_773486 != nil:
    section.add "Action", valid_773486
  var valid_773487 = query.getOrDefault("Timestamp")
  valid_773487 = validateParameter(valid_773487, JString, required = true,
                                 default = nil)
  if valid_773487 != nil:
    section.add "Timestamp", valid_773487
  var valid_773488 = query.getOrDefault("SignatureVersion")
  valid_773488 = validateParameter(valid_773488, JString, required = true,
                                 default = nil)
  if valid_773488 != nil:
    section.add "SignatureVersion", valid_773488
  var valid_773489 = query.getOrDefault("AWSAccessKeyId")
  valid_773489 = validateParameter(valid_773489, JString, required = true,
                                 default = nil)
  if valid_773489 != nil:
    section.add "AWSAccessKeyId", valid_773489
  var valid_773490 = query.getOrDefault("Version")
  valid_773490 = validateParameter(valid_773490, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_773490 != nil:
    section.add "Version", valid_773490
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
  var valid_773491 = formData.getOrDefault("NextToken")
  valid_773491 = validateParameter(valid_773491, JString, required = false,
                                 default = nil)
  if valid_773491 != nil:
    section.add "NextToken", valid_773491
  var valid_773492 = formData.getOrDefault("ConsistentRead")
  valid_773492 = validateParameter(valid_773492, JBool, required = false, default = nil)
  if valid_773492 != nil:
    section.add "ConsistentRead", valid_773492
  assert formData != nil, "formData argument is necessary due to required `SelectExpression` field"
  var valid_773493 = formData.getOrDefault("SelectExpression")
  valid_773493 = validateParameter(valid_773493, JString, required = true,
                                 default = nil)
  if valid_773493 != nil:
    section.add "SelectExpression", valid_773493
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773494: Call_PostSelect_773481; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  let valid = call_773494.validator(path, query, header, formData, body)
  let scheme = call_773494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773494.url(scheme.get, call_773494.host, call_773494.base,
                         call_773494.route, valid.getOrDefault("path"))
  result = hook(call_773494, url, valid)

proc call*(call_773495: Call_PostSelect_773481; SignatureMethod: string;
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
  var query_773496 = newJObject()
  var formData_773497 = newJObject()
  add(formData_773497, "NextToken", newJString(NextToken))
  add(query_773496, "SignatureMethod", newJString(SignatureMethod))
  add(formData_773497, "ConsistentRead", newJBool(ConsistentRead))
  add(query_773496, "Signature", newJString(Signature))
  add(query_773496, "Action", newJString(Action))
  add(query_773496, "Timestamp", newJString(Timestamp))
  add(query_773496, "SignatureVersion", newJString(SignatureVersion))
  add(query_773496, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_773497, "SelectExpression", newJString(SelectExpression))
  add(query_773496, "Version", newJString(Version))
  result = call_773495.call(nil, query_773496, nil, formData_773497, nil)

var postSelect* = Call_PostSelect_773481(name: "postSelect",
                                      meth: HttpMethod.HttpPost,
                                      host: "sdb.amazonaws.com",
                                      route: "/#Action=Select",
                                      validator: validate_PostSelect_773482,
                                      base: "/", url: url_PostSelect_773483,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSelect_773465 = ref object of OpenApiRestCall_772581
proc url_GetSelect_773467(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSelect_773466(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773468 = query.getOrDefault("SignatureMethod")
  valid_773468 = validateParameter(valid_773468, JString, required = true,
                                 default = nil)
  if valid_773468 != nil:
    section.add "SignatureMethod", valid_773468
  var valid_773469 = query.getOrDefault("Signature")
  valid_773469 = validateParameter(valid_773469, JString, required = true,
                                 default = nil)
  if valid_773469 != nil:
    section.add "Signature", valid_773469
  var valid_773470 = query.getOrDefault("NextToken")
  valid_773470 = validateParameter(valid_773470, JString, required = false,
                                 default = nil)
  if valid_773470 != nil:
    section.add "NextToken", valid_773470
  var valid_773471 = query.getOrDefault("SelectExpression")
  valid_773471 = validateParameter(valid_773471, JString, required = true,
                                 default = nil)
  if valid_773471 != nil:
    section.add "SelectExpression", valid_773471
  var valid_773472 = query.getOrDefault("Action")
  valid_773472 = validateParameter(valid_773472, JString, required = true,
                                 default = newJString("Select"))
  if valid_773472 != nil:
    section.add "Action", valid_773472
  var valid_773473 = query.getOrDefault("Timestamp")
  valid_773473 = validateParameter(valid_773473, JString, required = true,
                                 default = nil)
  if valid_773473 != nil:
    section.add "Timestamp", valid_773473
  var valid_773474 = query.getOrDefault("ConsistentRead")
  valid_773474 = validateParameter(valid_773474, JBool, required = false, default = nil)
  if valid_773474 != nil:
    section.add "ConsistentRead", valid_773474
  var valid_773475 = query.getOrDefault("SignatureVersion")
  valid_773475 = validateParameter(valid_773475, JString, required = true,
                                 default = nil)
  if valid_773475 != nil:
    section.add "SignatureVersion", valid_773475
  var valid_773476 = query.getOrDefault("AWSAccessKeyId")
  valid_773476 = validateParameter(valid_773476, JString, required = true,
                                 default = nil)
  if valid_773476 != nil:
    section.add "AWSAccessKeyId", valid_773476
  var valid_773477 = query.getOrDefault("Version")
  valid_773477 = validateParameter(valid_773477, JString, required = true,
                                 default = newJString("2009-04-15"))
  if valid_773477 != nil:
    section.add "Version", valid_773477
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773478: Call_GetSelect_773465; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  let valid = call_773478.validator(path, query, header, formData, body)
  let scheme = call_773478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773478.url(scheme.get, call_773478.host, call_773478.base,
                         call_773478.route, valid.getOrDefault("path"))
  result = hook(call_773478, url, valid)

proc call*(call_773479: Call_GetSelect_773465; SignatureMethod: string;
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
  var query_773480 = newJObject()
  add(query_773480, "SignatureMethod", newJString(SignatureMethod))
  add(query_773480, "Signature", newJString(Signature))
  add(query_773480, "NextToken", newJString(NextToken))
  add(query_773480, "SelectExpression", newJString(SelectExpression))
  add(query_773480, "Action", newJString(Action))
  add(query_773480, "Timestamp", newJString(Timestamp))
  add(query_773480, "ConsistentRead", newJBool(ConsistentRead))
  add(query_773480, "SignatureVersion", newJString(SignatureVersion))
  add(query_773480, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_773480, "Version", newJString(Version))
  result = call_773479.call(nil, query_773480, nil, nil, nil)

var getSelect* = Call_GetSelect_773465(name: "getSelect", meth: HttpMethod.HttpGet,
                                    host: "sdb.amazonaws.com",
                                    route: "/#Action=Select",
                                    validator: validate_GetSelect_773466,
                                    base: "/", url: url_GetSelect_773467,
                                    schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
