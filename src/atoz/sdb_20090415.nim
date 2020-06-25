
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625418 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625418](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625418): Option[Scheme] {.used.} =
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
    if required:
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_PostBatchDeleteAttributes_21626016 = ref object of OpenApiRestCall_21625418
proc url_PostBatchDeleteAttributes_21626018(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostBatchDeleteAttributes_21626017(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626019 = query.getOrDefault("SignatureMethod")
  valid_21626019 = validateParameter(valid_21626019, JString, required = true,
                                   default = nil)
  if valid_21626019 != nil:
    section.add "SignatureMethod", valid_21626019
  var valid_21626020 = query.getOrDefault("Signature")
  valid_21626020 = validateParameter(valid_21626020, JString, required = true,
                                   default = nil)
  if valid_21626020 != nil:
    section.add "Signature", valid_21626020
  var valid_21626021 = query.getOrDefault("Action")
  valid_21626021 = validateParameter(valid_21626021, JString, required = true, default = newJString(
      "BatchDeleteAttributes"))
  if valid_21626021 != nil:
    section.add "Action", valid_21626021
  var valid_21626022 = query.getOrDefault("Timestamp")
  valid_21626022 = validateParameter(valid_21626022, JString, required = true,
                                   default = nil)
  if valid_21626022 != nil:
    section.add "Timestamp", valid_21626022
  var valid_21626023 = query.getOrDefault("SignatureVersion")
  valid_21626023 = validateParameter(valid_21626023, JString, required = true,
                                   default = nil)
  if valid_21626023 != nil:
    section.add "SignatureVersion", valid_21626023
  var valid_21626024 = query.getOrDefault("AWSAccessKeyId")
  valid_21626024 = validateParameter(valid_21626024, JString, required = true,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "AWSAccessKeyId", valid_21626024
  var valid_21626025 = query.getOrDefault("Version")
  valid_21626025 = validateParameter(valid_21626025, JString, required = true,
                                   default = newJString("2009-04-15"))
  if valid_21626025 != nil:
    section.add "Version", valid_21626025
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
  var valid_21626026 = formData.getOrDefault("DomainName")
  valid_21626026 = validateParameter(valid_21626026, JString, required = true,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "DomainName", valid_21626026
  var valid_21626027 = formData.getOrDefault("Items")
  valid_21626027 = validateParameter(valid_21626027, JArray, required = true,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "Items", valid_21626027
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626028: Call_PostBatchDeleteAttributes_21626016;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  let valid = call_21626028.validator(path, query, header, formData, body, _)
  let scheme = call_21626028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626028.makeUrl(scheme.get, call_21626028.host, call_21626028.base,
                               call_21626028.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626028, uri, valid, _)

proc call*(call_21626029: Call_PostBatchDeleteAttributes_21626016;
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
  var query_21626030 = newJObject()
  var formData_21626031 = newJObject()
  add(query_21626030, "SignatureMethod", newJString(SignatureMethod))
  add(formData_21626031, "DomainName", newJString(DomainName))
  add(query_21626030, "Signature", newJString(Signature))
  add(query_21626030, "Action", newJString(Action))
  add(query_21626030, "Timestamp", newJString(Timestamp))
  if Items != nil:
    formData_21626031.add "Items", Items
  add(query_21626030, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626030, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626030, "Version", newJString(Version))
  result = call_21626029.call(nil, query_21626030, nil, formData_21626031, nil)

var postBatchDeleteAttributes* = Call_PostBatchDeleteAttributes_21626016(
    name: "postBatchDeleteAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=BatchDeleteAttributes",
    validator: validate_PostBatchDeleteAttributes_21626017, base: "/",
    makeUrl: url_PostBatchDeleteAttributes_21626018,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchDeleteAttributes_21625762 = ref object of OpenApiRestCall_21625418
proc url_GetBatchDeleteAttributes_21625764(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBatchDeleteAttributes_21625763(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21625865 = query.getOrDefault("SignatureMethod")
  valid_21625865 = validateParameter(valid_21625865, JString, required = true,
                                   default = nil)
  if valid_21625865 != nil:
    section.add "SignatureMethod", valid_21625865
  var valid_21625866 = query.getOrDefault("Signature")
  valid_21625866 = validateParameter(valid_21625866, JString, required = true,
                                   default = nil)
  if valid_21625866 != nil:
    section.add "Signature", valid_21625866
  var valid_21625881 = query.getOrDefault("Action")
  valid_21625881 = validateParameter(valid_21625881, JString, required = true, default = newJString(
      "BatchDeleteAttributes"))
  if valid_21625881 != nil:
    section.add "Action", valid_21625881
  var valid_21625882 = query.getOrDefault("Timestamp")
  valid_21625882 = validateParameter(valid_21625882, JString, required = true,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "Timestamp", valid_21625882
  var valid_21625883 = query.getOrDefault("Items")
  valid_21625883 = validateParameter(valid_21625883, JArray, required = true,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "Items", valid_21625883
  var valid_21625884 = query.getOrDefault("SignatureVersion")
  valid_21625884 = validateParameter(valid_21625884, JString, required = true,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "SignatureVersion", valid_21625884
  var valid_21625885 = query.getOrDefault("AWSAccessKeyId")
  valid_21625885 = validateParameter(valid_21625885, JString, required = true,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "AWSAccessKeyId", valid_21625885
  var valid_21625886 = query.getOrDefault("DomainName")
  valid_21625886 = validateParameter(valid_21625886, JString, required = true,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "DomainName", valid_21625886
  var valid_21625887 = query.getOrDefault("Version")
  valid_21625887 = validateParameter(valid_21625887, JString, required = true,
                                   default = newJString("2009-04-15"))
  if valid_21625887 != nil:
    section.add "Version", valid_21625887
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625912: Call_GetBatchDeleteAttributes_21625762;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
  ## 
  let valid = call_21625912.validator(path, query, header, formData, body, _)
  let scheme = call_21625912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625912.makeUrl(scheme.get, call_21625912.host, call_21625912.base,
                               call_21625912.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625912, uri, valid, _)

proc call*(call_21625975: Call_GetBatchDeleteAttributes_21625762;
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
  var query_21625977 = newJObject()
  add(query_21625977, "SignatureMethod", newJString(SignatureMethod))
  add(query_21625977, "Signature", newJString(Signature))
  add(query_21625977, "Action", newJString(Action))
  add(query_21625977, "Timestamp", newJString(Timestamp))
  if Items != nil:
    query_21625977.add "Items", Items
  add(query_21625977, "SignatureVersion", newJString(SignatureVersion))
  add(query_21625977, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21625977, "DomainName", newJString(DomainName))
  add(query_21625977, "Version", newJString(Version))
  result = call_21625975.call(nil, query_21625977, nil, nil, nil)

var getBatchDeleteAttributes* = Call_GetBatchDeleteAttributes_21625762(
    name: "getBatchDeleteAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=BatchDeleteAttributes",
    validator: validate_GetBatchDeleteAttributes_21625763, base: "/",
    makeUrl: url_GetBatchDeleteAttributes_21625764,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostBatchPutAttributes_21626047 = ref object of OpenApiRestCall_21625418
proc url_PostBatchPutAttributes_21626049(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostBatchPutAttributes_21626048(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626050 = query.getOrDefault("SignatureMethod")
  valid_21626050 = validateParameter(valid_21626050, JString, required = true,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "SignatureMethod", valid_21626050
  var valid_21626051 = query.getOrDefault("Signature")
  valid_21626051 = validateParameter(valid_21626051, JString, required = true,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "Signature", valid_21626051
  var valid_21626052 = query.getOrDefault("Action")
  valid_21626052 = validateParameter(valid_21626052, JString, required = true,
                                   default = newJString("BatchPutAttributes"))
  if valid_21626052 != nil:
    section.add "Action", valid_21626052
  var valid_21626053 = query.getOrDefault("Timestamp")
  valid_21626053 = validateParameter(valid_21626053, JString, required = true,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "Timestamp", valid_21626053
  var valid_21626054 = query.getOrDefault("SignatureVersion")
  valid_21626054 = validateParameter(valid_21626054, JString, required = true,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "SignatureVersion", valid_21626054
  var valid_21626055 = query.getOrDefault("AWSAccessKeyId")
  valid_21626055 = validateParameter(valid_21626055, JString, required = true,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "AWSAccessKeyId", valid_21626055
  var valid_21626056 = query.getOrDefault("Version")
  valid_21626056 = validateParameter(valid_21626056, JString, required = true,
                                   default = newJString("2009-04-15"))
  if valid_21626056 != nil:
    section.add "Version", valid_21626056
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
  var valid_21626057 = formData.getOrDefault("DomainName")
  valid_21626057 = validateParameter(valid_21626057, JString, required = true,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "DomainName", valid_21626057
  var valid_21626058 = formData.getOrDefault("Items")
  valid_21626058 = validateParameter(valid_21626058, JArray, required = true,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "Items", valid_21626058
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626059: Call_PostBatchPutAttributes_21626047;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  let valid = call_21626059.validator(path, query, header, formData, body, _)
  let scheme = call_21626059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626059.makeUrl(scheme.get, call_21626059.host, call_21626059.base,
                               call_21626059.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626059, uri, valid, _)

proc call*(call_21626060: Call_PostBatchPutAttributes_21626047;
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
  var query_21626061 = newJObject()
  var formData_21626062 = newJObject()
  add(query_21626061, "SignatureMethod", newJString(SignatureMethod))
  add(formData_21626062, "DomainName", newJString(DomainName))
  add(query_21626061, "Signature", newJString(Signature))
  add(query_21626061, "Action", newJString(Action))
  add(query_21626061, "Timestamp", newJString(Timestamp))
  if Items != nil:
    formData_21626062.add "Items", Items
  add(query_21626061, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626061, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626061, "Version", newJString(Version))
  result = call_21626060.call(nil, query_21626061, nil, formData_21626062, nil)

var postBatchPutAttributes* = Call_PostBatchPutAttributes_21626047(
    name: "postBatchPutAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=BatchPutAttributes",
    validator: validate_PostBatchPutAttributes_21626048, base: "/",
    makeUrl: url_PostBatchPutAttributes_21626049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchPutAttributes_21626032 = ref object of OpenApiRestCall_21625418
proc url_GetBatchPutAttributes_21626034(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBatchPutAttributes_21626033(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626035 = query.getOrDefault("SignatureMethod")
  valid_21626035 = validateParameter(valid_21626035, JString, required = true,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "SignatureMethod", valid_21626035
  var valid_21626036 = query.getOrDefault("Signature")
  valid_21626036 = validateParameter(valid_21626036, JString, required = true,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "Signature", valid_21626036
  var valid_21626037 = query.getOrDefault("Action")
  valid_21626037 = validateParameter(valid_21626037, JString, required = true,
                                   default = newJString("BatchPutAttributes"))
  if valid_21626037 != nil:
    section.add "Action", valid_21626037
  var valid_21626038 = query.getOrDefault("Timestamp")
  valid_21626038 = validateParameter(valid_21626038, JString, required = true,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "Timestamp", valid_21626038
  var valid_21626039 = query.getOrDefault("Items")
  valid_21626039 = validateParameter(valid_21626039, JArray, required = true,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "Items", valid_21626039
  var valid_21626040 = query.getOrDefault("SignatureVersion")
  valid_21626040 = validateParameter(valid_21626040, JString, required = true,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "SignatureVersion", valid_21626040
  var valid_21626041 = query.getOrDefault("AWSAccessKeyId")
  valid_21626041 = validateParameter(valid_21626041, JString, required = true,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "AWSAccessKeyId", valid_21626041
  var valid_21626042 = query.getOrDefault("DomainName")
  valid_21626042 = validateParameter(valid_21626042, JString, required = true,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "DomainName", valid_21626042
  var valid_21626043 = query.getOrDefault("Version")
  valid_21626043 = validateParameter(valid_21626043, JString, required = true,
                                   default = newJString("2009-04-15"))
  if valid_21626043 != nil:
    section.add "Version", valid_21626043
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626044: Call_GetBatchPutAttributes_21626032;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
  ## 
  let valid = call_21626044.validator(path, query, header, formData, body, _)
  let scheme = call_21626044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626044.makeUrl(scheme.get, call_21626044.host, call_21626044.base,
                               call_21626044.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626044, uri, valid, _)

proc call*(call_21626045: Call_GetBatchPutAttributes_21626032;
          SignatureMethod: string; Signature: string; Timestamp: string;
          Items: JsonNode; SignatureVersion: string; AWSAccessKeyId: string;
          DomainName: string; Action: string = "BatchPutAttributes";
          Version: string = "2009-04-15"): Recallable =
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
  var query_21626046 = newJObject()
  add(query_21626046, "SignatureMethod", newJString(SignatureMethod))
  add(query_21626046, "Signature", newJString(Signature))
  add(query_21626046, "Action", newJString(Action))
  add(query_21626046, "Timestamp", newJString(Timestamp))
  if Items != nil:
    query_21626046.add "Items", Items
  add(query_21626046, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626046, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626046, "DomainName", newJString(DomainName))
  add(query_21626046, "Version", newJString(Version))
  result = call_21626045.call(nil, query_21626046, nil, nil, nil)

var getBatchPutAttributes* = Call_GetBatchPutAttributes_21626032(
    name: "getBatchPutAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=BatchPutAttributes",
    validator: validate_GetBatchPutAttributes_21626033, base: "/",
    makeUrl: url_GetBatchPutAttributes_21626034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDomain_21626077 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDomain_21626079(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDomain_21626078(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626080 = query.getOrDefault("SignatureMethod")
  valid_21626080 = validateParameter(valid_21626080, JString, required = true,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "SignatureMethod", valid_21626080
  var valid_21626081 = query.getOrDefault("Signature")
  valid_21626081 = validateParameter(valid_21626081, JString, required = true,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "Signature", valid_21626081
  var valid_21626082 = query.getOrDefault("Action")
  valid_21626082 = validateParameter(valid_21626082, JString, required = true,
                                   default = newJString("CreateDomain"))
  if valid_21626082 != nil:
    section.add "Action", valid_21626082
  var valid_21626083 = query.getOrDefault("Timestamp")
  valid_21626083 = validateParameter(valid_21626083, JString, required = true,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "Timestamp", valid_21626083
  var valid_21626084 = query.getOrDefault("SignatureVersion")
  valid_21626084 = validateParameter(valid_21626084, JString, required = true,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "SignatureVersion", valid_21626084
  var valid_21626085 = query.getOrDefault("AWSAccessKeyId")
  valid_21626085 = validateParameter(valid_21626085, JString, required = true,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "AWSAccessKeyId", valid_21626085
  var valid_21626086 = query.getOrDefault("Version")
  valid_21626086 = validateParameter(valid_21626086, JString, required = true,
                                   default = newJString("2009-04-15"))
  if valid_21626086 != nil:
    section.add "Version", valid_21626086
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain to create. The name can range between 3 and 255 characters and can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626087 = formData.getOrDefault("DomainName")
  valid_21626087 = validateParameter(valid_21626087, JString, required = true,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "DomainName", valid_21626087
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626088: Call_PostCreateDomain_21626077; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  let valid = call_21626088.validator(path, query, header, formData, body, _)
  let scheme = call_21626088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626088.makeUrl(scheme.get, call_21626088.host, call_21626088.base,
                               call_21626088.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626088, uri, valid, _)

proc call*(call_21626089: Call_PostCreateDomain_21626077; SignatureMethod: string;
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
  var query_21626090 = newJObject()
  var formData_21626091 = newJObject()
  add(query_21626090, "SignatureMethod", newJString(SignatureMethod))
  add(formData_21626091, "DomainName", newJString(DomainName))
  add(query_21626090, "Signature", newJString(Signature))
  add(query_21626090, "Action", newJString(Action))
  add(query_21626090, "Timestamp", newJString(Timestamp))
  add(query_21626090, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626090, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626090, "Version", newJString(Version))
  result = call_21626089.call(nil, query_21626090, nil, formData_21626091, nil)

var postCreateDomain* = Call_PostCreateDomain_21626077(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_21626078,
    base: "/", makeUrl: url_PostCreateDomain_21626079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_21626063 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDomain_21626065(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDomain_21626064(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626066 = query.getOrDefault("SignatureMethod")
  valid_21626066 = validateParameter(valid_21626066, JString, required = true,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "SignatureMethod", valid_21626066
  var valid_21626067 = query.getOrDefault("Signature")
  valid_21626067 = validateParameter(valid_21626067, JString, required = true,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "Signature", valid_21626067
  var valid_21626068 = query.getOrDefault("Action")
  valid_21626068 = validateParameter(valid_21626068, JString, required = true,
                                   default = newJString("CreateDomain"))
  if valid_21626068 != nil:
    section.add "Action", valid_21626068
  var valid_21626069 = query.getOrDefault("Timestamp")
  valid_21626069 = validateParameter(valid_21626069, JString, required = true,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "Timestamp", valid_21626069
  var valid_21626070 = query.getOrDefault("SignatureVersion")
  valid_21626070 = validateParameter(valid_21626070, JString, required = true,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "SignatureVersion", valid_21626070
  var valid_21626071 = query.getOrDefault("AWSAccessKeyId")
  valid_21626071 = validateParameter(valid_21626071, JString, required = true,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "AWSAccessKeyId", valid_21626071
  var valid_21626072 = query.getOrDefault("DomainName")
  valid_21626072 = validateParameter(valid_21626072, JString, required = true,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "DomainName", valid_21626072
  var valid_21626073 = query.getOrDefault("Version")
  valid_21626073 = validateParameter(valid_21626073, JString, required = true,
                                   default = newJString("2009-04-15"))
  if valid_21626073 != nil:
    section.add "Version", valid_21626073
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626074: Call_GetCreateDomain_21626063; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
  ## 
  let valid = call_21626074.validator(path, query, header, formData, body, _)
  let scheme = call_21626074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626074.makeUrl(scheme.get, call_21626074.host, call_21626074.base,
                               call_21626074.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626074, uri, valid, _)

proc call*(call_21626075: Call_GetCreateDomain_21626063; SignatureMethod: string;
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
  var query_21626076 = newJObject()
  add(query_21626076, "SignatureMethod", newJString(SignatureMethod))
  add(query_21626076, "Signature", newJString(Signature))
  add(query_21626076, "Action", newJString(Action))
  add(query_21626076, "Timestamp", newJString(Timestamp))
  add(query_21626076, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626076, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626076, "DomainName", newJString(DomainName))
  add(query_21626076, "Version", newJString(Version))
  result = call_21626075.call(nil, query_21626076, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_21626063(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_21626064,
    base: "/", makeUrl: url_GetCreateDomain_21626065,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAttributes_21626112 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteAttributes_21626114(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteAttributes_21626113(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626115 = query.getOrDefault("SignatureMethod")
  valid_21626115 = validateParameter(valid_21626115, JString, required = true,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "SignatureMethod", valid_21626115
  var valid_21626116 = query.getOrDefault("Signature")
  valid_21626116 = validateParameter(valid_21626116, JString, required = true,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "Signature", valid_21626116
  var valid_21626117 = query.getOrDefault("Action")
  valid_21626117 = validateParameter(valid_21626117, JString, required = true,
                                   default = newJString("DeleteAttributes"))
  if valid_21626117 != nil:
    section.add "Action", valid_21626117
  var valid_21626118 = query.getOrDefault("Timestamp")
  valid_21626118 = validateParameter(valid_21626118, JString, required = true,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "Timestamp", valid_21626118
  var valid_21626119 = query.getOrDefault("SignatureVersion")
  valid_21626119 = validateParameter(valid_21626119, JString, required = true,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "SignatureVersion", valid_21626119
  var valid_21626120 = query.getOrDefault("AWSAccessKeyId")
  valid_21626120 = validateParameter(valid_21626120, JString, required = true,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "AWSAccessKeyId", valid_21626120
  var valid_21626121 = query.getOrDefault("Version")
  valid_21626121 = validateParameter(valid_21626121, JString, required = true,
                                   default = newJString("2009-04-15"))
  if valid_21626121 != nil:
    section.add "Version", valid_21626121
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
  var valid_21626122 = formData.getOrDefault("DomainName")
  valid_21626122 = validateParameter(valid_21626122, JString, required = true,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "DomainName", valid_21626122
  var valid_21626123 = formData.getOrDefault("ItemName")
  valid_21626123 = validateParameter(valid_21626123, JString, required = true,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "ItemName", valid_21626123
  var valid_21626124 = formData.getOrDefault("Expected.Exists")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "Expected.Exists", valid_21626124
  var valid_21626125 = formData.getOrDefault("Attributes")
  valid_21626125 = validateParameter(valid_21626125, JArray, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "Attributes", valid_21626125
  var valid_21626126 = formData.getOrDefault("Expected.Value")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "Expected.Value", valid_21626126
  var valid_21626127 = formData.getOrDefault("Expected.Name")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "Expected.Name", valid_21626127
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626128: Call_PostDeleteAttributes_21626112; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  let valid = call_21626128.validator(path, query, header, formData, body, _)
  let scheme = call_21626128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626128.makeUrl(scheme.get, call_21626128.host, call_21626128.base,
                               call_21626128.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626128, uri, valid, _)

proc call*(call_21626129: Call_PostDeleteAttributes_21626112;
          SignatureMethod: string; DomainName: string; ItemName: string;
          Signature: string; Timestamp: string; SignatureVersion: string;
          AWSAccessKeyId: string; ExpectedExists: string = "";
          Attributes: JsonNode = nil; Action: string = "DeleteAttributes";
          ExpectedValue: string = ""; ExpectedName: string = "";
          Version: string = "2009-04-15"): Recallable =
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
  var query_21626130 = newJObject()
  var formData_21626131 = newJObject()
  add(query_21626130, "SignatureMethod", newJString(SignatureMethod))
  add(formData_21626131, "DomainName", newJString(DomainName))
  add(formData_21626131, "ItemName", newJString(ItemName))
  add(formData_21626131, "Expected.Exists", newJString(ExpectedExists))
  add(query_21626130, "Signature", newJString(Signature))
  if Attributes != nil:
    formData_21626131.add "Attributes", Attributes
  add(query_21626130, "Action", newJString(Action))
  add(query_21626130, "Timestamp", newJString(Timestamp))
  add(formData_21626131, "Expected.Value", newJString(ExpectedValue))
  add(formData_21626131, "Expected.Name", newJString(ExpectedName))
  add(query_21626130, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626130, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626130, "Version", newJString(Version))
  result = call_21626129.call(nil, query_21626130, nil, formData_21626131, nil)

var postDeleteAttributes* = Call_PostDeleteAttributes_21626112(
    name: "postDeleteAttributes", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=DeleteAttributes",
    validator: validate_PostDeleteAttributes_21626113, base: "/",
    makeUrl: url_PostDeleteAttributes_21626114,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAttributes_21626092 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteAttributes_21626094(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteAttributes_21626093(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626095 = query.getOrDefault("SignatureMethod")
  valid_21626095 = validateParameter(valid_21626095, JString, required = true,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "SignatureMethod", valid_21626095
  var valid_21626096 = query.getOrDefault("Expected.Exists")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "Expected.Exists", valid_21626096
  var valid_21626097 = query.getOrDefault("Attributes")
  valid_21626097 = validateParameter(valid_21626097, JArray, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "Attributes", valid_21626097
  var valid_21626098 = query.getOrDefault("Signature")
  valid_21626098 = validateParameter(valid_21626098, JString, required = true,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "Signature", valid_21626098
  var valid_21626099 = query.getOrDefault("ItemName")
  valid_21626099 = validateParameter(valid_21626099, JString, required = true,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "ItemName", valid_21626099
  var valid_21626100 = query.getOrDefault("Action")
  valid_21626100 = validateParameter(valid_21626100, JString, required = true,
                                   default = newJString("DeleteAttributes"))
  if valid_21626100 != nil:
    section.add "Action", valid_21626100
  var valid_21626101 = query.getOrDefault("Expected.Value")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "Expected.Value", valid_21626101
  var valid_21626102 = query.getOrDefault("Timestamp")
  valid_21626102 = validateParameter(valid_21626102, JString, required = true,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "Timestamp", valid_21626102
  var valid_21626103 = query.getOrDefault("SignatureVersion")
  valid_21626103 = validateParameter(valid_21626103, JString, required = true,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "SignatureVersion", valid_21626103
  var valid_21626104 = query.getOrDefault("AWSAccessKeyId")
  valid_21626104 = validateParameter(valid_21626104, JString, required = true,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "AWSAccessKeyId", valid_21626104
  var valid_21626105 = query.getOrDefault("Expected.Name")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "Expected.Name", valid_21626105
  var valid_21626106 = query.getOrDefault("DomainName")
  valid_21626106 = validateParameter(valid_21626106, JString, required = true,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "DomainName", valid_21626106
  var valid_21626107 = query.getOrDefault("Version")
  valid_21626107 = validateParameter(valid_21626107, JString, required = true,
                                   default = newJString("2009-04-15"))
  if valid_21626107 != nil:
    section.add "Version", valid_21626107
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626108: Call_GetDeleteAttributes_21626092; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
  ## 
  let valid = call_21626108.validator(path, query, header, formData, body, _)
  let scheme = call_21626108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626108.makeUrl(scheme.get, call_21626108.host, call_21626108.base,
                               call_21626108.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626108, uri, valid, _)

proc call*(call_21626109: Call_GetDeleteAttributes_21626092;
          SignatureMethod: string; Signature: string; ItemName: string;
          Timestamp: string; SignatureVersion: string; AWSAccessKeyId: string;
          DomainName: string; ExpectedExists: string = ""; Attributes: JsonNode = nil;
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
  var query_21626110 = newJObject()
  add(query_21626110, "SignatureMethod", newJString(SignatureMethod))
  add(query_21626110, "Expected.Exists", newJString(ExpectedExists))
  if Attributes != nil:
    query_21626110.add "Attributes", Attributes
  add(query_21626110, "Signature", newJString(Signature))
  add(query_21626110, "ItemName", newJString(ItemName))
  add(query_21626110, "Action", newJString(Action))
  add(query_21626110, "Expected.Value", newJString(ExpectedValue))
  add(query_21626110, "Timestamp", newJString(Timestamp))
  add(query_21626110, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626110, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626110, "Expected.Name", newJString(ExpectedName))
  add(query_21626110, "DomainName", newJString(DomainName))
  add(query_21626110, "Version", newJString(Version))
  result = call_21626109.call(nil, query_21626110, nil, nil, nil)

var getDeleteAttributes* = Call_GetDeleteAttributes_21626092(
    name: "getDeleteAttributes", meth: HttpMethod.HttpGet,
    host: "sdb.amazonaws.com", route: "/#Action=DeleteAttributes",
    validator: validate_GetDeleteAttributes_21626093, base: "/",
    makeUrl: url_GetDeleteAttributes_21626094,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_21626146 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteDomain_21626148(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDomain_21626147(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626149 = query.getOrDefault("SignatureMethod")
  valid_21626149 = validateParameter(valid_21626149, JString, required = true,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "SignatureMethod", valid_21626149
  var valid_21626150 = query.getOrDefault("Signature")
  valid_21626150 = validateParameter(valid_21626150, JString, required = true,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "Signature", valid_21626150
  var valid_21626151 = query.getOrDefault("Action")
  valid_21626151 = validateParameter(valid_21626151, JString, required = true,
                                   default = newJString("DeleteDomain"))
  if valid_21626151 != nil:
    section.add "Action", valid_21626151
  var valid_21626152 = query.getOrDefault("Timestamp")
  valid_21626152 = validateParameter(valid_21626152, JString, required = true,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "Timestamp", valid_21626152
  var valid_21626153 = query.getOrDefault("SignatureVersion")
  valid_21626153 = validateParameter(valid_21626153, JString, required = true,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "SignatureVersion", valid_21626153
  var valid_21626154 = query.getOrDefault("AWSAccessKeyId")
  valid_21626154 = validateParameter(valid_21626154, JString, required = true,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "AWSAccessKeyId", valid_21626154
  var valid_21626155 = query.getOrDefault("Version")
  valid_21626155 = validateParameter(valid_21626155, JString, required = true,
                                   default = newJString("2009-04-15"))
  if valid_21626155 != nil:
    section.add "Version", valid_21626155
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626156 = formData.getOrDefault("DomainName")
  valid_21626156 = validateParameter(valid_21626156, JString, required = true,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "DomainName", valid_21626156
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626157: Call_PostDeleteDomain_21626146; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  let valid = call_21626157.validator(path, query, header, formData, body, _)
  let scheme = call_21626157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626157.makeUrl(scheme.get, call_21626157.host, call_21626157.base,
                               call_21626157.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626157, uri, valid, _)

proc call*(call_21626158: Call_PostDeleteDomain_21626146; SignatureMethod: string;
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
  var query_21626159 = newJObject()
  var formData_21626160 = newJObject()
  add(query_21626159, "SignatureMethod", newJString(SignatureMethod))
  add(formData_21626160, "DomainName", newJString(DomainName))
  add(query_21626159, "Signature", newJString(Signature))
  add(query_21626159, "Action", newJString(Action))
  add(query_21626159, "Timestamp", newJString(Timestamp))
  add(query_21626159, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626159, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626159, "Version", newJString(Version))
  result = call_21626158.call(nil, query_21626159, nil, formData_21626160, nil)

var postDeleteDomain* = Call_PostDeleteDomain_21626146(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_21626147,
    base: "/", makeUrl: url_PostDeleteDomain_21626148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_21626132 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteDomain_21626134(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDomain_21626133(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626135 = query.getOrDefault("SignatureMethod")
  valid_21626135 = validateParameter(valid_21626135, JString, required = true,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "SignatureMethod", valid_21626135
  var valid_21626136 = query.getOrDefault("Signature")
  valid_21626136 = validateParameter(valid_21626136, JString, required = true,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "Signature", valid_21626136
  var valid_21626137 = query.getOrDefault("Action")
  valid_21626137 = validateParameter(valid_21626137, JString, required = true,
                                   default = newJString("DeleteDomain"))
  if valid_21626137 != nil:
    section.add "Action", valid_21626137
  var valid_21626138 = query.getOrDefault("Timestamp")
  valid_21626138 = validateParameter(valid_21626138, JString, required = true,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "Timestamp", valid_21626138
  var valid_21626139 = query.getOrDefault("SignatureVersion")
  valid_21626139 = validateParameter(valid_21626139, JString, required = true,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "SignatureVersion", valid_21626139
  var valid_21626140 = query.getOrDefault("AWSAccessKeyId")
  valid_21626140 = validateParameter(valid_21626140, JString, required = true,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "AWSAccessKeyId", valid_21626140
  var valid_21626141 = query.getOrDefault("DomainName")
  valid_21626141 = validateParameter(valid_21626141, JString, required = true,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "DomainName", valid_21626141
  var valid_21626142 = query.getOrDefault("Version")
  valid_21626142 = validateParameter(valid_21626142, JString, required = true,
                                   default = newJString("2009-04-15"))
  if valid_21626142 != nil:
    section.add "Version", valid_21626142
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626143: Call_GetDeleteDomain_21626132; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
  ## 
  let valid = call_21626143.validator(path, query, header, formData, body, _)
  let scheme = call_21626143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626143.makeUrl(scheme.get, call_21626143.host, call_21626143.base,
                               call_21626143.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626143, uri, valid, _)

proc call*(call_21626144: Call_GetDeleteDomain_21626132; SignatureMethod: string;
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
  var query_21626145 = newJObject()
  add(query_21626145, "SignatureMethod", newJString(SignatureMethod))
  add(query_21626145, "Signature", newJString(Signature))
  add(query_21626145, "Action", newJString(Action))
  add(query_21626145, "Timestamp", newJString(Timestamp))
  add(query_21626145, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626145, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626145, "DomainName", newJString(DomainName))
  add(query_21626145, "Version", newJString(Version))
  result = call_21626144.call(nil, query_21626145, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_21626132(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_21626133,
    base: "/", makeUrl: url_GetDeleteDomain_21626134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDomainMetadata_21626175 = ref object of OpenApiRestCall_21625418
proc url_PostDomainMetadata_21626177(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDomainMetadata_21626176(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626178 = query.getOrDefault("SignatureMethod")
  valid_21626178 = validateParameter(valid_21626178, JString, required = true,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "SignatureMethod", valid_21626178
  var valid_21626179 = query.getOrDefault("Signature")
  valid_21626179 = validateParameter(valid_21626179, JString, required = true,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "Signature", valid_21626179
  var valid_21626180 = query.getOrDefault("Action")
  valid_21626180 = validateParameter(valid_21626180, JString, required = true,
                                   default = newJString("DomainMetadata"))
  if valid_21626180 != nil:
    section.add "Action", valid_21626180
  var valid_21626181 = query.getOrDefault("Timestamp")
  valid_21626181 = validateParameter(valid_21626181, JString, required = true,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "Timestamp", valid_21626181
  var valid_21626182 = query.getOrDefault("SignatureVersion")
  valid_21626182 = validateParameter(valid_21626182, JString, required = true,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "SignatureVersion", valid_21626182
  var valid_21626183 = query.getOrDefault("AWSAccessKeyId")
  valid_21626183 = validateParameter(valid_21626183, JString, required = true,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "AWSAccessKeyId", valid_21626183
  var valid_21626184 = query.getOrDefault("Version")
  valid_21626184 = validateParameter(valid_21626184, JString, required = true,
                                   default = newJString("2009-04-15"))
  if valid_21626184 != nil:
    section.add "Version", valid_21626184
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : The name of the domain for which to display the metadata of.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626185 = formData.getOrDefault("DomainName")
  valid_21626185 = validateParameter(valid_21626185, JString, required = true,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "DomainName", valid_21626185
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626186: Call_PostDomainMetadata_21626175; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  let valid = call_21626186.validator(path, query, header, formData, body, _)
  let scheme = call_21626186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626186.makeUrl(scheme.get, call_21626186.host, call_21626186.base,
                               call_21626186.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626186, uri, valid, _)

proc call*(call_21626187: Call_PostDomainMetadata_21626175;
          SignatureMethod: string; DomainName: string; Signature: string;
          Timestamp: string; SignatureVersion: string; AWSAccessKeyId: string;
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
  var query_21626188 = newJObject()
  var formData_21626189 = newJObject()
  add(query_21626188, "SignatureMethod", newJString(SignatureMethod))
  add(formData_21626189, "DomainName", newJString(DomainName))
  add(query_21626188, "Signature", newJString(Signature))
  add(query_21626188, "Action", newJString(Action))
  add(query_21626188, "Timestamp", newJString(Timestamp))
  add(query_21626188, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626188, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626188, "Version", newJString(Version))
  result = call_21626187.call(nil, query_21626188, nil, formData_21626189, nil)

var postDomainMetadata* = Call_PostDomainMetadata_21626175(
    name: "postDomainMetadata", meth: HttpMethod.HttpPost,
    host: "sdb.amazonaws.com", route: "/#Action=DomainMetadata",
    validator: validate_PostDomainMetadata_21626176, base: "/",
    makeUrl: url_PostDomainMetadata_21626177, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainMetadata_21626161 = ref object of OpenApiRestCall_21625418
proc url_GetDomainMetadata_21626163(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDomainMetadata_21626162(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626164 = query.getOrDefault("SignatureMethod")
  valid_21626164 = validateParameter(valid_21626164, JString, required = true,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "SignatureMethod", valid_21626164
  var valid_21626165 = query.getOrDefault("Signature")
  valid_21626165 = validateParameter(valid_21626165, JString, required = true,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "Signature", valid_21626165
  var valid_21626166 = query.getOrDefault("Action")
  valid_21626166 = validateParameter(valid_21626166, JString, required = true,
                                   default = newJString("DomainMetadata"))
  if valid_21626166 != nil:
    section.add "Action", valid_21626166
  var valid_21626167 = query.getOrDefault("Timestamp")
  valid_21626167 = validateParameter(valid_21626167, JString, required = true,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "Timestamp", valid_21626167
  var valid_21626168 = query.getOrDefault("SignatureVersion")
  valid_21626168 = validateParameter(valid_21626168, JString, required = true,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "SignatureVersion", valid_21626168
  var valid_21626169 = query.getOrDefault("AWSAccessKeyId")
  valid_21626169 = validateParameter(valid_21626169, JString, required = true,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "AWSAccessKeyId", valid_21626169
  var valid_21626170 = query.getOrDefault("DomainName")
  valid_21626170 = validateParameter(valid_21626170, JString, required = true,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "DomainName", valid_21626170
  var valid_21626171 = query.getOrDefault("Version")
  valid_21626171 = validateParameter(valid_21626171, JString, required = true,
                                   default = newJString("2009-04-15"))
  if valid_21626171 != nil:
    section.add "Version", valid_21626171
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626172: Call_GetDomainMetadata_21626161; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
  ## 
  let valid = call_21626172.validator(path, query, header, formData, body, _)
  let scheme = call_21626172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626172.makeUrl(scheme.get, call_21626172.host, call_21626172.base,
                               call_21626172.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626172, uri, valid, _)

proc call*(call_21626173: Call_GetDomainMetadata_21626161; SignatureMethod: string;
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
  var query_21626174 = newJObject()
  add(query_21626174, "SignatureMethod", newJString(SignatureMethod))
  add(query_21626174, "Signature", newJString(Signature))
  add(query_21626174, "Action", newJString(Action))
  add(query_21626174, "Timestamp", newJString(Timestamp))
  add(query_21626174, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626174, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626174, "DomainName", newJString(DomainName))
  add(query_21626174, "Version", newJString(Version))
  result = call_21626173.call(nil, query_21626174, nil, nil, nil)

var getDomainMetadata* = Call_GetDomainMetadata_21626161(name: "getDomainMetadata",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=DomainMetadata", validator: validate_GetDomainMetadata_21626162,
    base: "/", makeUrl: url_GetDomainMetadata_21626163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetAttributes_21626207 = ref object of OpenApiRestCall_21625418
proc url_PostGetAttributes_21626209(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetAttributes_21626208(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626210 = query.getOrDefault("SignatureMethod")
  valid_21626210 = validateParameter(valid_21626210, JString, required = true,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "SignatureMethod", valid_21626210
  var valid_21626211 = query.getOrDefault("Signature")
  valid_21626211 = validateParameter(valid_21626211, JString, required = true,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "Signature", valid_21626211
  var valid_21626212 = query.getOrDefault("Action")
  valid_21626212 = validateParameter(valid_21626212, JString, required = true,
                                   default = newJString("GetAttributes"))
  if valid_21626212 != nil:
    section.add "Action", valid_21626212
  var valid_21626213 = query.getOrDefault("Timestamp")
  valid_21626213 = validateParameter(valid_21626213, JString, required = true,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "Timestamp", valid_21626213
  var valid_21626214 = query.getOrDefault("SignatureVersion")
  valid_21626214 = validateParameter(valid_21626214, JString, required = true,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "SignatureVersion", valid_21626214
  var valid_21626215 = query.getOrDefault("AWSAccessKeyId")
  valid_21626215 = validateParameter(valid_21626215, JString, required = true,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "AWSAccessKeyId", valid_21626215
  var valid_21626216 = query.getOrDefault("Version")
  valid_21626216 = validateParameter(valid_21626216, JString, required = true,
                                   default = newJString("2009-04-15"))
  if valid_21626216 != nil:
    section.add "Version", valid_21626216
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
  var valid_21626217 = formData.getOrDefault("DomainName")
  valid_21626217 = validateParameter(valid_21626217, JString, required = true,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "DomainName", valid_21626217
  var valid_21626218 = formData.getOrDefault("ItemName")
  valid_21626218 = validateParameter(valid_21626218, JString, required = true,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "ItemName", valid_21626218
  var valid_21626219 = formData.getOrDefault("ConsistentRead")
  valid_21626219 = validateParameter(valid_21626219, JBool, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "ConsistentRead", valid_21626219
  var valid_21626220 = formData.getOrDefault("AttributeNames")
  valid_21626220 = validateParameter(valid_21626220, JArray, required = false,
                                   default = nil)
  if valid_21626220 != nil:
    section.add "AttributeNames", valid_21626220
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626221: Call_PostGetAttributes_21626207; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  let valid = call_21626221.validator(path, query, header, formData, body, _)
  let scheme = call_21626221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626221.makeUrl(scheme.get, call_21626221.host, call_21626221.base,
                               call_21626221.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626221, uri, valid, _)

proc call*(call_21626222: Call_PostGetAttributes_21626207; SignatureMethod: string;
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
  var query_21626223 = newJObject()
  var formData_21626224 = newJObject()
  add(query_21626223, "SignatureMethod", newJString(SignatureMethod))
  add(formData_21626224, "DomainName", newJString(DomainName))
  add(formData_21626224, "ItemName", newJString(ItemName))
  add(formData_21626224, "ConsistentRead", newJBool(ConsistentRead))
  add(query_21626223, "Signature", newJString(Signature))
  add(query_21626223, "Action", newJString(Action))
  add(query_21626223, "Timestamp", newJString(Timestamp))
  if AttributeNames != nil:
    formData_21626224.add "AttributeNames", AttributeNames
  add(query_21626223, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626223, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626223, "Version", newJString(Version))
  result = call_21626222.call(nil, query_21626223, nil, formData_21626224, nil)

var postGetAttributes* = Call_PostGetAttributes_21626207(name: "postGetAttributes",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=GetAttributes", validator: validate_PostGetAttributes_21626208,
    base: "/", makeUrl: url_PostGetAttributes_21626209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetAttributes_21626190 = ref object of OpenApiRestCall_21625418
proc url_GetGetAttributes_21626192(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetAttributes_21626191(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626193 = query.getOrDefault("SignatureMethod")
  valid_21626193 = validateParameter(valid_21626193, JString, required = true,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "SignatureMethod", valid_21626193
  var valid_21626194 = query.getOrDefault("AttributeNames")
  valid_21626194 = validateParameter(valid_21626194, JArray, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "AttributeNames", valid_21626194
  var valid_21626195 = query.getOrDefault("Signature")
  valid_21626195 = validateParameter(valid_21626195, JString, required = true,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "Signature", valid_21626195
  var valid_21626196 = query.getOrDefault("ItemName")
  valid_21626196 = validateParameter(valid_21626196, JString, required = true,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "ItemName", valid_21626196
  var valid_21626197 = query.getOrDefault("Action")
  valid_21626197 = validateParameter(valid_21626197, JString, required = true,
                                   default = newJString("GetAttributes"))
  if valid_21626197 != nil:
    section.add "Action", valid_21626197
  var valid_21626198 = query.getOrDefault("Timestamp")
  valid_21626198 = validateParameter(valid_21626198, JString, required = true,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "Timestamp", valid_21626198
  var valid_21626199 = query.getOrDefault("ConsistentRead")
  valid_21626199 = validateParameter(valid_21626199, JBool, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "ConsistentRead", valid_21626199
  var valid_21626200 = query.getOrDefault("SignatureVersion")
  valid_21626200 = validateParameter(valid_21626200, JString, required = true,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "SignatureVersion", valid_21626200
  var valid_21626201 = query.getOrDefault("AWSAccessKeyId")
  valid_21626201 = validateParameter(valid_21626201, JString, required = true,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "AWSAccessKeyId", valid_21626201
  var valid_21626202 = query.getOrDefault("DomainName")
  valid_21626202 = validateParameter(valid_21626202, JString, required = true,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "DomainName", valid_21626202
  var valid_21626203 = query.getOrDefault("Version")
  valid_21626203 = validateParameter(valid_21626203, JString, required = true,
                                   default = newJString("2009-04-15"))
  if valid_21626203 != nil:
    section.add "Version", valid_21626203
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626204: Call_GetGetAttributes_21626190; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
  ## 
  let valid = call_21626204.validator(path, query, header, formData, body, _)
  let scheme = call_21626204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626204.makeUrl(scheme.get, call_21626204.host, call_21626204.base,
                               call_21626204.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626204, uri, valid, _)

proc call*(call_21626205: Call_GetGetAttributes_21626190; SignatureMethod: string;
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
  var query_21626206 = newJObject()
  add(query_21626206, "SignatureMethod", newJString(SignatureMethod))
  if AttributeNames != nil:
    query_21626206.add "AttributeNames", AttributeNames
  add(query_21626206, "Signature", newJString(Signature))
  add(query_21626206, "ItemName", newJString(ItemName))
  add(query_21626206, "Action", newJString(Action))
  add(query_21626206, "Timestamp", newJString(Timestamp))
  add(query_21626206, "ConsistentRead", newJBool(ConsistentRead))
  add(query_21626206, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626206, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626206, "DomainName", newJString(DomainName))
  add(query_21626206, "Version", newJString(Version))
  result = call_21626205.call(nil, query_21626206, nil, nil, nil)

var getGetAttributes* = Call_GetGetAttributes_21626190(name: "getGetAttributes",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=GetAttributes", validator: validate_GetGetAttributes_21626191,
    base: "/", makeUrl: url_GetGetAttributes_21626192,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDomains_21626240 = ref object of OpenApiRestCall_21625418
proc url_PostListDomains_21626242(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListDomains_21626241(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626243 = query.getOrDefault("SignatureMethod")
  valid_21626243 = validateParameter(valid_21626243, JString, required = true,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "SignatureMethod", valid_21626243
  var valid_21626244 = query.getOrDefault("Signature")
  valid_21626244 = validateParameter(valid_21626244, JString, required = true,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "Signature", valid_21626244
  var valid_21626245 = query.getOrDefault("Action")
  valid_21626245 = validateParameter(valid_21626245, JString, required = true,
                                   default = newJString("ListDomains"))
  if valid_21626245 != nil:
    section.add "Action", valid_21626245
  var valid_21626246 = query.getOrDefault("Timestamp")
  valid_21626246 = validateParameter(valid_21626246, JString, required = true,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "Timestamp", valid_21626246
  var valid_21626247 = query.getOrDefault("SignatureVersion")
  valid_21626247 = validateParameter(valid_21626247, JString, required = true,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "SignatureVersion", valid_21626247
  var valid_21626248 = query.getOrDefault("AWSAccessKeyId")
  valid_21626248 = validateParameter(valid_21626248, JString, required = true,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "AWSAccessKeyId", valid_21626248
  var valid_21626249 = query.getOrDefault("Version")
  valid_21626249 = validateParameter(valid_21626249, JString, required = true,
                                   default = newJString("2009-04-15"))
  if valid_21626249 != nil:
    section.add "Version", valid_21626249
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : A string informing Amazon SimpleDB where to start the next list of domain names.
  ##   MaxNumberOfDomains: JInt
  ##                     : The maximum number of domain names you want returned. The range is 1 to 100. The default setting is 100.
  section = newJObject()
  var valid_21626250 = formData.getOrDefault("NextToken")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "NextToken", valid_21626250
  var valid_21626251 = formData.getOrDefault("MaxNumberOfDomains")
  valid_21626251 = validateParameter(valid_21626251, JInt, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "MaxNumberOfDomains", valid_21626251
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626252: Call_PostListDomains_21626240; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  let valid = call_21626252.validator(path, query, header, formData, body, _)
  let scheme = call_21626252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626252.makeUrl(scheme.get, call_21626252.host, call_21626252.base,
                               call_21626252.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626252, uri, valid, _)

proc call*(call_21626253: Call_PostListDomains_21626240; SignatureMethod: string;
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
  var query_21626254 = newJObject()
  var formData_21626255 = newJObject()
  add(formData_21626255, "NextToken", newJString(NextToken))
  add(query_21626254, "SignatureMethod", newJString(SignatureMethod))
  add(query_21626254, "Signature", newJString(Signature))
  add(query_21626254, "Action", newJString(Action))
  add(query_21626254, "Timestamp", newJString(Timestamp))
  add(query_21626254, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626254, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_21626255, "MaxNumberOfDomains", newJInt(MaxNumberOfDomains))
  add(query_21626254, "Version", newJString(Version))
  result = call_21626253.call(nil, query_21626254, nil, formData_21626255, nil)

var postListDomains* = Call_PostListDomains_21626240(name: "postListDomains",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=ListDomains", validator: validate_PostListDomains_21626241,
    base: "/", makeUrl: url_PostListDomains_21626242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDomains_21626225 = ref object of OpenApiRestCall_21625418
proc url_GetListDomains_21626227(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListDomains_21626226(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626228 = query.getOrDefault("SignatureMethod")
  valid_21626228 = validateParameter(valid_21626228, JString, required = true,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "SignatureMethod", valid_21626228
  var valid_21626229 = query.getOrDefault("Signature")
  valid_21626229 = validateParameter(valid_21626229, JString, required = true,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "Signature", valid_21626229
  var valid_21626230 = query.getOrDefault("NextToken")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "NextToken", valid_21626230
  var valid_21626231 = query.getOrDefault("Action")
  valid_21626231 = validateParameter(valid_21626231, JString, required = true,
                                   default = newJString("ListDomains"))
  if valid_21626231 != nil:
    section.add "Action", valid_21626231
  var valid_21626232 = query.getOrDefault("Timestamp")
  valid_21626232 = validateParameter(valid_21626232, JString, required = true,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "Timestamp", valid_21626232
  var valid_21626233 = query.getOrDefault("SignatureVersion")
  valid_21626233 = validateParameter(valid_21626233, JString, required = true,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "SignatureVersion", valid_21626233
  var valid_21626234 = query.getOrDefault("AWSAccessKeyId")
  valid_21626234 = validateParameter(valid_21626234, JString, required = true,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "AWSAccessKeyId", valid_21626234
  var valid_21626235 = query.getOrDefault("Version")
  valid_21626235 = validateParameter(valid_21626235, JString, required = true,
                                   default = newJString("2009-04-15"))
  if valid_21626235 != nil:
    section.add "Version", valid_21626235
  var valid_21626236 = query.getOrDefault("MaxNumberOfDomains")
  valid_21626236 = validateParameter(valid_21626236, JInt, required = false,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "MaxNumberOfDomains", valid_21626236
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626237: Call_GetListDomains_21626225; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
  ## 
  let valid = call_21626237.validator(path, query, header, formData, body, _)
  let scheme = call_21626237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626237.makeUrl(scheme.get, call_21626237.host, call_21626237.base,
                               call_21626237.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626237, uri, valid, _)

proc call*(call_21626238: Call_GetListDomains_21626225; SignatureMethod: string;
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
  var query_21626239 = newJObject()
  add(query_21626239, "SignatureMethod", newJString(SignatureMethod))
  add(query_21626239, "Signature", newJString(Signature))
  add(query_21626239, "NextToken", newJString(NextToken))
  add(query_21626239, "Action", newJString(Action))
  add(query_21626239, "Timestamp", newJString(Timestamp))
  add(query_21626239, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626239, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626239, "Version", newJString(Version))
  add(query_21626239, "MaxNumberOfDomains", newJInt(MaxNumberOfDomains))
  result = call_21626238.call(nil, query_21626239, nil, nil, nil)

var getListDomains* = Call_GetListDomains_21626225(name: "getListDomains",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=ListDomains", validator: validate_GetListDomains_21626226,
    base: "/", makeUrl: url_GetListDomains_21626227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPutAttributes_21626275 = ref object of OpenApiRestCall_21625418
proc url_PostPutAttributes_21626277(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPutAttributes_21626276(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626278 = query.getOrDefault("SignatureMethod")
  valid_21626278 = validateParameter(valid_21626278, JString, required = true,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "SignatureMethod", valid_21626278
  var valid_21626279 = query.getOrDefault("Signature")
  valid_21626279 = validateParameter(valid_21626279, JString, required = true,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "Signature", valid_21626279
  var valid_21626280 = query.getOrDefault("Action")
  valid_21626280 = validateParameter(valid_21626280, JString, required = true,
                                   default = newJString("PutAttributes"))
  if valid_21626280 != nil:
    section.add "Action", valid_21626280
  var valid_21626281 = query.getOrDefault("Timestamp")
  valid_21626281 = validateParameter(valid_21626281, JString, required = true,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "Timestamp", valid_21626281
  var valid_21626282 = query.getOrDefault("SignatureVersion")
  valid_21626282 = validateParameter(valid_21626282, JString, required = true,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "SignatureVersion", valid_21626282
  var valid_21626283 = query.getOrDefault("AWSAccessKeyId")
  valid_21626283 = validateParameter(valid_21626283, JString, required = true,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "AWSAccessKeyId", valid_21626283
  var valid_21626284 = query.getOrDefault("Version")
  valid_21626284 = validateParameter(valid_21626284, JString, required = true,
                                   default = newJString("2009-04-15"))
  if valid_21626284 != nil:
    section.add "Version", valid_21626284
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
  var valid_21626285 = formData.getOrDefault("DomainName")
  valid_21626285 = validateParameter(valid_21626285, JString, required = true,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "DomainName", valid_21626285
  var valid_21626286 = formData.getOrDefault("ItemName")
  valid_21626286 = validateParameter(valid_21626286, JString, required = true,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "ItemName", valid_21626286
  var valid_21626287 = formData.getOrDefault("Expected.Exists")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "Expected.Exists", valid_21626287
  var valid_21626288 = formData.getOrDefault("Attributes")
  valid_21626288 = validateParameter(valid_21626288, JArray, required = true,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "Attributes", valid_21626288
  var valid_21626289 = formData.getOrDefault("Expected.Value")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "Expected.Value", valid_21626289
  var valid_21626290 = formData.getOrDefault("Expected.Name")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "Expected.Name", valid_21626290
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626291: Call_PostPutAttributes_21626275; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  let valid = call_21626291.validator(path, query, header, formData, body, _)
  let scheme = call_21626291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626291.makeUrl(scheme.get, call_21626291.host, call_21626291.base,
                               call_21626291.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626291, uri, valid, _)

proc call*(call_21626292: Call_PostPutAttributes_21626275; SignatureMethod: string;
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
  var query_21626293 = newJObject()
  var formData_21626294 = newJObject()
  add(query_21626293, "SignatureMethod", newJString(SignatureMethod))
  add(formData_21626294, "DomainName", newJString(DomainName))
  add(formData_21626294, "ItemName", newJString(ItemName))
  add(formData_21626294, "Expected.Exists", newJString(ExpectedExists))
  add(query_21626293, "Signature", newJString(Signature))
  if Attributes != nil:
    formData_21626294.add "Attributes", Attributes
  add(query_21626293, "Action", newJString(Action))
  add(query_21626293, "Timestamp", newJString(Timestamp))
  add(formData_21626294, "Expected.Value", newJString(ExpectedValue))
  add(formData_21626294, "Expected.Name", newJString(ExpectedName))
  add(query_21626293, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626293, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626293, "Version", newJString(Version))
  result = call_21626292.call(nil, query_21626293, nil, formData_21626294, nil)

var postPutAttributes* = Call_PostPutAttributes_21626275(name: "postPutAttributes",
    meth: HttpMethod.HttpPost, host: "sdb.amazonaws.com",
    route: "/#Action=PutAttributes", validator: validate_PostPutAttributes_21626276,
    base: "/", makeUrl: url_PostPutAttributes_21626277,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPutAttributes_21626256 = ref object of OpenApiRestCall_21625418
proc url_GetPutAttributes_21626258(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPutAttributes_21626257(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626259 = query.getOrDefault("SignatureMethod")
  valid_21626259 = validateParameter(valid_21626259, JString, required = true,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "SignatureMethod", valid_21626259
  var valid_21626260 = query.getOrDefault("Expected.Exists")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "Expected.Exists", valid_21626260
  var valid_21626261 = query.getOrDefault("Attributes")
  valid_21626261 = validateParameter(valid_21626261, JArray, required = true,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "Attributes", valid_21626261
  var valid_21626262 = query.getOrDefault("Signature")
  valid_21626262 = validateParameter(valid_21626262, JString, required = true,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "Signature", valid_21626262
  var valid_21626263 = query.getOrDefault("ItemName")
  valid_21626263 = validateParameter(valid_21626263, JString, required = true,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "ItemName", valid_21626263
  var valid_21626264 = query.getOrDefault("Action")
  valid_21626264 = validateParameter(valid_21626264, JString, required = true,
                                   default = newJString("PutAttributes"))
  if valid_21626264 != nil:
    section.add "Action", valid_21626264
  var valid_21626265 = query.getOrDefault("Expected.Value")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "Expected.Value", valid_21626265
  var valid_21626266 = query.getOrDefault("Timestamp")
  valid_21626266 = validateParameter(valid_21626266, JString, required = true,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "Timestamp", valid_21626266
  var valid_21626267 = query.getOrDefault("SignatureVersion")
  valid_21626267 = validateParameter(valid_21626267, JString, required = true,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "SignatureVersion", valid_21626267
  var valid_21626268 = query.getOrDefault("AWSAccessKeyId")
  valid_21626268 = validateParameter(valid_21626268, JString, required = true,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "AWSAccessKeyId", valid_21626268
  var valid_21626269 = query.getOrDefault("Expected.Name")
  valid_21626269 = validateParameter(valid_21626269, JString, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "Expected.Name", valid_21626269
  var valid_21626270 = query.getOrDefault("DomainName")
  valid_21626270 = validateParameter(valid_21626270, JString, required = true,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "DomainName", valid_21626270
  var valid_21626271 = query.getOrDefault("Version")
  valid_21626271 = validateParameter(valid_21626271, JString, required = true,
                                   default = newJString("2009-04-15"))
  if valid_21626271 != nil:
    section.add "Version", valid_21626271
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626272: Call_GetPutAttributes_21626256; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
  ## 
  let valid = call_21626272.validator(path, query, header, formData, body, _)
  let scheme = call_21626272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626272.makeUrl(scheme.get, call_21626272.host, call_21626272.base,
                               call_21626272.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626272, uri, valid, _)

proc call*(call_21626273: Call_GetPutAttributes_21626256; SignatureMethod: string;
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
  var query_21626274 = newJObject()
  add(query_21626274, "SignatureMethod", newJString(SignatureMethod))
  add(query_21626274, "Expected.Exists", newJString(ExpectedExists))
  if Attributes != nil:
    query_21626274.add "Attributes", Attributes
  add(query_21626274, "Signature", newJString(Signature))
  add(query_21626274, "ItemName", newJString(ItemName))
  add(query_21626274, "Action", newJString(Action))
  add(query_21626274, "Expected.Value", newJString(ExpectedValue))
  add(query_21626274, "Timestamp", newJString(Timestamp))
  add(query_21626274, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626274, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626274, "Expected.Name", newJString(ExpectedName))
  add(query_21626274, "DomainName", newJString(DomainName))
  add(query_21626274, "Version", newJString(Version))
  result = call_21626273.call(nil, query_21626274, nil, nil, nil)

var getPutAttributes* = Call_GetPutAttributes_21626256(name: "getPutAttributes",
    meth: HttpMethod.HttpGet, host: "sdb.amazonaws.com",
    route: "/#Action=PutAttributes", validator: validate_GetPutAttributes_21626257,
    base: "/", makeUrl: url_GetPutAttributes_21626258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSelect_21626311 = ref object of OpenApiRestCall_21625418
proc url_PostSelect_21626313(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSelect_21626312(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626314 = query.getOrDefault("SignatureMethod")
  valid_21626314 = validateParameter(valid_21626314, JString, required = true,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "SignatureMethod", valid_21626314
  var valid_21626315 = query.getOrDefault("Signature")
  valid_21626315 = validateParameter(valid_21626315, JString, required = true,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "Signature", valid_21626315
  var valid_21626316 = query.getOrDefault("Action")
  valid_21626316 = validateParameter(valid_21626316, JString, required = true,
                                   default = newJString("Select"))
  if valid_21626316 != nil:
    section.add "Action", valid_21626316
  var valid_21626317 = query.getOrDefault("Timestamp")
  valid_21626317 = validateParameter(valid_21626317, JString, required = true,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "Timestamp", valid_21626317
  var valid_21626318 = query.getOrDefault("SignatureVersion")
  valid_21626318 = validateParameter(valid_21626318, JString, required = true,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "SignatureVersion", valid_21626318
  var valid_21626319 = query.getOrDefault("AWSAccessKeyId")
  valid_21626319 = validateParameter(valid_21626319, JString, required = true,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "AWSAccessKeyId", valid_21626319
  var valid_21626320 = query.getOrDefault("Version")
  valid_21626320 = validateParameter(valid_21626320, JString, required = true,
                                   default = newJString("2009-04-15"))
  if valid_21626320 != nil:
    section.add "Version", valid_21626320
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
  var valid_21626321 = formData.getOrDefault("NextToken")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "NextToken", valid_21626321
  var valid_21626322 = formData.getOrDefault("ConsistentRead")
  valid_21626322 = validateParameter(valid_21626322, JBool, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "ConsistentRead", valid_21626322
  assert formData != nil, "formData argument is necessary due to required `SelectExpression` field"
  var valid_21626323 = formData.getOrDefault("SelectExpression")
  valid_21626323 = validateParameter(valid_21626323, JString, required = true,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "SelectExpression", valid_21626323
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626324: Call_PostSelect_21626311; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  let valid = call_21626324.validator(path, query, header, formData, body, _)
  let scheme = call_21626324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626324.makeUrl(scheme.get, call_21626324.host, call_21626324.base,
                               call_21626324.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626324, uri, valid, _)

proc call*(call_21626325: Call_PostSelect_21626311; SignatureMethod: string;
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
  var query_21626326 = newJObject()
  var formData_21626327 = newJObject()
  add(formData_21626327, "NextToken", newJString(NextToken))
  add(query_21626326, "SignatureMethod", newJString(SignatureMethod))
  add(formData_21626327, "ConsistentRead", newJBool(ConsistentRead))
  add(query_21626326, "Signature", newJString(Signature))
  add(query_21626326, "Action", newJString(Action))
  add(query_21626326, "Timestamp", newJString(Timestamp))
  add(query_21626326, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626326, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_21626327, "SelectExpression", newJString(SelectExpression))
  add(query_21626326, "Version", newJString(Version))
  result = call_21626325.call(nil, query_21626326, nil, formData_21626327, nil)

var postSelect* = Call_PostSelect_21626311(name: "postSelect",
                                        meth: HttpMethod.HttpPost,
                                        host: "sdb.amazonaws.com",
                                        route: "/#Action=Select",
                                        validator: validate_PostSelect_21626312,
                                        base: "/", makeUrl: url_PostSelect_21626313,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSelect_21626295 = ref object of OpenApiRestCall_21625418
proc url_GetSelect_21626297(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSelect_21626296(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626298 = query.getOrDefault("SignatureMethod")
  valid_21626298 = validateParameter(valid_21626298, JString, required = true,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "SignatureMethod", valid_21626298
  var valid_21626299 = query.getOrDefault("Signature")
  valid_21626299 = validateParameter(valid_21626299, JString, required = true,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "Signature", valid_21626299
  var valid_21626300 = query.getOrDefault("NextToken")
  valid_21626300 = validateParameter(valid_21626300, JString, required = false,
                                   default = nil)
  if valid_21626300 != nil:
    section.add "NextToken", valid_21626300
  var valid_21626301 = query.getOrDefault("SelectExpression")
  valid_21626301 = validateParameter(valid_21626301, JString, required = true,
                                   default = nil)
  if valid_21626301 != nil:
    section.add "SelectExpression", valid_21626301
  var valid_21626302 = query.getOrDefault("Action")
  valid_21626302 = validateParameter(valid_21626302, JString, required = true,
                                   default = newJString("Select"))
  if valid_21626302 != nil:
    section.add "Action", valid_21626302
  var valid_21626303 = query.getOrDefault("Timestamp")
  valid_21626303 = validateParameter(valid_21626303, JString, required = true,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "Timestamp", valid_21626303
  var valid_21626304 = query.getOrDefault("ConsistentRead")
  valid_21626304 = validateParameter(valid_21626304, JBool, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "ConsistentRead", valid_21626304
  var valid_21626305 = query.getOrDefault("SignatureVersion")
  valid_21626305 = validateParameter(valid_21626305, JString, required = true,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "SignatureVersion", valid_21626305
  var valid_21626306 = query.getOrDefault("AWSAccessKeyId")
  valid_21626306 = validateParameter(valid_21626306, JString, required = true,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "AWSAccessKeyId", valid_21626306
  var valid_21626307 = query.getOrDefault("Version")
  valid_21626307 = validateParameter(valid_21626307, JString, required = true,
                                   default = newJString("2009-04-15"))
  if valid_21626307 != nil:
    section.add "Version", valid_21626307
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626308: Call_GetSelect_21626295; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
  ## 
  let valid = call_21626308.validator(path, query, header, formData, body, _)
  let scheme = call_21626308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626308.makeUrl(scheme.get, call_21626308.host, call_21626308.base,
                               call_21626308.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626308, uri, valid, _)

proc call*(call_21626309: Call_GetSelect_21626295; SignatureMethod: string;
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
  var query_21626310 = newJObject()
  add(query_21626310, "SignatureMethod", newJString(SignatureMethod))
  add(query_21626310, "Signature", newJString(Signature))
  add(query_21626310, "NextToken", newJString(NextToken))
  add(query_21626310, "SelectExpression", newJString(SelectExpression))
  add(query_21626310, "Action", newJString(Action))
  add(query_21626310, "Timestamp", newJString(Timestamp))
  add(query_21626310, "ConsistentRead", newJBool(ConsistentRead))
  add(query_21626310, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626310, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626310, "Version", newJString(Version))
  result = call_21626309.call(nil, query_21626310, nil, nil, nil)

var getSelect* = Call_GetSelect_21626295(name: "getSelect", meth: HttpMethod.HttpGet,
                                      host: "sdb.amazonaws.com",
                                      route: "/#Action=Select",
                                      validator: validate_GetSelect_21626296,
                                      base: "/", makeUrl: url_GetSelect_21626297,
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}