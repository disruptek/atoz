
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Glue
## version: 2017-03-31
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Glue</fullname> <p>Defines the public endpoint for the AWS Glue service.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/glue/
type
  Scheme* {.pure.} = enum
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

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "glue.ap-northeast-1.amazonaws.com", "ap-southeast-1": "glue.ap-southeast-1.amazonaws.com",
                               "us-west-2": "glue.us-west-2.amazonaws.com",
                               "eu-west-2": "glue.eu-west-2.amazonaws.com", "ap-northeast-3": "glue.ap-northeast-3.amazonaws.com", "eu-central-1": "glue.eu-central-1.amazonaws.com",
                               "us-east-2": "glue.us-east-2.amazonaws.com",
                               "us-east-1": "glue.us-east-1.amazonaws.com", "cn-northwest-1": "glue.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "glue.ap-south-1.amazonaws.com",
                               "eu-north-1": "glue.eu-north-1.amazonaws.com", "ap-northeast-2": "glue.ap-northeast-2.amazonaws.com",
                               "us-west-1": "glue.us-west-1.amazonaws.com", "us-gov-east-1": "glue.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "glue.eu-west-3.amazonaws.com", "cn-north-1": "glue.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "glue.sa-east-1.amazonaws.com",
                               "eu-west-1": "glue.eu-west-1.amazonaws.com", "us-gov-west-1": "glue.us-gov-west-1.amazonaws.com", "ap-southeast-2": "glue.ap-southeast-2.amazonaws.com", "ca-central-1": "glue.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "glue.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "glue.ap-southeast-1.amazonaws.com",
      "us-west-2": "glue.us-west-2.amazonaws.com",
      "eu-west-2": "glue.eu-west-2.amazonaws.com",
      "ap-northeast-3": "glue.ap-northeast-3.amazonaws.com",
      "eu-central-1": "glue.eu-central-1.amazonaws.com",
      "us-east-2": "glue.us-east-2.amazonaws.com",
      "us-east-1": "glue.us-east-1.amazonaws.com",
      "cn-northwest-1": "glue.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "glue.ap-south-1.amazonaws.com",
      "eu-north-1": "glue.eu-north-1.amazonaws.com",
      "ap-northeast-2": "glue.ap-northeast-2.amazonaws.com",
      "us-west-1": "glue.us-west-1.amazonaws.com",
      "us-gov-east-1": "glue.us-gov-east-1.amazonaws.com",
      "eu-west-3": "glue.eu-west-3.amazonaws.com",
      "cn-north-1": "glue.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "glue.sa-east-1.amazonaws.com",
      "eu-west-1": "glue.eu-west-1.amazonaws.com",
      "us-gov-west-1": "glue.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "glue.ap-southeast-2.amazonaws.com",
      "ca-central-1": "glue.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "glue"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_BatchCreatePartition_402656294 = ref object of OpenApiRestCall_402656044
proc url_BatchCreatePartition_402656296(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchCreatePartition_402656295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates one or more partitions in a batch operation.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656390 = header.getOrDefault("X-Amz-Target")
  valid_402656390 = validateParameter(valid_402656390, JString, required = true, default = newJString(
      "AWSGlue.BatchCreatePartition"))
  if valid_402656390 != nil:
    section.add "X-Amz-Target", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Security-Token", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Signature")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Signature", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656393
  var valid_402656394 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656394 = validateParameter(valid_402656394, JString,
                                      required = false, default = nil)
  if valid_402656394 != nil:
    section.add "X-Amz-Algorithm", valid_402656394
  var valid_402656395 = header.getOrDefault("X-Amz-Date")
  valid_402656395 = validateParameter(valid_402656395, JString,
                                      required = false, default = nil)
  if valid_402656395 != nil:
    section.add "X-Amz-Date", valid_402656395
  var valid_402656396 = header.getOrDefault("X-Amz-Credential")
  valid_402656396 = validateParameter(valid_402656396, JString,
                                      required = false, default = nil)
  if valid_402656396 != nil:
    section.add "X-Amz-Credential", valid_402656396
  var valid_402656397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656397 = validateParameter(valid_402656397, JString,
                                      required = false, default = nil)
  if valid_402656397 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656412: Call_BatchCreatePartition_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates one or more partitions in a batch operation.
                                                                                         ## 
  let valid = call_402656412.validator(path, query, header, formData, body, _)
  let scheme = call_402656412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656412.makeUrl(scheme.get, call_402656412.host, call_402656412.base,
                                   call_402656412.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656412, uri, valid, _)

proc call*(call_402656461: Call_BatchCreatePartition_402656294; body: JsonNode): Recallable =
  ## batchCreatePartition
  ## Creates one or more partitions in a batch operation.
  ##   body: JObject (required)
  var body_402656462 = newJObject()
  if body != nil:
    body_402656462 = body
  result = call_402656461.call(nil, nil, nil, nil, body_402656462)

var batchCreatePartition* = Call_BatchCreatePartition_402656294(
    name: "batchCreatePartition", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchCreatePartition",
    validator: validate_BatchCreatePartition_402656295, base: "/",
    makeUrl: url_BatchCreatePartition_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteConnection_402656489 = ref object of OpenApiRestCall_402656044
proc url_BatchDeleteConnection_402656491(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDeleteConnection_402656490(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a list of connection definitions from the Data Catalog.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656492 = header.getOrDefault("X-Amz-Target")
  valid_402656492 = validateParameter(valid_402656492, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteConnection"))
  if valid_402656492 != nil:
    section.add "X-Amz-Target", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Security-Token", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Signature")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Signature", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Algorithm", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Date")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Date", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Credential")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Credential", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656501: Call_BatchDeleteConnection_402656489;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a list of connection definitions from the Data Catalog.
                                                                                         ## 
  let valid = call_402656501.validator(path, query, header, formData, body, _)
  let scheme = call_402656501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656501.makeUrl(scheme.get, call_402656501.host, call_402656501.base,
                                   call_402656501.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656501, uri, valid, _)

proc call*(call_402656502: Call_BatchDeleteConnection_402656489; body: JsonNode): Recallable =
  ## batchDeleteConnection
  ## Deletes a list of connection definitions from the Data Catalog.
  ##   body: JObject (required)
  var body_402656503 = newJObject()
  if body != nil:
    body_402656503 = body
  result = call_402656502.call(nil, nil, nil, nil, body_402656503)

var batchDeleteConnection* = Call_BatchDeleteConnection_402656489(
    name: "batchDeleteConnection", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteConnection",
    validator: validate_BatchDeleteConnection_402656490, base: "/",
    makeUrl: url_BatchDeleteConnection_402656491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeletePartition_402656504 = ref object of OpenApiRestCall_402656044
proc url_BatchDeletePartition_402656506(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDeletePartition_402656505(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes one or more partitions in a batch operation.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656507 = header.getOrDefault("X-Amz-Target")
  valid_402656507 = validateParameter(valid_402656507, JString, required = true, default = newJString(
      "AWSGlue.BatchDeletePartition"))
  if valid_402656507 != nil:
    section.add "X-Amz-Target", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Security-Token", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Signature")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Signature", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Algorithm", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Date")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Date", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Credential")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Credential", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656516: Call_BatchDeletePartition_402656504;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes one or more partitions in a batch operation.
                                                                                         ## 
  let valid = call_402656516.validator(path, query, header, formData, body, _)
  let scheme = call_402656516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656516.makeUrl(scheme.get, call_402656516.host, call_402656516.base,
                                   call_402656516.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656516, uri, valid, _)

proc call*(call_402656517: Call_BatchDeletePartition_402656504; body: JsonNode): Recallable =
  ## batchDeletePartition
  ## Deletes one or more partitions in a batch operation.
  ##   body: JObject (required)
  var body_402656518 = newJObject()
  if body != nil:
    body_402656518 = body
  result = call_402656517.call(nil, nil, nil, nil, body_402656518)

var batchDeletePartition* = Call_BatchDeletePartition_402656504(
    name: "batchDeletePartition", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeletePartition",
    validator: validate_BatchDeletePartition_402656505, base: "/",
    makeUrl: url_BatchDeletePartition_402656506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteTable_402656519 = ref object of OpenApiRestCall_402656044
proc url_BatchDeleteTable_402656521(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDeleteTable_402656520(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656522 = header.getOrDefault("X-Amz-Target")
  valid_402656522 = validateParameter(valid_402656522, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteTable"))
  if valid_402656522 != nil:
    section.add "X-Amz-Target", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Security-Token", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Signature")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Signature", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Algorithm", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Date")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Date", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Credential")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Credential", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656531: Call_BatchDeleteTable_402656519;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
                                                                                         ## 
  let valid = call_402656531.validator(path, query, header, formData, body, _)
  let scheme = call_402656531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656531.makeUrl(scheme.get, call_402656531.host, call_402656531.base,
                                   call_402656531.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656531, uri, valid, _)

proc call*(call_402656532: Call_BatchDeleteTable_402656519; body: JsonNode): Recallable =
  ## batchDeleteTable
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402656533 = newJObject()
  if body != nil:
    body_402656533 = body
  result = call_402656532.call(nil, nil, nil, nil, body_402656533)

var batchDeleteTable* = Call_BatchDeleteTable_402656519(
    name: "batchDeleteTable", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteTable",
    validator: validate_BatchDeleteTable_402656520, base: "/",
    makeUrl: url_BatchDeleteTable_402656521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteTableVersion_402656534 = ref object of OpenApiRestCall_402656044
proc url_BatchDeleteTableVersion_402656536(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDeleteTableVersion_402656535(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a specified batch of versions of a table.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656537 = header.getOrDefault("X-Amz-Target")
  valid_402656537 = validateParameter(valid_402656537, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteTableVersion"))
  if valid_402656537 != nil:
    section.add "X-Amz-Target", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Security-Token", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Signature")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Signature", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Algorithm", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Date")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Date", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Credential")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Credential", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656546: Call_BatchDeleteTableVersion_402656534;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified batch of versions of a table.
                                                                                         ## 
  let valid = call_402656546.validator(path, query, header, formData, body, _)
  let scheme = call_402656546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656546.makeUrl(scheme.get, call_402656546.host, call_402656546.base,
                                   call_402656546.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656546, uri, valid, _)

proc call*(call_402656547: Call_BatchDeleteTableVersion_402656534;
           body: JsonNode): Recallable =
  ## batchDeleteTableVersion
  ## Deletes a specified batch of versions of a table.
  ##   body: JObject (required)
  var body_402656548 = newJObject()
  if body != nil:
    body_402656548 = body
  result = call_402656547.call(nil, nil, nil, nil, body_402656548)

var batchDeleteTableVersion* = Call_BatchDeleteTableVersion_402656534(
    name: "batchDeleteTableVersion", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteTableVersion",
    validator: validate_BatchDeleteTableVersion_402656535, base: "/",
    makeUrl: url_BatchDeleteTableVersion_402656536,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetCrawlers_402656549 = ref object of OpenApiRestCall_402656044
proc url_BatchGetCrawlers_402656551(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetCrawlers_402656550(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656552 = header.getOrDefault("X-Amz-Target")
  valid_402656552 = validateParameter(valid_402656552, JString, required = true, default = newJString(
      "AWSGlue.BatchGetCrawlers"))
  if valid_402656552 != nil:
    section.add "X-Amz-Target", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Security-Token", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Signature")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Signature", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Algorithm", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Date")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Date", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Credential")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Credential", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656561: Call_BatchGetCrawlers_402656549;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
                                                                                         ## 
  let valid = call_402656561.validator(path, query, header, formData, body, _)
  let scheme = call_402656561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656561.makeUrl(scheme.get, call_402656561.host, call_402656561.base,
                                   call_402656561.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656561, uri, valid, _)

proc call*(call_402656562: Call_BatchGetCrawlers_402656549; body: JsonNode): Recallable =
  ## batchGetCrawlers
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   
                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656563 = newJObject()
  if body != nil:
    body_402656563 = body
  result = call_402656562.call(nil, nil, nil, nil, body_402656563)

var batchGetCrawlers* = Call_BatchGetCrawlers_402656549(
    name: "batchGetCrawlers", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetCrawlers",
    validator: validate_BatchGetCrawlers_402656550, base: "/",
    makeUrl: url_BatchGetCrawlers_402656551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDevEndpoints_402656564 = ref object of OpenApiRestCall_402656044
proc url_BatchGetDevEndpoints_402656566(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetDevEndpoints_402656565(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656567 = header.getOrDefault("X-Amz-Target")
  valid_402656567 = validateParameter(valid_402656567, JString, required = true, default = newJString(
      "AWSGlue.BatchGetDevEndpoints"))
  if valid_402656567 != nil:
    section.add "X-Amz-Target", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Security-Token", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Signature")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Signature", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Algorithm", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Date")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Date", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Credential")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Credential", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656576: Call_BatchGetDevEndpoints_402656564;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
                                                                                         ## 
  let valid = call_402656576.validator(path, query, header, formData, body, _)
  let scheme = call_402656576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656576.makeUrl(scheme.get, call_402656576.host, call_402656576.base,
                                   call_402656576.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656576, uri, valid, _)

proc call*(call_402656577: Call_BatchGetDevEndpoints_402656564; body: JsonNode): Recallable =
  ## batchGetDevEndpoints
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   
                                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402656578 = newJObject()
  if body != nil:
    body_402656578 = body
  result = call_402656577.call(nil, nil, nil, nil, body_402656578)

var batchGetDevEndpoints* = Call_BatchGetDevEndpoints_402656564(
    name: "batchGetDevEndpoints", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetDevEndpoints",
    validator: validate_BatchGetDevEndpoints_402656565, base: "/",
    makeUrl: url_BatchGetDevEndpoints_402656566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetJobs_402656579 = ref object of OpenApiRestCall_402656044
proc url_BatchGetJobs_402656581(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetJobs_402656580(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656582 = header.getOrDefault("X-Amz-Target")
  valid_402656582 = validateParameter(valid_402656582, JString, required = true, default = newJString(
      "AWSGlue.BatchGetJobs"))
  if valid_402656582 != nil:
    section.add "X-Amz-Target", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Security-Token", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Signature")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Signature", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Algorithm", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Date")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Date", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Credential")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Credential", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656591: Call_BatchGetJobs_402656579; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
                                                                                         ## 
  let valid = call_402656591.validator(path, query, header, formData, body, _)
  let scheme = call_402656591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656591.makeUrl(scheme.get, call_402656591.host, call_402656591.base,
                                   call_402656591.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656591, uri, valid, _)

proc call*(call_402656592: Call_BatchGetJobs_402656579; body: JsonNode): Recallable =
  ## batchGetJobs
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
  ##   
                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656593 = newJObject()
  if body != nil:
    body_402656593 = body
  result = call_402656592.call(nil, nil, nil, nil, body_402656593)

var batchGetJobs* = Call_BatchGetJobs_402656579(name: "batchGetJobs",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetJobs",
    validator: validate_BatchGetJobs_402656580, base: "/",
    makeUrl: url_BatchGetJobs_402656581, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetPartition_402656594 = ref object of OpenApiRestCall_402656044
proc url_BatchGetPartition_402656596(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetPartition_402656595(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves partitions in a batch request.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656597 = header.getOrDefault("X-Amz-Target")
  valid_402656597 = validateParameter(valid_402656597, JString, required = true, default = newJString(
      "AWSGlue.BatchGetPartition"))
  if valid_402656597 != nil:
    section.add "X-Amz-Target", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Security-Token", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Signature")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Signature", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Algorithm", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Date")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Date", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Credential")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Credential", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656606: Call_BatchGetPartition_402656594;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves partitions in a batch request.
                                                                                         ## 
  let valid = call_402656606.validator(path, query, header, formData, body, _)
  let scheme = call_402656606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656606.makeUrl(scheme.get, call_402656606.host, call_402656606.base,
                                   call_402656606.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656606, uri, valid, _)

proc call*(call_402656607: Call_BatchGetPartition_402656594; body: JsonNode): Recallable =
  ## batchGetPartition
  ## Retrieves partitions in a batch request.
  ##   body: JObject (required)
  var body_402656608 = newJObject()
  if body != nil:
    body_402656608 = body
  result = call_402656607.call(nil, nil, nil, nil, body_402656608)

var batchGetPartition* = Call_BatchGetPartition_402656594(
    name: "batchGetPartition", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetPartition",
    validator: validate_BatchGetPartition_402656595, base: "/",
    makeUrl: url_BatchGetPartition_402656596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetTriggers_402656609 = ref object of OpenApiRestCall_402656044
proc url_BatchGetTriggers_402656611(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetTriggers_402656610(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656612 = header.getOrDefault("X-Amz-Target")
  valid_402656612 = validateParameter(valid_402656612, JString, required = true, default = newJString(
      "AWSGlue.BatchGetTriggers"))
  if valid_402656612 != nil:
    section.add "X-Amz-Target", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Security-Token", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Signature")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Signature", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Algorithm", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Date")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Date", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Credential")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Credential", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656621: Call_BatchGetTriggers_402656609;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
                                                                                         ## 
  let valid = call_402656621.validator(path, query, header, formData, body, _)
  let scheme = call_402656621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656621.makeUrl(scheme.get, call_402656621.host, call_402656621.base,
                                   call_402656621.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656621, uri, valid, _)

proc call*(call_402656622: Call_BatchGetTriggers_402656609; body: JsonNode): Recallable =
  ## batchGetTriggers
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   
                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656623 = newJObject()
  if body != nil:
    body_402656623 = body
  result = call_402656622.call(nil, nil, nil, nil, body_402656623)

var batchGetTriggers* = Call_BatchGetTriggers_402656609(
    name: "batchGetTriggers", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetTriggers",
    validator: validate_BatchGetTriggers_402656610, base: "/",
    makeUrl: url_BatchGetTriggers_402656611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetWorkflows_402656624 = ref object of OpenApiRestCall_402656044
proc url_BatchGetWorkflows_402656626(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetWorkflows_402656625(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656627 = header.getOrDefault("X-Amz-Target")
  valid_402656627 = validateParameter(valid_402656627, JString, required = true, default = newJString(
      "AWSGlue.BatchGetWorkflows"))
  if valid_402656627 != nil:
    section.add "X-Amz-Target", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Security-Token", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Signature")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Signature", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Algorithm", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Date")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Date", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Credential")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Credential", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656636: Call_BatchGetWorkflows_402656624;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
                                                                                         ## 
  let valid = call_402656636.validator(path, query, header, formData, body, _)
  let scheme = call_402656636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656636.makeUrl(scheme.get, call_402656636.host, call_402656636.base,
                                   call_402656636.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656636, uri, valid, _)

proc call*(call_402656637: Call_BatchGetWorkflows_402656624; body: JsonNode): Recallable =
  ## batchGetWorkflows
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   
                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656638 = newJObject()
  if body != nil:
    body_402656638 = body
  result = call_402656637.call(nil, nil, nil, nil, body_402656638)

var batchGetWorkflows* = Call_BatchGetWorkflows_402656624(
    name: "batchGetWorkflows", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetWorkflows",
    validator: validate_BatchGetWorkflows_402656625, base: "/",
    makeUrl: url_BatchGetWorkflows_402656626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchStopJobRun_402656639 = ref object of OpenApiRestCall_402656044
proc url_BatchStopJobRun_402656641(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchStopJobRun_402656640(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Stops one or more job runs for a specified job definition.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656642 = header.getOrDefault("X-Amz-Target")
  valid_402656642 = validateParameter(valid_402656642, JString, required = true, default = newJString(
      "AWSGlue.BatchStopJobRun"))
  if valid_402656642 != nil:
    section.add "X-Amz-Target", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Security-Token", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Signature")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Signature", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Algorithm", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Date")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Date", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Credential")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Credential", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656651: Call_BatchStopJobRun_402656639; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops one or more job runs for a specified job definition.
                                                                                         ## 
  let valid = call_402656651.validator(path, query, header, formData, body, _)
  let scheme = call_402656651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656651.makeUrl(scheme.get, call_402656651.host, call_402656651.base,
                                   call_402656651.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656651, uri, valid, _)

proc call*(call_402656652: Call_BatchStopJobRun_402656639; body: JsonNode): Recallable =
  ## batchStopJobRun
  ## Stops one or more job runs for a specified job definition.
  ##   body: JObject (required)
  var body_402656653 = newJObject()
  if body != nil:
    body_402656653 = body
  result = call_402656652.call(nil, nil, nil, nil, body_402656653)

var batchStopJobRun* = Call_BatchStopJobRun_402656639(name: "batchStopJobRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchStopJobRun",
    validator: validate_BatchStopJobRun_402656640, base: "/",
    makeUrl: url_BatchStopJobRun_402656641, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelMLTaskRun_402656654 = ref object of OpenApiRestCall_402656044
proc url_CancelMLTaskRun_402656656(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelMLTaskRun_402656655(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656657 = header.getOrDefault("X-Amz-Target")
  valid_402656657 = validateParameter(valid_402656657, JString, required = true, default = newJString(
      "AWSGlue.CancelMLTaskRun"))
  if valid_402656657 != nil:
    section.add "X-Amz-Target", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Security-Token", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Signature")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Signature", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Algorithm", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Date")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Date", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Credential")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Credential", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656666: Call_CancelMLTaskRun_402656654; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
                                                                                         ## 
  let valid = call_402656666.validator(path, query, header, formData, body, _)
  let scheme = call_402656666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656666.makeUrl(scheme.get, call_402656666.host, call_402656666.base,
                                   call_402656666.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656666, uri, valid, _)

proc call*(call_402656667: Call_CancelMLTaskRun_402656654; body: JsonNode): Recallable =
  ## cancelMLTaskRun
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656668 = newJObject()
  if body != nil:
    body_402656668 = body
  result = call_402656667.call(nil, nil, nil, nil, body_402656668)

var cancelMLTaskRun* = Call_CancelMLTaskRun_402656654(name: "cancelMLTaskRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CancelMLTaskRun",
    validator: validate_CancelMLTaskRun_402656655, base: "/",
    makeUrl: url_CancelMLTaskRun_402656656, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateClassifier_402656669 = ref object of OpenApiRestCall_402656044
proc url_CreateClassifier_402656671(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateClassifier_402656670(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656672 = header.getOrDefault("X-Amz-Target")
  valid_402656672 = validateParameter(valid_402656672, JString, required = true, default = newJString(
      "AWSGlue.CreateClassifier"))
  if valid_402656672 != nil:
    section.add "X-Amz-Target", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Security-Token", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Signature")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Signature", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Algorithm", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Date")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Date", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Credential")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Credential", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656681: Call_CreateClassifier_402656669;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
                                                                                         ## 
  let valid = call_402656681.validator(path, query, header, formData, body, _)
  let scheme = call_402656681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656681.makeUrl(scheme.get, call_402656681.host, call_402656681.base,
                                   call_402656681.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656681, uri, valid, _)

proc call*(call_402656682: Call_CreateClassifier_402656669; body: JsonNode): Recallable =
  ## createClassifier
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
  ##   
                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656683 = newJObject()
  if body != nil:
    body_402656683 = body
  result = call_402656682.call(nil, nil, nil, nil, body_402656683)

var createClassifier* = Call_CreateClassifier_402656669(
    name: "createClassifier", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateClassifier",
    validator: validate_CreateClassifier_402656670, base: "/",
    makeUrl: url_CreateClassifier_402656671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnection_402656684 = ref object of OpenApiRestCall_402656044
proc url_CreateConnection_402656686(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConnection_402656685(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a connection definition in the Data Catalog.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656687 = header.getOrDefault("X-Amz-Target")
  valid_402656687 = validateParameter(valid_402656687, JString, required = true, default = newJString(
      "AWSGlue.CreateConnection"))
  if valid_402656687 != nil:
    section.add "X-Amz-Target", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Security-Token", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Signature")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Signature", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Algorithm", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Date")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Date", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Credential")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Credential", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656696: Call_CreateConnection_402656684;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a connection definition in the Data Catalog.
                                                                                         ## 
  let valid = call_402656696.validator(path, query, header, formData, body, _)
  let scheme = call_402656696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656696.makeUrl(scheme.get, call_402656696.host, call_402656696.base,
                                   call_402656696.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656696, uri, valid, _)

proc call*(call_402656697: Call_CreateConnection_402656684; body: JsonNode): Recallable =
  ## createConnection
  ## Creates a connection definition in the Data Catalog.
  ##   body: JObject (required)
  var body_402656698 = newJObject()
  if body != nil:
    body_402656698 = body
  result = call_402656697.call(nil, nil, nil, nil, body_402656698)

var createConnection* = Call_CreateConnection_402656684(
    name: "createConnection", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateConnection",
    validator: validate_CreateConnection_402656685, base: "/",
    makeUrl: url_CreateConnection_402656686,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCrawler_402656699 = ref object of OpenApiRestCall_402656044
proc url_CreateCrawler_402656701(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCrawler_402656700(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656702 = header.getOrDefault("X-Amz-Target")
  valid_402656702 = validateParameter(valid_402656702, JString, required = true, default = newJString(
      "AWSGlue.CreateCrawler"))
  if valid_402656702 != nil:
    section.add "X-Amz-Target", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Security-Token", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Signature")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Signature", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Algorithm", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Date")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Date", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Credential")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Credential", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656711: Call_CreateCrawler_402656699; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
                                                                                         ## 
  let valid = call_402656711.validator(path, query, header, formData, body, _)
  let scheme = call_402656711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656711.makeUrl(scheme.get, call_402656711.host, call_402656711.base,
                                   call_402656711.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656711, uri, valid, _)

proc call*(call_402656712: Call_CreateCrawler_402656699; body: JsonNode): Recallable =
  ## createCrawler
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
  ##   
                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656713 = newJObject()
  if body != nil:
    body_402656713 = body
  result = call_402656712.call(nil, nil, nil, nil, body_402656713)

var createCrawler* = Call_CreateCrawler_402656699(name: "createCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateCrawler",
    validator: validate_CreateCrawler_402656700, base: "/",
    makeUrl: url_CreateCrawler_402656701, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatabase_402656714 = ref object of OpenApiRestCall_402656044
proc url_CreateDatabase_402656716(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDatabase_402656715(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new database in a Data Catalog.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656717 = header.getOrDefault("X-Amz-Target")
  valid_402656717 = validateParameter(valid_402656717, JString, required = true, default = newJString(
      "AWSGlue.CreateDatabase"))
  if valid_402656717 != nil:
    section.add "X-Amz-Target", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Security-Token", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Signature")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Signature", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Algorithm", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Date")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Date", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Credential")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Credential", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656726: Call_CreateDatabase_402656714; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new database in a Data Catalog.
                                                                                         ## 
  let valid = call_402656726.validator(path, query, header, formData, body, _)
  let scheme = call_402656726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656726.makeUrl(scheme.get, call_402656726.host, call_402656726.base,
                                   call_402656726.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656726, uri, valid, _)

proc call*(call_402656727: Call_CreateDatabase_402656714; body: JsonNode): Recallable =
  ## createDatabase
  ## Creates a new database in a Data Catalog.
  ##   body: JObject (required)
  var body_402656728 = newJObject()
  if body != nil:
    body_402656728 = body
  result = call_402656727.call(nil, nil, nil, nil, body_402656728)

var createDatabase* = Call_CreateDatabase_402656714(name: "createDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateDatabase",
    validator: validate_CreateDatabase_402656715, base: "/",
    makeUrl: url_CreateDatabase_402656716, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDevEndpoint_402656729 = ref object of OpenApiRestCall_402656044
proc url_CreateDevEndpoint_402656731(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDevEndpoint_402656730(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new development endpoint.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656732 = header.getOrDefault("X-Amz-Target")
  valid_402656732 = validateParameter(valid_402656732, JString, required = true, default = newJString(
      "AWSGlue.CreateDevEndpoint"))
  if valid_402656732 != nil:
    section.add "X-Amz-Target", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Security-Token", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Signature")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Signature", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Algorithm", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Date")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Date", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Credential")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Credential", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656739
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656741: Call_CreateDevEndpoint_402656729;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new development endpoint.
                                                                                         ## 
  let valid = call_402656741.validator(path, query, header, formData, body, _)
  let scheme = call_402656741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656741.makeUrl(scheme.get, call_402656741.host, call_402656741.base,
                                   call_402656741.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656741, uri, valid, _)

proc call*(call_402656742: Call_CreateDevEndpoint_402656729; body: JsonNode): Recallable =
  ## createDevEndpoint
  ## Creates a new development endpoint.
  ##   body: JObject (required)
  var body_402656743 = newJObject()
  if body != nil:
    body_402656743 = body
  result = call_402656742.call(nil, nil, nil, nil, body_402656743)

var createDevEndpoint* = Call_CreateDevEndpoint_402656729(
    name: "createDevEndpoint", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateDevEndpoint",
    validator: validate_CreateDevEndpoint_402656730, base: "/",
    makeUrl: url_CreateDevEndpoint_402656731,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_402656744 = ref object of OpenApiRestCall_402656044
proc url_CreateJob_402656746(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateJob_402656745(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new job definition.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656747 = header.getOrDefault("X-Amz-Target")
  valid_402656747 = validateParameter(valid_402656747, JString, required = true,
                                      default = newJString("AWSGlue.CreateJob"))
  if valid_402656747 != nil:
    section.add "X-Amz-Target", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Security-Token", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Signature")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Signature", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Algorithm", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Date")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Date", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Credential")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Credential", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656756: Call_CreateJob_402656744; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new job definition.
                                                                                         ## 
  let valid = call_402656756.validator(path, query, header, formData, body, _)
  let scheme = call_402656756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656756.makeUrl(scheme.get, call_402656756.host, call_402656756.base,
                                   call_402656756.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656756, uri, valid, _)

proc call*(call_402656757: Call_CreateJob_402656744; body: JsonNode): Recallable =
  ## createJob
  ## Creates a new job definition.
  ##   body: JObject (required)
  var body_402656758 = newJObject()
  if body != nil:
    body_402656758 = body
  result = call_402656757.call(nil, nil, nil, nil, body_402656758)

var createJob* = Call_CreateJob_402656744(name: "createJob",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateJob", validator: validate_CreateJob_402656745,
    base: "/", makeUrl: url_CreateJob_402656746,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMLTransform_402656759 = ref object of OpenApiRestCall_402656044
proc url_CreateMLTransform_402656761(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMLTransform_402656760(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656762 = header.getOrDefault("X-Amz-Target")
  valid_402656762 = validateParameter(valid_402656762, JString, required = true, default = newJString(
      "AWSGlue.CreateMLTransform"))
  if valid_402656762 != nil:
    section.add "X-Amz-Target", valid_402656762
  var valid_402656763 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-Security-Token", valid_402656763
  var valid_402656764 = header.getOrDefault("X-Amz-Signature")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Signature", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Algorithm", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Date")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Date", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Credential")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Credential", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656771: Call_CreateMLTransform_402656759;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
                                                                                         ## 
  let valid = call_402656771.validator(path, query, header, formData, body, _)
  let scheme = call_402656771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656771.makeUrl(scheme.get, call_402656771.host, call_402656771.base,
                                   call_402656771.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656771, uri, valid, _)

proc call*(call_402656772: Call_CreateMLTransform_402656759; body: JsonNode): Recallable =
  ## createMLTransform
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402656773 = newJObject()
  if body != nil:
    body_402656773 = body
  result = call_402656772.call(nil, nil, nil, nil, body_402656773)

var createMLTransform* = Call_CreateMLTransform_402656759(
    name: "createMLTransform", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateMLTransform",
    validator: validate_CreateMLTransform_402656760, base: "/",
    makeUrl: url_CreateMLTransform_402656761,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePartition_402656774 = ref object of OpenApiRestCall_402656044
proc url_CreatePartition_402656776(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePartition_402656775(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new partition.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656777 = header.getOrDefault("X-Amz-Target")
  valid_402656777 = validateParameter(valid_402656777, JString, required = true, default = newJString(
      "AWSGlue.CreatePartition"))
  if valid_402656777 != nil:
    section.add "X-Amz-Target", valid_402656777
  var valid_402656778 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656778 = validateParameter(valid_402656778, JString,
                                      required = false, default = nil)
  if valid_402656778 != nil:
    section.add "X-Amz-Security-Token", valid_402656778
  var valid_402656779 = header.getOrDefault("X-Amz-Signature")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-Signature", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656780
  var valid_402656781 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "X-Amz-Algorithm", valid_402656781
  var valid_402656782 = header.getOrDefault("X-Amz-Date")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "X-Amz-Date", valid_402656782
  var valid_402656783 = header.getOrDefault("X-Amz-Credential")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-Credential", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656786: Call_CreatePartition_402656774; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new partition.
                                                                                         ## 
  let valid = call_402656786.validator(path, query, header, formData, body, _)
  let scheme = call_402656786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656786.makeUrl(scheme.get, call_402656786.host, call_402656786.base,
                                   call_402656786.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656786, uri, valid, _)

proc call*(call_402656787: Call_CreatePartition_402656774; body: JsonNode): Recallable =
  ## createPartition
  ## Creates a new partition.
  ##   body: JObject (required)
  var body_402656788 = newJObject()
  if body != nil:
    body_402656788 = body
  result = call_402656787.call(nil, nil, nil, nil, body_402656788)

var createPartition* = Call_CreatePartition_402656774(name: "createPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreatePartition",
    validator: validate_CreatePartition_402656775, base: "/",
    makeUrl: url_CreatePartition_402656776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateScript_402656789 = ref object of OpenApiRestCall_402656044
proc url_CreateScript_402656791(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateScript_402656790(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Transforms a directed acyclic graph (DAG) into code.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656792 = header.getOrDefault("X-Amz-Target")
  valid_402656792 = validateParameter(valid_402656792, JString, required = true, default = newJString(
      "AWSGlue.CreateScript"))
  if valid_402656792 != nil:
    section.add "X-Amz-Target", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Security-Token", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-Signature")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Signature", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Algorithm", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-Date")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-Date", valid_402656797
  var valid_402656798 = header.getOrDefault("X-Amz-Credential")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-Credential", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656799
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656801: Call_CreateScript_402656789; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Transforms a directed acyclic graph (DAG) into code.
                                                                                         ## 
  let valid = call_402656801.validator(path, query, header, formData, body, _)
  let scheme = call_402656801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656801.makeUrl(scheme.get, call_402656801.host, call_402656801.base,
                                   call_402656801.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656801, uri, valid, _)

proc call*(call_402656802: Call_CreateScript_402656789; body: JsonNode): Recallable =
  ## createScript
  ## Transforms a directed acyclic graph (DAG) into code.
  ##   body: JObject (required)
  var body_402656803 = newJObject()
  if body != nil:
    body_402656803 = body
  result = call_402656802.call(nil, nil, nil, nil, body_402656803)

var createScript* = Call_CreateScript_402656789(name: "createScript",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateScript",
    validator: validate_CreateScript_402656790, base: "/",
    makeUrl: url_CreateScript_402656791, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSecurityConfiguration_402656804 = ref object of OpenApiRestCall_402656044
proc url_CreateSecurityConfiguration_402656806(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSecurityConfiguration_402656805(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656807 = header.getOrDefault("X-Amz-Target")
  valid_402656807 = validateParameter(valid_402656807, JString, required = true, default = newJString(
      "AWSGlue.CreateSecurityConfiguration"))
  if valid_402656807 != nil:
    section.add "X-Amz-Target", valid_402656807
  var valid_402656808 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-Security-Token", valid_402656808
  var valid_402656809 = header.getOrDefault("X-Amz-Signature")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-Signature", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656810
  var valid_402656811 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-Algorithm", valid_402656811
  var valid_402656812 = header.getOrDefault("X-Amz-Date")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "X-Amz-Date", valid_402656812
  var valid_402656813 = header.getOrDefault("X-Amz-Credential")
  valid_402656813 = validateParameter(valid_402656813, JString,
                                      required = false, default = nil)
  if valid_402656813 != nil:
    section.add "X-Amz-Credential", valid_402656813
  var valid_402656814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656814 = validateParameter(valid_402656814, JString,
                                      required = false, default = nil)
  if valid_402656814 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656816: Call_CreateSecurityConfiguration_402656804;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
                                                                                         ## 
  let valid = call_402656816.validator(path, query, header, formData, body, _)
  let scheme = call_402656816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656816.makeUrl(scheme.get, call_402656816.host, call_402656816.base,
                                   call_402656816.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656816, uri, valid, _)

proc call*(call_402656817: Call_CreateSecurityConfiguration_402656804;
           body: JsonNode): Recallable =
  ## createSecurityConfiguration
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656818 = newJObject()
  if body != nil:
    body_402656818 = body
  result = call_402656817.call(nil, nil, nil, nil, body_402656818)

var createSecurityConfiguration* = Call_CreateSecurityConfiguration_402656804(
    name: "createSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateSecurityConfiguration",
    validator: validate_CreateSecurityConfiguration_402656805, base: "/",
    makeUrl: url_CreateSecurityConfiguration_402656806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTable_402656819 = ref object of OpenApiRestCall_402656044
proc url_CreateTable_402656821(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTable_402656820(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new table definition in the Data Catalog.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656822 = header.getOrDefault("X-Amz-Target")
  valid_402656822 = validateParameter(valid_402656822, JString, required = true, default = newJString(
      "AWSGlue.CreateTable"))
  if valid_402656822 != nil:
    section.add "X-Amz-Target", valid_402656822
  var valid_402656823 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Security-Token", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-Signature")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-Signature", valid_402656824
  var valid_402656825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656825
  var valid_402656826 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "X-Amz-Algorithm", valid_402656826
  var valid_402656827 = header.getOrDefault("X-Amz-Date")
  valid_402656827 = validateParameter(valid_402656827, JString,
                                      required = false, default = nil)
  if valid_402656827 != nil:
    section.add "X-Amz-Date", valid_402656827
  var valid_402656828 = header.getOrDefault("X-Amz-Credential")
  valid_402656828 = validateParameter(valid_402656828, JString,
                                      required = false, default = nil)
  if valid_402656828 != nil:
    section.add "X-Amz-Credential", valid_402656828
  var valid_402656829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656829 = validateParameter(valid_402656829, JString,
                                      required = false, default = nil)
  if valid_402656829 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656831: Call_CreateTable_402656819; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new table definition in the Data Catalog.
                                                                                         ## 
  let valid = call_402656831.validator(path, query, header, formData, body, _)
  let scheme = call_402656831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656831.makeUrl(scheme.get, call_402656831.host, call_402656831.base,
                                   call_402656831.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656831, uri, valid, _)

proc call*(call_402656832: Call_CreateTable_402656819; body: JsonNode): Recallable =
  ## createTable
  ## Creates a new table definition in the Data Catalog.
  ##   body: JObject (required)
  var body_402656833 = newJObject()
  if body != nil:
    body_402656833 = body
  result = call_402656832.call(nil, nil, nil, nil, body_402656833)

var createTable* = Call_CreateTable_402656819(name: "createTable",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateTable",
    validator: validate_CreateTable_402656820, base: "/",
    makeUrl: url_CreateTable_402656821, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrigger_402656834 = ref object of OpenApiRestCall_402656044
proc url_CreateTrigger_402656836(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTrigger_402656835(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new trigger.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656837 = header.getOrDefault("X-Amz-Target")
  valid_402656837 = validateParameter(valid_402656837, JString, required = true, default = newJString(
      "AWSGlue.CreateTrigger"))
  if valid_402656837 != nil:
    section.add "X-Amz-Target", valid_402656837
  var valid_402656838 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "X-Amz-Security-Token", valid_402656838
  var valid_402656839 = header.getOrDefault("X-Amz-Signature")
  valid_402656839 = validateParameter(valid_402656839, JString,
                                      required = false, default = nil)
  if valid_402656839 != nil:
    section.add "X-Amz-Signature", valid_402656839
  var valid_402656840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656840 = validateParameter(valid_402656840, JString,
                                      required = false, default = nil)
  if valid_402656840 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656840
  var valid_402656841 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656841 = validateParameter(valid_402656841, JString,
                                      required = false, default = nil)
  if valid_402656841 != nil:
    section.add "X-Amz-Algorithm", valid_402656841
  var valid_402656842 = header.getOrDefault("X-Amz-Date")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-Date", valid_402656842
  var valid_402656843 = header.getOrDefault("X-Amz-Credential")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-Credential", valid_402656843
  var valid_402656844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656844 = validateParameter(valid_402656844, JString,
                                      required = false, default = nil)
  if valid_402656844 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656844
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656846: Call_CreateTrigger_402656834; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new trigger.
                                                                                         ## 
  let valid = call_402656846.validator(path, query, header, formData, body, _)
  let scheme = call_402656846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656846.makeUrl(scheme.get, call_402656846.host, call_402656846.base,
                                   call_402656846.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656846, uri, valid, _)

proc call*(call_402656847: Call_CreateTrigger_402656834; body: JsonNode): Recallable =
  ## createTrigger
  ## Creates a new trigger.
  ##   body: JObject (required)
  var body_402656848 = newJObject()
  if body != nil:
    body_402656848 = body
  result = call_402656847.call(nil, nil, nil, nil, body_402656848)

var createTrigger* = Call_CreateTrigger_402656834(name: "createTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateTrigger",
    validator: validate_CreateTrigger_402656835, base: "/",
    makeUrl: url_CreateTrigger_402656836, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserDefinedFunction_402656849 = ref object of OpenApiRestCall_402656044
proc url_CreateUserDefinedFunction_402656851(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserDefinedFunction_402656850(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a new function definition in the Data Catalog.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656852 = header.getOrDefault("X-Amz-Target")
  valid_402656852 = validateParameter(valid_402656852, JString, required = true, default = newJString(
      "AWSGlue.CreateUserDefinedFunction"))
  if valid_402656852 != nil:
    section.add "X-Amz-Target", valid_402656852
  var valid_402656853 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656853 = validateParameter(valid_402656853, JString,
                                      required = false, default = nil)
  if valid_402656853 != nil:
    section.add "X-Amz-Security-Token", valid_402656853
  var valid_402656854 = header.getOrDefault("X-Amz-Signature")
  valid_402656854 = validateParameter(valid_402656854, JString,
                                      required = false, default = nil)
  if valid_402656854 != nil:
    section.add "X-Amz-Signature", valid_402656854
  var valid_402656855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656855 = validateParameter(valid_402656855, JString,
                                      required = false, default = nil)
  if valid_402656855 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656855
  var valid_402656856 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "X-Amz-Algorithm", valid_402656856
  var valid_402656857 = header.getOrDefault("X-Amz-Date")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Date", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-Credential")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-Credential", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656859
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656861: Call_CreateUserDefinedFunction_402656849;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new function definition in the Data Catalog.
                                                                                         ## 
  let valid = call_402656861.validator(path, query, header, formData, body, _)
  let scheme = call_402656861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656861.makeUrl(scheme.get, call_402656861.host, call_402656861.base,
                                   call_402656861.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656861, uri, valid, _)

proc call*(call_402656862: Call_CreateUserDefinedFunction_402656849;
           body: JsonNode): Recallable =
  ## createUserDefinedFunction
  ## Creates a new function definition in the Data Catalog.
  ##   body: JObject (required)
  var body_402656863 = newJObject()
  if body != nil:
    body_402656863 = body
  result = call_402656862.call(nil, nil, nil, nil, body_402656863)

var createUserDefinedFunction* = Call_CreateUserDefinedFunction_402656849(
    name: "createUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateUserDefinedFunction",
    validator: validate_CreateUserDefinedFunction_402656850, base: "/",
    makeUrl: url_CreateUserDefinedFunction_402656851,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkflow_402656864 = ref object of OpenApiRestCall_402656044
proc url_CreateWorkflow_402656866(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateWorkflow_402656865(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new workflow.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656867 = header.getOrDefault("X-Amz-Target")
  valid_402656867 = validateParameter(valid_402656867, JString, required = true, default = newJString(
      "AWSGlue.CreateWorkflow"))
  if valid_402656867 != nil:
    section.add "X-Amz-Target", valid_402656867
  var valid_402656868 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656868 = validateParameter(valid_402656868, JString,
                                      required = false, default = nil)
  if valid_402656868 != nil:
    section.add "X-Amz-Security-Token", valid_402656868
  var valid_402656869 = header.getOrDefault("X-Amz-Signature")
  valid_402656869 = validateParameter(valid_402656869, JString,
                                      required = false, default = nil)
  if valid_402656869 != nil:
    section.add "X-Amz-Signature", valid_402656869
  var valid_402656870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656870 = validateParameter(valid_402656870, JString,
                                      required = false, default = nil)
  if valid_402656870 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656870
  var valid_402656871 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656871 = validateParameter(valid_402656871, JString,
                                      required = false, default = nil)
  if valid_402656871 != nil:
    section.add "X-Amz-Algorithm", valid_402656871
  var valid_402656872 = header.getOrDefault("X-Amz-Date")
  valid_402656872 = validateParameter(valid_402656872, JString,
                                      required = false, default = nil)
  if valid_402656872 != nil:
    section.add "X-Amz-Date", valid_402656872
  var valid_402656873 = header.getOrDefault("X-Amz-Credential")
  valid_402656873 = validateParameter(valid_402656873, JString,
                                      required = false, default = nil)
  if valid_402656873 != nil:
    section.add "X-Amz-Credential", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656876: Call_CreateWorkflow_402656864; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new workflow.
                                                                                         ## 
  let valid = call_402656876.validator(path, query, header, formData, body, _)
  let scheme = call_402656876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656876.makeUrl(scheme.get, call_402656876.host, call_402656876.base,
                                   call_402656876.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656876, uri, valid, _)

proc call*(call_402656877: Call_CreateWorkflow_402656864; body: JsonNode): Recallable =
  ## createWorkflow
  ## Creates a new workflow.
  ##   body: JObject (required)
  var body_402656878 = newJObject()
  if body != nil:
    body_402656878 = body
  result = call_402656877.call(nil, nil, nil, nil, body_402656878)

var createWorkflow* = Call_CreateWorkflow_402656864(name: "createWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateWorkflow",
    validator: validate_CreateWorkflow_402656865, base: "/",
    makeUrl: url_CreateWorkflow_402656866, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteClassifier_402656879 = ref object of OpenApiRestCall_402656044
proc url_DeleteClassifier_402656881(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteClassifier_402656880(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes a classifier from the Data Catalog.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656882 = header.getOrDefault("X-Amz-Target")
  valid_402656882 = validateParameter(valid_402656882, JString, required = true, default = newJString(
      "AWSGlue.DeleteClassifier"))
  if valid_402656882 != nil:
    section.add "X-Amz-Target", valid_402656882
  var valid_402656883 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656883 = validateParameter(valid_402656883, JString,
                                      required = false, default = nil)
  if valid_402656883 != nil:
    section.add "X-Amz-Security-Token", valid_402656883
  var valid_402656884 = header.getOrDefault("X-Amz-Signature")
  valid_402656884 = validateParameter(valid_402656884, JString,
                                      required = false, default = nil)
  if valid_402656884 != nil:
    section.add "X-Amz-Signature", valid_402656884
  var valid_402656885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656885 = validateParameter(valid_402656885, JString,
                                      required = false, default = nil)
  if valid_402656885 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656885
  var valid_402656886 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656886 = validateParameter(valid_402656886, JString,
                                      required = false, default = nil)
  if valid_402656886 != nil:
    section.add "X-Amz-Algorithm", valid_402656886
  var valid_402656887 = header.getOrDefault("X-Amz-Date")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "X-Amz-Date", valid_402656887
  var valid_402656888 = header.getOrDefault("X-Amz-Credential")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-Credential", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656891: Call_DeleteClassifier_402656879;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a classifier from the Data Catalog.
                                                                                         ## 
  let valid = call_402656891.validator(path, query, header, formData, body, _)
  let scheme = call_402656891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656891.makeUrl(scheme.get, call_402656891.host, call_402656891.base,
                                   call_402656891.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656891, uri, valid, _)

proc call*(call_402656892: Call_DeleteClassifier_402656879; body: JsonNode): Recallable =
  ## deleteClassifier
  ## Removes a classifier from the Data Catalog.
  ##   body: JObject (required)
  var body_402656893 = newJObject()
  if body != nil:
    body_402656893 = body
  result = call_402656892.call(nil, nil, nil, nil, body_402656893)

var deleteClassifier* = Call_DeleteClassifier_402656879(
    name: "deleteClassifier", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteClassifier",
    validator: validate_DeleteClassifier_402656880, base: "/",
    makeUrl: url_DeleteClassifier_402656881,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_402656894 = ref object of OpenApiRestCall_402656044
proc url_DeleteConnection_402656896(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteConnection_402656895(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a connection from the Data Catalog.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656897 = header.getOrDefault("X-Amz-Target")
  valid_402656897 = validateParameter(valid_402656897, JString, required = true, default = newJString(
      "AWSGlue.DeleteConnection"))
  if valid_402656897 != nil:
    section.add "X-Amz-Target", valid_402656897
  var valid_402656898 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656898 = validateParameter(valid_402656898, JString,
                                      required = false, default = nil)
  if valid_402656898 != nil:
    section.add "X-Amz-Security-Token", valid_402656898
  var valid_402656899 = header.getOrDefault("X-Amz-Signature")
  valid_402656899 = validateParameter(valid_402656899, JString,
                                      required = false, default = nil)
  if valid_402656899 != nil:
    section.add "X-Amz-Signature", valid_402656899
  var valid_402656900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656900 = validateParameter(valid_402656900, JString,
                                      required = false, default = nil)
  if valid_402656900 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656900
  var valid_402656901 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656901 = validateParameter(valid_402656901, JString,
                                      required = false, default = nil)
  if valid_402656901 != nil:
    section.add "X-Amz-Algorithm", valid_402656901
  var valid_402656902 = header.getOrDefault("X-Amz-Date")
  valid_402656902 = validateParameter(valid_402656902, JString,
                                      required = false, default = nil)
  if valid_402656902 != nil:
    section.add "X-Amz-Date", valid_402656902
  var valid_402656903 = header.getOrDefault("X-Amz-Credential")
  valid_402656903 = validateParameter(valid_402656903, JString,
                                      required = false, default = nil)
  if valid_402656903 != nil:
    section.add "X-Amz-Credential", valid_402656903
  var valid_402656904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656904 = validateParameter(valid_402656904, JString,
                                      required = false, default = nil)
  if valid_402656904 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656906: Call_DeleteConnection_402656894;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a connection from the Data Catalog.
                                                                                         ## 
  let valid = call_402656906.validator(path, query, header, formData, body, _)
  let scheme = call_402656906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656906.makeUrl(scheme.get, call_402656906.host, call_402656906.base,
                                   call_402656906.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656906, uri, valid, _)

proc call*(call_402656907: Call_DeleteConnection_402656894; body: JsonNode): Recallable =
  ## deleteConnection
  ## Deletes a connection from the Data Catalog.
  ##   body: JObject (required)
  var body_402656908 = newJObject()
  if body != nil:
    body_402656908 = body
  result = call_402656907.call(nil, nil, nil, nil, body_402656908)

var deleteConnection* = Call_DeleteConnection_402656894(
    name: "deleteConnection", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteConnection",
    validator: validate_DeleteConnection_402656895, base: "/",
    makeUrl: url_DeleteConnection_402656896,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCrawler_402656909 = ref object of OpenApiRestCall_402656044
proc url_DeleteCrawler_402656911(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteCrawler_402656910(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656912 = header.getOrDefault("X-Amz-Target")
  valid_402656912 = validateParameter(valid_402656912, JString, required = true, default = newJString(
      "AWSGlue.DeleteCrawler"))
  if valid_402656912 != nil:
    section.add "X-Amz-Target", valid_402656912
  var valid_402656913 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656913 = validateParameter(valid_402656913, JString,
                                      required = false, default = nil)
  if valid_402656913 != nil:
    section.add "X-Amz-Security-Token", valid_402656913
  var valid_402656914 = header.getOrDefault("X-Amz-Signature")
  valid_402656914 = validateParameter(valid_402656914, JString,
                                      required = false, default = nil)
  if valid_402656914 != nil:
    section.add "X-Amz-Signature", valid_402656914
  var valid_402656915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656915 = validateParameter(valid_402656915, JString,
                                      required = false, default = nil)
  if valid_402656915 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656915
  var valid_402656916 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656916 = validateParameter(valid_402656916, JString,
                                      required = false, default = nil)
  if valid_402656916 != nil:
    section.add "X-Amz-Algorithm", valid_402656916
  var valid_402656917 = header.getOrDefault("X-Amz-Date")
  valid_402656917 = validateParameter(valid_402656917, JString,
                                      required = false, default = nil)
  if valid_402656917 != nil:
    section.add "X-Amz-Date", valid_402656917
  var valid_402656918 = header.getOrDefault("X-Amz-Credential")
  valid_402656918 = validateParameter(valid_402656918, JString,
                                      required = false, default = nil)
  if valid_402656918 != nil:
    section.add "X-Amz-Credential", valid_402656918
  var valid_402656919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656919 = validateParameter(valid_402656919, JString,
                                      required = false, default = nil)
  if valid_402656919 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656919
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656921: Call_DeleteCrawler_402656909; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
                                                                                         ## 
  let valid = call_402656921.validator(path, query, header, formData, body, _)
  let scheme = call_402656921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656921.makeUrl(scheme.get, call_402656921.host, call_402656921.base,
                                   call_402656921.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656921, uri, valid, _)

proc call*(call_402656922: Call_DeleteCrawler_402656909; body: JsonNode): Recallable =
  ## deleteCrawler
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
  ##   
                                                                                                                  ## body: JObject (required)
  var body_402656923 = newJObject()
  if body != nil:
    body_402656923 = body
  result = call_402656922.call(nil, nil, nil, nil, body_402656923)

var deleteCrawler* = Call_DeleteCrawler_402656909(name: "deleteCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteCrawler",
    validator: validate_DeleteCrawler_402656910, base: "/",
    makeUrl: url_DeleteCrawler_402656911, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatabase_402656924 = ref object of OpenApiRestCall_402656044
proc url_DeleteDatabase_402656926(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDatabase_402656925(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656927 = header.getOrDefault("X-Amz-Target")
  valid_402656927 = validateParameter(valid_402656927, JString, required = true, default = newJString(
      "AWSGlue.DeleteDatabase"))
  if valid_402656927 != nil:
    section.add "X-Amz-Target", valid_402656927
  var valid_402656928 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656928 = validateParameter(valid_402656928, JString,
                                      required = false, default = nil)
  if valid_402656928 != nil:
    section.add "X-Amz-Security-Token", valid_402656928
  var valid_402656929 = header.getOrDefault("X-Amz-Signature")
  valid_402656929 = validateParameter(valid_402656929, JString,
                                      required = false, default = nil)
  if valid_402656929 != nil:
    section.add "X-Amz-Signature", valid_402656929
  var valid_402656930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656930 = validateParameter(valid_402656930, JString,
                                      required = false, default = nil)
  if valid_402656930 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656930
  var valid_402656931 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656931 = validateParameter(valid_402656931, JString,
                                      required = false, default = nil)
  if valid_402656931 != nil:
    section.add "X-Amz-Algorithm", valid_402656931
  var valid_402656932 = header.getOrDefault("X-Amz-Date")
  valid_402656932 = validateParameter(valid_402656932, JString,
                                      required = false, default = nil)
  if valid_402656932 != nil:
    section.add "X-Amz-Date", valid_402656932
  var valid_402656933 = header.getOrDefault("X-Amz-Credential")
  valid_402656933 = validateParameter(valid_402656933, JString,
                                      required = false, default = nil)
  if valid_402656933 != nil:
    section.add "X-Amz-Credential", valid_402656933
  var valid_402656934 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656934 = validateParameter(valid_402656934, JString,
                                      required = false, default = nil)
  if valid_402656934 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656934
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656936: Call_DeleteDatabase_402656924; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
                                                                                         ## 
  let valid = call_402656936.validator(path, query, header, formData, body, _)
  let scheme = call_402656936.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656936.makeUrl(scheme.get, call_402656936.host, call_402656936.base,
                                   call_402656936.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656936, uri, valid, _)

proc call*(call_402656937: Call_DeleteDatabase_402656924; body: JsonNode): Recallable =
  ## deleteDatabase
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656938 = newJObject()
  if body != nil:
    body_402656938 = body
  result = call_402656937.call(nil, nil, nil, nil, body_402656938)

var deleteDatabase* = Call_DeleteDatabase_402656924(name: "deleteDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteDatabase",
    validator: validate_DeleteDatabase_402656925, base: "/",
    makeUrl: url_DeleteDatabase_402656926, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevEndpoint_402656939 = ref object of OpenApiRestCall_402656044
proc url_DeleteDevEndpoint_402656941(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDevEndpoint_402656940(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a specified development endpoint.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656942 = header.getOrDefault("X-Amz-Target")
  valid_402656942 = validateParameter(valid_402656942, JString, required = true, default = newJString(
      "AWSGlue.DeleteDevEndpoint"))
  if valid_402656942 != nil:
    section.add "X-Amz-Target", valid_402656942
  var valid_402656943 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656943 = validateParameter(valid_402656943, JString,
                                      required = false, default = nil)
  if valid_402656943 != nil:
    section.add "X-Amz-Security-Token", valid_402656943
  var valid_402656944 = header.getOrDefault("X-Amz-Signature")
  valid_402656944 = validateParameter(valid_402656944, JString,
                                      required = false, default = nil)
  if valid_402656944 != nil:
    section.add "X-Amz-Signature", valid_402656944
  var valid_402656945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656945 = validateParameter(valid_402656945, JString,
                                      required = false, default = nil)
  if valid_402656945 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656945
  var valid_402656946 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656946 = validateParameter(valid_402656946, JString,
                                      required = false, default = nil)
  if valid_402656946 != nil:
    section.add "X-Amz-Algorithm", valid_402656946
  var valid_402656947 = header.getOrDefault("X-Amz-Date")
  valid_402656947 = validateParameter(valid_402656947, JString,
                                      required = false, default = nil)
  if valid_402656947 != nil:
    section.add "X-Amz-Date", valid_402656947
  var valid_402656948 = header.getOrDefault("X-Amz-Credential")
  valid_402656948 = validateParameter(valid_402656948, JString,
                                      required = false, default = nil)
  if valid_402656948 != nil:
    section.add "X-Amz-Credential", valid_402656948
  var valid_402656949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656949 = validateParameter(valid_402656949, JString,
                                      required = false, default = nil)
  if valid_402656949 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656949
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656951: Call_DeleteDevEndpoint_402656939;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified development endpoint.
                                                                                         ## 
  let valid = call_402656951.validator(path, query, header, formData, body, _)
  let scheme = call_402656951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656951.makeUrl(scheme.get, call_402656951.host, call_402656951.base,
                                   call_402656951.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656951, uri, valid, _)

proc call*(call_402656952: Call_DeleteDevEndpoint_402656939; body: JsonNode): Recallable =
  ## deleteDevEndpoint
  ## Deletes a specified development endpoint.
  ##   body: JObject (required)
  var body_402656953 = newJObject()
  if body != nil:
    body_402656953 = body
  result = call_402656952.call(nil, nil, nil, nil, body_402656953)

var deleteDevEndpoint* = Call_DeleteDevEndpoint_402656939(
    name: "deleteDevEndpoint", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteDevEndpoint",
    validator: validate_DeleteDevEndpoint_402656940, base: "/",
    makeUrl: url_DeleteDevEndpoint_402656941,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJob_402656954 = ref object of OpenApiRestCall_402656044
proc url_DeleteJob_402656956(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteJob_402656955(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656957 = header.getOrDefault("X-Amz-Target")
  valid_402656957 = validateParameter(valid_402656957, JString, required = true,
                                      default = newJString("AWSGlue.DeleteJob"))
  if valid_402656957 != nil:
    section.add "X-Amz-Target", valid_402656957
  var valid_402656958 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656958 = validateParameter(valid_402656958, JString,
                                      required = false, default = nil)
  if valid_402656958 != nil:
    section.add "X-Amz-Security-Token", valid_402656958
  var valid_402656959 = header.getOrDefault("X-Amz-Signature")
  valid_402656959 = validateParameter(valid_402656959, JString,
                                      required = false, default = nil)
  if valid_402656959 != nil:
    section.add "X-Amz-Signature", valid_402656959
  var valid_402656960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656960 = validateParameter(valid_402656960, JString,
                                      required = false, default = nil)
  if valid_402656960 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656960
  var valid_402656961 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656961 = validateParameter(valid_402656961, JString,
                                      required = false, default = nil)
  if valid_402656961 != nil:
    section.add "X-Amz-Algorithm", valid_402656961
  var valid_402656962 = header.getOrDefault("X-Amz-Date")
  valid_402656962 = validateParameter(valid_402656962, JString,
                                      required = false, default = nil)
  if valid_402656962 != nil:
    section.add "X-Amz-Date", valid_402656962
  var valid_402656963 = header.getOrDefault("X-Amz-Credential")
  valid_402656963 = validateParameter(valid_402656963, JString,
                                      required = false, default = nil)
  if valid_402656963 != nil:
    section.add "X-Amz-Credential", valid_402656963
  var valid_402656964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656964 = validateParameter(valid_402656964, JString,
                                      required = false, default = nil)
  if valid_402656964 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656964
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656966: Call_DeleteJob_402656954; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
                                                                                         ## 
  let valid = call_402656966.validator(path, query, header, formData, body, _)
  let scheme = call_402656966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656966.makeUrl(scheme.get, call_402656966.host, call_402656966.base,
                                   call_402656966.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656966, uri, valid, _)

proc call*(call_402656967: Call_DeleteJob_402656954; body: JsonNode): Recallable =
  ## deleteJob
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
  ##   
                                                                                                    ## body: JObject (required)
  var body_402656968 = newJObject()
  if body != nil:
    body_402656968 = body
  result = call_402656967.call(nil, nil, nil, nil, body_402656968)

var deleteJob* = Call_DeleteJob_402656954(name: "deleteJob",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteJob", validator: validate_DeleteJob_402656955,
    base: "/", makeUrl: url_DeleteJob_402656956,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMLTransform_402656969 = ref object of OpenApiRestCall_402656044
proc url_DeleteMLTransform_402656971(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteMLTransform_402656970(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656972 = header.getOrDefault("X-Amz-Target")
  valid_402656972 = validateParameter(valid_402656972, JString, required = true, default = newJString(
      "AWSGlue.DeleteMLTransform"))
  if valid_402656972 != nil:
    section.add "X-Amz-Target", valid_402656972
  var valid_402656973 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656973 = validateParameter(valid_402656973, JString,
                                      required = false, default = nil)
  if valid_402656973 != nil:
    section.add "X-Amz-Security-Token", valid_402656973
  var valid_402656974 = header.getOrDefault("X-Amz-Signature")
  valid_402656974 = validateParameter(valid_402656974, JString,
                                      required = false, default = nil)
  if valid_402656974 != nil:
    section.add "X-Amz-Signature", valid_402656974
  var valid_402656975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656975 = validateParameter(valid_402656975, JString,
                                      required = false, default = nil)
  if valid_402656975 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656975
  var valid_402656976 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656976 = validateParameter(valid_402656976, JString,
                                      required = false, default = nil)
  if valid_402656976 != nil:
    section.add "X-Amz-Algorithm", valid_402656976
  var valid_402656977 = header.getOrDefault("X-Amz-Date")
  valid_402656977 = validateParameter(valid_402656977, JString,
                                      required = false, default = nil)
  if valid_402656977 != nil:
    section.add "X-Amz-Date", valid_402656977
  var valid_402656978 = header.getOrDefault("X-Amz-Credential")
  valid_402656978 = validateParameter(valid_402656978, JString,
                                      required = false, default = nil)
  if valid_402656978 != nil:
    section.add "X-Amz-Credential", valid_402656978
  var valid_402656979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656979 = validateParameter(valid_402656979, JString,
                                      required = false, default = nil)
  if valid_402656979 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656979
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656981: Call_DeleteMLTransform_402656969;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
                                                                                         ## 
  let valid = call_402656981.validator(path, query, header, formData, body, _)
  let scheme = call_402656981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656981.makeUrl(scheme.get, call_402656981.host, call_402656981.base,
                                   call_402656981.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656981, uri, valid, _)

proc call*(call_402656982: Call_DeleteMLTransform_402656969; body: JsonNode): Recallable =
  ## deleteMLTransform
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402656983 = newJObject()
  if body != nil:
    body_402656983 = body
  result = call_402656982.call(nil, nil, nil, nil, body_402656983)

var deleteMLTransform* = Call_DeleteMLTransform_402656969(
    name: "deleteMLTransform", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteMLTransform",
    validator: validate_DeleteMLTransform_402656970, base: "/",
    makeUrl: url_DeleteMLTransform_402656971,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePartition_402656984 = ref object of OpenApiRestCall_402656044
proc url_DeletePartition_402656986(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePartition_402656985(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a specified partition.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656987 = header.getOrDefault("X-Amz-Target")
  valid_402656987 = validateParameter(valid_402656987, JString, required = true, default = newJString(
      "AWSGlue.DeletePartition"))
  if valid_402656987 != nil:
    section.add "X-Amz-Target", valid_402656987
  var valid_402656988 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656988 = validateParameter(valid_402656988, JString,
                                      required = false, default = nil)
  if valid_402656988 != nil:
    section.add "X-Amz-Security-Token", valid_402656988
  var valid_402656989 = header.getOrDefault("X-Amz-Signature")
  valid_402656989 = validateParameter(valid_402656989, JString,
                                      required = false, default = nil)
  if valid_402656989 != nil:
    section.add "X-Amz-Signature", valid_402656989
  var valid_402656990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656990 = validateParameter(valid_402656990, JString,
                                      required = false, default = nil)
  if valid_402656990 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656990
  var valid_402656991 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656991 = validateParameter(valid_402656991, JString,
                                      required = false, default = nil)
  if valid_402656991 != nil:
    section.add "X-Amz-Algorithm", valid_402656991
  var valid_402656992 = header.getOrDefault("X-Amz-Date")
  valid_402656992 = validateParameter(valid_402656992, JString,
                                      required = false, default = nil)
  if valid_402656992 != nil:
    section.add "X-Amz-Date", valid_402656992
  var valid_402656993 = header.getOrDefault("X-Amz-Credential")
  valid_402656993 = validateParameter(valid_402656993, JString,
                                      required = false, default = nil)
  if valid_402656993 != nil:
    section.add "X-Amz-Credential", valid_402656993
  var valid_402656994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656994 = validateParameter(valid_402656994, JString,
                                      required = false, default = nil)
  if valid_402656994 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656994
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656996: Call_DeletePartition_402656984; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified partition.
                                                                                         ## 
  let valid = call_402656996.validator(path, query, header, formData, body, _)
  let scheme = call_402656996.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656996.makeUrl(scheme.get, call_402656996.host, call_402656996.base,
                                   call_402656996.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656996, uri, valid, _)

proc call*(call_402656997: Call_DeletePartition_402656984; body: JsonNode): Recallable =
  ## deletePartition
  ## Deletes a specified partition.
  ##   body: JObject (required)
  var body_402656998 = newJObject()
  if body != nil:
    body_402656998 = body
  result = call_402656997.call(nil, nil, nil, nil, body_402656998)

var deletePartition* = Call_DeletePartition_402656984(name: "deletePartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeletePartition",
    validator: validate_DeletePartition_402656985, base: "/",
    makeUrl: url_DeletePartition_402656986, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourcePolicy_402656999 = ref object of OpenApiRestCall_402656044
proc url_DeleteResourcePolicy_402657001(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteResourcePolicy_402657000(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a specified policy.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657002 = header.getOrDefault("X-Amz-Target")
  valid_402657002 = validateParameter(valid_402657002, JString, required = true, default = newJString(
      "AWSGlue.DeleteResourcePolicy"))
  if valid_402657002 != nil:
    section.add "X-Amz-Target", valid_402657002
  var valid_402657003 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657003 = validateParameter(valid_402657003, JString,
                                      required = false, default = nil)
  if valid_402657003 != nil:
    section.add "X-Amz-Security-Token", valid_402657003
  var valid_402657004 = header.getOrDefault("X-Amz-Signature")
  valid_402657004 = validateParameter(valid_402657004, JString,
                                      required = false, default = nil)
  if valid_402657004 != nil:
    section.add "X-Amz-Signature", valid_402657004
  var valid_402657005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657005 = validateParameter(valid_402657005, JString,
                                      required = false, default = nil)
  if valid_402657005 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657005
  var valid_402657006 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657006 = validateParameter(valid_402657006, JString,
                                      required = false, default = nil)
  if valid_402657006 != nil:
    section.add "X-Amz-Algorithm", valid_402657006
  var valid_402657007 = header.getOrDefault("X-Amz-Date")
  valid_402657007 = validateParameter(valid_402657007, JString,
                                      required = false, default = nil)
  if valid_402657007 != nil:
    section.add "X-Amz-Date", valid_402657007
  var valid_402657008 = header.getOrDefault("X-Amz-Credential")
  valid_402657008 = validateParameter(valid_402657008, JString,
                                      required = false, default = nil)
  if valid_402657008 != nil:
    section.add "X-Amz-Credential", valid_402657008
  var valid_402657009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657009 = validateParameter(valid_402657009, JString,
                                      required = false, default = nil)
  if valid_402657009 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657011: Call_DeleteResourcePolicy_402656999;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified policy.
                                                                                         ## 
  let valid = call_402657011.validator(path, query, header, formData, body, _)
  let scheme = call_402657011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657011.makeUrl(scheme.get, call_402657011.host, call_402657011.base,
                                   call_402657011.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657011, uri, valid, _)

proc call*(call_402657012: Call_DeleteResourcePolicy_402656999; body: JsonNode): Recallable =
  ## deleteResourcePolicy
  ## Deletes a specified policy.
  ##   body: JObject (required)
  var body_402657013 = newJObject()
  if body != nil:
    body_402657013 = body
  result = call_402657012.call(nil, nil, nil, nil, body_402657013)

var deleteResourcePolicy* = Call_DeleteResourcePolicy_402656999(
    name: "deleteResourcePolicy", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteResourcePolicy",
    validator: validate_DeleteResourcePolicy_402657000, base: "/",
    makeUrl: url_DeleteResourcePolicy_402657001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSecurityConfiguration_402657014 = ref object of OpenApiRestCall_402656044
proc url_DeleteSecurityConfiguration_402657016(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSecurityConfiguration_402657015(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes a specified security configuration.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657017 = header.getOrDefault("X-Amz-Target")
  valid_402657017 = validateParameter(valid_402657017, JString, required = true, default = newJString(
      "AWSGlue.DeleteSecurityConfiguration"))
  if valid_402657017 != nil:
    section.add "X-Amz-Target", valid_402657017
  var valid_402657018 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657018 = validateParameter(valid_402657018, JString,
                                      required = false, default = nil)
  if valid_402657018 != nil:
    section.add "X-Amz-Security-Token", valid_402657018
  var valid_402657019 = header.getOrDefault("X-Amz-Signature")
  valid_402657019 = validateParameter(valid_402657019, JString,
                                      required = false, default = nil)
  if valid_402657019 != nil:
    section.add "X-Amz-Signature", valid_402657019
  var valid_402657020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657020 = validateParameter(valid_402657020, JString,
                                      required = false, default = nil)
  if valid_402657020 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657020
  var valid_402657021 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657021 = validateParameter(valid_402657021, JString,
                                      required = false, default = nil)
  if valid_402657021 != nil:
    section.add "X-Amz-Algorithm", valid_402657021
  var valid_402657022 = header.getOrDefault("X-Amz-Date")
  valid_402657022 = validateParameter(valid_402657022, JString,
                                      required = false, default = nil)
  if valid_402657022 != nil:
    section.add "X-Amz-Date", valid_402657022
  var valid_402657023 = header.getOrDefault("X-Amz-Credential")
  valid_402657023 = validateParameter(valid_402657023, JString,
                                      required = false, default = nil)
  if valid_402657023 != nil:
    section.add "X-Amz-Credential", valid_402657023
  var valid_402657024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657024 = validateParameter(valid_402657024, JString,
                                      required = false, default = nil)
  if valid_402657024 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657024
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657026: Call_DeleteSecurityConfiguration_402657014;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified security configuration.
                                                                                         ## 
  let valid = call_402657026.validator(path, query, header, formData, body, _)
  let scheme = call_402657026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657026.makeUrl(scheme.get, call_402657026.host, call_402657026.base,
                                   call_402657026.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657026, uri, valid, _)

proc call*(call_402657027: Call_DeleteSecurityConfiguration_402657014;
           body: JsonNode): Recallable =
  ## deleteSecurityConfiguration
  ## Deletes a specified security configuration.
  ##   body: JObject (required)
  var body_402657028 = newJObject()
  if body != nil:
    body_402657028 = body
  result = call_402657027.call(nil, nil, nil, nil, body_402657028)

var deleteSecurityConfiguration* = Call_DeleteSecurityConfiguration_402657014(
    name: "deleteSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteSecurityConfiguration",
    validator: validate_DeleteSecurityConfiguration_402657015, base: "/",
    makeUrl: url_DeleteSecurityConfiguration_402657016,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTable_402657029 = ref object of OpenApiRestCall_402656044
proc url_DeleteTable_402657031(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTable_402657030(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657032 = header.getOrDefault("X-Amz-Target")
  valid_402657032 = validateParameter(valid_402657032, JString, required = true, default = newJString(
      "AWSGlue.DeleteTable"))
  if valid_402657032 != nil:
    section.add "X-Amz-Target", valid_402657032
  var valid_402657033 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657033 = validateParameter(valid_402657033, JString,
                                      required = false, default = nil)
  if valid_402657033 != nil:
    section.add "X-Amz-Security-Token", valid_402657033
  var valid_402657034 = header.getOrDefault("X-Amz-Signature")
  valid_402657034 = validateParameter(valid_402657034, JString,
                                      required = false, default = nil)
  if valid_402657034 != nil:
    section.add "X-Amz-Signature", valid_402657034
  var valid_402657035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657035 = validateParameter(valid_402657035, JString,
                                      required = false, default = nil)
  if valid_402657035 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657035
  var valid_402657036 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657036 = validateParameter(valid_402657036, JString,
                                      required = false, default = nil)
  if valid_402657036 != nil:
    section.add "X-Amz-Algorithm", valid_402657036
  var valid_402657037 = header.getOrDefault("X-Amz-Date")
  valid_402657037 = validateParameter(valid_402657037, JString,
                                      required = false, default = nil)
  if valid_402657037 != nil:
    section.add "X-Amz-Date", valid_402657037
  var valid_402657038 = header.getOrDefault("X-Amz-Credential")
  valid_402657038 = validateParameter(valid_402657038, JString,
                                      required = false, default = nil)
  if valid_402657038 != nil:
    section.add "X-Amz-Credential", valid_402657038
  var valid_402657039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657039 = validateParameter(valid_402657039, JString,
                                      required = false, default = nil)
  if valid_402657039 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657041: Call_DeleteTable_402657029; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
                                                                                         ## 
  let valid = call_402657041.validator(path, query, header, formData, body, _)
  let scheme = call_402657041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657041.makeUrl(scheme.get, call_402657041.host, call_402657041.base,
                                   call_402657041.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657041, uri, valid, _)

proc call*(call_402657042: Call_DeleteTable_402657029; body: JsonNode): Recallable =
  ## deleteTable
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402657043 = newJObject()
  if body != nil:
    body_402657043 = body
  result = call_402657042.call(nil, nil, nil, nil, body_402657043)

var deleteTable* = Call_DeleteTable_402657029(name: "deleteTable",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTable",
    validator: validate_DeleteTable_402657030, base: "/",
    makeUrl: url_DeleteTable_402657031, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTableVersion_402657044 = ref object of OpenApiRestCall_402656044
proc url_DeleteTableVersion_402657046(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTableVersion_402657045(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a specified version of a table.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657047 = header.getOrDefault("X-Amz-Target")
  valid_402657047 = validateParameter(valid_402657047, JString, required = true, default = newJString(
      "AWSGlue.DeleteTableVersion"))
  if valid_402657047 != nil:
    section.add "X-Amz-Target", valid_402657047
  var valid_402657048 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657048 = validateParameter(valid_402657048, JString,
                                      required = false, default = nil)
  if valid_402657048 != nil:
    section.add "X-Amz-Security-Token", valid_402657048
  var valid_402657049 = header.getOrDefault("X-Amz-Signature")
  valid_402657049 = validateParameter(valid_402657049, JString,
                                      required = false, default = nil)
  if valid_402657049 != nil:
    section.add "X-Amz-Signature", valid_402657049
  var valid_402657050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657050 = validateParameter(valid_402657050, JString,
                                      required = false, default = nil)
  if valid_402657050 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657050
  var valid_402657051 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657051 = validateParameter(valid_402657051, JString,
                                      required = false, default = nil)
  if valid_402657051 != nil:
    section.add "X-Amz-Algorithm", valid_402657051
  var valid_402657052 = header.getOrDefault("X-Amz-Date")
  valid_402657052 = validateParameter(valid_402657052, JString,
                                      required = false, default = nil)
  if valid_402657052 != nil:
    section.add "X-Amz-Date", valid_402657052
  var valid_402657053 = header.getOrDefault("X-Amz-Credential")
  valid_402657053 = validateParameter(valid_402657053, JString,
                                      required = false, default = nil)
  if valid_402657053 != nil:
    section.add "X-Amz-Credential", valid_402657053
  var valid_402657054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657054 = validateParameter(valid_402657054, JString,
                                      required = false, default = nil)
  if valid_402657054 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657056: Call_DeleteTableVersion_402657044;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified version of a table.
                                                                                         ## 
  let valid = call_402657056.validator(path, query, header, formData, body, _)
  let scheme = call_402657056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657056.makeUrl(scheme.get, call_402657056.host, call_402657056.base,
                                   call_402657056.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657056, uri, valid, _)

proc call*(call_402657057: Call_DeleteTableVersion_402657044; body: JsonNode): Recallable =
  ## deleteTableVersion
  ## Deletes a specified version of a table.
  ##   body: JObject (required)
  var body_402657058 = newJObject()
  if body != nil:
    body_402657058 = body
  result = call_402657057.call(nil, nil, nil, nil, body_402657058)

var deleteTableVersion* = Call_DeleteTableVersion_402657044(
    name: "deleteTableVersion", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTableVersion",
    validator: validate_DeleteTableVersion_402657045, base: "/",
    makeUrl: url_DeleteTableVersion_402657046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrigger_402657059 = ref object of OpenApiRestCall_402656044
proc url_DeleteTrigger_402657061(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTrigger_402657060(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657062 = header.getOrDefault("X-Amz-Target")
  valid_402657062 = validateParameter(valid_402657062, JString, required = true, default = newJString(
      "AWSGlue.DeleteTrigger"))
  if valid_402657062 != nil:
    section.add "X-Amz-Target", valid_402657062
  var valid_402657063 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657063 = validateParameter(valid_402657063, JString,
                                      required = false, default = nil)
  if valid_402657063 != nil:
    section.add "X-Amz-Security-Token", valid_402657063
  var valid_402657064 = header.getOrDefault("X-Amz-Signature")
  valid_402657064 = validateParameter(valid_402657064, JString,
                                      required = false, default = nil)
  if valid_402657064 != nil:
    section.add "X-Amz-Signature", valid_402657064
  var valid_402657065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657065 = validateParameter(valid_402657065, JString,
                                      required = false, default = nil)
  if valid_402657065 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657065
  var valid_402657066 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657066 = validateParameter(valid_402657066, JString,
                                      required = false, default = nil)
  if valid_402657066 != nil:
    section.add "X-Amz-Algorithm", valid_402657066
  var valid_402657067 = header.getOrDefault("X-Amz-Date")
  valid_402657067 = validateParameter(valid_402657067, JString,
                                      required = false, default = nil)
  if valid_402657067 != nil:
    section.add "X-Amz-Date", valid_402657067
  var valid_402657068 = header.getOrDefault("X-Amz-Credential")
  valid_402657068 = validateParameter(valid_402657068, JString,
                                      required = false, default = nil)
  if valid_402657068 != nil:
    section.add "X-Amz-Credential", valid_402657068
  var valid_402657069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657069 = validateParameter(valid_402657069, JString,
                                      required = false, default = nil)
  if valid_402657069 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657071: Call_DeleteTrigger_402657059; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
                                                                                         ## 
  let valid = call_402657071.validator(path, query, header, formData, body, _)
  let scheme = call_402657071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657071.makeUrl(scheme.get, call_402657071.host, call_402657071.base,
                                   call_402657071.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657071, uri, valid, _)

proc call*(call_402657072: Call_DeleteTrigger_402657059; body: JsonNode): Recallable =
  ## deleteTrigger
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
  ##   
                                                                                      ## body: JObject (required)
  var body_402657073 = newJObject()
  if body != nil:
    body_402657073 = body
  result = call_402657072.call(nil, nil, nil, nil, body_402657073)

var deleteTrigger* = Call_DeleteTrigger_402657059(name: "deleteTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTrigger",
    validator: validate_DeleteTrigger_402657060, base: "/",
    makeUrl: url_DeleteTrigger_402657061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserDefinedFunction_402657074 = ref object of OpenApiRestCall_402656044
proc url_DeleteUserDefinedFunction_402657076(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserDefinedFunction_402657075(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes an existing function definition from the Data Catalog.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657077 = header.getOrDefault("X-Amz-Target")
  valid_402657077 = validateParameter(valid_402657077, JString, required = true, default = newJString(
      "AWSGlue.DeleteUserDefinedFunction"))
  if valid_402657077 != nil:
    section.add "X-Amz-Target", valid_402657077
  var valid_402657078 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657078 = validateParameter(valid_402657078, JString,
                                      required = false, default = nil)
  if valid_402657078 != nil:
    section.add "X-Amz-Security-Token", valid_402657078
  var valid_402657079 = header.getOrDefault("X-Amz-Signature")
  valid_402657079 = validateParameter(valid_402657079, JString,
                                      required = false, default = nil)
  if valid_402657079 != nil:
    section.add "X-Amz-Signature", valid_402657079
  var valid_402657080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657080 = validateParameter(valid_402657080, JString,
                                      required = false, default = nil)
  if valid_402657080 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657080
  var valid_402657081 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657081 = validateParameter(valid_402657081, JString,
                                      required = false, default = nil)
  if valid_402657081 != nil:
    section.add "X-Amz-Algorithm", valid_402657081
  var valid_402657082 = header.getOrDefault("X-Amz-Date")
  valid_402657082 = validateParameter(valid_402657082, JString,
                                      required = false, default = nil)
  if valid_402657082 != nil:
    section.add "X-Amz-Date", valid_402657082
  var valid_402657083 = header.getOrDefault("X-Amz-Credential")
  valid_402657083 = validateParameter(valid_402657083, JString,
                                      required = false, default = nil)
  if valid_402657083 != nil:
    section.add "X-Amz-Credential", valid_402657083
  var valid_402657084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657084 = validateParameter(valid_402657084, JString,
                                      required = false, default = nil)
  if valid_402657084 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657086: Call_DeleteUserDefinedFunction_402657074;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing function definition from the Data Catalog.
                                                                                         ## 
  let valid = call_402657086.validator(path, query, header, formData, body, _)
  let scheme = call_402657086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657086.makeUrl(scheme.get, call_402657086.host, call_402657086.base,
                                   call_402657086.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657086, uri, valid, _)

proc call*(call_402657087: Call_DeleteUserDefinedFunction_402657074;
           body: JsonNode): Recallable =
  ## deleteUserDefinedFunction
  ## Deletes an existing function definition from the Data Catalog.
  ##   body: JObject (required)
  var body_402657088 = newJObject()
  if body != nil:
    body_402657088 = body
  result = call_402657087.call(nil, nil, nil, nil, body_402657088)

var deleteUserDefinedFunction* = Call_DeleteUserDefinedFunction_402657074(
    name: "deleteUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteUserDefinedFunction",
    validator: validate_DeleteUserDefinedFunction_402657075, base: "/",
    makeUrl: url_DeleteUserDefinedFunction_402657076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkflow_402657089 = ref object of OpenApiRestCall_402656044
proc url_DeleteWorkflow_402657091(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteWorkflow_402657090(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a workflow.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657092 = header.getOrDefault("X-Amz-Target")
  valid_402657092 = validateParameter(valid_402657092, JString, required = true, default = newJString(
      "AWSGlue.DeleteWorkflow"))
  if valid_402657092 != nil:
    section.add "X-Amz-Target", valid_402657092
  var valid_402657093 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657093 = validateParameter(valid_402657093, JString,
                                      required = false, default = nil)
  if valid_402657093 != nil:
    section.add "X-Amz-Security-Token", valid_402657093
  var valid_402657094 = header.getOrDefault("X-Amz-Signature")
  valid_402657094 = validateParameter(valid_402657094, JString,
                                      required = false, default = nil)
  if valid_402657094 != nil:
    section.add "X-Amz-Signature", valid_402657094
  var valid_402657095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657095 = validateParameter(valid_402657095, JString,
                                      required = false, default = nil)
  if valid_402657095 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657095
  var valid_402657096 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657096 = validateParameter(valid_402657096, JString,
                                      required = false, default = nil)
  if valid_402657096 != nil:
    section.add "X-Amz-Algorithm", valid_402657096
  var valid_402657097 = header.getOrDefault("X-Amz-Date")
  valid_402657097 = validateParameter(valid_402657097, JString,
                                      required = false, default = nil)
  if valid_402657097 != nil:
    section.add "X-Amz-Date", valid_402657097
  var valid_402657098 = header.getOrDefault("X-Amz-Credential")
  valid_402657098 = validateParameter(valid_402657098, JString,
                                      required = false, default = nil)
  if valid_402657098 != nil:
    section.add "X-Amz-Credential", valid_402657098
  var valid_402657099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657099 = validateParameter(valid_402657099, JString,
                                      required = false, default = nil)
  if valid_402657099 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657101: Call_DeleteWorkflow_402657089; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a workflow.
                                                                                         ## 
  let valid = call_402657101.validator(path, query, header, formData, body, _)
  let scheme = call_402657101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657101.makeUrl(scheme.get, call_402657101.host, call_402657101.base,
                                   call_402657101.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657101, uri, valid, _)

proc call*(call_402657102: Call_DeleteWorkflow_402657089; body: JsonNode): Recallable =
  ## deleteWorkflow
  ## Deletes a workflow.
  ##   body: JObject (required)
  var body_402657103 = newJObject()
  if body != nil:
    body_402657103 = body
  result = call_402657102.call(nil, nil, nil, nil, body_402657103)

var deleteWorkflow* = Call_DeleteWorkflow_402657089(name: "deleteWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteWorkflow",
    validator: validate_DeleteWorkflow_402657090, base: "/",
    makeUrl: url_DeleteWorkflow_402657091, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCatalogImportStatus_402657104 = ref object of OpenApiRestCall_402656044
proc url_GetCatalogImportStatus_402657106(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCatalogImportStatus_402657105(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the status of a migration operation.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657107 = header.getOrDefault("X-Amz-Target")
  valid_402657107 = validateParameter(valid_402657107, JString, required = true, default = newJString(
      "AWSGlue.GetCatalogImportStatus"))
  if valid_402657107 != nil:
    section.add "X-Amz-Target", valid_402657107
  var valid_402657108 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657108 = validateParameter(valid_402657108, JString,
                                      required = false, default = nil)
  if valid_402657108 != nil:
    section.add "X-Amz-Security-Token", valid_402657108
  var valid_402657109 = header.getOrDefault("X-Amz-Signature")
  valid_402657109 = validateParameter(valid_402657109, JString,
                                      required = false, default = nil)
  if valid_402657109 != nil:
    section.add "X-Amz-Signature", valid_402657109
  var valid_402657110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657110 = validateParameter(valid_402657110, JString,
                                      required = false, default = nil)
  if valid_402657110 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657110
  var valid_402657111 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657111 = validateParameter(valid_402657111, JString,
                                      required = false, default = nil)
  if valid_402657111 != nil:
    section.add "X-Amz-Algorithm", valid_402657111
  var valid_402657112 = header.getOrDefault("X-Amz-Date")
  valid_402657112 = validateParameter(valid_402657112, JString,
                                      required = false, default = nil)
  if valid_402657112 != nil:
    section.add "X-Amz-Date", valid_402657112
  var valid_402657113 = header.getOrDefault("X-Amz-Credential")
  valid_402657113 = validateParameter(valid_402657113, JString,
                                      required = false, default = nil)
  if valid_402657113 != nil:
    section.add "X-Amz-Credential", valid_402657113
  var valid_402657114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657114 = validateParameter(valid_402657114, JString,
                                      required = false, default = nil)
  if valid_402657114 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657116: Call_GetCatalogImportStatus_402657104;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the status of a migration operation.
                                                                                         ## 
  let valid = call_402657116.validator(path, query, header, formData, body, _)
  let scheme = call_402657116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657116.makeUrl(scheme.get, call_402657116.host, call_402657116.base,
                                   call_402657116.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657116, uri, valid, _)

proc call*(call_402657117: Call_GetCatalogImportStatus_402657104; body: JsonNode): Recallable =
  ## getCatalogImportStatus
  ## Retrieves the status of a migration operation.
  ##   body: JObject (required)
  var body_402657118 = newJObject()
  if body != nil:
    body_402657118 = body
  result = call_402657117.call(nil, nil, nil, nil, body_402657118)

var getCatalogImportStatus* = Call_GetCatalogImportStatus_402657104(
    name: "getCatalogImportStatus", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCatalogImportStatus",
    validator: validate_GetCatalogImportStatus_402657105, base: "/",
    makeUrl: url_GetCatalogImportStatus_402657106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClassifier_402657119 = ref object of OpenApiRestCall_402656044
proc url_GetClassifier_402657121(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetClassifier_402657120(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve a classifier by name.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657122 = header.getOrDefault("X-Amz-Target")
  valid_402657122 = validateParameter(valid_402657122, JString, required = true, default = newJString(
      "AWSGlue.GetClassifier"))
  if valid_402657122 != nil:
    section.add "X-Amz-Target", valid_402657122
  var valid_402657123 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657123 = validateParameter(valid_402657123, JString,
                                      required = false, default = nil)
  if valid_402657123 != nil:
    section.add "X-Amz-Security-Token", valid_402657123
  var valid_402657124 = header.getOrDefault("X-Amz-Signature")
  valid_402657124 = validateParameter(valid_402657124, JString,
                                      required = false, default = nil)
  if valid_402657124 != nil:
    section.add "X-Amz-Signature", valid_402657124
  var valid_402657125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657125 = validateParameter(valid_402657125, JString,
                                      required = false, default = nil)
  if valid_402657125 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657125
  var valid_402657126 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657126 = validateParameter(valid_402657126, JString,
                                      required = false, default = nil)
  if valid_402657126 != nil:
    section.add "X-Amz-Algorithm", valid_402657126
  var valid_402657127 = header.getOrDefault("X-Amz-Date")
  valid_402657127 = validateParameter(valid_402657127, JString,
                                      required = false, default = nil)
  if valid_402657127 != nil:
    section.add "X-Amz-Date", valid_402657127
  var valid_402657128 = header.getOrDefault("X-Amz-Credential")
  valid_402657128 = validateParameter(valid_402657128, JString,
                                      required = false, default = nil)
  if valid_402657128 != nil:
    section.add "X-Amz-Credential", valid_402657128
  var valid_402657129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657129 = validateParameter(valid_402657129, JString,
                                      required = false, default = nil)
  if valid_402657129 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657131: Call_GetClassifier_402657119; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve a classifier by name.
                                                                                         ## 
  let valid = call_402657131.validator(path, query, header, formData, body, _)
  let scheme = call_402657131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657131.makeUrl(scheme.get, call_402657131.host, call_402657131.base,
                                   call_402657131.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657131, uri, valid, _)

proc call*(call_402657132: Call_GetClassifier_402657119; body: JsonNode): Recallable =
  ## getClassifier
  ## Retrieve a classifier by name.
  ##   body: JObject (required)
  var body_402657133 = newJObject()
  if body != nil:
    body_402657133 = body
  result = call_402657132.call(nil, nil, nil, nil, body_402657133)

var getClassifier* = Call_GetClassifier_402657119(name: "getClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetClassifier",
    validator: validate_GetClassifier_402657120, base: "/",
    makeUrl: url_GetClassifier_402657121, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClassifiers_402657134 = ref object of OpenApiRestCall_402656044
proc url_GetClassifiers_402657136(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetClassifiers_402657135(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists all classifier objects in the Data Catalog.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657137 = query.getOrDefault("MaxResults")
  valid_402657137 = validateParameter(valid_402657137, JString,
                                      required = false, default = nil)
  if valid_402657137 != nil:
    section.add "MaxResults", valid_402657137
  var valid_402657138 = query.getOrDefault("NextToken")
  valid_402657138 = validateParameter(valid_402657138, JString,
                                      required = false, default = nil)
  if valid_402657138 != nil:
    section.add "NextToken", valid_402657138
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657139 = header.getOrDefault("X-Amz-Target")
  valid_402657139 = validateParameter(valid_402657139, JString, required = true, default = newJString(
      "AWSGlue.GetClassifiers"))
  if valid_402657139 != nil:
    section.add "X-Amz-Target", valid_402657139
  var valid_402657140 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657140 = validateParameter(valid_402657140, JString,
                                      required = false, default = nil)
  if valid_402657140 != nil:
    section.add "X-Amz-Security-Token", valid_402657140
  var valid_402657141 = header.getOrDefault("X-Amz-Signature")
  valid_402657141 = validateParameter(valid_402657141, JString,
                                      required = false, default = nil)
  if valid_402657141 != nil:
    section.add "X-Amz-Signature", valid_402657141
  var valid_402657142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657142 = validateParameter(valid_402657142, JString,
                                      required = false, default = nil)
  if valid_402657142 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657142
  var valid_402657143 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657143 = validateParameter(valid_402657143, JString,
                                      required = false, default = nil)
  if valid_402657143 != nil:
    section.add "X-Amz-Algorithm", valid_402657143
  var valid_402657144 = header.getOrDefault("X-Amz-Date")
  valid_402657144 = validateParameter(valid_402657144, JString,
                                      required = false, default = nil)
  if valid_402657144 != nil:
    section.add "X-Amz-Date", valid_402657144
  var valid_402657145 = header.getOrDefault("X-Amz-Credential")
  valid_402657145 = validateParameter(valid_402657145, JString,
                                      required = false, default = nil)
  if valid_402657145 != nil:
    section.add "X-Amz-Credential", valid_402657145
  var valid_402657146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657146 = validateParameter(valid_402657146, JString,
                                      required = false, default = nil)
  if valid_402657146 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657148: Call_GetClassifiers_402657134; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all classifier objects in the Data Catalog.
                                                                                         ## 
  let valid = call_402657148.validator(path, query, header, formData, body, _)
  let scheme = call_402657148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657148.makeUrl(scheme.get, call_402657148.host, call_402657148.base,
                                   call_402657148.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657148, uri, valid, _)

proc call*(call_402657149: Call_GetClassifiers_402657134; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getClassifiers
  ## Lists all classifier objects in the Data Catalog.
  ##   MaxResults: string
                                                      ##             : Pagination limit
  ##   
                                                                                       ## body: JObject (required)
  ##   
                                                                                                                  ## NextToken: string
                                                                                                                  ##            
                                                                                                                  ## : 
                                                                                                                  ## Pagination 
                                                                                                                  ## token
  var query_402657150 = newJObject()
  var body_402657151 = newJObject()
  add(query_402657150, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657151 = body
  add(query_402657150, "NextToken", newJString(NextToken))
  result = call_402657149.call(nil, query_402657150, nil, nil, body_402657151)

var getClassifiers* = Call_GetClassifiers_402657134(name: "getClassifiers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetClassifiers",
    validator: validate_GetClassifiers_402657135, base: "/",
    makeUrl: url_GetClassifiers_402657136, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnection_402657152 = ref object of OpenApiRestCall_402656044
proc url_GetConnection_402657154(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConnection_402657153(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a connection definition from the Data Catalog.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657155 = header.getOrDefault("X-Amz-Target")
  valid_402657155 = validateParameter(valid_402657155, JString, required = true, default = newJString(
      "AWSGlue.GetConnection"))
  if valid_402657155 != nil:
    section.add "X-Amz-Target", valid_402657155
  var valid_402657156 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657156 = validateParameter(valid_402657156, JString,
                                      required = false, default = nil)
  if valid_402657156 != nil:
    section.add "X-Amz-Security-Token", valid_402657156
  var valid_402657157 = header.getOrDefault("X-Amz-Signature")
  valid_402657157 = validateParameter(valid_402657157, JString,
                                      required = false, default = nil)
  if valid_402657157 != nil:
    section.add "X-Amz-Signature", valid_402657157
  var valid_402657158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657158 = validateParameter(valid_402657158, JString,
                                      required = false, default = nil)
  if valid_402657158 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657158
  var valid_402657159 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657159 = validateParameter(valid_402657159, JString,
                                      required = false, default = nil)
  if valid_402657159 != nil:
    section.add "X-Amz-Algorithm", valid_402657159
  var valid_402657160 = header.getOrDefault("X-Amz-Date")
  valid_402657160 = validateParameter(valid_402657160, JString,
                                      required = false, default = nil)
  if valid_402657160 != nil:
    section.add "X-Amz-Date", valid_402657160
  var valid_402657161 = header.getOrDefault("X-Amz-Credential")
  valid_402657161 = validateParameter(valid_402657161, JString,
                                      required = false, default = nil)
  if valid_402657161 != nil:
    section.add "X-Amz-Credential", valid_402657161
  var valid_402657162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657162 = validateParameter(valid_402657162, JString,
                                      required = false, default = nil)
  if valid_402657162 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657164: Call_GetConnection_402657152; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a connection definition from the Data Catalog.
                                                                                         ## 
  let valid = call_402657164.validator(path, query, header, formData, body, _)
  let scheme = call_402657164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657164.makeUrl(scheme.get, call_402657164.host, call_402657164.base,
                                   call_402657164.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657164, uri, valid, _)

proc call*(call_402657165: Call_GetConnection_402657152; body: JsonNode): Recallable =
  ## getConnection
  ## Retrieves a connection definition from the Data Catalog.
  ##   body: JObject (required)
  var body_402657166 = newJObject()
  if body != nil:
    body_402657166 = body
  result = call_402657165.call(nil, nil, nil, nil, body_402657166)

var getConnection* = Call_GetConnection_402657152(name: "getConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetConnection",
    validator: validate_GetConnection_402657153, base: "/",
    makeUrl: url_GetConnection_402657154, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnections_402657167 = ref object of OpenApiRestCall_402656044
proc url_GetConnections_402657169(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConnections_402657168(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of connection definitions from the Data Catalog.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657170 = query.getOrDefault("MaxResults")
  valid_402657170 = validateParameter(valid_402657170, JString,
                                      required = false, default = nil)
  if valid_402657170 != nil:
    section.add "MaxResults", valid_402657170
  var valid_402657171 = query.getOrDefault("NextToken")
  valid_402657171 = validateParameter(valid_402657171, JString,
                                      required = false, default = nil)
  if valid_402657171 != nil:
    section.add "NextToken", valid_402657171
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657172 = header.getOrDefault("X-Amz-Target")
  valid_402657172 = validateParameter(valid_402657172, JString, required = true, default = newJString(
      "AWSGlue.GetConnections"))
  if valid_402657172 != nil:
    section.add "X-Amz-Target", valid_402657172
  var valid_402657173 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657173 = validateParameter(valid_402657173, JString,
                                      required = false, default = nil)
  if valid_402657173 != nil:
    section.add "X-Amz-Security-Token", valid_402657173
  var valid_402657174 = header.getOrDefault("X-Amz-Signature")
  valid_402657174 = validateParameter(valid_402657174, JString,
                                      required = false, default = nil)
  if valid_402657174 != nil:
    section.add "X-Amz-Signature", valid_402657174
  var valid_402657175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657175 = validateParameter(valid_402657175, JString,
                                      required = false, default = nil)
  if valid_402657175 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657175
  var valid_402657176 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657176 = validateParameter(valid_402657176, JString,
                                      required = false, default = nil)
  if valid_402657176 != nil:
    section.add "X-Amz-Algorithm", valid_402657176
  var valid_402657177 = header.getOrDefault("X-Amz-Date")
  valid_402657177 = validateParameter(valid_402657177, JString,
                                      required = false, default = nil)
  if valid_402657177 != nil:
    section.add "X-Amz-Date", valid_402657177
  var valid_402657178 = header.getOrDefault("X-Amz-Credential")
  valid_402657178 = validateParameter(valid_402657178, JString,
                                      required = false, default = nil)
  if valid_402657178 != nil:
    section.add "X-Amz-Credential", valid_402657178
  var valid_402657179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657179 = validateParameter(valid_402657179, JString,
                                      required = false, default = nil)
  if valid_402657179 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657181: Call_GetConnections_402657167; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of connection definitions from the Data Catalog.
                                                                                         ## 
  let valid = call_402657181.validator(path, query, header, formData, body, _)
  let scheme = call_402657181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657181.makeUrl(scheme.get, call_402657181.host, call_402657181.base,
                                   call_402657181.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657181, uri, valid, _)

proc call*(call_402657182: Call_GetConnections_402657167; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getConnections
  ## Retrieves a list of connection definitions from the Data Catalog.
  ##   
                                                                      ## MaxResults: string
                                                                      ##             
                                                                      ## : 
                                                                      ## Pagination limit
  ##   
                                                                                         ## body: JObject (required)
  ##   
                                                                                                                    ## NextToken: string
                                                                                                                    ##            
                                                                                                                    ## : 
                                                                                                                    ## Pagination 
                                                                                                                    ## token
  var query_402657183 = newJObject()
  var body_402657184 = newJObject()
  add(query_402657183, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657184 = body
  add(query_402657183, "NextToken", newJString(NextToken))
  result = call_402657182.call(nil, query_402657183, nil, nil, body_402657184)

var getConnections* = Call_GetConnections_402657167(name: "getConnections",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetConnections",
    validator: validate_GetConnections_402657168, base: "/",
    makeUrl: url_GetConnections_402657169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawler_402657185 = ref object of OpenApiRestCall_402656044
proc url_GetCrawler_402657187(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCrawler_402657186(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves metadata for a specified crawler.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657188 = header.getOrDefault("X-Amz-Target")
  valid_402657188 = validateParameter(valid_402657188, JString, required = true, default = newJString(
      "AWSGlue.GetCrawler"))
  if valid_402657188 != nil:
    section.add "X-Amz-Target", valid_402657188
  var valid_402657189 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657189 = validateParameter(valid_402657189, JString,
                                      required = false, default = nil)
  if valid_402657189 != nil:
    section.add "X-Amz-Security-Token", valid_402657189
  var valid_402657190 = header.getOrDefault("X-Amz-Signature")
  valid_402657190 = validateParameter(valid_402657190, JString,
                                      required = false, default = nil)
  if valid_402657190 != nil:
    section.add "X-Amz-Signature", valid_402657190
  var valid_402657191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657191 = validateParameter(valid_402657191, JString,
                                      required = false, default = nil)
  if valid_402657191 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657191
  var valid_402657192 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657192 = validateParameter(valid_402657192, JString,
                                      required = false, default = nil)
  if valid_402657192 != nil:
    section.add "X-Amz-Algorithm", valid_402657192
  var valid_402657193 = header.getOrDefault("X-Amz-Date")
  valid_402657193 = validateParameter(valid_402657193, JString,
                                      required = false, default = nil)
  if valid_402657193 != nil:
    section.add "X-Amz-Date", valid_402657193
  var valid_402657194 = header.getOrDefault("X-Amz-Credential")
  valid_402657194 = validateParameter(valid_402657194, JString,
                                      required = false, default = nil)
  if valid_402657194 != nil:
    section.add "X-Amz-Credential", valid_402657194
  var valid_402657195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657195 = validateParameter(valid_402657195, JString,
                                      required = false, default = nil)
  if valid_402657195 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657197: Call_GetCrawler_402657185; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves metadata for a specified crawler.
                                                                                         ## 
  let valid = call_402657197.validator(path, query, header, formData, body, _)
  let scheme = call_402657197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657197.makeUrl(scheme.get, call_402657197.host, call_402657197.base,
                                   call_402657197.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657197, uri, valid, _)

proc call*(call_402657198: Call_GetCrawler_402657185; body: JsonNode): Recallable =
  ## getCrawler
  ## Retrieves metadata for a specified crawler.
  ##   body: JObject (required)
  var body_402657199 = newJObject()
  if body != nil:
    body_402657199 = body
  result = call_402657198.call(nil, nil, nil, nil, body_402657199)

var getCrawler* = Call_GetCrawler_402657185(name: "getCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCrawler", validator: validate_GetCrawler_402657186,
    base: "/", makeUrl: url_GetCrawler_402657187,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawlerMetrics_402657200 = ref object of OpenApiRestCall_402656044
proc url_GetCrawlerMetrics_402657202(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCrawlerMetrics_402657201(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves metrics about specified crawlers.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657203 = query.getOrDefault("MaxResults")
  valid_402657203 = validateParameter(valid_402657203, JString,
                                      required = false, default = nil)
  if valid_402657203 != nil:
    section.add "MaxResults", valid_402657203
  var valid_402657204 = query.getOrDefault("NextToken")
  valid_402657204 = validateParameter(valid_402657204, JString,
                                      required = false, default = nil)
  if valid_402657204 != nil:
    section.add "NextToken", valid_402657204
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657205 = header.getOrDefault("X-Amz-Target")
  valid_402657205 = validateParameter(valid_402657205, JString, required = true, default = newJString(
      "AWSGlue.GetCrawlerMetrics"))
  if valid_402657205 != nil:
    section.add "X-Amz-Target", valid_402657205
  var valid_402657206 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657206 = validateParameter(valid_402657206, JString,
                                      required = false, default = nil)
  if valid_402657206 != nil:
    section.add "X-Amz-Security-Token", valid_402657206
  var valid_402657207 = header.getOrDefault("X-Amz-Signature")
  valid_402657207 = validateParameter(valid_402657207, JString,
                                      required = false, default = nil)
  if valid_402657207 != nil:
    section.add "X-Amz-Signature", valid_402657207
  var valid_402657208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657208 = validateParameter(valid_402657208, JString,
                                      required = false, default = nil)
  if valid_402657208 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657208
  var valid_402657209 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657209 = validateParameter(valid_402657209, JString,
                                      required = false, default = nil)
  if valid_402657209 != nil:
    section.add "X-Amz-Algorithm", valid_402657209
  var valid_402657210 = header.getOrDefault("X-Amz-Date")
  valid_402657210 = validateParameter(valid_402657210, JString,
                                      required = false, default = nil)
  if valid_402657210 != nil:
    section.add "X-Amz-Date", valid_402657210
  var valid_402657211 = header.getOrDefault("X-Amz-Credential")
  valid_402657211 = validateParameter(valid_402657211, JString,
                                      required = false, default = nil)
  if valid_402657211 != nil:
    section.add "X-Amz-Credential", valid_402657211
  var valid_402657212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657212 = validateParameter(valid_402657212, JString,
                                      required = false, default = nil)
  if valid_402657212 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657214: Call_GetCrawlerMetrics_402657200;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves metrics about specified crawlers.
                                                                                         ## 
  let valid = call_402657214.validator(path, query, header, formData, body, _)
  let scheme = call_402657214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657214.makeUrl(scheme.get, call_402657214.host, call_402657214.base,
                                   call_402657214.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657214, uri, valid, _)

proc call*(call_402657215: Call_GetCrawlerMetrics_402657200; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getCrawlerMetrics
  ## Retrieves metrics about specified crawlers.
  ##   MaxResults: string
                                                ##             : Pagination limit
  ##   
                                                                                 ## body: JObject (required)
  ##   
                                                                                                            ## NextToken: string
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## Pagination 
                                                                                                            ## token
  var query_402657216 = newJObject()
  var body_402657217 = newJObject()
  add(query_402657216, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657217 = body
  add(query_402657216, "NextToken", newJString(NextToken))
  result = call_402657215.call(nil, query_402657216, nil, nil, body_402657217)

var getCrawlerMetrics* = Call_GetCrawlerMetrics_402657200(
    name: "getCrawlerMetrics", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCrawlerMetrics",
    validator: validate_GetCrawlerMetrics_402657201, base: "/",
    makeUrl: url_GetCrawlerMetrics_402657202,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawlers_402657218 = ref object of OpenApiRestCall_402656044
proc url_GetCrawlers_402657220(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCrawlers_402657219(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves metadata for all crawlers defined in the customer account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657221 = query.getOrDefault("MaxResults")
  valid_402657221 = validateParameter(valid_402657221, JString,
                                      required = false, default = nil)
  if valid_402657221 != nil:
    section.add "MaxResults", valid_402657221
  var valid_402657222 = query.getOrDefault("NextToken")
  valid_402657222 = validateParameter(valid_402657222, JString,
                                      required = false, default = nil)
  if valid_402657222 != nil:
    section.add "NextToken", valid_402657222
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657223 = header.getOrDefault("X-Amz-Target")
  valid_402657223 = validateParameter(valid_402657223, JString, required = true, default = newJString(
      "AWSGlue.GetCrawlers"))
  if valid_402657223 != nil:
    section.add "X-Amz-Target", valid_402657223
  var valid_402657224 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657224 = validateParameter(valid_402657224, JString,
                                      required = false, default = nil)
  if valid_402657224 != nil:
    section.add "X-Amz-Security-Token", valid_402657224
  var valid_402657225 = header.getOrDefault("X-Amz-Signature")
  valid_402657225 = validateParameter(valid_402657225, JString,
                                      required = false, default = nil)
  if valid_402657225 != nil:
    section.add "X-Amz-Signature", valid_402657225
  var valid_402657226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657226 = validateParameter(valid_402657226, JString,
                                      required = false, default = nil)
  if valid_402657226 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657226
  var valid_402657227 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657227 = validateParameter(valid_402657227, JString,
                                      required = false, default = nil)
  if valid_402657227 != nil:
    section.add "X-Amz-Algorithm", valid_402657227
  var valid_402657228 = header.getOrDefault("X-Amz-Date")
  valid_402657228 = validateParameter(valid_402657228, JString,
                                      required = false, default = nil)
  if valid_402657228 != nil:
    section.add "X-Amz-Date", valid_402657228
  var valid_402657229 = header.getOrDefault("X-Amz-Credential")
  valid_402657229 = validateParameter(valid_402657229, JString,
                                      required = false, default = nil)
  if valid_402657229 != nil:
    section.add "X-Amz-Credential", valid_402657229
  var valid_402657230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657230 = validateParameter(valid_402657230, JString,
                                      required = false, default = nil)
  if valid_402657230 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657232: Call_GetCrawlers_402657218; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves metadata for all crawlers defined in the customer account.
                                                                                         ## 
  let valid = call_402657232.validator(path, query, header, formData, body, _)
  let scheme = call_402657232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657232.makeUrl(scheme.get, call_402657232.host, call_402657232.base,
                                   call_402657232.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657232, uri, valid, _)

proc call*(call_402657233: Call_GetCrawlers_402657218; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getCrawlers
  ## Retrieves metadata for all crawlers defined in the customer account.
  ##   
                                                                         ## MaxResults: string
                                                                         ##             
                                                                         ## : 
                                                                         ## Pagination 
                                                                         ## limit
  ##   
                                                                                 ## body: JObject (required)
  ##   
                                                                                                            ## NextToken: string
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## Pagination 
                                                                                                            ## token
  var query_402657234 = newJObject()
  var body_402657235 = newJObject()
  add(query_402657234, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657235 = body
  add(query_402657234, "NextToken", newJString(NextToken))
  result = call_402657233.call(nil, query_402657234, nil, nil, body_402657235)

var getCrawlers* = Call_GetCrawlers_402657218(name: "getCrawlers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCrawlers",
    validator: validate_GetCrawlers_402657219, base: "/",
    makeUrl: url_GetCrawlers_402657220, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataCatalogEncryptionSettings_402657236 = ref object of OpenApiRestCall_402656044
proc url_GetDataCatalogEncryptionSettings_402657238(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDataCatalogEncryptionSettings_402657237(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves the security configuration for a specified catalog.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657239 = header.getOrDefault("X-Amz-Target")
  valid_402657239 = validateParameter(valid_402657239, JString, required = true, default = newJString(
      "AWSGlue.GetDataCatalogEncryptionSettings"))
  if valid_402657239 != nil:
    section.add "X-Amz-Target", valid_402657239
  var valid_402657240 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657240 = validateParameter(valid_402657240, JString,
                                      required = false, default = nil)
  if valid_402657240 != nil:
    section.add "X-Amz-Security-Token", valid_402657240
  var valid_402657241 = header.getOrDefault("X-Amz-Signature")
  valid_402657241 = validateParameter(valid_402657241, JString,
                                      required = false, default = nil)
  if valid_402657241 != nil:
    section.add "X-Amz-Signature", valid_402657241
  var valid_402657242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657242 = validateParameter(valid_402657242, JString,
                                      required = false, default = nil)
  if valid_402657242 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657242
  var valid_402657243 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657243 = validateParameter(valid_402657243, JString,
                                      required = false, default = nil)
  if valid_402657243 != nil:
    section.add "X-Amz-Algorithm", valid_402657243
  var valid_402657244 = header.getOrDefault("X-Amz-Date")
  valid_402657244 = validateParameter(valid_402657244, JString,
                                      required = false, default = nil)
  if valid_402657244 != nil:
    section.add "X-Amz-Date", valid_402657244
  var valid_402657245 = header.getOrDefault("X-Amz-Credential")
  valid_402657245 = validateParameter(valid_402657245, JString,
                                      required = false, default = nil)
  if valid_402657245 != nil:
    section.add "X-Amz-Credential", valid_402657245
  var valid_402657246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657246 = validateParameter(valid_402657246, JString,
                                      required = false, default = nil)
  if valid_402657246 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657248: Call_GetDataCatalogEncryptionSettings_402657236;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the security configuration for a specified catalog.
                                                                                         ## 
  let valid = call_402657248.validator(path, query, header, formData, body, _)
  let scheme = call_402657248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657248.makeUrl(scheme.get, call_402657248.host, call_402657248.base,
                                   call_402657248.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657248, uri, valid, _)

proc call*(call_402657249: Call_GetDataCatalogEncryptionSettings_402657236;
           body: JsonNode): Recallable =
  ## getDataCatalogEncryptionSettings
  ## Retrieves the security configuration for a specified catalog.
  ##   body: JObject (required)
  var body_402657250 = newJObject()
  if body != nil:
    body_402657250 = body
  result = call_402657249.call(nil, nil, nil, nil, body_402657250)

var getDataCatalogEncryptionSettings* = Call_GetDataCatalogEncryptionSettings_402657236(
    name: "getDataCatalogEncryptionSettings", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDataCatalogEncryptionSettings",
    validator: validate_GetDataCatalogEncryptionSettings_402657237, base: "/",
    makeUrl: url_GetDataCatalogEncryptionSettings_402657238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatabase_402657251 = ref object of OpenApiRestCall_402656044
proc url_GetDatabase_402657253(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDatabase_402657252(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the definition of a specified database.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657254 = header.getOrDefault("X-Amz-Target")
  valid_402657254 = validateParameter(valid_402657254, JString, required = true, default = newJString(
      "AWSGlue.GetDatabase"))
  if valid_402657254 != nil:
    section.add "X-Amz-Target", valid_402657254
  var valid_402657255 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657255 = validateParameter(valid_402657255, JString,
                                      required = false, default = nil)
  if valid_402657255 != nil:
    section.add "X-Amz-Security-Token", valid_402657255
  var valid_402657256 = header.getOrDefault("X-Amz-Signature")
  valid_402657256 = validateParameter(valid_402657256, JString,
                                      required = false, default = nil)
  if valid_402657256 != nil:
    section.add "X-Amz-Signature", valid_402657256
  var valid_402657257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657257 = validateParameter(valid_402657257, JString,
                                      required = false, default = nil)
  if valid_402657257 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657257
  var valid_402657258 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657258 = validateParameter(valid_402657258, JString,
                                      required = false, default = nil)
  if valid_402657258 != nil:
    section.add "X-Amz-Algorithm", valid_402657258
  var valid_402657259 = header.getOrDefault("X-Amz-Date")
  valid_402657259 = validateParameter(valid_402657259, JString,
                                      required = false, default = nil)
  if valid_402657259 != nil:
    section.add "X-Amz-Date", valid_402657259
  var valid_402657260 = header.getOrDefault("X-Amz-Credential")
  valid_402657260 = validateParameter(valid_402657260, JString,
                                      required = false, default = nil)
  if valid_402657260 != nil:
    section.add "X-Amz-Credential", valid_402657260
  var valid_402657261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657261 = validateParameter(valid_402657261, JString,
                                      required = false, default = nil)
  if valid_402657261 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657263: Call_GetDatabase_402657251; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the definition of a specified database.
                                                                                         ## 
  let valid = call_402657263.validator(path, query, header, formData, body, _)
  let scheme = call_402657263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657263.makeUrl(scheme.get, call_402657263.host, call_402657263.base,
                                   call_402657263.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657263, uri, valid, _)

proc call*(call_402657264: Call_GetDatabase_402657251; body: JsonNode): Recallable =
  ## getDatabase
  ## Retrieves the definition of a specified database.
  ##   body: JObject (required)
  var body_402657265 = newJObject()
  if body != nil:
    body_402657265 = body
  result = call_402657264.call(nil, nil, nil, nil, body_402657265)

var getDatabase* = Call_GetDatabase_402657251(name: "getDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDatabase",
    validator: validate_GetDatabase_402657252, base: "/",
    makeUrl: url_GetDatabase_402657253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatabases_402657266 = ref object of OpenApiRestCall_402656044
proc url_GetDatabases_402657268(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDatabases_402657267(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves all databases defined in a given Data Catalog.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657269 = query.getOrDefault("MaxResults")
  valid_402657269 = validateParameter(valid_402657269, JString,
                                      required = false, default = nil)
  if valid_402657269 != nil:
    section.add "MaxResults", valid_402657269
  var valid_402657270 = query.getOrDefault("NextToken")
  valid_402657270 = validateParameter(valid_402657270, JString,
                                      required = false, default = nil)
  if valid_402657270 != nil:
    section.add "NextToken", valid_402657270
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657271 = header.getOrDefault("X-Amz-Target")
  valid_402657271 = validateParameter(valid_402657271, JString, required = true, default = newJString(
      "AWSGlue.GetDatabases"))
  if valid_402657271 != nil:
    section.add "X-Amz-Target", valid_402657271
  var valid_402657272 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657272 = validateParameter(valid_402657272, JString,
                                      required = false, default = nil)
  if valid_402657272 != nil:
    section.add "X-Amz-Security-Token", valid_402657272
  var valid_402657273 = header.getOrDefault("X-Amz-Signature")
  valid_402657273 = validateParameter(valid_402657273, JString,
                                      required = false, default = nil)
  if valid_402657273 != nil:
    section.add "X-Amz-Signature", valid_402657273
  var valid_402657274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657274 = validateParameter(valid_402657274, JString,
                                      required = false, default = nil)
  if valid_402657274 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657274
  var valid_402657275 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657275 = validateParameter(valid_402657275, JString,
                                      required = false, default = nil)
  if valid_402657275 != nil:
    section.add "X-Amz-Algorithm", valid_402657275
  var valid_402657276 = header.getOrDefault("X-Amz-Date")
  valid_402657276 = validateParameter(valid_402657276, JString,
                                      required = false, default = nil)
  if valid_402657276 != nil:
    section.add "X-Amz-Date", valid_402657276
  var valid_402657277 = header.getOrDefault("X-Amz-Credential")
  valid_402657277 = validateParameter(valid_402657277, JString,
                                      required = false, default = nil)
  if valid_402657277 != nil:
    section.add "X-Amz-Credential", valid_402657277
  var valid_402657278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657278 = validateParameter(valid_402657278, JString,
                                      required = false, default = nil)
  if valid_402657278 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657280: Call_GetDatabases_402657266; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves all databases defined in a given Data Catalog.
                                                                                         ## 
  let valid = call_402657280.validator(path, query, header, formData, body, _)
  let scheme = call_402657280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657280.makeUrl(scheme.get, call_402657280.host, call_402657280.base,
                                   call_402657280.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657280, uri, valid, _)

proc call*(call_402657281: Call_GetDatabases_402657266; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getDatabases
  ## Retrieves all databases defined in a given Data Catalog.
  ##   MaxResults: string
                                                             ##             : Pagination limit
  ##   
                                                                                              ## body: JObject (required)
  ##   
                                                                                                                         ## NextToken: string
                                                                                                                         ##            
                                                                                                                         ## : 
                                                                                                                         ## Pagination 
                                                                                                                         ## token
  var query_402657282 = newJObject()
  var body_402657283 = newJObject()
  add(query_402657282, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657283 = body
  add(query_402657282, "NextToken", newJString(NextToken))
  result = call_402657281.call(nil, query_402657282, nil, nil, body_402657283)

var getDatabases* = Call_GetDatabases_402657266(name: "getDatabases",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDatabases",
    validator: validate_GetDatabases_402657267, base: "/",
    makeUrl: url_GetDatabases_402657268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataflowGraph_402657284 = ref object of OpenApiRestCall_402656044
proc url_GetDataflowGraph_402657286(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDataflowGraph_402657285(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Transforms a Python script into a directed acyclic graph (DAG). 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657287 = header.getOrDefault("X-Amz-Target")
  valid_402657287 = validateParameter(valid_402657287, JString, required = true, default = newJString(
      "AWSGlue.GetDataflowGraph"))
  if valid_402657287 != nil:
    section.add "X-Amz-Target", valid_402657287
  var valid_402657288 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657288 = validateParameter(valid_402657288, JString,
                                      required = false, default = nil)
  if valid_402657288 != nil:
    section.add "X-Amz-Security-Token", valid_402657288
  var valid_402657289 = header.getOrDefault("X-Amz-Signature")
  valid_402657289 = validateParameter(valid_402657289, JString,
                                      required = false, default = nil)
  if valid_402657289 != nil:
    section.add "X-Amz-Signature", valid_402657289
  var valid_402657290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657290 = validateParameter(valid_402657290, JString,
                                      required = false, default = nil)
  if valid_402657290 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657290
  var valid_402657291 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657291 = validateParameter(valid_402657291, JString,
                                      required = false, default = nil)
  if valid_402657291 != nil:
    section.add "X-Amz-Algorithm", valid_402657291
  var valid_402657292 = header.getOrDefault("X-Amz-Date")
  valid_402657292 = validateParameter(valid_402657292, JString,
                                      required = false, default = nil)
  if valid_402657292 != nil:
    section.add "X-Amz-Date", valid_402657292
  var valid_402657293 = header.getOrDefault("X-Amz-Credential")
  valid_402657293 = validateParameter(valid_402657293, JString,
                                      required = false, default = nil)
  if valid_402657293 != nil:
    section.add "X-Amz-Credential", valid_402657293
  var valid_402657294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657294 = validateParameter(valid_402657294, JString,
                                      required = false, default = nil)
  if valid_402657294 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657296: Call_GetDataflowGraph_402657284;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Transforms a Python script into a directed acyclic graph (DAG). 
                                                                                         ## 
  let valid = call_402657296.validator(path, query, header, formData, body, _)
  let scheme = call_402657296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657296.makeUrl(scheme.get, call_402657296.host, call_402657296.base,
                                   call_402657296.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657296, uri, valid, _)

proc call*(call_402657297: Call_GetDataflowGraph_402657284; body: JsonNode): Recallable =
  ## getDataflowGraph
  ## Transforms a Python script into a directed acyclic graph (DAG). 
  ##   body: JObject (required)
  var body_402657298 = newJObject()
  if body != nil:
    body_402657298 = body
  result = call_402657297.call(nil, nil, nil, nil, body_402657298)

var getDataflowGraph* = Call_GetDataflowGraph_402657284(
    name: "getDataflowGraph", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDataflowGraph",
    validator: validate_GetDataflowGraph_402657285, base: "/",
    makeUrl: url_GetDataflowGraph_402657286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevEndpoint_402657299 = ref object of OpenApiRestCall_402656044
proc url_GetDevEndpoint_402657301(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevEndpoint_402657300(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657302 = header.getOrDefault("X-Amz-Target")
  valid_402657302 = validateParameter(valid_402657302, JString, required = true, default = newJString(
      "AWSGlue.GetDevEndpoint"))
  if valid_402657302 != nil:
    section.add "X-Amz-Target", valid_402657302
  var valid_402657303 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657303 = validateParameter(valid_402657303, JString,
                                      required = false, default = nil)
  if valid_402657303 != nil:
    section.add "X-Amz-Security-Token", valid_402657303
  var valid_402657304 = header.getOrDefault("X-Amz-Signature")
  valid_402657304 = validateParameter(valid_402657304, JString,
                                      required = false, default = nil)
  if valid_402657304 != nil:
    section.add "X-Amz-Signature", valid_402657304
  var valid_402657305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657305 = validateParameter(valid_402657305, JString,
                                      required = false, default = nil)
  if valid_402657305 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657305
  var valid_402657306 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657306 = validateParameter(valid_402657306, JString,
                                      required = false, default = nil)
  if valid_402657306 != nil:
    section.add "X-Amz-Algorithm", valid_402657306
  var valid_402657307 = header.getOrDefault("X-Amz-Date")
  valid_402657307 = validateParameter(valid_402657307, JString,
                                      required = false, default = nil)
  if valid_402657307 != nil:
    section.add "X-Amz-Date", valid_402657307
  var valid_402657308 = header.getOrDefault("X-Amz-Credential")
  valid_402657308 = validateParameter(valid_402657308, JString,
                                      required = false, default = nil)
  if valid_402657308 != nil:
    section.add "X-Amz-Credential", valid_402657308
  var valid_402657309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657309 = validateParameter(valid_402657309, JString,
                                      required = false, default = nil)
  if valid_402657309 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657311: Call_GetDevEndpoint_402657299; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
                                                                                         ## 
  let valid = call_402657311.validator(path, query, header, formData, body, _)
  let scheme = call_402657311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657311.makeUrl(scheme.get, call_402657311.host, call_402657311.base,
                                   call_402657311.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657311, uri, valid, _)

proc call*(call_402657312: Call_GetDevEndpoint_402657299; body: JsonNode): Recallable =
  ## getDevEndpoint
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402657313 = newJObject()
  if body != nil:
    body_402657313 = body
  result = call_402657312.call(nil, nil, nil, nil, body_402657313)

var getDevEndpoint* = Call_GetDevEndpoint_402657299(name: "getDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDevEndpoint",
    validator: validate_GetDevEndpoint_402657300, base: "/",
    makeUrl: url_GetDevEndpoint_402657301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevEndpoints_402657314 = ref object of OpenApiRestCall_402656044
proc url_GetDevEndpoints_402657316(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevEndpoints_402657315(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657317 = query.getOrDefault("MaxResults")
  valid_402657317 = validateParameter(valid_402657317, JString,
                                      required = false, default = nil)
  if valid_402657317 != nil:
    section.add "MaxResults", valid_402657317
  var valid_402657318 = query.getOrDefault("NextToken")
  valid_402657318 = validateParameter(valid_402657318, JString,
                                      required = false, default = nil)
  if valid_402657318 != nil:
    section.add "NextToken", valid_402657318
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657319 = header.getOrDefault("X-Amz-Target")
  valid_402657319 = validateParameter(valid_402657319, JString, required = true, default = newJString(
      "AWSGlue.GetDevEndpoints"))
  if valid_402657319 != nil:
    section.add "X-Amz-Target", valid_402657319
  var valid_402657320 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657320 = validateParameter(valid_402657320, JString,
                                      required = false, default = nil)
  if valid_402657320 != nil:
    section.add "X-Amz-Security-Token", valid_402657320
  var valid_402657321 = header.getOrDefault("X-Amz-Signature")
  valid_402657321 = validateParameter(valid_402657321, JString,
                                      required = false, default = nil)
  if valid_402657321 != nil:
    section.add "X-Amz-Signature", valid_402657321
  var valid_402657322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657322 = validateParameter(valid_402657322, JString,
                                      required = false, default = nil)
  if valid_402657322 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657322
  var valid_402657323 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657323 = validateParameter(valid_402657323, JString,
                                      required = false, default = nil)
  if valid_402657323 != nil:
    section.add "X-Amz-Algorithm", valid_402657323
  var valid_402657324 = header.getOrDefault("X-Amz-Date")
  valid_402657324 = validateParameter(valid_402657324, JString,
                                      required = false, default = nil)
  if valid_402657324 != nil:
    section.add "X-Amz-Date", valid_402657324
  var valid_402657325 = header.getOrDefault("X-Amz-Credential")
  valid_402657325 = validateParameter(valid_402657325, JString,
                                      required = false, default = nil)
  if valid_402657325 != nil:
    section.add "X-Amz-Credential", valid_402657325
  var valid_402657326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657326 = validateParameter(valid_402657326, JString,
                                      required = false, default = nil)
  if valid_402657326 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657328: Call_GetDevEndpoints_402657314; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
                                                                                         ## 
  let valid = call_402657328.validator(path, query, header, formData, body, _)
  let scheme = call_402657328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657328.makeUrl(scheme.get, call_402657328.host, call_402657328.base,
                                   call_402657328.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657328, uri, valid, _)

proc call*(call_402657329: Call_GetDevEndpoints_402657314; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getDevEndpoints
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                               ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                               ##             
                                                                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                                                                               ## Pagination 
                                                                                                                                                                                                                                                                                                                                                               ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                  ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                  ##            
                                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                                  ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                  ## token
  var query_402657330 = newJObject()
  var body_402657331 = newJObject()
  add(query_402657330, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657331 = body
  add(query_402657330, "NextToken", newJString(NextToken))
  result = call_402657329.call(nil, query_402657330, nil, nil, body_402657331)

var getDevEndpoints* = Call_GetDevEndpoints_402657314(name: "getDevEndpoints",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDevEndpoints",
    validator: validate_GetDevEndpoints_402657315, base: "/",
    makeUrl: url_GetDevEndpoints_402657316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_402657332 = ref object of OpenApiRestCall_402656044
proc url_GetJob_402657334(protocol: Scheme; host: string; base: string;
                          route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJob_402657333(path: JsonNode; query: JsonNode;
                               header: JsonNode; formData: JsonNode;
                               body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves an existing job definition.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657335 = header.getOrDefault("X-Amz-Target")
  valid_402657335 = validateParameter(valid_402657335, JString, required = true,
                                      default = newJString("AWSGlue.GetJob"))
  if valid_402657335 != nil:
    section.add "X-Amz-Target", valid_402657335
  var valid_402657336 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657336 = validateParameter(valid_402657336, JString,
                                      required = false, default = nil)
  if valid_402657336 != nil:
    section.add "X-Amz-Security-Token", valid_402657336
  var valid_402657337 = header.getOrDefault("X-Amz-Signature")
  valid_402657337 = validateParameter(valid_402657337, JString,
                                      required = false, default = nil)
  if valid_402657337 != nil:
    section.add "X-Amz-Signature", valid_402657337
  var valid_402657338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657338 = validateParameter(valid_402657338, JString,
                                      required = false, default = nil)
  if valid_402657338 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657338
  var valid_402657339 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657339 = validateParameter(valid_402657339, JString,
                                      required = false, default = nil)
  if valid_402657339 != nil:
    section.add "X-Amz-Algorithm", valid_402657339
  var valid_402657340 = header.getOrDefault("X-Amz-Date")
  valid_402657340 = validateParameter(valid_402657340, JString,
                                      required = false, default = nil)
  if valid_402657340 != nil:
    section.add "X-Amz-Date", valid_402657340
  var valid_402657341 = header.getOrDefault("X-Amz-Credential")
  valid_402657341 = validateParameter(valid_402657341, JString,
                                      required = false, default = nil)
  if valid_402657341 != nil:
    section.add "X-Amz-Credential", valid_402657341
  var valid_402657342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657342 = validateParameter(valid_402657342, JString,
                                      required = false, default = nil)
  if valid_402657342 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657344: Call_GetJob_402657332; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves an existing job definition.
                                                                                         ## 
  let valid = call_402657344.validator(path, query, header, formData, body, _)
  let scheme = call_402657344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657344.makeUrl(scheme.get, call_402657344.host, call_402657344.base,
                                   call_402657344.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657344, uri, valid, _)

proc call*(call_402657345: Call_GetJob_402657332; body: JsonNode): Recallable =
  ## getJob
  ## Retrieves an existing job definition.
  ##   body: JObject (required)
  var body_402657346 = newJObject()
  if body != nil:
    body_402657346 = body
  result = call_402657345.call(nil, nil, nil, nil, body_402657346)

var getJob* = Call_GetJob_402657332(name: "getJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.GetJob",
                                    validator: validate_GetJob_402657333,
                                    base: "/", makeUrl: url_GetJob_402657334,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobBookmark_402657347 = ref object of OpenApiRestCall_402656044
proc url_GetJobBookmark_402657349(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJobBookmark_402657348(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information on a job bookmark entry.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657350 = header.getOrDefault("X-Amz-Target")
  valid_402657350 = validateParameter(valid_402657350, JString, required = true, default = newJString(
      "AWSGlue.GetJobBookmark"))
  if valid_402657350 != nil:
    section.add "X-Amz-Target", valid_402657350
  var valid_402657351 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657351 = validateParameter(valid_402657351, JString,
                                      required = false, default = nil)
  if valid_402657351 != nil:
    section.add "X-Amz-Security-Token", valid_402657351
  var valid_402657352 = header.getOrDefault("X-Amz-Signature")
  valid_402657352 = validateParameter(valid_402657352, JString,
                                      required = false, default = nil)
  if valid_402657352 != nil:
    section.add "X-Amz-Signature", valid_402657352
  var valid_402657353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657353 = validateParameter(valid_402657353, JString,
                                      required = false, default = nil)
  if valid_402657353 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657353
  var valid_402657354 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657354 = validateParameter(valid_402657354, JString,
                                      required = false, default = nil)
  if valid_402657354 != nil:
    section.add "X-Amz-Algorithm", valid_402657354
  var valid_402657355 = header.getOrDefault("X-Amz-Date")
  valid_402657355 = validateParameter(valid_402657355, JString,
                                      required = false, default = nil)
  if valid_402657355 != nil:
    section.add "X-Amz-Date", valid_402657355
  var valid_402657356 = header.getOrDefault("X-Amz-Credential")
  valid_402657356 = validateParameter(valid_402657356, JString,
                                      required = false, default = nil)
  if valid_402657356 != nil:
    section.add "X-Amz-Credential", valid_402657356
  var valid_402657357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657357 = validateParameter(valid_402657357, JString,
                                      required = false, default = nil)
  if valid_402657357 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657359: Call_GetJobBookmark_402657347; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information on a job bookmark entry.
                                                                                         ## 
  let valid = call_402657359.validator(path, query, header, formData, body, _)
  let scheme = call_402657359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657359.makeUrl(scheme.get, call_402657359.host, call_402657359.base,
                                   call_402657359.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657359, uri, valid, _)

proc call*(call_402657360: Call_GetJobBookmark_402657347; body: JsonNode): Recallable =
  ## getJobBookmark
  ## Returns information on a job bookmark entry.
  ##   body: JObject (required)
  var body_402657361 = newJObject()
  if body != nil:
    body_402657361 = body
  result = call_402657360.call(nil, nil, nil, nil, body_402657361)

var getJobBookmark* = Call_GetJobBookmark_402657347(name: "getJobBookmark",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetJobBookmark",
    validator: validate_GetJobBookmark_402657348, base: "/",
    makeUrl: url_GetJobBookmark_402657349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobRun_402657362 = ref object of OpenApiRestCall_402656044
proc url_GetJobRun_402657364(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJobRun_402657363(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the metadata for a given job run.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657365 = header.getOrDefault("X-Amz-Target")
  valid_402657365 = validateParameter(valid_402657365, JString, required = true,
                                      default = newJString("AWSGlue.GetJobRun"))
  if valid_402657365 != nil:
    section.add "X-Amz-Target", valid_402657365
  var valid_402657366 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657366 = validateParameter(valid_402657366, JString,
                                      required = false, default = nil)
  if valid_402657366 != nil:
    section.add "X-Amz-Security-Token", valid_402657366
  var valid_402657367 = header.getOrDefault("X-Amz-Signature")
  valid_402657367 = validateParameter(valid_402657367, JString,
                                      required = false, default = nil)
  if valid_402657367 != nil:
    section.add "X-Amz-Signature", valid_402657367
  var valid_402657368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657368 = validateParameter(valid_402657368, JString,
                                      required = false, default = nil)
  if valid_402657368 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657368
  var valid_402657369 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657369 = validateParameter(valid_402657369, JString,
                                      required = false, default = nil)
  if valid_402657369 != nil:
    section.add "X-Amz-Algorithm", valid_402657369
  var valid_402657370 = header.getOrDefault("X-Amz-Date")
  valid_402657370 = validateParameter(valid_402657370, JString,
                                      required = false, default = nil)
  if valid_402657370 != nil:
    section.add "X-Amz-Date", valid_402657370
  var valid_402657371 = header.getOrDefault("X-Amz-Credential")
  valid_402657371 = validateParameter(valid_402657371, JString,
                                      required = false, default = nil)
  if valid_402657371 != nil:
    section.add "X-Amz-Credential", valid_402657371
  var valid_402657372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657372 = validateParameter(valid_402657372, JString,
                                      required = false, default = nil)
  if valid_402657372 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657374: Call_GetJobRun_402657362; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the metadata for a given job run.
                                                                                         ## 
  let valid = call_402657374.validator(path, query, header, formData, body, _)
  let scheme = call_402657374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657374.makeUrl(scheme.get, call_402657374.host, call_402657374.base,
                                   call_402657374.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657374, uri, valid, _)

proc call*(call_402657375: Call_GetJobRun_402657362; body: JsonNode): Recallable =
  ## getJobRun
  ## Retrieves the metadata for a given job run.
  ##   body: JObject (required)
  var body_402657376 = newJObject()
  if body != nil:
    body_402657376 = body
  result = call_402657375.call(nil, nil, nil, nil, body_402657376)

var getJobRun* = Call_GetJobRun_402657362(name: "getJobRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetJobRun", validator: validate_GetJobRun_402657363,
    base: "/", makeUrl: url_GetJobRun_402657364,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobRuns_402657377 = ref object of OpenApiRestCall_402656044
proc url_GetJobRuns_402657379(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJobRuns_402657378(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves metadata for all runs of a given job definition.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657380 = query.getOrDefault("MaxResults")
  valid_402657380 = validateParameter(valid_402657380, JString,
                                      required = false, default = nil)
  if valid_402657380 != nil:
    section.add "MaxResults", valid_402657380
  var valid_402657381 = query.getOrDefault("NextToken")
  valid_402657381 = validateParameter(valid_402657381, JString,
                                      required = false, default = nil)
  if valid_402657381 != nil:
    section.add "NextToken", valid_402657381
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657382 = header.getOrDefault("X-Amz-Target")
  valid_402657382 = validateParameter(valid_402657382, JString, required = true, default = newJString(
      "AWSGlue.GetJobRuns"))
  if valid_402657382 != nil:
    section.add "X-Amz-Target", valid_402657382
  var valid_402657383 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657383 = validateParameter(valid_402657383, JString,
                                      required = false, default = nil)
  if valid_402657383 != nil:
    section.add "X-Amz-Security-Token", valid_402657383
  var valid_402657384 = header.getOrDefault("X-Amz-Signature")
  valid_402657384 = validateParameter(valid_402657384, JString,
                                      required = false, default = nil)
  if valid_402657384 != nil:
    section.add "X-Amz-Signature", valid_402657384
  var valid_402657385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657385 = validateParameter(valid_402657385, JString,
                                      required = false, default = nil)
  if valid_402657385 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657385
  var valid_402657386 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657386 = validateParameter(valid_402657386, JString,
                                      required = false, default = nil)
  if valid_402657386 != nil:
    section.add "X-Amz-Algorithm", valid_402657386
  var valid_402657387 = header.getOrDefault("X-Amz-Date")
  valid_402657387 = validateParameter(valid_402657387, JString,
                                      required = false, default = nil)
  if valid_402657387 != nil:
    section.add "X-Amz-Date", valid_402657387
  var valid_402657388 = header.getOrDefault("X-Amz-Credential")
  valid_402657388 = validateParameter(valid_402657388, JString,
                                      required = false, default = nil)
  if valid_402657388 != nil:
    section.add "X-Amz-Credential", valid_402657388
  var valid_402657389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657389 = validateParameter(valid_402657389, JString,
                                      required = false, default = nil)
  if valid_402657389 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657391: Call_GetJobRuns_402657377; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves metadata for all runs of a given job definition.
                                                                                         ## 
  let valid = call_402657391.validator(path, query, header, formData, body, _)
  let scheme = call_402657391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657391.makeUrl(scheme.get, call_402657391.host, call_402657391.base,
                                   call_402657391.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657391, uri, valid, _)

proc call*(call_402657392: Call_GetJobRuns_402657377; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getJobRuns
  ## Retrieves metadata for all runs of a given job definition.
  ##   MaxResults: string
                                                               ##             : Pagination limit
  ##   
                                                                                                ## body: JObject (required)
  ##   
                                                                                                                           ## NextToken: string
                                                                                                                           ##            
                                                                                                                           ## : 
                                                                                                                           ## Pagination 
                                                                                                                           ## token
  var query_402657393 = newJObject()
  var body_402657394 = newJObject()
  add(query_402657393, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657394 = body
  add(query_402657393, "NextToken", newJString(NextToken))
  result = call_402657392.call(nil, query_402657393, nil, nil, body_402657394)

var getJobRuns* = Call_GetJobRuns_402657377(name: "getJobRuns",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetJobRuns", validator: validate_GetJobRuns_402657378,
    base: "/", makeUrl: url_GetJobRuns_402657379,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobs_402657395 = ref object of OpenApiRestCall_402656044
proc url_GetJobs_402657397(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJobs_402657396(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves all current job definitions.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657398 = query.getOrDefault("MaxResults")
  valid_402657398 = validateParameter(valid_402657398, JString,
                                      required = false, default = nil)
  if valid_402657398 != nil:
    section.add "MaxResults", valid_402657398
  var valid_402657399 = query.getOrDefault("NextToken")
  valid_402657399 = validateParameter(valid_402657399, JString,
                                      required = false, default = nil)
  if valid_402657399 != nil:
    section.add "NextToken", valid_402657399
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657400 = header.getOrDefault("X-Amz-Target")
  valid_402657400 = validateParameter(valid_402657400, JString, required = true,
                                      default = newJString("AWSGlue.GetJobs"))
  if valid_402657400 != nil:
    section.add "X-Amz-Target", valid_402657400
  var valid_402657401 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657401 = validateParameter(valid_402657401, JString,
                                      required = false, default = nil)
  if valid_402657401 != nil:
    section.add "X-Amz-Security-Token", valid_402657401
  var valid_402657402 = header.getOrDefault("X-Amz-Signature")
  valid_402657402 = validateParameter(valid_402657402, JString,
                                      required = false, default = nil)
  if valid_402657402 != nil:
    section.add "X-Amz-Signature", valid_402657402
  var valid_402657403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657403 = validateParameter(valid_402657403, JString,
                                      required = false, default = nil)
  if valid_402657403 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657403
  var valid_402657404 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657404 = validateParameter(valid_402657404, JString,
                                      required = false, default = nil)
  if valid_402657404 != nil:
    section.add "X-Amz-Algorithm", valid_402657404
  var valid_402657405 = header.getOrDefault("X-Amz-Date")
  valid_402657405 = validateParameter(valid_402657405, JString,
                                      required = false, default = nil)
  if valid_402657405 != nil:
    section.add "X-Amz-Date", valid_402657405
  var valid_402657406 = header.getOrDefault("X-Amz-Credential")
  valid_402657406 = validateParameter(valid_402657406, JString,
                                      required = false, default = nil)
  if valid_402657406 != nil:
    section.add "X-Amz-Credential", valid_402657406
  var valid_402657407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657407 = validateParameter(valid_402657407, JString,
                                      required = false, default = nil)
  if valid_402657407 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657409: Call_GetJobs_402657395; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves all current job definitions.
                                                                                         ## 
  let valid = call_402657409.validator(path, query, header, formData, body, _)
  let scheme = call_402657409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657409.makeUrl(scheme.get, call_402657409.host, call_402657409.base,
                                   call_402657409.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657409, uri, valid, _)

proc call*(call_402657410: Call_GetJobs_402657395; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getJobs
  ## Retrieves all current job definitions.
  ##   MaxResults: string
                                           ##             : Pagination limit
  ##   
                                                                            ## body: JObject (required)
  ##   
                                                                                                       ## NextToken: string
                                                                                                       ##            
                                                                                                       ## : 
                                                                                                       ## Pagination 
                                                                                                       ## token
  var query_402657411 = newJObject()
  var body_402657412 = newJObject()
  add(query_402657411, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657412 = body
  add(query_402657411, "NextToken", newJString(NextToken))
  result = call_402657410.call(nil, query_402657411, nil, nil, body_402657412)

var getJobs* = Call_GetJobs_402657395(name: "getJobs",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com",
                                      route: "/#X-Amz-Target=AWSGlue.GetJobs",
                                      validator: validate_GetJobs_402657396,
                                      base: "/", makeUrl: url_GetJobs_402657397,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTaskRun_402657413 = ref object of OpenApiRestCall_402656044
proc url_GetMLTaskRun_402657415(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMLTaskRun_402657414(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657416 = header.getOrDefault("X-Amz-Target")
  valid_402657416 = validateParameter(valid_402657416, JString, required = true, default = newJString(
      "AWSGlue.GetMLTaskRun"))
  if valid_402657416 != nil:
    section.add "X-Amz-Target", valid_402657416
  var valid_402657417 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657417 = validateParameter(valid_402657417, JString,
                                      required = false, default = nil)
  if valid_402657417 != nil:
    section.add "X-Amz-Security-Token", valid_402657417
  var valid_402657418 = header.getOrDefault("X-Amz-Signature")
  valid_402657418 = validateParameter(valid_402657418, JString,
                                      required = false, default = nil)
  if valid_402657418 != nil:
    section.add "X-Amz-Signature", valid_402657418
  var valid_402657419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657419 = validateParameter(valid_402657419, JString,
                                      required = false, default = nil)
  if valid_402657419 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657419
  var valid_402657420 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657420 = validateParameter(valid_402657420, JString,
                                      required = false, default = nil)
  if valid_402657420 != nil:
    section.add "X-Amz-Algorithm", valid_402657420
  var valid_402657421 = header.getOrDefault("X-Amz-Date")
  valid_402657421 = validateParameter(valid_402657421, JString,
                                      required = false, default = nil)
  if valid_402657421 != nil:
    section.add "X-Amz-Date", valid_402657421
  var valid_402657422 = header.getOrDefault("X-Amz-Credential")
  valid_402657422 = validateParameter(valid_402657422, JString,
                                      required = false, default = nil)
  if valid_402657422 != nil:
    section.add "X-Amz-Credential", valid_402657422
  var valid_402657423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657423 = validateParameter(valid_402657423, JString,
                                      required = false, default = nil)
  if valid_402657423 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657425: Call_GetMLTaskRun_402657413; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
                                                                                         ## 
  let valid = call_402657425.validator(path, query, header, formData, body, _)
  let scheme = call_402657425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657425.makeUrl(scheme.get, call_402657425.host, call_402657425.base,
                                   call_402657425.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657425, uri, valid, _)

proc call*(call_402657426: Call_GetMLTaskRun_402657413; body: JsonNode): Recallable =
  ## getMLTaskRun
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
  ##   
                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402657427 = newJObject()
  if body != nil:
    body_402657427 = body
  result = call_402657426.call(nil, nil, nil, nil, body_402657427)

var getMLTaskRun* = Call_GetMLTaskRun_402657413(name: "getMLTaskRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTaskRun",
    validator: validate_GetMLTaskRun_402657414, base: "/",
    makeUrl: url_GetMLTaskRun_402657415, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTaskRuns_402657428 = ref object of OpenApiRestCall_402656044
proc url_GetMLTaskRuns_402657430(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMLTaskRuns_402657429(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657431 = query.getOrDefault("MaxResults")
  valid_402657431 = validateParameter(valid_402657431, JString,
                                      required = false, default = nil)
  if valid_402657431 != nil:
    section.add "MaxResults", valid_402657431
  var valid_402657432 = query.getOrDefault("NextToken")
  valid_402657432 = validateParameter(valid_402657432, JString,
                                      required = false, default = nil)
  if valid_402657432 != nil:
    section.add "NextToken", valid_402657432
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657433 = header.getOrDefault("X-Amz-Target")
  valid_402657433 = validateParameter(valid_402657433, JString, required = true, default = newJString(
      "AWSGlue.GetMLTaskRuns"))
  if valid_402657433 != nil:
    section.add "X-Amz-Target", valid_402657433
  var valid_402657434 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657434 = validateParameter(valid_402657434, JString,
                                      required = false, default = nil)
  if valid_402657434 != nil:
    section.add "X-Amz-Security-Token", valid_402657434
  var valid_402657435 = header.getOrDefault("X-Amz-Signature")
  valid_402657435 = validateParameter(valid_402657435, JString,
                                      required = false, default = nil)
  if valid_402657435 != nil:
    section.add "X-Amz-Signature", valid_402657435
  var valid_402657436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657436 = validateParameter(valid_402657436, JString,
                                      required = false, default = nil)
  if valid_402657436 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657436
  var valid_402657437 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657437 = validateParameter(valid_402657437, JString,
                                      required = false, default = nil)
  if valid_402657437 != nil:
    section.add "X-Amz-Algorithm", valid_402657437
  var valid_402657438 = header.getOrDefault("X-Amz-Date")
  valid_402657438 = validateParameter(valid_402657438, JString,
                                      required = false, default = nil)
  if valid_402657438 != nil:
    section.add "X-Amz-Date", valid_402657438
  var valid_402657439 = header.getOrDefault("X-Amz-Credential")
  valid_402657439 = validateParameter(valid_402657439, JString,
                                      required = false, default = nil)
  if valid_402657439 != nil:
    section.add "X-Amz-Credential", valid_402657439
  var valid_402657440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657440 = validateParameter(valid_402657440, JString,
                                      required = false, default = nil)
  if valid_402657440 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657442: Call_GetMLTaskRuns_402657428; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
                                                                                         ## 
  let valid = call_402657442.validator(path, query, header, formData, body, _)
  let scheme = call_402657442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657442.makeUrl(scheme.get, call_402657442.host, call_402657442.base,
                                   call_402657442.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657442, uri, valid, _)

proc call*(call_402657443: Call_GetMLTaskRuns_402657428; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getMLTaskRuns
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## token
  var query_402657444 = newJObject()
  var body_402657445 = newJObject()
  add(query_402657444, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657445 = body
  add(query_402657444, "NextToken", newJString(NextToken))
  result = call_402657443.call(nil, query_402657444, nil, nil, body_402657445)

var getMLTaskRuns* = Call_GetMLTaskRuns_402657428(name: "getMLTaskRuns",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTaskRuns",
    validator: validate_GetMLTaskRuns_402657429, base: "/",
    makeUrl: url_GetMLTaskRuns_402657430, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTransform_402657446 = ref object of OpenApiRestCall_402656044
proc url_GetMLTransform_402657448(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMLTransform_402657447(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657449 = header.getOrDefault("X-Amz-Target")
  valid_402657449 = validateParameter(valid_402657449, JString, required = true, default = newJString(
      "AWSGlue.GetMLTransform"))
  if valid_402657449 != nil:
    section.add "X-Amz-Target", valid_402657449
  var valid_402657450 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657450 = validateParameter(valid_402657450, JString,
                                      required = false, default = nil)
  if valid_402657450 != nil:
    section.add "X-Amz-Security-Token", valid_402657450
  var valid_402657451 = header.getOrDefault("X-Amz-Signature")
  valid_402657451 = validateParameter(valid_402657451, JString,
                                      required = false, default = nil)
  if valid_402657451 != nil:
    section.add "X-Amz-Signature", valid_402657451
  var valid_402657452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657452 = validateParameter(valid_402657452, JString,
                                      required = false, default = nil)
  if valid_402657452 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657452
  var valid_402657453 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657453 = validateParameter(valid_402657453, JString,
                                      required = false, default = nil)
  if valid_402657453 != nil:
    section.add "X-Amz-Algorithm", valid_402657453
  var valid_402657454 = header.getOrDefault("X-Amz-Date")
  valid_402657454 = validateParameter(valid_402657454, JString,
                                      required = false, default = nil)
  if valid_402657454 != nil:
    section.add "X-Amz-Date", valid_402657454
  var valid_402657455 = header.getOrDefault("X-Amz-Credential")
  valid_402657455 = validateParameter(valid_402657455, JString,
                                      required = false, default = nil)
  if valid_402657455 != nil:
    section.add "X-Amz-Credential", valid_402657455
  var valid_402657456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657456 = validateParameter(valid_402657456, JString,
                                      required = false, default = nil)
  if valid_402657456 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657458: Call_GetMLTransform_402657446; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
                                                                                         ## 
  let valid = call_402657458.validator(path, query, header, formData, body, _)
  let scheme = call_402657458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657458.makeUrl(scheme.get, call_402657458.host, call_402657458.base,
                                   call_402657458.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657458, uri, valid, _)

proc call*(call_402657459: Call_GetMLTransform_402657446; body: JsonNode): Recallable =
  ## getMLTransform
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402657460 = newJObject()
  if body != nil:
    body_402657460 = body
  result = call_402657459.call(nil, nil, nil, nil, body_402657460)

var getMLTransform* = Call_GetMLTransform_402657446(name: "getMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTransform",
    validator: validate_GetMLTransform_402657447, base: "/",
    makeUrl: url_GetMLTransform_402657448, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTransforms_402657461 = ref object of OpenApiRestCall_402656044
proc url_GetMLTransforms_402657463(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMLTransforms_402657462(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657464 = query.getOrDefault("MaxResults")
  valid_402657464 = validateParameter(valid_402657464, JString,
                                      required = false, default = nil)
  if valid_402657464 != nil:
    section.add "MaxResults", valid_402657464
  var valid_402657465 = query.getOrDefault("NextToken")
  valid_402657465 = validateParameter(valid_402657465, JString,
                                      required = false, default = nil)
  if valid_402657465 != nil:
    section.add "NextToken", valid_402657465
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657466 = header.getOrDefault("X-Amz-Target")
  valid_402657466 = validateParameter(valid_402657466, JString, required = true, default = newJString(
      "AWSGlue.GetMLTransforms"))
  if valid_402657466 != nil:
    section.add "X-Amz-Target", valid_402657466
  var valid_402657467 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657467 = validateParameter(valid_402657467, JString,
                                      required = false, default = nil)
  if valid_402657467 != nil:
    section.add "X-Amz-Security-Token", valid_402657467
  var valid_402657468 = header.getOrDefault("X-Amz-Signature")
  valid_402657468 = validateParameter(valid_402657468, JString,
                                      required = false, default = nil)
  if valid_402657468 != nil:
    section.add "X-Amz-Signature", valid_402657468
  var valid_402657469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657469 = validateParameter(valid_402657469, JString,
                                      required = false, default = nil)
  if valid_402657469 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657469
  var valid_402657470 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657470 = validateParameter(valid_402657470, JString,
                                      required = false, default = nil)
  if valid_402657470 != nil:
    section.add "X-Amz-Algorithm", valid_402657470
  var valid_402657471 = header.getOrDefault("X-Amz-Date")
  valid_402657471 = validateParameter(valid_402657471, JString,
                                      required = false, default = nil)
  if valid_402657471 != nil:
    section.add "X-Amz-Date", valid_402657471
  var valid_402657472 = header.getOrDefault("X-Amz-Credential")
  valid_402657472 = validateParameter(valid_402657472, JString,
                                      required = false, default = nil)
  if valid_402657472 != nil:
    section.add "X-Amz-Credential", valid_402657472
  var valid_402657473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657473 = validateParameter(valid_402657473, JString,
                                      required = false, default = nil)
  if valid_402657473 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657475: Call_GetMLTransforms_402657461; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
                                                                                         ## 
  let valid = call_402657475.validator(path, query, header, formData, body, _)
  let scheme = call_402657475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657475.makeUrl(scheme.get, call_402657475.host, call_402657475.base,
                                   call_402657475.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657475, uri, valid, _)

proc call*(call_402657476: Call_GetMLTransforms_402657461; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getMLTransforms
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                     ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                     ##             
                                                                                                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                     ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                     ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## token
  var query_402657477 = newJObject()
  var body_402657478 = newJObject()
  add(query_402657477, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657478 = body
  add(query_402657477, "NextToken", newJString(NextToken))
  result = call_402657476.call(nil, query_402657477, nil, nil, body_402657478)

var getMLTransforms* = Call_GetMLTransforms_402657461(name: "getMLTransforms",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTransforms",
    validator: validate_GetMLTransforms_402657462, base: "/",
    makeUrl: url_GetMLTransforms_402657463, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMapping_402657479 = ref object of OpenApiRestCall_402656044
proc url_GetMapping_402657481(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMapping_402657480(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates mappings.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657482 = header.getOrDefault("X-Amz-Target")
  valid_402657482 = validateParameter(valid_402657482, JString, required = true, default = newJString(
      "AWSGlue.GetMapping"))
  if valid_402657482 != nil:
    section.add "X-Amz-Target", valid_402657482
  var valid_402657483 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657483 = validateParameter(valid_402657483, JString,
                                      required = false, default = nil)
  if valid_402657483 != nil:
    section.add "X-Amz-Security-Token", valid_402657483
  var valid_402657484 = header.getOrDefault("X-Amz-Signature")
  valid_402657484 = validateParameter(valid_402657484, JString,
                                      required = false, default = nil)
  if valid_402657484 != nil:
    section.add "X-Amz-Signature", valid_402657484
  var valid_402657485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657485 = validateParameter(valid_402657485, JString,
                                      required = false, default = nil)
  if valid_402657485 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657485
  var valid_402657486 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657486 = validateParameter(valid_402657486, JString,
                                      required = false, default = nil)
  if valid_402657486 != nil:
    section.add "X-Amz-Algorithm", valid_402657486
  var valid_402657487 = header.getOrDefault("X-Amz-Date")
  valid_402657487 = validateParameter(valid_402657487, JString,
                                      required = false, default = nil)
  if valid_402657487 != nil:
    section.add "X-Amz-Date", valid_402657487
  var valid_402657488 = header.getOrDefault("X-Amz-Credential")
  valid_402657488 = validateParameter(valid_402657488, JString,
                                      required = false, default = nil)
  if valid_402657488 != nil:
    section.add "X-Amz-Credential", valid_402657488
  var valid_402657489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657489 = validateParameter(valid_402657489, JString,
                                      required = false, default = nil)
  if valid_402657489 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657491: Call_GetMapping_402657479; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates mappings.
                                                                                         ## 
  let valid = call_402657491.validator(path, query, header, formData, body, _)
  let scheme = call_402657491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657491.makeUrl(scheme.get, call_402657491.host, call_402657491.base,
                                   call_402657491.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657491, uri, valid, _)

proc call*(call_402657492: Call_GetMapping_402657479; body: JsonNode): Recallable =
  ## getMapping
  ## Creates mappings.
  ##   body: JObject (required)
  var body_402657493 = newJObject()
  if body != nil:
    body_402657493 = body
  result = call_402657492.call(nil, nil, nil, nil, body_402657493)

var getMapping* = Call_GetMapping_402657479(name: "getMapping",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMapping", validator: validate_GetMapping_402657480,
    base: "/", makeUrl: url_GetMapping_402657481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPartition_402657494 = ref object of OpenApiRestCall_402656044
proc url_GetPartition_402657496(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPartition_402657495(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about a specified partition.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657497 = header.getOrDefault("X-Amz-Target")
  valid_402657497 = validateParameter(valid_402657497, JString, required = true, default = newJString(
      "AWSGlue.GetPartition"))
  if valid_402657497 != nil:
    section.add "X-Amz-Target", valid_402657497
  var valid_402657498 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657498 = validateParameter(valid_402657498, JString,
                                      required = false, default = nil)
  if valid_402657498 != nil:
    section.add "X-Amz-Security-Token", valid_402657498
  var valid_402657499 = header.getOrDefault("X-Amz-Signature")
  valid_402657499 = validateParameter(valid_402657499, JString,
                                      required = false, default = nil)
  if valid_402657499 != nil:
    section.add "X-Amz-Signature", valid_402657499
  var valid_402657500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657500 = validateParameter(valid_402657500, JString,
                                      required = false, default = nil)
  if valid_402657500 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657500
  var valid_402657501 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657501 = validateParameter(valid_402657501, JString,
                                      required = false, default = nil)
  if valid_402657501 != nil:
    section.add "X-Amz-Algorithm", valid_402657501
  var valid_402657502 = header.getOrDefault("X-Amz-Date")
  valid_402657502 = validateParameter(valid_402657502, JString,
                                      required = false, default = nil)
  if valid_402657502 != nil:
    section.add "X-Amz-Date", valid_402657502
  var valid_402657503 = header.getOrDefault("X-Amz-Credential")
  valid_402657503 = validateParameter(valid_402657503, JString,
                                      required = false, default = nil)
  if valid_402657503 != nil:
    section.add "X-Amz-Credential", valid_402657503
  var valid_402657504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657504 = validateParameter(valid_402657504, JString,
                                      required = false, default = nil)
  if valid_402657504 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657506: Call_GetPartition_402657494; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a specified partition.
                                                                                         ## 
  let valid = call_402657506.validator(path, query, header, formData, body, _)
  let scheme = call_402657506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657506.makeUrl(scheme.get, call_402657506.host, call_402657506.base,
                                   call_402657506.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657506, uri, valid, _)

proc call*(call_402657507: Call_GetPartition_402657494; body: JsonNode): Recallable =
  ## getPartition
  ## Retrieves information about a specified partition.
  ##   body: JObject (required)
  var body_402657508 = newJObject()
  if body != nil:
    body_402657508 = body
  result = call_402657507.call(nil, nil, nil, nil, body_402657508)

var getPartition* = Call_GetPartition_402657494(name: "getPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetPartition",
    validator: validate_GetPartition_402657495, base: "/",
    makeUrl: url_GetPartition_402657496, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPartitions_402657509 = ref object of OpenApiRestCall_402656044
proc url_GetPartitions_402657511(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPartitions_402657510(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the partitions in a table.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657512 = query.getOrDefault("MaxResults")
  valid_402657512 = validateParameter(valid_402657512, JString,
                                      required = false, default = nil)
  if valid_402657512 != nil:
    section.add "MaxResults", valid_402657512
  var valid_402657513 = query.getOrDefault("NextToken")
  valid_402657513 = validateParameter(valid_402657513, JString,
                                      required = false, default = nil)
  if valid_402657513 != nil:
    section.add "NextToken", valid_402657513
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657514 = header.getOrDefault("X-Amz-Target")
  valid_402657514 = validateParameter(valid_402657514, JString, required = true, default = newJString(
      "AWSGlue.GetPartitions"))
  if valid_402657514 != nil:
    section.add "X-Amz-Target", valid_402657514
  var valid_402657515 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657515 = validateParameter(valid_402657515, JString,
                                      required = false, default = nil)
  if valid_402657515 != nil:
    section.add "X-Amz-Security-Token", valid_402657515
  var valid_402657516 = header.getOrDefault("X-Amz-Signature")
  valid_402657516 = validateParameter(valid_402657516, JString,
                                      required = false, default = nil)
  if valid_402657516 != nil:
    section.add "X-Amz-Signature", valid_402657516
  var valid_402657517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657517 = validateParameter(valid_402657517, JString,
                                      required = false, default = nil)
  if valid_402657517 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657517
  var valid_402657518 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657518 = validateParameter(valid_402657518, JString,
                                      required = false, default = nil)
  if valid_402657518 != nil:
    section.add "X-Amz-Algorithm", valid_402657518
  var valid_402657519 = header.getOrDefault("X-Amz-Date")
  valid_402657519 = validateParameter(valid_402657519, JString,
                                      required = false, default = nil)
  if valid_402657519 != nil:
    section.add "X-Amz-Date", valid_402657519
  var valid_402657520 = header.getOrDefault("X-Amz-Credential")
  valid_402657520 = validateParameter(valid_402657520, JString,
                                      required = false, default = nil)
  if valid_402657520 != nil:
    section.add "X-Amz-Credential", valid_402657520
  var valid_402657521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657521 = validateParameter(valid_402657521, JString,
                                      required = false, default = nil)
  if valid_402657521 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657523: Call_GetPartitions_402657509; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the partitions in a table.
                                                                                         ## 
  let valid = call_402657523.validator(path, query, header, formData, body, _)
  let scheme = call_402657523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657523.makeUrl(scheme.get, call_402657523.host, call_402657523.base,
                                   call_402657523.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657523, uri, valid, _)

proc call*(call_402657524: Call_GetPartitions_402657509; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getPartitions
  ## Retrieves information about the partitions in a table.
  ##   MaxResults: string
                                                           ##             : Pagination limit
  ##   
                                                                                            ## body: JObject (required)
  ##   
                                                                                                                       ## NextToken: string
                                                                                                                       ##            
                                                                                                                       ## : 
                                                                                                                       ## Pagination 
                                                                                                                       ## token
  var query_402657525 = newJObject()
  var body_402657526 = newJObject()
  add(query_402657525, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657526 = body
  add(query_402657525, "NextToken", newJString(NextToken))
  result = call_402657524.call(nil, query_402657525, nil, nil, body_402657526)

var getPartitions* = Call_GetPartitions_402657509(name: "getPartitions",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetPartitions",
    validator: validate_GetPartitions_402657510, base: "/",
    makeUrl: url_GetPartitions_402657511, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPlan_402657527 = ref object of OpenApiRestCall_402656044
proc url_GetPlan_402657529(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPlan_402657528(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets code to perform a specified mapping.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657530 = header.getOrDefault("X-Amz-Target")
  valid_402657530 = validateParameter(valid_402657530, JString, required = true,
                                      default = newJString("AWSGlue.GetPlan"))
  if valid_402657530 != nil:
    section.add "X-Amz-Target", valid_402657530
  var valid_402657531 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657531 = validateParameter(valid_402657531, JString,
                                      required = false, default = nil)
  if valid_402657531 != nil:
    section.add "X-Amz-Security-Token", valid_402657531
  var valid_402657532 = header.getOrDefault("X-Amz-Signature")
  valid_402657532 = validateParameter(valid_402657532, JString,
                                      required = false, default = nil)
  if valid_402657532 != nil:
    section.add "X-Amz-Signature", valid_402657532
  var valid_402657533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657533 = validateParameter(valid_402657533, JString,
                                      required = false, default = nil)
  if valid_402657533 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657533
  var valid_402657534 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657534 = validateParameter(valid_402657534, JString,
                                      required = false, default = nil)
  if valid_402657534 != nil:
    section.add "X-Amz-Algorithm", valid_402657534
  var valid_402657535 = header.getOrDefault("X-Amz-Date")
  valid_402657535 = validateParameter(valid_402657535, JString,
                                      required = false, default = nil)
  if valid_402657535 != nil:
    section.add "X-Amz-Date", valid_402657535
  var valid_402657536 = header.getOrDefault("X-Amz-Credential")
  valid_402657536 = validateParameter(valid_402657536, JString,
                                      required = false, default = nil)
  if valid_402657536 != nil:
    section.add "X-Amz-Credential", valid_402657536
  var valid_402657537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657537 = validateParameter(valid_402657537, JString,
                                      required = false, default = nil)
  if valid_402657537 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657539: Call_GetPlan_402657527; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets code to perform a specified mapping.
                                                                                         ## 
  let valid = call_402657539.validator(path, query, header, formData, body, _)
  let scheme = call_402657539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657539.makeUrl(scheme.get, call_402657539.host, call_402657539.base,
                                   call_402657539.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657539, uri, valid, _)

proc call*(call_402657540: Call_GetPlan_402657527; body: JsonNode): Recallable =
  ## getPlan
  ## Gets code to perform a specified mapping.
  ##   body: JObject (required)
  var body_402657541 = newJObject()
  if body != nil:
    body_402657541 = body
  result = call_402657540.call(nil, nil, nil, nil, body_402657541)

var getPlan* = Call_GetPlan_402657527(name: "getPlan",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com",
                                      route: "/#X-Amz-Target=AWSGlue.GetPlan",
                                      validator: validate_GetPlan_402657528,
                                      base: "/", makeUrl: url_GetPlan_402657529,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicy_402657542 = ref object of OpenApiRestCall_402656044
proc url_GetResourcePolicy_402657544(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResourcePolicy_402657543(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a specified resource policy.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657545 = header.getOrDefault("X-Amz-Target")
  valid_402657545 = validateParameter(valid_402657545, JString, required = true, default = newJString(
      "AWSGlue.GetResourcePolicy"))
  if valid_402657545 != nil:
    section.add "X-Amz-Target", valid_402657545
  var valid_402657546 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657546 = validateParameter(valid_402657546, JString,
                                      required = false, default = nil)
  if valid_402657546 != nil:
    section.add "X-Amz-Security-Token", valid_402657546
  var valid_402657547 = header.getOrDefault("X-Amz-Signature")
  valid_402657547 = validateParameter(valid_402657547, JString,
                                      required = false, default = nil)
  if valid_402657547 != nil:
    section.add "X-Amz-Signature", valid_402657547
  var valid_402657548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657548 = validateParameter(valid_402657548, JString,
                                      required = false, default = nil)
  if valid_402657548 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657548
  var valid_402657549 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657549 = validateParameter(valid_402657549, JString,
                                      required = false, default = nil)
  if valid_402657549 != nil:
    section.add "X-Amz-Algorithm", valid_402657549
  var valid_402657550 = header.getOrDefault("X-Amz-Date")
  valid_402657550 = validateParameter(valid_402657550, JString,
                                      required = false, default = nil)
  if valid_402657550 != nil:
    section.add "X-Amz-Date", valid_402657550
  var valid_402657551 = header.getOrDefault("X-Amz-Credential")
  valid_402657551 = validateParameter(valid_402657551, JString,
                                      required = false, default = nil)
  if valid_402657551 != nil:
    section.add "X-Amz-Credential", valid_402657551
  var valid_402657552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657552 = validateParameter(valid_402657552, JString,
                                      required = false, default = nil)
  if valid_402657552 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657554: Call_GetResourcePolicy_402657542;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a specified resource policy.
                                                                                         ## 
  let valid = call_402657554.validator(path, query, header, formData, body, _)
  let scheme = call_402657554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657554.makeUrl(scheme.get, call_402657554.host, call_402657554.base,
                                   call_402657554.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657554, uri, valid, _)

proc call*(call_402657555: Call_GetResourcePolicy_402657542; body: JsonNode): Recallable =
  ## getResourcePolicy
  ## Retrieves a specified resource policy.
  ##   body: JObject (required)
  var body_402657556 = newJObject()
  if body != nil:
    body_402657556 = body
  result = call_402657555.call(nil, nil, nil, nil, body_402657556)

var getResourcePolicy* = Call_GetResourcePolicy_402657542(
    name: "getResourcePolicy", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetResourcePolicy",
    validator: validate_GetResourcePolicy_402657543, base: "/",
    makeUrl: url_GetResourcePolicy_402657544,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecurityConfiguration_402657557 = ref object of OpenApiRestCall_402656044
proc url_GetSecurityConfiguration_402657559(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSecurityConfiguration_402657558(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves a specified security configuration.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657560 = header.getOrDefault("X-Amz-Target")
  valid_402657560 = validateParameter(valid_402657560, JString, required = true, default = newJString(
      "AWSGlue.GetSecurityConfiguration"))
  if valid_402657560 != nil:
    section.add "X-Amz-Target", valid_402657560
  var valid_402657561 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657561 = validateParameter(valid_402657561, JString,
                                      required = false, default = nil)
  if valid_402657561 != nil:
    section.add "X-Amz-Security-Token", valid_402657561
  var valid_402657562 = header.getOrDefault("X-Amz-Signature")
  valid_402657562 = validateParameter(valid_402657562, JString,
                                      required = false, default = nil)
  if valid_402657562 != nil:
    section.add "X-Amz-Signature", valid_402657562
  var valid_402657563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657563 = validateParameter(valid_402657563, JString,
                                      required = false, default = nil)
  if valid_402657563 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657563
  var valid_402657564 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657564 = validateParameter(valid_402657564, JString,
                                      required = false, default = nil)
  if valid_402657564 != nil:
    section.add "X-Amz-Algorithm", valid_402657564
  var valid_402657565 = header.getOrDefault("X-Amz-Date")
  valid_402657565 = validateParameter(valid_402657565, JString,
                                      required = false, default = nil)
  if valid_402657565 != nil:
    section.add "X-Amz-Date", valid_402657565
  var valid_402657566 = header.getOrDefault("X-Amz-Credential")
  valid_402657566 = validateParameter(valid_402657566, JString,
                                      required = false, default = nil)
  if valid_402657566 != nil:
    section.add "X-Amz-Credential", valid_402657566
  var valid_402657567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657567 = validateParameter(valid_402657567, JString,
                                      required = false, default = nil)
  if valid_402657567 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657569: Call_GetSecurityConfiguration_402657557;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a specified security configuration.
                                                                                         ## 
  let valid = call_402657569.validator(path, query, header, formData, body, _)
  let scheme = call_402657569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657569.makeUrl(scheme.get, call_402657569.host, call_402657569.base,
                                   call_402657569.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657569, uri, valid, _)

proc call*(call_402657570: Call_GetSecurityConfiguration_402657557;
           body: JsonNode): Recallable =
  ## getSecurityConfiguration
  ## Retrieves a specified security configuration.
  ##   body: JObject (required)
  var body_402657571 = newJObject()
  if body != nil:
    body_402657571 = body
  result = call_402657570.call(nil, nil, nil, nil, body_402657571)

var getSecurityConfiguration* = Call_GetSecurityConfiguration_402657557(
    name: "getSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetSecurityConfiguration",
    validator: validate_GetSecurityConfiguration_402657558, base: "/",
    makeUrl: url_GetSecurityConfiguration_402657559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecurityConfigurations_402657572 = ref object of OpenApiRestCall_402656044
proc url_GetSecurityConfigurations_402657574(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSecurityConfigurations_402657573(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves a list of all security configurations.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657575 = query.getOrDefault("MaxResults")
  valid_402657575 = validateParameter(valid_402657575, JString,
                                      required = false, default = nil)
  if valid_402657575 != nil:
    section.add "MaxResults", valid_402657575
  var valid_402657576 = query.getOrDefault("NextToken")
  valid_402657576 = validateParameter(valid_402657576, JString,
                                      required = false, default = nil)
  if valid_402657576 != nil:
    section.add "NextToken", valid_402657576
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657577 = header.getOrDefault("X-Amz-Target")
  valid_402657577 = validateParameter(valid_402657577, JString, required = true, default = newJString(
      "AWSGlue.GetSecurityConfigurations"))
  if valid_402657577 != nil:
    section.add "X-Amz-Target", valid_402657577
  var valid_402657578 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657578 = validateParameter(valid_402657578, JString,
                                      required = false, default = nil)
  if valid_402657578 != nil:
    section.add "X-Amz-Security-Token", valid_402657578
  var valid_402657579 = header.getOrDefault("X-Amz-Signature")
  valid_402657579 = validateParameter(valid_402657579, JString,
                                      required = false, default = nil)
  if valid_402657579 != nil:
    section.add "X-Amz-Signature", valid_402657579
  var valid_402657580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657580 = validateParameter(valid_402657580, JString,
                                      required = false, default = nil)
  if valid_402657580 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657580
  var valid_402657581 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657581 = validateParameter(valid_402657581, JString,
                                      required = false, default = nil)
  if valid_402657581 != nil:
    section.add "X-Amz-Algorithm", valid_402657581
  var valid_402657582 = header.getOrDefault("X-Amz-Date")
  valid_402657582 = validateParameter(valid_402657582, JString,
                                      required = false, default = nil)
  if valid_402657582 != nil:
    section.add "X-Amz-Date", valid_402657582
  var valid_402657583 = header.getOrDefault("X-Amz-Credential")
  valid_402657583 = validateParameter(valid_402657583, JString,
                                      required = false, default = nil)
  if valid_402657583 != nil:
    section.add "X-Amz-Credential", valid_402657583
  var valid_402657584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657584 = validateParameter(valid_402657584, JString,
                                      required = false, default = nil)
  if valid_402657584 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657586: Call_GetSecurityConfigurations_402657572;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of all security configurations.
                                                                                         ## 
  let valid = call_402657586.validator(path, query, header, formData, body, _)
  let scheme = call_402657586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657586.makeUrl(scheme.get, call_402657586.host, call_402657586.base,
                                   call_402657586.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657586, uri, valid, _)

proc call*(call_402657587: Call_GetSecurityConfigurations_402657572;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getSecurityConfigurations
  ## Retrieves a list of all security configurations.
  ##   MaxResults: string
                                                     ##             : Pagination limit
  ##   
                                                                                      ## body: JObject (required)
  ##   
                                                                                                                 ## NextToken: string
                                                                                                                 ##            
                                                                                                                 ## : 
                                                                                                                 ## Pagination 
                                                                                                                 ## token
  var query_402657588 = newJObject()
  var body_402657589 = newJObject()
  add(query_402657588, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657589 = body
  add(query_402657588, "NextToken", newJString(NextToken))
  result = call_402657587.call(nil, query_402657588, nil, nil, body_402657589)

var getSecurityConfigurations* = Call_GetSecurityConfigurations_402657572(
    name: "getSecurityConfigurations", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetSecurityConfigurations",
    validator: validate_GetSecurityConfigurations_402657573, base: "/",
    makeUrl: url_GetSecurityConfigurations_402657574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTable_402657590 = ref object of OpenApiRestCall_402656044
proc url_GetTable_402657592(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTable_402657591(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657593 = header.getOrDefault("X-Amz-Target")
  valid_402657593 = validateParameter(valid_402657593, JString, required = true,
                                      default = newJString("AWSGlue.GetTable"))
  if valid_402657593 != nil:
    section.add "X-Amz-Target", valid_402657593
  var valid_402657594 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657594 = validateParameter(valid_402657594, JString,
                                      required = false, default = nil)
  if valid_402657594 != nil:
    section.add "X-Amz-Security-Token", valid_402657594
  var valid_402657595 = header.getOrDefault("X-Amz-Signature")
  valid_402657595 = validateParameter(valid_402657595, JString,
                                      required = false, default = nil)
  if valid_402657595 != nil:
    section.add "X-Amz-Signature", valid_402657595
  var valid_402657596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657596 = validateParameter(valid_402657596, JString,
                                      required = false, default = nil)
  if valid_402657596 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657596
  var valid_402657597 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657597 = validateParameter(valid_402657597, JString,
                                      required = false, default = nil)
  if valid_402657597 != nil:
    section.add "X-Amz-Algorithm", valid_402657597
  var valid_402657598 = header.getOrDefault("X-Amz-Date")
  valid_402657598 = validateParameter(valid_402657598, JString,
                                      required = false, default = nil)
  if valid_402657598 != nil:
    section.add "X-Amz-Date", valid_402657598
  var valid_402657599 = header.getOrDefault("X-Amz-Credential")
  valid_402657599 = validateParameter(valid_402657599, JString,
                                      required = false, default = nil)
  if valid_402657599 != nil:
    section.add "X-Amz-Credential", valid_402657599
  var valid_402657600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657600 = validateParameter(valid_402657600, JString,
                                      required = false, default = nil)
  if valid_402657600 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657602: Call_GetTable_402657590; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
                                                                                         ## 
  let valid = call_402657602.validator(path, query, header, formData, body, _)
  let scheme = call_402657602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657602.makeUrl(scheme.get, call_402657602.host, call_402657602.base,
                                   call_402657602.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657602, uri, valid, _)

proc call*(call_402657603: Call_GetTable_402657590; body: JsonNode): Recallable =
  ## getTable
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
  ##   
                                                                                         ## body: JObject (required)
  var body_402657604 = newJObject()
  if body != nil:
    body_402657604 = body
  result = call_402657603.call(nil, nil, nil, nil, body_402657604)

var getTable* = Call_GetTable_402657590(name: "getTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetTable",
                                        validator: validate_GetTable_402657591,
                                        base: "/", makeUrl: url_GetTable_402657592,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTableVersion_402657605 = ref object of OpenApiRestCall_402656044
proc url_GetTableVersion_402657607(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTableVersion_402657606(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a specified version of a table.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657608 = header.getOrDefault("X-Amz-Target")
  valid_402657608 = validateParameter(valid_402657608, JString, required = true, default = newJString(
      "AWSGlue.GetTableVersion"))
  if valid_402657608 != nil:
    section.add "X-Amz-Target", valid_402657608
  var valid_402657609 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657609 = validateParameter(valid_402657609, JString,
                                      required = false, default = nil)
  if valid_402657609 != nil:
    section.add "X-Amz-Security-Token", valid_402657609
  var valid_402657610 = header.getOrDefault("X-Amz-Signature")
  valid_402657610 = validateParameter(valid_402657610, JString,
                                      required = false, default = nil)
  if valid_402657610 != nil:
    section.add "X-Amz-Signature", valid_402657610
  var valid_402657611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657611 = validateParameter(valid_402657611, JString,
                                      required = false, default = nil)
  if valid_402657611 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657611
  var valid_402657612 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657612 = validateParameter(valid_402657612, JString,
                                      required = false, default = nil)
  if valid_402657612 != nil:
    section.add "X-Amz-Algorithm", valid_402657612
  var valid_402657613 = header.getOrDefault("X-Amz-Date")
  valid_402657613 = validateParameter(valid_402657613, JString,
                                      required = false, default = nil)
  if valid_402657613 != nil:
    section.add "X-Amz-Date", valid_402657613
  var valid_402657614 = header.getOrDefault("X-Amz-Credential")
  valid_402657614 = validateParameter(valid_402657614, JString,
                                      required = false, default = nil)
  if valid_402657614 != nil:
    section.add "X-Amz-Credential", valid_402657614
  var valid_402657615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657615 = validateParameter(valid_402657615, JString,
                                      required = false, default = nil)
  if valid_402657615 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657617: Call_GetTableVersion_402657605; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a specified version of a table.
                                                                                         ## 
  let valid = call_402657617.validator(path, query, header, formData, body, _)
  let scheme = call_402657617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657617.makeUrl(scheme.get, call_402657617.host, call_402657617.base,
                                   call_402657617.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657617, uri, valid, _)

proc call*(call_402657618: Call_GetTableVersion_402657605; body: JsonNode): Recallable =
  ## getTableVersion
  ## Retrieves a specified version of a table.
  ##   body: JObject (required)
  var body_402657619 = newJObject()
  if body != nil:
    body_402657619 = body
  result = call_402657618.call(nil, nil, nil, nil, body_402657619)

var getTableVersion* = Call_GetTableVersion_402657605(name: "getTableVersion",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTableVersion",
    validator: validate_GetTableVersion_402657606, base: "/",
    makeUrl: url_GetTableVersion_402657607, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTableVersions_402657620 = ref object of OpenApiRestCall_402656044
proc url_GetTableVersions_402657622(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTableVersions_402657621(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of strings that identify available versions of a specified table.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657623 = query.getOrDefault("MaxResults")
  valid_402657623 = validateParameter(valid_402657623, JString,
                                      required = false, default = nil)
  if valid_402657623 != nil:
    section.add "MaxResults", valid_402657623
  var valid_402657624 = query.getOrDefault("NextToken")
  valid_402657624 = validateParameter(valid_402657624, JString,
                                      required = false, default = nil)
  if valid_402657624 != nil:
    section.add "NextToken", valid_402657624
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657625 = header.getOrDefault("X-Amz-Target")
  valid_402657625 = validateParameter(valid_402657625, JString, required = true, default = newJString(
      "AWSGlue.GetTableVersions"))
  if valid_402657625 != nil:
    section.add "X-Amz-Target", valid_402657625
  var valid_402657626 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657626 = validateParameter(valid_402657626, JString,
                                      required = false, default = nil)
  if valid_402657626 != nil:
    section.add "X-Amz-Security-Token", valid_402657626
  var valid_402657627 = header.getOrDefault("X-Amz-Signature")
  valid_402657627 = validateParameter(valid_402657627, JString,
                                      required = false, default = nil)
  if valid_402657627 != nil:
    section.add "X-Amz-Signature", valid_402657627
  var valid_402657628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657628 = validateParameter(valid_402657628, JString,
                                      required = false, default = nil)
  if valid_402657628 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657628
  var valid_402657629 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657629 = validateParameter(valid_402657629, JString,
                                      required = false, default = nil)
  if valid_402657629 != nil:
    section.add "X-Amz-Algorithm", valid_402657629
  var valid_402657630 = header.getOrDefault("X-Amz-Date")
  valid_402657630 = validateParameter(valid_402657630, JString,
                                      required = false, default = nil)
  if valid_402657630 != nil:
    section.add "X-Amz-Date", valid_402657630
  var valid_402657631 = header.getOrDefault("X-Amz-Credential")
  valid_402657631 = validateParameter(valid_402657631, JString,
                                      required = false, default = nil)
  if valid_402657631 != nil:
    section.add "X-Amz-Credential", valid_402657631
  var valid_402657632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657632 = validateParameter(valid_402657632, JString,
                                      required = false, default = nil)
  if valid_402657632 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657634: Call_GetTableVersions_402657620;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of strings that identify available versions of a specified table.
                                                                                         ## 
  let valid = call_402657634.validator(path, query, header, formData, body, _)
  let scheme = call_402657634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657634.makeUrl(scheme.get, call_402657634.host, call_402657634.base,
                                   call_402657634.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657634, uri, valid, _)

proc call*(call_402657635: Call_GetTableVersions_402657620; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTableVersions
  ## Retrieves a list of strings that identify available versions of a specified table.
  ##   
                                                                                       ## MaxResults: string
                                                                                       ##             
                                                                                       ## : 
                                                                                       ## Pagination 
                                                                                       ## limit
  ##   
                                                                                               ## body: JObject (required)
  ##   
                                                                                                                          ## NextToken: string
                                                                                                                          ##            
                                                                                                                          ## : 
                                                                                                                          ## Pagination 
                                                                                                                          ## token
  var query_402657636 = newJObject()
  var body_402657637 = newJObject()
  add(query_402657636, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657637 = body
  add(query_402657636, "NextToken", newJString(NextToken))
  result = call_402657635.call(nil, query_402657636, nil, nil, body_402657637)

var getTableVersions* = Call_GetTableVersions_402657620(
    name: "getTableVersions", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTableVersions",
    validator: validate_GetTableVersions_402657621, base: "/",
    makeUrl: url_GetTableVersions_402657622,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTables_402657638 = ref object of OpenApiRestCall_402656044
proc url_GetTables_402657640(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTables_402657639(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657641 = query.getOrDefault("MaxResults")
  valid_402657641 = validateParameter(valid_402657641, JString,
                                      required = false, default = nil)
  if valid_402657641 != nil:
    section.add "MaxResults", valid_402657641
  var valid_402657642 = query.getOrDefault("NextToken")
  valid_402657642 = validateParameter(valid_402657642, JString,
                                      required = false, default = nil)
  if valid_402657642 != nil:
    section.add "NextToken", valid_402657642
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657643 = header.getOrDefault("X-Amz-Target")
  valid_402657643 = validateParameter(valid_402657643, JString, required = true,
                                      default = newJString("AWSGlue.GetTables"))
  if valid_402657643 != nil:
    section.add "X-Amz-Target", valid_402657643
  var valid_402657644 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657644 = validateParameter(valid_402657644, JString,
                                      required = false, default = nil)
  if valid_402657644 != nil:
    section.add "X-Amz-Security-Token", valid_402657644
  var valid_402657645 = header.getOrDefault("X-Amz-Signature")
  valid_402657645 = validateParameter(valid_402657645, JString,
                                      required = false, default = nil)
  if valid_402657645 != nil:
    section.add "X-Amz-Signature", valid_402657645
  var valid_402657646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657646 = validateParameter(valid_402657646, JString,
                                      required = false, default = nil)
  if valid_402657646 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657646
  var valid_402657647 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657647 = validateParameter(valid_402657647, JString,
                                      required = false, default = nil)
  if valid_402657647 != nil:
    section.add "X-Amz-Algorithm", valid_402657647
  var valid_402657648 = header.getOrDefault("X-Amz-Date")
  valid_402657648 = validateParameter(valid_402657648, JString,
                                      required = false, default = nil)
  if valid_402657648 != nil:
    section.add "X-Amz-Date", valid_402657648
  var valid_402657649 = header.getOrDefault("X-Amz-Credential")
  valid_402657649 = validateParameter(valid_402657649, JString,
                                      required = false, default = nil)
  if valid_402657649 != nil:
    section.add "X-Amz-Credential", valid_402657649
  var valid_402657650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657650 = validateParameter(valid_402657650, JString,
                                      required = false, default = nil)
  if valid_402657650 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657652: Call_GetTables_402657638; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
                                                                                         ## 
  let valid = call_402657652.validator(path, query, header, formData, body, _)
  let scheme = call_402657652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657652.makeUrl(scheme.get, call_402657652.host, call_402657652.base,
                                   call_402657652.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657652, uri, valid, _)

proc call*(call_402657653: Call_GetTables_402657638; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTables
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ##   
                                                                                             ## MaxResults: string
                                                                                             ##             
                                                                                             ## : 
                                                                                             ## Pagination 
                                                                                             ## limit
  ##   
                                                                                                     ## body: JObject (required)
  ##   
                                                                                                                                ## NextToken: string
                                                                                                                                ##            
                                                                                                                                ## : 
                                                                                                                                ## Pagination 
                                                                                                                                ## token
  var query_402657654 = newJObject()
  var body_402657655 = newJObject()
  add(query_402657654, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657655 = body
  add(query_402657654, "NextToken", newJString(NextToken))
  result = call_402657653.call(nil, query_402657654, nil, nil, body_402657655)

var getTables* = Call_GetTables_402657638(name: "getTables",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTables", validator: validate_GetTables_402657639,
    base: "/", makeUrl: url_GetTables_402657640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_402657656 = ref object of OpenApiRestCall_402656044
proc url_GetTags_402657658(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTags_402657657(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of tags associated with a resource.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657659 = header.getOrDefault("X-Amz-Target")
  valid_402657659 = validateParameter(valid_402657659, JString, required = true,
                                      default = newJString("AWSGlue.GetTags"))
  if valid_402657659 != nil:
    section.add "X-Amz-Target", valid_402657659
  var valid_402657660 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657660 = validateParameter(valid_402657660, JString,
                                      required = false, default = nil)
  if valid_402657660 != nil:
    section.add "X-Amz-Security-Token", valid_402657660
  var valid_402657661 = header.getOrDefault("X-Amz-Signature")
  valid_402657661 = validateParameter(valid_402657661, JString,
                                      required = false, default = nil)
  if valid_402657661 != nil:
    section.add "X-Amz-Signature", valid_402657661
  var valid_402657662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657662 = validateParameter(valid_402657662, JString,
                                      required = false, default = nil)
  if valid_402657662 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657662
  var valid_402657663 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657663 = validateParameter(valid_402657663, JString,
                                      required = false, default = nil)
  if valid_402657663 != nil:
    section.add "X-Amz-Algorithm", valid_402657663
  var valid_402657664 = header.getOrDefault("X-Amz-Date")
  valid_402657664 = validateParameter(valid_402657664, JString,
                                      required = false, default = nil)
  if valid_402657664 != nil:
    section.add "X-Amz-Date", valid_402657664
  var valid_402657665 = header.getOrDefault("X-Amz-Credential")
  valid_402657665 = validateParameter(valid_402657665, JString,
                                      required = false, default = nil)
  if valid_402657665 != nil:
    section.add "X-Amz-Credential", valid_402657665
  var valid_402657666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657666 = validateParameter(valid_402657666, JString,
                                      required = false, default = nil)
  if valid_402657666 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657668: Call_GetTags_402657656; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of tags associated with a resource.
                                                                                         ## 
  let valid = call_402657668.validator(path, query, header, formData, body, _)
  let scheme = call_402657668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657668.makeUrl(scheme.get, call_402657668.host, call_402657668.base,
                                   call_402657668.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657668, uri, valid, _)

proc call*(call_402657669: Call_GetTags_402657656; body: JsonNode): Recallable =
  ## getTags
  ## Retrieves a list of tags associated with a resource.
  ##   body: JObject (required)
  var body_402657670 = newJObject()
  if body != nil:
    body_402657670 = body
  result = call_402657669.call(nil, nil, nil, nil, body_402657670)

var getTags* = Call_GetTags_402657656(name: "getTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com",
                                      route: "/#X-Amz-Target=AWSGlue.GetTags",
                                      validator: validate_GetTags_402657657,
                                      base: "/", makeUrl: url_GetTags_402657658,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrigger_402657671 = ref object of OpenApiRestCall_402656044
proc url_GetTrigger_402657673(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTrigger_402657672(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the definition of a trigger.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657674 = header.getOrDefault("X-Amz-Target")
  valid_402657674 = validateParameter(valid_402657674, JString, required = true, default = newJString(
      "AWSGlue.GetTrigger"))
  if valid_402657674 != nil:
    section.add "X-Amz-Target", valid_402657674
  var valid_402657675 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657675 = validateParameter(valid_402657675, JString,
                                      required = false, default = nil)
  if valid_402657675 != nil:
    section.add "X-Amz-Security-Token", valid_402657675
  var valid_402657676 = header.getOrDefault("X-Amz-Signature")
  valid_402657676 = validateParameter(valid_402657676, JString,
                                      required = false, default = nil)
  if valid_402657676 != nil:
    section.add "X-Amz-Signature", valid_402657676
  var valid_402657677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657677 = validateParameter(valid_402657677, JString,
                                      required = false, default = nil)
  if valid_402657677 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657677
  var valid_402657678 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657678 = validateParameter(valid_402657678, JString,
                                      required = false, default = nil)
  if valid_402657678 != nil:
    section.add "X-Amz-Algorithm", valid_402657678
  var valid_402657679 = header.getOrDefault("X-Amz-Date")
  valid_402657679 = validateParameter(valid_402657679, JString,
                                      required = false, default = nil)
  if valid_402657679 != nil:
    section.add "X-Amz-Date", valid_402657679
  var valid_402657680 = header.getOrDefault("X-Amz-Credential")
  valid_402657680 = validateParameter(valid_402657680, JString,
                                      required = false, default = nil)
  if valid_402657680 != nil:
    section.add "X-Amz-Credential", valid_402657680
  var valid_402657681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657681 = validateParameter(valid_402657681, JString,
                                      required = false, default = nil)
  if valid_402657681 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657683: Call_GetTrigger_402657671; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the definition of a trigger.
                                                                                         ## 
  let valid = call_402657683.validator(path, query, header, formData, body, _)
  let scheme = call_402657683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657683.makeUrl(scheme.get, call_402657683.host, call_402657683.base,
                                   call_402657683.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657683, uri, valid, _)

proc call*(call_402657684: Call_GetTrigger_402657671; body: JsonNode): Recallable =
  ## getTrigger
  ## Retrieves the definition of a trigger.
  ##   body: JObject (required)
  var body_402657685 = newJObject()
  if body != nil:
    body_402657685 = body
  result = call_402657684.call(nil, nil, nil, nil, body_402657685)

var getTrigger* = Call_GetTrigger_402657671(name: "getTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTrigger", validator: validate_GetTrigger_402657672,
    base: "/", makeUrl: url_GetTrigger_402657673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTriggers_402657686 = ref object of OpenApiRestCall_402656044
proc url_GetTriggers_402657688(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTriggers_402657687(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets all the triggers associated with a job.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657689 = query.getOrDefault("MaxResults")
  valid_402657689 = validateParameter(valid_402657689, JString,
                                      required = false, default = nil)
  if valid_402657689 != nil:
    section.add "MaxResults", valid_402657689
  var valid_402657690 = query.getOrDefault("NextToken")
  valid_402657690 = validateParameter(valid_402657690, JString,
                                      required = false, default = nil)
  if valid_402657690 != nil:
    section.add "NextToken", valid_402657690
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657691 = header.getOrDefault("X-Amz-Target")
  valid_402657691 = validateParameter(valid_402657691, JString, required = true, default = newJString(
      "AWSGlue.GetTriggers"))
  if valid_402657691 != nil:
    section.add "X-Amz-Target", valid_402657691
  var valid_402657692 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657692 = validateParameter(valid_402657692, JString,
                                      required = false, default = nil)
  if valid_402657692 != nil:
    section.add "X-Amz-Security-Token", valid_402657692
  var valid_402657693 = header.getOrDefault("X-Amz-Signature")
  valid_402657693 = validateParameter(valid_402657693, JString,
                                      required = false, default = nil)
  if valid_402657693 != nil:
    section.add "X-Amz-Signature", valid_402657693
  var valid_402657694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657694 = validateParameter(valid_402657694, JString,
                                      required = false, default = nil)
  if valid_402657694 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657694
  var valid_402657695 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657695 = validateParameter(valid_402657695, JString,
                                      required = false, default = nil)
  if valid_402657695 != nil:
    section.add "X-Amz-Algorithm", valid_402657695
  var valid_402657696 = header.getOrDefault("X-Amz-Date")
  valid_402657696 = validateParameter(valid_402657696, JString,
                                      required = false, default = nil)
  if valid_402657696 != nil:
    section.add "X-Amz-Date", valid_402657696
  var valid_402657697 = header.getOrDefault("X-Amz-Credential")
  valid_402657697 = validateParameter(valid_402657697, JString,
                                      required = false, default = nil)
  if valid_402657697 != nil:
    section.add "X-Amz-Credential", valid_402657697
  var valid_402657698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657698 = validateParameter(valid_402657698, JString,
                                      required = false, default = nil)
  if valid_402657698 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657700: Call_GetTriggers_402657686; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets all the triggers associated with a job.
                                                                                         ## 
  let valid = call_402657700.validator(path, query, header, formData, body, _)
  let scheme = call_402657700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657700.makeUrl(scheme.get, call_402657700.host, call_402657700.base,
                                   call_402657700.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657700, uri, valid, _)

proc call*(call_402657701: Call_GetTriggers_402657686; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTriggers
  ## Gets all the triggers associated with a job.
  ##   MaxResults: string
                                                 ##             : Pagination limit
  ##   
                                                                                  ## body: JObject (required)
  ##   
                                                                                                             ## NextToken: string
                                                                                                             ##            
                                                                                                             ## : 
                                                                                                             ## Pagination 
                                                                                                             ## token
  var query_402657702 = newJObject()
  var body_402657703 = newJObject()
  add(query_402657702, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657703 = body
  add(query_402657702, "NextToken", newJString(NextToken))
  result = call_402657701.call(nil, query_402657702, nil, nil, body_402657703)

var getTriggers* = Call_GetTriggers_402657686(name: "getTriggers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTriggers",
    validator: validate_GetTriggers_402657687, base: "/",
    makeUrl: url_GetTriggers_402657688, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserDefinedFunction_402657704 = ref object of OpenApiRestCall_402656044
proc url_GetUserDefinedFunction_402657706(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUserDefinedFunction_402657705(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a specified function definition from the Data Catalog.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657707 = header.getOrDefault("X-Amz-Target")
  valid_402657707 = validateParameter(valid_402657707, JString, required = true, default = newJString(
      "AWSGlue.GetUserDefinedFunction"))
  if valid_402657707 != nil:
    section.add "X-Amz-Target", valid_402657707
  var valid_402657708 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657708 = validateParameter(valid_402657708, JString,
                                      required = false, default = nil)
  if valid_402657708 != nil:
    section.add "X-Amz-Security-Token", valid_402657708
  var valid_402657709 = header.getOrDefault("X-Amz-Signature")
  valid_402657709 = validateParameter(valid_402657709, JString,
                                      required = false, default = nil)
  if valid_402657709 != nil:
    section.add "X-Amz-Signature", valid_402657709
  var valid_402657710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657710 = validateParameter(valid_402657710, JString,
                                      required = false, default = nil)
  if valid_402657710 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657710
  var valid_402657711 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657711 = validateParameter(valid_402657711, JString,
                                      required = false, default = nil)
  if valid_402657711 != nil:
    section.add "X-Amz-Algorithm", valid_402657711
  var valid_402657712 = header.getOrDefault("X-Amz-Date")
  valid_402657712 = validateParameter(valid_402657712, JString,
                                      required = false, default = nil)
  if valid_402657712 != nil:
    section.add "X-Amz-Date", valid_402657712
  var valid_402657713 = header.getOrDefault("X-Amz-Credential")
  valid_402657713 = validateParameter(valid_402657713, JString,
                                      required = false, default = nil)
  if valid_402657713 != nil:
    section.add "X-Amz-Credential", valid_402657713
  var valid_402657714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657714 = validateParameter(valid_402657714, JString,
                                      required = false, default = nil)
  if valid_402657714 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657716: Call_GetUserDefinedFunction_402657704;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a specified function definition from the Data Catalog.
                                                                                         ## 
  let valid = call_402657716.validator(path, query, header, formData, body, _)
  let scheme = call_402657716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657716.makeUrl(scheme.get, call_402657716.host, call_402657716.base,
                                   call_402657716.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657716, uri, valid, _)

proc call*(call_402657717: Call_GetUserDefinedFunction_402657704; body: JsonNode): Recallable =
  ## getUserDefinedFunction
  ## Retrieves a specified function definition from the Data Catalog.
  ##   body: JObject (required)
  var body_402657718 = newJObject()
  if body != nil:
    body_402657718 = body
  result = call_402657717.call(nil, nil, nil, nil, body_402657718)

var getUserDefinedFunction* = Call_GetUserDefinedFunction_402657704(
    name: "getUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetUserDefinedFunction",
    validator: validate_GetUserDefinedFunction_402657705, base: "/",
    makeUrl: url_GetUserDefinedFunction_402657706,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserDefinedFunctions_402657719 = ref object of OpenApiRestCall_402656044
proc url_GetUserDefinedFunctions_402657721(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUserDefinedFunctions_402657720(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves multiple function definitions from the Data Catalog.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657722 = query.getOrDefault("MaxResults")
  valid_402657722 = validateParameter(valid_402657722, JString,
                                      required = false, default = nil)
  if valid_402657722 != nil:
    section.add "MaxResults", valid_402657722
  var valid_402657723 = query.getOrDefault("NextToken")
  valid_402657723 = validateParameter(valid_402657723, JString,
                                      required = false, default = nil)
  if valid_402657723 != nil:
    section.add "NextToken", valid_402657723
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657724 = header.getOrDefault("X-Amz-Target")
  valid_402657724 = validateParameter(valid_402657724, JString, required = true, default = newJString(
      "AWSGlue.GetUserDefinedFunctions"))
  if valid_402657724 != nil:
    section.add "X-Amz-Target", valid_402657724
  var valid_402657725 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657725 = validateParameter(valid_402657725, JString,
                                      required = false, default = nil)
  if valid_402657725 != nil:
    section.add "X-Amz-Security-Token", valid_402657725
  var valid_402657726 = header.getOrDefault("X-Amz-Signature")
  valid_402657726 = validateParameter(valid_402657726, JString,
                                      required = false, default = nil)
  if valid_402657726 != nil:
    section.add "X-Amz-Signature", valid_402657726
  var valid_402657727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657727 = validateParameter(valid_402657727, JString,
                                      required = false, default = nil)
  if valid_402657727 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657727
  var valid_402657728 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657728 = validateParameter(valid_402657728, JString,
                                      required = false, default = nil)
  if valid_402657728 != nil:
    section.add "X-Amz-Algorithm", valid_402657728
  var valid_402657729 = header.getOrDefault("X-Amz-Date")
  valid_402657729 = validateParameter(valid_402657729, JString,
                                      required = false, default = nil)
  if valid_402657729 != nil:
    section.add "X-Amz-Date", valid_402657729
  var valid_402657730 = header.getOrDefault("X-Amz-Credential")
  valid_402657730 = validateParameter(valid_402657730, JString,
                                      required = false, default = nil)
  if valid_402657730 != nil:
    section.add "X-Amz-Credential", valid_402657730
  var valid_402657731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657731 = validateParameter(valid_402657731, JString,
                                      required = false, default = nil)
  if valid_402657731 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657733: Call_GetUserDefinedFunctions_402657719;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves multiple function definitions from the Data Catalog.
                                                                                         ## 
  let valid = call_402657733.validator(path, query, header, formData, body, _)
  let scheme = call_402657733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657733.makeUrl(scheme.get, call_402657733.host, call_402657733.base,
                                   call_402657733.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657733, uri, valid, _)

proc call*(call_402657734: Call_GetUserDefinedFunctions_402657719;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getUserDefinedFunctions
  ## Retrieves multiple function definitions from the Data Catalog.
  ##   MaxResults: string
                                                                   ##             : Pagination limit
  ##   
                                                                                                    ## body: JObject (required)
  ##   
                                                                                                                               ## NextToken: string
                                                                                                                               ##            
                                                                                                                               ## : 
                                                                                                                               ## Pagination 
                                                                                                                               ## token
  var query_402657735 = newJObject()
  var body_402657736 = newJObject()
  add(query_402657735, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657736 = body
  add(query_402657735, "NextToken", newJString(NextToken))
  result = call_402657734.call(nil, query_402657735, nil, nil, body_402657736)

var getUserDefinedFunctions* = Call_GetUserDefinedFunctions_402657719(
    name: "getUserDefinedFunctions", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetUserDefinedFunctions",
    validator: validate_GetUserDefinedFunctions_402657720, base: "/",
    makeUrl: url_GetUserDefinedFunctions_402657721,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflow_402657737 = ref object of OpenApiRestCall_402656044
proc url_GetWorkflow_402657739(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetWorkflow_402657738(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves resource metadata for a workflow.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657740 = header.getOrDefault("X-Amz-Target")
  valid_402657740 = validateParameter(valid_402657740, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflow"))
  if valid_402657740 != nil:
    section.add "X-Amz-Target", valid_402657740
  var valid_402657741 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657741 = validateParameter(valid_402657741, JString,
                                      required = false, default = nil)
  if valid_402657741 != nil:
    section.add "X-Amz-Security-Token", valid_402657741
  var valid_402657742 = header.getOrDefault("X-Amz-Signature")
  valid_402657742 = validateParameter(valid_402657742, JString,
                                      required = false, default = nil)
  if valid_402657742 != nil:
    section.add "X-Amz-Signature", valid_402657742
  var valid_402657743 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657743 = validateParameter(valid_402657743, JString,
                                      required = false, default = nil)
  if valid_402657743 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657743
  var valid_402657744 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657744 = validateParameter(valid_402657744, JString,
                                      required = false, default = nil)
  if valid_402657744 != nil:
    section.add "X-Amz-Algorithm", valid_402657744
  var valid_402657745 = header.getOrDefault("X-Amz-Date")
  valid_402657745 = validateParameter(valid_402657745, JString,
                                      required = false, default = nil)
  if valid_402657745 != nil:
    section.add "X-Amz-Date", valid_402657745
  var valid_402657746 = header.getOrDefault("X-Amz-Credential")
  valid_402657746 = validateParameter(valid_402657746, JString,
                                      required = false, default = nil)
  if valid_402657746 != nil:
    section.add "X-Amz-Credential", valid_402657746
  var valid_402657747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657747 = validateParameter(valid_402657747, JString,
                                      required = false, default = nil)
  if valid_402657747 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657747
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657749: Call_GetWorkflow_402657737; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves resource metadata for a workflow.
                                                                                         ## 
  let valid = call_402657749.validator(path, query, header, formData, body, _)
  let scheme = call_402657749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657749.makeUrl(scheme.get, call_402657749.host, call_402657749.base,
                                   call_402657749.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657749, uri, valid, _)

proc call*(call_402657750: Call_GetWorkflow_402657737; body: JsonNode): Recallable =
  ## getWorkflow
  ## Retrieves resource metadata for a workflow.
  ##   body: JObject (required)
  var body_402657751 = newJObject()
  if body != nil:
    body_402657751 = body
  result = call_402657750.call(nil, nil, nil, nil, body_402657751)

var getWorkflow* = Call_GetWorkflow_402657737(name: "getWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflow",
    validator: validate_GetWorkflow_402657738, base: "/",
    makeUrl: url_GetWorkflow_402657739, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRun_402657752 = ref object of OpenApiRestCall_402656044
proc url_GetWorkflowRun_402657754(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetWorkflowRun_402657753(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the metadata for a given workflow run. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657755 = header.getOrDefault("X-Amz-Target")
  valid_402657755 = validateParameter(valid_402657755, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRun"))
  if valid_402657755 != nil:
    section.add "X-Amz-Target", valid_402657755
  var valid_402657756 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657756 = validateParameter(valid_402657756, JString,
                                      required = false, default = nil)
  if valid_402657756 != nil:
    section.add "X-Amz-Security-Token", valid_402657756
  var valid_402657757 = header.getOrDefault("X-Amz-Signature")
  valid_402657757 = validateParameter(valid_402657757, JString,
                                      required = false, default = nil)
  if valid_402657757 != nil:
    section.add "X-Amz-Signature", valid_402657757
  var valid_402657758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657758 = validateParameter(valid_402657758, JString,
                                      required = false, default = nil)
  if valid_402657758 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657758
  var valid_402657759 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657759 = validateParameter(valid_402657759, JString,
                                      required = false, default = nil)
  if valid_402657759 != nil:
    section.add "X-Amz-Algorithm", valid_402657759
  var valid_402657760 = header.getOrDefault("X-Amz-Date")
  valid_402657760 = validateParameter(valid_402657760, JString,
                                      required = false, default = nil)
  if valid_402657760 != nil:
    section.add "X-Amz-Date", valid_402657760
  var valid_402657761 = header.getOrDefault("X-Amz-Credential")
  valid_402657761 = validateParameter(valid_402657761, JString,
                                      required = false, default = nil)
  if valid_402657761 != nil:
    section.add "X-Amz-Credential", valid_402657761
  var valid_402657762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657762 = validateParameter(valid_402657762, JString,
                                      required = false, default = nil)
  if valid_402657762 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657764: Call_GetWorkflowRun_402657752; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the metadata for a given workflow run. 
                                                                                         ## 
  let valid = call_402657764.validator(path, query, header, formData, body, _)
  let scheme = call_402657764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657764.makeUrl(scheme.get, call_402657764.host, call_402657764.base,
                                   call_402657764.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657764, uri, valid, _)

proc call*(call_402657765: Call_GetWorkflowRun_402657752; body: JsonNode): Recallable =
  ## getWorkflowRun
  ## Retrieves the metadata for a given workflow run. 
  ##   body: JObject (required)
  var body_402657766 = newJObject()
  if body != nil:
    body_402657766 = body
  result = call_402657765.call(nil, nil, nil, nil, body_402657766)

var getWorkflowRun* = Call_GetWorkflowRun_402657752(name: "getWorkflowRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRun",
    validator: validate_GetWorkflowRun_402657753, base: "/",
    makeUrl: url_GetWorkflowRun_402657754, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRunProperties_402657767 = ref object of OpenApiRestCall_402656044
proc url_GetWorkflowRunProperties_402657769(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetWorkflowRunProperties_402657768(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves the workflow run properties which were set during the run.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657770 = header.getOrDefault("X-Amz-Target")
  valid_402657770 = validateParameter(valid_402657770, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRunProperties"))
  if valid_402657770 != nil:
    section.add "X-Amz-Target", valid_402657770
  var valid_402657771 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657771 = validateParameter(valid_402657771, JString,
                                      required = false, default = nil)
  if valid_402657771 != nil:
    section.add "X-Amz-Security-Token", valid_402657771
  var valid_402657772 = header.getOrDefault("X-Amz-Signature")
  valid_402657772 = validateParameter(valid_402657772, JString,
                                      required = false, default = nil)
  if valid_402657772 != nil:
    section.add "X-Amz-Signature", valid_402657772
  var valid_402657773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657773 = validateParameter(valid_402657773, JString,
                                      required = false, default = nil)
  if valid_402657773 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657773
  var valid_402657774 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657774 = validateParameter(valid_402657774, JString,
                                      required = false, default = nil)
  if valid_402657774 != nil:
    section.add "X-Amz-Algorithm", valid_402657774
  var valid_402657775 = header.getOrDefault("X-Amz-Date")
  valid_402657775 = validateParameter(valid_402657775, JString,
                                      required = false, default = nil)
  if valid_402657775 != nil:
    section.add "X-Amz-Date", valid_402657775
  var valid_402657776 = header.getOrDefault("X-Amz-Credential")
  valid_402657776 = validateParameter(valid_402657776, JString,
                                      required = false, default = nil)
  if valid_402657776 != nil:
    section.add "X-Amz-Credential", valid_402657776
  var valid_402657777 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657777 = validateParameter(valid_402657777, JString,
                                      required = false, default = nil)
  if valid_402657777 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657777
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657779: Call_GetWorkflowRunProperties_402657767;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the workflow run properties which were set during the run.
                                                                                         ## 
  let valid = call_402657779.validator(path, query, header, formData, body, _)
  let scheme = call_402657779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657779.makeUrl(scheme.get, call_402657779.host, call_402657779.base,
                                   call_402657779.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657779, uri, valid, _)

proc call*(call_402657780: Call_GetWorkflowRunProperties_402657767;
           body: JsonNode): Recallable =
  ## getWorkflowRunProperties
  ## Retrieves the workflow run properties which were set during the run.
  ##   body: JObject 
                                                                         ## (required)
  var body_402657781 = newJObject()
  if body != nil:
    body_402657781 = body
  result = call_402657780.call(nil, nil, nil, nil, body_402657781)

var getWorkflowRunProperties* = Call_GetWorkflowRunProperties_402657767(
    name: "getWorkflowRunProperties", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRunProperties",
    validator: validate_GetWorkflowRunProperties_402657768, base: "/",
    makeUrl: url_GetWorkflowRunProperties_402657769,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRuns_402657782 = ref object of OpenApiRestCall_402656044
proc url_GetWorkflowRuns_402657784(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetWorkflowRuns_402657783(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves metadata for all runs of a given workflow.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657785 = query.getOrDefault("MaxResults")
  valid_402657785 = validateParameter(valid_402657785, JString,
                                      required = false, default = nil)
  if valid_402657785 != nil:
    section.add "MaxResults", valid_402657785
  var valid_402657786 = query.getOrDefault("NextToken")
  valid_402657786 = validateParameter(valid_402657786, JString,
                                      required = false, default = nil)
  if valid_402657786 != nil:
    section.add "NextToken", valid_402657786
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657787 = header.getOrDefault("X-Amz-Target")
  valid_402657787 = validateParameter(valid_402657787, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRuns"))
  if valid_402657787 != nil:
    section.add "X-Amz-Target", valid_402657787
  var valid_402657788 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657788 = validateParameter(valid_402657788, JString,
                                      required = false, default = nil)
  if valid_402657788 != nil:
    section.add "X-Amz-Security-Token", valid_402657788
  var valid_402657789 = header.getOrDefault("X-Amz-Signature")
  valid_402657789 = validateParameter(valid_402657789, JString,
                                      required = false, default = nil)
  if valid_402657789 != nil:
    section.add "X-Amz-Signature", valid_402657789
  var valid_402657790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657790 = validateParameter(valid_402657790, JString,
                                      required = false, default = nil)
  if valid_402657790 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657790
  var valid_402657791 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657791 = validateParameter(valid_402657791, JString,
                                      required = false, default = nil)
  if valid_402657791 != nil:
    section.add "X-Amz-Algorithm", valid_402657791
  var valid_402657792 = header.getOrDefault("X-Amz-Date")
  valid_402657792 = validateParameter(valid_402657792, JString,
                                      required = false, default = nil)
  if valid_402657792 != nil:
    section.add "X-Amz-Date", valid_402657792
  var valid_402657793 = header.getOrDefault("X-Amz-Credential")
  valid_402657793 = validateParameter(valid_402657793, JString,
                                      required = false, default = nil)
  if valid_402657793 != nil:
    section.add "X-Amz-Credential", valid_402657793
  var valid_402657794 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657794 = validateParameter(valid_402657794, JString,
                                      required = false, default = nil)
  if valid_402657794 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657794
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657796: Call_GetWorkflowRuns_402657782; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves metadata for all runs of a given workflow.
                                                                                         ## 
  let valid = call_402657796.validator(path, query, header, formData, body, _)
  let scheme = call_402657796.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657796.makeUrl(scheme.get, call_402657796.host, call_402657796.base,
                                   call_402657796.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657796, uri, valid, _)

proc call*(call_402657797: Call_GetWorkflowRuns_402657782; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getWorkflowRuns
  ## Retrieves metadata for all runs of a given workflow.
  ##   MaxResults: string
                                                         ##             : Pagination limit
  ##   
                                                                                          ## body: JObject (required)
  ##   
                                                                                                                     ## NextToken: string
                                                                                                                     ##            
                                                                                                                     ## : 
                                                                                                                     ## Pagination 
                                                                                                                     ## token
  var query_402657798 = newJObject()
  var body_402657799 = newJObject()
  add(query_402657798, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657799 = body
  add(query_402657798, "NextToken", newJString(NextToken))
  result = call_402657797.call(nil, query_402657798, nil, nil, body_402657799)

var getWorkflowRuns* = Call_GetWorkflowRuns_402657782(name: "getWorkflowRuns",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRuns",
    validator: validate_GetWorkflowRuns_402657783, base: "/",
    makeUrl: url_GetWorkflowRuns_402657784, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportCatalogToGlue_402657800 = ref object of OpenApiRestCall_402656044
proc url_ImportCatalogToGlue_402657802(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportCatalogToGlue_402657801(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657803 = header.getOrDefault("X-Amz-Target")
  valid_402657803 = validateParameter(valid_402657803, JString, required = true, default = newJString(
      "AWSGlue.ImportCatalogToGlue"))
  if valid_402657803 != nil:
    section.add "X-Amz-Target", valid_402657803
  var valid_402657804 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657804 = validateParameter(valid_402657804, JString,
                                      required = false, default = nil)
  if valid_402657804 != nil:
    section.add "X-Amz-Security-Token", valid_402657804
  var valid_402657805 = header.getOrDefault("X-Amz-Signature")
  valid_402657805 = validateParameter(valid_402657805, JString,
                                      required = false, default = nil)
  if valid_402657805 != nil:
    section.add "X-Amz-Signature", valid_402657805
  var valid_402657806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657806 = validateParameter(valid_402657806, JString,
                                      required = false, default = nil)
  if valid_402657806 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657806
  var valid_402657807 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657807 = validateParameter(valid_402657807, JString,
                                      required = false, default = nil)
  if valid_402657807 != nil:
    section.add "X-Amz-Algorithm", valid_402657807
  var valid_402657808 = header.getOrDefault("X-Amz-Date")
  valid_402657808 = validateParameter(valid_402657808, JString,
                                      required = false, default = nil)
  if valid_402657808 != nil:
    section.add "X-Amz-Date", valid_402657808
  var valid_402657809 = header.getOrDefault("X-Amz-Credential")
  valid_402657809 = validateParameter(valid_402657809, JString,
                                      required = false, default = nil)
  if valid_402657809 != nil:
    section.add "X-Amz-Credential", valid_402657809
  var valid_402657810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657810 = validateParameter(valid_402657810, JString,
                                      required = false, default = nil)
  if valid_402657810 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657812: Call_ImportCatalogToGlue_402657800;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
                                                                                         ## 
  let valid = call_402657812.validator(path, query, header, formData, body, _)
  let scheme = call_402657812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657812.makeUrl(scheme.get, call_402657812.host, call_402657812.base,
                                   call_402657812.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657812, uri, valid, _)

proc call*(call_402657813: Call_ImportCatalogToGlue_402657800; body: JsonNode): Recallable =
  ## importCatalogToGlue
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
  ##   body: JObject (required)
  var body_402657814 = newJObject()
  if body != nil:
    body_402657814 = body
  result = call_402657813.call(nil, nil, nil, nil, body_402657814)

var importCatalogToGlue* = Call_ImportCatalogToGlue_402657800(
    name: "importCatalogToGlue", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ImportCatalogToGlue",
    validator: validate_ImportCatalogToGlue_402657801, base: "/",
    makeUrl: url_ImportCatalogToGlue_402657802,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCrawlers_402657815 = ref object of OpenApiRestCall_402656044
proc url_ListCrawlers_402657817(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCrawlers_402657816(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657818 = query.getOrDefault("MaxResults")
  valid_402657818 = validateParameter(valid_402657818, JString,
                                      required = false, default = nil)
  if valid_402657818 != nil:
    section.add "MaxResults", valid_402657818
  var valid_402657819 = query.getOrDefault("NextToken")
  valid_402657819 = validateParameter(valid_402657819, JString,
                                      required = false, default = nil)
  if valid_402657819 != nil:
    section.add "NextToken", valid_402657819
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657820 = header.getOrDefault("X-Amz-Target")
  valid_402657820 = validateParameter(valid_402657820, JString, required = true, default = newJString(
      "AWSGlue.ListCrawlers"))
  if valid_402657820 != nil:
    section.add "X-Amz-Target", valid_402657820
  var valid_402657821 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657821 = validateParameter(valid_402657821, JString,
                                      required = false, default = nil)
  if valid_402657821 != nil:
    section.add "X-Amz-Security-Token", valid_402657821
  var valid_402657822 = header.getOrDefault("X-Amz-Signature")
  valid_402657822 = validateParameter(valid_402657822, JString,
                                      required = false, default = nil)
  if valid_402657822 != nil:
    section.add "X-Amz-Signature", valid_402657822
  var valid_402657823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657823 = validateParameter(valid_402657823, JString,
                                      required = false, default = nil)
  if valid_402657823 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657823
  var valid_402657824 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657824 = validateParameter(valid_402657824, JString,
                                      required = false, default = nil)
  if valid_402657824 != nil:
    section.add "X-Amz-Algorithm", valid_402657824
  var valid_402657825 = header.getOrDefault("X-Amz-Date")
  valid_402657825 = validateParameter(valid_402657825, JString,
                                      required = false, default = nil)
  if valid_402657825 != nil:
    section.add "X-Amz-Date", valid_402657825
  var valid_402657826 = header.getOrDefault("X-Amz-Credential")
  valid_402657826 = validateParameter(valid_402657826, JString,
                                      required = false, default = nil)
  if valid_402657826 != nil:
    section.add "X-Amz-Credential", valid_402657826
  var valid_402657827 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657827 = validateParameter(valid_402657827, JString,
                                      required = false, default = nil)
  if valid_402657827 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657829: Call_ListCrawlers_402657815; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
                                                                                         ## 
  let valid = call_402657829.validator(path, query, header, formData, body, _)
  let scheme = call_402657829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657829.makeUrl(scheme.get, call_402657829.host, call_402657829.base,
                                   call_402657829.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657829, uri, valid, _)

proc call*(call_402657830: Call_ListCrawlers_402657815; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCrawlers
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## token
  var query_402657831 = newJObject()
  var body_402657832 = newJObject()
  add(query_402657831, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657832 = body
  add(query_402657831, "NextToken", newJString(NextToken))
  result = call_402657830.call(nil, query_402657831, nil, nil, body_402657832)

var listCrawlers* = Call_ListCrawlers_402657815(name: "listCrawlers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListCrawlers",
    validator: validate_ListCrawlers_402657816, base: "/",
    makeUrl: url_ListCrawlers_402657817, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevEndpoints_402657833 = ref object of OpenApiRestCall_402656044
proc url_ListDevEndpoints_402657835(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevEndpoints_402657834(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657836 = query.getOrDefault("MaxResults")
  valid_402657836 = validateParameter(valid_402657836, JString,
                                      required = false, default = nil)
  if valid_402657836 != nil:
    section.add "MaxResults", valid_402657836
  var valid_402657837 = query.getOrDefault("NextToken")
  valid_402657837 = validateParameter(valid_402657837, JString,
                                      required = false, default = nil)
  if valid_402657837 != nil:
    section.add "NextToken", valid_402657837
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657838 = header.getOrDefault("X-Amz-Target")
  valid_402657838 = validateParameter(valid_402657838, JString, required = true, default = newJString(
      "AWSGlue.ListDevEndpoints"))
  if valid_402657838 != nil:
    section.add "X-Amz-Target", valid_402657838
  var valid_402657839 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657839 = validateParameter(valid_402657839, JString,
                                      required = false, default = nil)
  if valid_402657839 != nil:
    section.add "X-Amz-Security-Token", valid_402657839
  var valid_402657840 = header.getOrDefault("X-Amz-Signature")
  valid_402657840 = validateParameter(valid_402657840, JString,
                                      required = false, default = nil)
  if valid_402657840 != nil:
    section.add "X-Amz-Signature", valid_402657840
  var valid_402657841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657841 = validateParameter(valid_402657841, JString,
                                      required = false, default = nil)
  if valid_402657841 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657841
  var valid_402657842 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657842 = validateParameter(valid_402657842, JString,
                                      required = false, default = nil)
  if valid_402657842 != nil:
    section.add "X-Amz-Algorithm", valid_402657842
  var valid_402657843 = header.getOrDefault("X-Amz-Date")
  valid_402657843 = validateParameter(valid_402657843, JString,
                                      required = false, default = nil)
  if valid_402657843 != nil:
    section.add "X-Amz-Date", valid_402657843
  var valid_402657844 = header.getOrDefault("X-Amz-Credential")
  valid_402657844 = validateParameter(valid_402657844, JString,
                                      required = false, default = nil)
  if valid_402657844 != nil:
    section.add "X-Amz-Credential", valid_402657844
  var valid_402657845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657845 = validateParameter(valid_402657845, JString,
                                      required = false, default = nil)
  if valid_402657845 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657847: Call_ListDevEndpoints_402657833;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
                                                                                         ## 
  let valid = call_402657847.validator(path, query, header, formData, body, _)
  let scheme = call_402657847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657847.makeUrl(scheme.get, call_402657847.host, call_402657847.base,
                                   call_402657847.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657847, uri, valid, _)

proc call*(call_402657848: Call_ListDevEndpoints_402657833; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDevEndpoints
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## token
  var query_402657849 = newJObject()
  var body_402657850 = newJObject()
  add(query_402657849, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657850 = body
  add(query_402657849, "NextToken", newJString(NextToken))
  result = call_402657848.call(nil, query_402657849, nil, nil, body_402657850)

var listDevEndpoints* = Call_ListDevEndpoints_402657833(
    name: "listDevEndpoints", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListDevEndpoints",
    validator: validate_ListDevEndpoints_402657834, base: "/",
    makeUrl: url_ListDevEndpoints_402657835,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_402657851 = ref object of OpenApiRestCall_402656044
proc url_ListJobs_402657853(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobs_402657852(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657854 = query.getOrDefault("MaxResults")
  valid_402657854 = validateParameter(valid_402657854, JString,
                                      required = false, default = nil)
  if valid_402657854 != nil:
    section.add "MaxResults", valid_402657854
  var valid_402657855 = query.getOrDefault("NextToken")
  valid_402657855 = validateParameter(valid_402657855, JString,
                                      required = false, default = nil)
  if valid_402657855 != nil:
    section.add "NextToken", valid_402657855
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657856 = header.getOrDefault("X-Amz-Target")
  valid_402657856 = validateParameter(valid_402657856, JString, required = true,
                                      default = newJString("AWSGlue.ListJobs"))
  if valid_402657856 != nil:
    section.add "X-Amz-Target", valid_402657856
  var valid_402657857 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657857 = validateParameter(valid_402657857, JString,
                                      required = false, default = nil)
  if valid_402657857 != nil:
    section.add "X-Amz-Security-Token", valid_402657857
  var valid_402657858 = header.getOrDefault("X-Amz-Signature")
  valid_402657858 = validateParameter(valid_402657858, JString,
                                      required = false, default = nil)
  if valid_402657858 != nil:
    section.add "X-Amz-Signature", valid_402657858
  var valid_402657859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657859 = validateParameter(valid_402657859, JString,
                                      required = false, default = nil)
  if valid_402657859 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657859
  var valid_402657860 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657860 = validateParameter(valid_402657860, JString,
                                      required = false, default = nil)
  if valid_402657860 != nil:
    section.add "X-Amz-Algorithm", valid_402657860
  var valid_402657861 = header.getOrDefault("X-Amz-Date")
  valid_402657861 = validateParameter(valid_402657861, JString,
                                      required = false, default = nil)
  if valid_402657861 != nil:
    section.add "X-Amz-Date", valid_402657861
  var valid_402657862 = header.getOrDefault("X-Amz-Credential")
  valid_402657862 = validateParameter(valid_402657862, JString,
                                      required = false, default = nil)
  if valid_402657862 != nil:
    section.add "X-Amz-Credential", valid_402657862
  var valid_402657863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657863 = validateParameter(valid_402657863, JString,
                                      required = false, default = nil)
  if valid_402657863 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657865: Call_ListJobs_402657851; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
                                                                                         ## 
  let valid = call_402657865.validator(path, query, header, formData, body, _)
  let scheme = call_402657865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657865.makeUrl(scheme.get, call_402657865.host, call_402657865.base,
                                   call_402657865.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657865, uri, valid, _)

proc call*(call_402657866: Call_ListJobs_402657851; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listJobs
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## token
  var query_402657867 = newJObject()
  var body_402657868 = newJObject()
  add(query_402657867, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657868 = body
  add(query_402657867, "NextToken", newJString(NextToken))
  result = call_402657866.call(nil, query_402657867, nil, nil, body_402657868)

var listJobs* = Call_ListJobs_402657851(name: "listJobs",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.ListJobs",
                                        validator: validate_ListJobs_402657852,
                                        base: "/", makeUrl: url_ListJobs_402657853,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTriggers_402657869 = ref object of OpenApiRestCall_402656044
proc url_ListTriggers_402657871(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTriggers_402657870(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657872 = query.getOrDefault("MaxResults")
  valid_402657872 = validateParameter(valid_402657872, JString,
                                      required = false, default = nil)
  if valid_402657872 != nil:
    section.add "MaxResults", valid_402657872
  var valid_402657873 = query.getOrDefault("NextToken")
  valid_402657873 = validateParameter(valid_402657873, JString,
                                      required = false, default = nil)
  if valid_402657873 != nil:
    section.add "NextToken", valid_402657873
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657874 = header.getOrDefault("X-Amz-Target")
  valid_402657874 = validateParameter(valid_402657874, JString, required = true, default = newJString(
      "AWSGlue.ListTriggers"))
  if valid_402657874 != nil:
    section.add "X-Amz-Target", valid_402657874
  var valid_402657875 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657875 = validateParameter(valid_402657875, JString,
                                      required = false, default = nil)
  if valid_402657875 != nil:
    section.add "X-Amz-Security-Token", valid_402657875
  var valid_402657876 = header.getOrDefault("X-Amz-Signature")
  valid_402657876 = validateParameter(valid_402657876, JString,
                                      required = false, default = nil)
  if valid_402657876 != nil:
    section.add "X-Amz-Signature", valid_402657876
  var valid_402657877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657877 = validateParameter(valid_402657877, JString,
                                      required = false, default = nil)
  if valid_402657877 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657877
  var valid_402657878 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657878 = validateParameter(valid_402657878, JString,
                                      required = false, default = nil)
  if valid_402657878 != nil:
    section.add "X-Amz-Algorithm", valid_402657878
  var valid_402657879 = header.getOrDefault("X-Amz-Date")
  valid_402657879 = validateParameter(valid_402657879, JString,
                                      required = false, default = nil)
  if valid_402657879 != nil:
    section.add "X-Amz-Date", valid_402657879
  var valid_402657880 = header.getOrDefault("X-Amz-Credential")
  valid_402657880 = validateParameter(valid_402657880, JString,
                                      required = false, default = nil)
  if valid_402657880 != nil:
    section.add "X-Amz-Credential", valid_402657880
  var valid_402657881 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657881 = validateParameter(valid_402657881, JString,
                                      required = false, default = nil)
  if valid_402657881 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657883: Call_ListTriggers_402657869; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
                                                                                         ## 
  let valid = call_402657883.validator(path, query, header, formData, body, _)
  let scheme = call_402657883.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657883.makeUrl(scheme.get, call_402657883.host, call_402657883.base,
                                   call_402657883.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657883, uri, valid, _)

proc call*(call_402657884: Call_ListTriggers_402657869; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTriggers
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## token
  var query_402657885 = newJObject()
  var body_402657886 = newJObject()
  add(query_402657885, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657886 = body
  add(query_402657885, "NextToken", newJString(NextToken))
  result = call_402657884.call(nil, query_402657885, nil, nil, body_402657886)

var listTriggers* = Call_ListTriggers_402657869(name: "listTriggers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListTriggers",
    validator: validate_ListTriggers_402657870, base: "/",
    makeUrl: url_ListTriggers_402657871, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkflows_402657887 = ref object of OpenApiRestCall_402656044
proc url_ListWorkflows_402657889(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListWorkflows_402657888(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists names of workflows created in the account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657890 = query.getOrDefault("MaxResults")
  valid_402657890 = validateParameter(valid_402657890, JString,
                                      required = false, default = nil)
  if valid_402657890 != nil:
    section.add "MaxResults", valid_402657890
  var valid_402657891 = query.getOrDefault("NextToken")
  valid_402657891 = validateParameter(valid_402657891, JString,
                                      required = false, default = nil)
  if valid_402657891 != nil:
    section.add "NextToken", valid_402657891
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657892 = header.getOrDefault("X-Amz-Target")
  valid_402657892 = validateParameter(valid_402657892, JString, required = true, default = newJString(
      "AWSGlue.ListWorkflows"))
  if valid_402657892 != nil:
    section.add "X-Amz-Target", valid_402657892
  var valid_402657893 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657893 = validateParameter(valid_402657893, JString,
                                      required = false, default = nil)
  if valid_402657893 != nil:
    section.add "X-Amz-Security-Token", valid_402657893
  var valid_402657894 = header.getOrDefault("X-Amz-Signature")
  valid_402657894 = validateParameter(valid_402657894, JString,
                                      required = false, default = nil)
  if valid_402657894 != nil:
    section.add "X-Amz-Signature", valid_402657894
  var valid_402657895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657895 = validateParameter(valid_402657895, JString,
                                      required = false, default = nil)
  if valid_402657895 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657895
  var valid_402657896 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657896 = validateParameter(valid_402657896, JString,
                                      required = false, default = nil)
  if valid_402657896 != nil:
    section.add "X-Amz-Algorithm", valid_402657896
  var valid_402657897 = header.getOrDefault("X-Amz-Date")
  valid_402657897 = validateParameter(valid_402657897, JString,
                                      required = false, default = nil)
  if valid_402657897 != nil:
    section.add "X-Amz-Date", valid_402657897
  var valid_402657898 = header.getOrDefault("X-Amz-Credential")
  valid_402657898 = validateParameter(valid_402657898, JString,
                                      required = false, default = nil)
  if valid_402657898 != nil:
    section.add "X-Amz-Credential", valid_402657898
  var valid_402657899 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657899 = validateParameter(valid_402657899, JString,
                                      required = false, default = nil)
  if valid_402657899 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657899
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657901: Call_ListWorkflows_402657887; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists names of workflows created in the account.
                                                                                         ## 
  let valid = call_402657901.validator(path, query, header, formData, body, _)
  let scheme = call_402657901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657901.makeUrl(scheme.get, call_402657901.host, call_402657901.base,
                                   call_402657901.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657901, uri, valid, _)

proc call*(call_402657902: Call_ListWorkflows_402657887; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWorkflows
  ## Lists names of workflows created in the account.
  ##   MaxResults: string
                                                     ##             : Pagination limit
  ##   
                                                                                      ## body: JObject (required)
  ##   
                                                                                                                 ## NextToken: string
                                                                                                                 ##            
                                                                                                                 ## : 
                                                                                                                 ## Pagination 
                                                                                                                 ## token
  var query_402657903 = newJObject()
  var body_402657904 = newJObject()
  add(query_402657903, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657904 = body
  add(query_402657903, "NextToken", newJString(NextToken))
  result = call_402657902.call(nil, query_402657903, nil, nil, body_402657904)

var listWorkflows* = Call_ListWorkflows_402657887(name: "listWorkflows",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListWorkflows",
    validator: validate_ListWorkflows_402657888, base: "/",
    makeUrl: url_ListWorkflows_402657889, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDataCatalogEncryptionSettings_402657905 = ref object of OpenApiRestCall_402656044
proc url_PutDataCatalogEncryptionSettings_402657907(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutDataCatalogEncryptionSettings_402657906(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657908 = header.getOrDefault("X-Amz-Target")
  valid_402657908 = validateParameter(valid_402657908, JString, required = true, default = newJString(
      "AWSGlue.PutDataCatalogEncryptionSettings"))
  if valid_402657908 != nil:
    section.add "X-Amz-Target", valid_402657908
  var valid_402657909 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657909 = validateParameter(valid_402657909, JString,
                                      required = false, default = nil)
  if valid_402657909 != nil:
    section.add "X-Amz-Security-Token", valid_402657909
  var valid_402657910 = header.getOrDefault("X-Amz-Signature")
  valid_402657910 = validateParameter(valid_402657910, JString,
                                      required = false, default = nil)
  if valid_402657910 != nil:
    section.add "X-Amz-Signature", valid_402657910
  var valid_402657911 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657911 = validateParameter(valid_402657911, JString,
                                      required = false, default = nil)
  if valid_402657911 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657911
  var valid_402657912 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657912 = validateParameter(valid_402657912, JString,
                                      required = false, default = nil)
  if valid_402657912 != nil:
    section.add "X-Amz-Algorithm", valid_402657912
  var valid_402657913 = header.getOrDefault("X-Amz-Date")
  valid_402657913 = validateParameter(valid_402657913, JString,
                                      required = false, default = nil)
  if valid_402657913 != nil:
    section.add "X-Amz-Date", valid_402657913
  var valid_402657914 = header.getOrDefault("X-Amz-Credential")
  valid_402657914 = validateParameter(valid_402657914, JString,
                                      required = false, default = nil)
  if valid_402657914 != nil:
    section.add "X-Amz-Credential", valid_402657914
  var valid_402657915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657915 = validateParameter(valid_402657915, JString,
                                      required = false, default = nil)
  if valid_402657915 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657915
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657917: Call_PutDataCatalogEncryptionSettings_402657905;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
                                                                                         ## 
  let valid = call_402657917.validator(path, query, header, formData, body, _)
  let scheme = call_402657917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657917.makeUrl(scheme.get, call_402657917.host, call_402657917.base,
                                   call_402657917.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657917, uri, valid, _)

proc call*(call_402657918: Call_PutDataCatalogEncryptionSettings_402657905;
           body: JsonNode): Recallable =
  ## putDataCatalogEncryptionSettings
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
  ##   
                                                                                                                                                                          ## body: JObject (required)
  var body_402657919 = newJObject()
  if body != nil:
    body_402657919 = body
  result = call_402657918.call(nil, nil, nil, nil, body_402657919)

var putDataCatalogEncryptionSettings* = Call_PutDataCatalogEncryptionSettings_402657905(
    name: "putDataCatalogEncryptionSettings", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutDataCatalogEncryptionSettings",
    validator: validate_PutDataCatalogEncryptionSettings_402657906, base: "/",
    makeUrl: url_PutDataCatalogEncryptionSettings_402657907,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResourcePolicy_402657920 = ref object of OpenApiRestCall_402656044
proc url_PutResourcePolicy_402657922(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutResourcePolicy_402657921(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Sets the Data Catalog resource policy for access control.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657923 = header.getOrDefault("X-Amz-Target")
  valid_402657923 = validateParameter(valid_402657923, JString, required = true, default = newJString(
      "AWSGlue.PutResourcePolicy"))
  if valid_402657923 != nil:
    section.add "X-Amz-Target", valid_402657923
  var valid_402657924 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657924 = validateParameter(valid_402657924, JString,
                                      required = false, default = nil)
  if valid_402657924 != nil:
    section.add "X-Amz-Security-Token", valid_402657924
  var valid_402657925 = header.getOrDefault("X-Amz-Signature")
  valid_402657925 = validateParameter(valid_402657925, JString,
                                      required = false, default = nil)
  if valid_402657925 != nil:
    section.add "X-Amz-Signature", valid_402657925
  var valid_402657926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657926 = validateParameter(valid_402657926, JString,
                                      required = false, default = nil)
  if valid_402657926 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657926
  var valid_402657927 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657927 = validateParameter(valid_402657927, JString,
                                      required = false, default = nil)
  if valid_402657927 != nil:
    section.add "X-Amz-Algorithm", valid_402657927
  var valid_402657928 = header.getOrDefault("X-Amz-Date")
  valid_402657928 = validateParameter(valid_402657928, JString,
                                      required = false, default = nil)
  if valid_402657928 != nil:
    section.add "X-Amz-Date", valid_402657928
  var valid_402657929 = header.getOrDefault("X-Amz-Credential")
  valid_402657929 = validateParameter(valid_402657929, JString,
                                      required = false, default = nil)
  if valid_402657929 != nil:
    section.add "X-Amz-Credential", valid_402657929
  var valid_402657930 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657930 = validateParameter(valid_402657930, JString,
                                      required = false, default = nil)
  if valid_402657930 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657930
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657932: Call_PutResourcePolicy_402657920;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets the Data Catalog resource policy for access control.
                                                                                         ## 
  let valid = call_402657932.validator(path, query, header, formData, body, _)
  let scheme = call_402657932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657932.makeUrl(scheme.get, call_402657932.host, call_402657932.base,
                                   call_402657932.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657932, uri, valid, _)

proc call*(call_402657933: Call_PutResourcePolicy_402657920; body: JsonNode): Recallable =
  ## putResourcePolicy
  ## Sets the Data Catalog resource policy for access control.
  ##   body: JObject (required)
  var body_402657934 = newJObject()
  if body != nil:
    body_402657934 = body
  result = call_402657933.call(nil, nil, nil, nil, body_402657934)

var putResourcePolicy* = Call_PutResourcePolicy_402657920(
    name: "putResourcePolicy", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutResourcePolicy",
    validator: validate_PutResourcePolicy_402657921, base: "/",
    makeUrl: url_PutResourcePolicy_402657922,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutWorkflowRunProperties_402657935 = ref object of OpenApiRestCall_402656044
proc url_PutWorkflowRunProperties_402657937(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutWorkflowRunProperties_402657936(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657938 = header.getOrDefault("X-Amz-Target")
  valid_402657938 = validateParameter(valid_402657938, JString, required = true, default = newJString(
      "AWSGlue.PutWorkflowRunProperties"))
  if valid_402657938 != nil:
    section.add "X-Amz-Target", valid_402657938
  var valid_402657939 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657939 = validateParameter(valid_402657939, JString,
                                      required = false, default = nil)
  if valid_402657939 != nil:
    section.add "X-Amz-Security-Token", valid_402657939
  var valid_402657940 = header.getOrDefault("X-Amz-Signature")
  valid_402657940 = validateParameter(valid_402657940, JString,
                                      required = false, default = nil)
  if valid_402657940 != nil:
    section.add "X-Amz-Signature", valid_402657940
  var valid_402657941 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657941 = validateParameter(valid_402657941, JString,
                                      required = false, default = nil)
  if valid_402657941 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657941
  var valid_402657942 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657942 = validateParameter(valid_402657942, JString,
                                      required = false, default = nil)
  if valid_402657942 != nil:
    section.add "X-Amz-Algorithm", valid_402657942
  var valid_402657943 = header.getOrDefault("X-Amz-Date")
  valid_402657943 = validateParameter(valid_402657943, JString,
                                      required = false, default = nil)
  if valid_402657943 != nil:
    section.add "X-Amz-Date", valid_402657943
  var valid_402657944 = header.getOrDefault("X-Amz-Credential")
  valid_402657944 = validateParameter(valid_402657944, JString,
                                      required = false, default = nil)
  if valid_402657944 != nil:
    section.add "X-Amz-Credential", valid_402657944
  var valid_402657945 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657945 = validateParameter(valid_402657945, JString,
                                      required = false, default = nil)
  if valid_402657945 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657945
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657947: Call_PutWorkflowRunProperties_402657935;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
                                                                                         ## 
  let valid = call_402657947.validator(path, query, header, formData, body, _)
  let scheme = call_402657947.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657947.makeUrl(scheme.get, call_402657947.host, call_402657947.base,
                                   call_402657947.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657947, uri, valid, _)

proc call*(call_402657948: Call_PutWorkflowRunProperties_402657935;
           body: JsonNode): Recallable =
  ## putWorkflowRunProperties
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
  ##   
                                                                                                                                                                                                               ## body: JObject (required)
  var body_402657949 = newJObject()
  if body != nil:
    body_402657949 = body
  result = call_402657948.call(nil, nil, nil, nil, body_402657949)

var putWorkflowRunProperties* = Call_PutWorkflowRunProperties_402657935(
    name: "putWorkflowRunProperties", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutWorkflowRunProperties",
    validator: validate_PutWorkflowRunProperties_402657936, base: "/",
    makeUrl: url_PutWorkflowRunProperties_402657937,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetJobBookmark_402657950 = ref object of OpenApiRestCall_402656044
proc url_ResetJobBookmark_402657952(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ResetJobBookmark_402657951(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Resets a bookmark entry.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657953 = header.getOrDefault("X-Amz-Target")
  valid_402657953 = validateParameter(valid_402657953, JString, required = true, default = newJString(
      "AWSGlue.ResetJobBookmark"))
  if valid_402657953 != nil:
    section.add "X-Amz-Target", valid_402657953
  var valid_402657954 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657954 = validateParameter(valid_402657954, JString,
                                      required = false, default = nil)
  if valid_402657954 != nil:
    section.add "X-Amz-Security-Token", valid_402657954
  var valid_402657955 = header.getOrDefault("X-Amz-Signature")
  valid_402657955 = validateParameter(valid_402657955, JString,
                                      required = false, default = nil)
  if valid_402657955 != nil:
    section.add "X-Amz-Signature", valid_402657955
  var valid_402657956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657956 = validateParameter(valid_402657956, JString,
                                      required = false, default = nil)
  if valid_402657956 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657956
  var valid_402657957 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657957 = validateParameter(valid_402657957, JString,
                                      required = false, default = nil)
  if valid_402657957 != nil:
    section.add "X-Amz-Algorithm", valid_402657957
  var valid_402657958 = header.getOrDefault("X-Amz-Date")
  valid_402657958 = validateParameter(valid_402657958, JString,
                                      required = false, default = nil)
  if valid_402657958 != nil:
    section.add "X-Amz-Date", valid_402657958
  var valid_402657959 = header.getOrDefault("X-Amz-Credential")
  valid_402657959 = validateParameter(valid_402657959, JString,
                                      required = false, default = nil)
  if valid_402657959 != nil:
    section.add "X-Amz-Credential", valid_402657959
  var valid_402657960 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657960 = validateParameter(valid_402657960, JString,
                                      required = false, default = nil)
  if valid_402657960 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657960
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657962: Call_ResetJobBookmark_402657950;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Resets a bookmark entry.
                                                                                         ## 
  let valid = call_402657962.validator(path, query, header, formData, body, _)
  let scheme = call_402657962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657962.makeUrl(scheme.get, call_402657962.host, call_402657962.base,
                                   call_402657962.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657962, uri, valid, _)

proc call*(call_402657963: Call_ResetJobBookmark_402657950; body: JsonNode): Recallable =
  ## resetJobBookmark
  ## Resets a bookmark entry.
  ##   body: JObject (required)
  var body_402657964 = newJObject()
  if body != nil:
    body_402657964 = body
  result = call_402657963.call(nil, nil, nil, nil, body_402657964)

var resetJobBookmark* = Call_ResetJobBookmark_402657950(
    name: "resetJobBookmark", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ResetJobBookmark",
    validator: validate_ResetJobBookmark_402657951, base: "/",
    makeUrl: url_ResetJobBookmark_402657952,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchTables_402657965 = ref object of OpenApiRestCall_402656044
proc url_SearchTables_402657967(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchTables_402657966(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657968 = query.getOrDefault("MaxResults")
  valid_402657968 = validateParameter(valid_402657968, JString,
                                      required = false, default = nil)
  if valid_402657968 != nil:
    section.add "MaxResults", valid_402657968
  var valid_402657969 = query.getOrDefault("NextToken")
  valid_402657969 = validateParameter(valid_402657969, JString,
                                      required = false, default = nil)
  if valid_402657969 != nil:
    section.add "NextToken", valid_402657969
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657970 = header.getOrDefault("X-Amz-Target")
  valid_402657970 = validateParameter(valid_402657970, JString, required = true, default = newJString(
      "AWSGlue.SearchTables"))
  if valid_402657970 != nil:
    section.add "X-Amz-Target", valid_402657970
  var valid_402657971 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657971 = validateParameter(valid_402657971, JString,
                                      required = false, default = nil)
  if valid_402657971 != nil:
    section.add "X-Amz-Security-Token", valid_402657971
  var valid_402657972 = header.getOrDefault("X-Amz-Signature")
  valid_402657972 = validateParameter(valid_402657972, JString,
                                      required = false, default = nil)
  if valid_402657972 != nil:
    section.add "X-Amz-Signature", valid_402657972
  var valid_402657973 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657973 = validateParameter(valid_402657973, JString,
                                      required = false, default = nil)
  if valid_402657973 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657973
  var valid_402657974 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657974 = validateParameter(valid_402657974, JString,
                                      required = false, default = nil)
  if valid_402657974 != nil:
    section.add "X-Amz-Algorithm", valid_402657974
  var valid_402657975 = header.getOrDefault("X-Amz-Date")
  valid_402657975 = validateParameter(valid_402657975, JString,
                                      required = false, default = nil)
  if valid_402657975 != nil:
    section.add "X-Amz-Date", valid_402657975
  var valid_402657976 = header.getOrDefault("X-Amz-Credential")
  valid_402657976 = validateParameter(valid_402657976, JString,
                                      required = false, default = nil)
  if valid_402657976 != nil:
    section.add "X-Amz-Credential", valid_402657976
  var valid_402657977 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657977 = validateParameter(valid_402657977, JString,
                                      required = false, default = nil)
  if valid_402657977 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657977
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657979: Call_SearchTables_402657965; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
                                                                                         ## 
  let valid = call_402657979.validator(path, query, header, formData, body, _)
  let scheme = call_402657979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657979.makeUrl(scheme.get, call_402657979.host, call_402657979.base,
                                   call_402657979.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657979, uri, valid, _)

proc call*(call_402657980: Call_SearchTables_402657965; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchTables
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## token
  var query_402657981 = newJObject()
  var body_402657982 = newJObject()
  add(query_402657981, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657982 = body
  add(query_402657981, "NextToken", newJString(NextToken))
  result = call_402657980.call(nil, query_402657981, nil, nil, body_402657982)

var searchTables* = Call_SearchTables_402657965(name: "searchTables",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.SearchTables",
    validator: validate_SearchTables_402657966, base: "/",
    makeUrl: url_SearchTables_402657967, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCrawler_402657983 = ref object of OpenApiRestCall_402656044
proc url_StartCrawler_402657985(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartCrawler_402657984(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657986 = header.getOrDefault("X-Amz-Target")
  valid_402657986 = validateParameter(valid_402657986, JString, required = true, default = newJString(
      "AWSGlue.StartCrawler"))
  if valid_402657986 != nil:
    section.add "X-Amz-Target", valid_402657986
  var valid_402657987 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657987 = validateParameter(valid_402657987, JString,
                                      required = false, default = nil)
  if valid_402657987 != nil:
    section.add "X-Amz-Security-Token", valid_402657987
  var valid_402657988 = header.getOrDefault("X-Amz-Signature")
  valid_402657988 = validateParameter(valid_402657988, JString,
                                      required = false, default = nil)
  if valid_402657988 != nil:
    section.add "X-Amz-Signature", valid_402657988
  var valid_402657989 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657989 = validateParameter(valid_402657989, JString,
                                      required = false, default = nil)
  if valid_402657989 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657989
  var valid_402657990 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657990 = validateParameter(valid_402657990, JString,
                                      required = false, default = nil)
  if valid_402657990 != nil:
    section.add "X-Amz-Algorithm", valid_402657990
  var valid_402657991 = header.getOrDefault("X-Amz-Date")
  valid_402657991 = validateParameter(valid_402657991, JString,
                                      required = false, default = nil)
  if valid_402657991 != nil:
    section.add "X-Amz-Date", valid_402657991
  var valid_402657992 = header.getOrDefault("X-Amz-Credential")
  valid_402657992 = validateParameter(valid_402657992, JString,
                                      required = false, default = nil)
  if valid_402657992 != nil:
    section.add "X-Amz-Credential", valid_402657992
  var valid_402657993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657993 = validateParameter(valid_402657993, JString,
                                      required = false, default = nil)
  if valid_402657993 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657995: Call_StartCrawler_402657983; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
                                                                                         ## 
  let valid = call_402657995.validator(path, query, header, formData, body, _)
  let scheme = call_402657995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657995.makeUrl(scheme.get, call_402657995.host, call_402657995.base,
                                   call_402657995.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657995, uri, valid, _)

proc call*(call_402657996: Call_StartCrawler_402657983; body: JsonNode): Recallable =
  ## startCrawler
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
  ##   
                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402657997 = newJObject()
  if body != nil:
    body_402657997 = body
  result = call_402657996.call(nil, nil, nil, nil, body_402657997)

var startCrawler* = Call_StartCrawler_402657983(name: "startCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartCrawler",
    validator: validate_StartCrawler_402657984, base: "/",
    makeUrl: url_StartCrawler_402657985, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCrawlerSchedule_402657998 = ref object of OpenApiRestCall_402656044
proc url_StartCrawlerSchedule_402658000(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartCrawlerSchedule_402657999(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658001 = header.getOrDefault("X-Amz-Target")
  valid_402658001 = validateParameter(valid_402658001, JString, required = true, default = newJString(
      "AWSGlue.StartCrawlerSchedule"))
  if valid_402658001 != nil:
    section.add "X-Amz-Target", valid_402658001
  var valid_402658002 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658002 = validateParameter(valid_402658002, JString,
                                      required = false, default = nil)
  if valid_402658002 != nil:
    section.add "X-Amz-Security-Token", valid_402658002
  var valid_402658003 = header.getOrDefault("X-Amz-Signature")
  valid_402658003 = validateParameter(valid_402658003, JString,
                                      required = false, default = nil)
  if valid_402658003 != nil:
    section.add "X-Amz-Signature", valid_402658003
  var valid_402658004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658004 = validateParameter(valid_402658004, JString,
                                      required = false, default = nil)
  if valid_402658004 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658004
  var valid_402658005 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658005 = validateParameter(valid_402658005, JString,
                                      required = false, default = nil)
  if valid_402658005 != nil:
    section.add "X-Amz-Algorithm", valid_402658005
  var valid_402658006 = header.getOrDefault("X-Amz-Date")
  valid_402658006 = validateParameter(valid_402658006, JString,
                                      required = false, default = nil)
  if valid_402658006 != nil:
    section.add "X-Amz-Date", valid_402658006
  var valid_402658007 = header.getOrDefault("X-Amz-Credential")
  valid_402658007 = validateParameter(valid_402658007, JString,
                                      required = false, default = nil)
  if valid_402658007 != nil:
    section.add "X-Amz-Credential", valid_402658007
  var valid_402658008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658008 = validateParameter(valid_402658008, JString,
                                      required = false, default = nil)
  if valid_402658008 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658008
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658010: Call_StartCrawlerSchedule_402657998;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
                                                                                         ## 
  let valid = call_402658010.validator(path, query, header, formData, body, _)
  let scheme = call_402658010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658010.makeUrl(scheme.get, call_402658010.host, call_402658010.base,
                                   call_402658010.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658010, uri, valid, _)

proc call*(call_402658011: Call_StartCrawlerSchedule_402657998; body: JsonNode): Recallable =
  ## startCrawlerSchedule
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
  ##   
                                                                                                                                                                                  ## body: JObject (required)
  var body_402658012 = newJObject()
  if body != nil:
    body_402658012 = body
  result = call_402658011.call(nil, nil, nil, nil, body_402658012)

var startCrawlerSchedule* = Call_StartCrawlerSchedule_402657998(
    name: "startCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartCrawlerSchedule",
    validator: validate_StartCrawlerSchedule_402657999, base: "/",
    makeUrl: url_StartCrawlerSchedule_402658000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartExportLabelsTaskRun_402658013 = ref object of OpenApiRestCall_402656044
proc url_StartExportLabelsTaskRun_402658015(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartExportLabelsTaskRun_402658014(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658016 = header.getOrDefault("X-Amz-Target")
  valid_402658016 = validateParameter(valid_402658016, JString, required = true, default = newJString(
      "AWSGlue.StartExportLabelsTaskRun"))
  if valid_402658016 != nil:
    section.add "X-Amz-Target", valid_402658016
  var valid_402658017 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658017 = validateParameter(valid_402658017, JString,
                                      required = false, default = nil)
  if valid_402658017 != nil:
    section.add "X-Amz-Security-Token", valid_402658017
  var valid_402658018 = header.getOrDefault("X-Amz-Signature")
  valid_402658018 = validateParameter(valid_402658018, JString,
                                      required = false, default = nil)
  if valid_402658018 != nil:
    section.add "X-Amz-Signature", valid_402658018
  var valid_402658019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658019 = validateParameter(valid_402658019, JString,
                                      required = false, default = nil)
  if valid_402658019 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658019
  var valid_402658020 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658020 = validateParameter(valid_402658020, JString,
                                      required = false, default = nil)
  if valid_402658020 != nil:
    section.add "X-Amz-Algorithm", valid_402658020
  var valid_402658021 = header.getOrDefault("X-Amz-Date")
  valid_402658021 = validateParameter(valid_402658021, JString,
                                      required = false, default = nil)
  if valid_402658021 != nil:
    section.add "X-Amz-Date", valid_402658021
  var valid_402658022 = header.getOrDefault("X-Amz-Credential")
  valid_402658022 = validateParameter(valid_402658022, JString,
                                      required = false, default = nil)
  if valid_402658022 != nil:
    section.add "X-Amz-Credential", valid_402658022
  var valid_402658023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658023 = validateParameter(valid_402658023, JString,
                                      required = false, default = nil)
  if valid_402658023 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658025: Call_StartExportLabelsTaskRun_402658013;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
                                                                                         ## 
  let valid = call_402658025.validator(path, query, header, formData, body, _)
  let scheme = call_402658025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658025.makeUrl(scheme.get, call_402658025.host, call_402658025.base,
                                   call_402658025.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658025, uri, valid, _)

proc call*(call_402658026: Call_StartExportLabelsTaskRun_402658013;
           body: JsonNode): Recallable =
  ## startExportLabelsTaskRun
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402658027 = newJObject()
  if body != nil:
    body_402658027 = body
  result = call_402658026.call(nil, nil, nil, nil, body_402658027)

var startExportLabelsTaskRun* = Call_StartExportLabelsTaskRun_402658013(
    name: "startExportLabelsTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartExportLabelsTaskRun",
    validator: validate_StartExportLabelsTaskRun_402658014, base: "/",
    makeUrl: url_StartExportLabelsTaskRun_402658015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImportLabelsTaskRun_402658028 = ref object of OpenApiRestCall_402656044
proc url_StartImportLabelsTaskRun_402658030(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartImportLabelsTaskRun_402658029(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658031 = header.getOrDefault("X-Amz-Target")
  valid_402658031 = validateParameter(valid_402658031, JString, required = true, default = newJString(
      "AWSGlue.StartImportLabelsTaskRun"))
  if valid_402658031 != nil:
    section.add "X-Amz-Target", valid_402658031
  var valid_402658032 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658032 = validateParameter(valid_402658032, JString,
                                      required = false, default = nil)
  if valid_402658032 != nil:
    section.add "X-Amz-Security-Token", valid_402658032
  var valid_402658033 = header.getOrDefault("X-Amz-Signature")
  valid_402658033 = validateParameter(valid_402658033, JString,
                                      required = false, default = nil)
  if valid_402658033 != nil:
    section.add "X-Amz-Signature", valid_402658033
  var valid_402658034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658034 = validateParameter(valid_402658034, JString,
                                      required = false, default = nil)
  if valid_402658034 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658034
  var valid_402658035 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658035 = validateParameter(valid_402658035, JString,
                                      required = false, default = nil)
  if valid_402658035 != nil:
    section.add "X-Amz-Algorithm", valid_402658035
  var valid_402658036 = header.getOrDefault("X-Amz-Date")
  valid_402658036 = validateParameter(valid_402658036, JString,
                                      required = false, default = nil)
  if valid_402658036 != nil:
    section.add "X-Amz-Date", valid_402658036
  var valid_402658037 = header.getOrDefault("X-Amz-Credential")
  valid_402658037 = validateParameter(valid_402658037, JString,
                                      required = false, default = nil)
  if valid_402658037 != nil:
    section.add "X-Amz-Credential", valid_402658037
  var valid_402658038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658038 = validateParameter(valid_402658038, JString,
                                      required = false, default = nil)
  if valid_402658038 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658040: Call_StartImportLabelsTaskRun_402658028;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
                                                                                         ## 
  let valid = call_402658040.validator(path, query, header, formData, body, _)
  let scheme = call_402658040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658040.makeUrl(scheme.get, call_402658040.host, call_402658040.base,
                                   call_402658040.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658040, uri, valid, _)

proc call*(call_402658041: Call_StartImportLabelsTaskRun_402658028;
           body: JsonNode): Recallable =
  ## startImportLabelsTaskRun
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402658042 = newJObject()
  if body != nil:
    body_402658042 = body
  result = call_402658041.call(nil, nil, nil, nil, body_402658042)

var startImportLabelsTaskRun* = Call_StartImportLabelsTaskRun_402658028(
    name: "startImportLabelsTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartImportLabelsTaskRun",
    validator: validate_StartImportLabelsTaskRun_402658029, base: "/",
    makeUrl: url_StartImportLabelsTaskRun_402658030,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJobRun_402658043 = ref object of OpenApiRestCall_402656044
proc url_StartJobRun_402658045(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartJobRun_402658044(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Starts a job run using a job definition.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658046 = header.getOrDefault("X-Amz-Target")
  valid_402658046 = validateParameter(valid_402658046, JString, required = true, default = newJString(
      "AWSGlue.StartJobRun"))
  if valid_402658046 != nil:
    section.add "X-Amz-Target", valid_402658046
  var valid_402658047 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658047 = validateParameter(valid_402658047, JString,
                                      required = false, default = nil)
  if valid_402658047 != nil:
    section.add "X-Amz-Security-Token", valid_402658047
  var valid_402658048 = header.getOrDefault("X-Amz-Signature")
  valid_402658048 = validateParameter(valid_402658048, JString,
                                      required = false, default = nil)
  if valid_402658048 != nil:
    section.add "X-Amz-Signature", valid_402658048
  var valid_402658049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658049 = validateParameter(valid_402658049, JString,
                                      required = false, default = nil)
  if valid_402658049 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658049
  var valid_402658050 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658050 = validateParameter(valid_402658050, JString,
                                      required = false, default = nil)
  if valid_402658050 != nil:
    section.add "X-Amz-Algorithm", valid_402658050
  var valid_402658051 = header.getOrDefault("X-Amz-Date")
  valid_402658051 = validateParameter(valid_402658051, JString,
                                      required = false, default = nil)
  if valid_402658051 != nil:
    section.add "X-Amz-Date", valid_402658051
  var valid_402658052 = header.getOrDefault("X-Amz-Credential")
  valid_402658052 = validateParameter(valid_402658052, JString,
                                      required = false, default = nil)
  if valid_402658052 != nil:
    section.add "X-Amz-Credential", valid_402658052
  var valid_402658053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658053 = validateParameter(valid_402658053, JString,
                                      required = false, default = nil)
  if valid_402658053 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658055: Call_StartJobRun_402658043; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts a job run using a job definition.
                                                                                         ## 
  let valid = call_402658055.validator(path, query, header, formData, body, _)
  let scheme = call_402658055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658055.makeUrl(scheme.get, call_402658055.host, call_402658055.base,
                                   call_402658055.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658055, uri, valid, _)

proc call*(call_402658056: Call_StartJobRun_402658043; body: JsonNode): Recallable =
  ## startJobRun
  ## Starts a job run using a job definition.
  ##   body: JObject (required)
  var body_402658057 = newJObject()
  if body != nil:
    body_402658057 = body
  result = call_402658056.call(nil, nil, nil, nil, body_402658057)

var startJobRun* = Call_StartJobRun_402658043(name: "startJobRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartJobRun",
    validator: validate_StartJobRun_402658044, base: "/",
    makeUrl: url_StartJobRun_402658045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMLEvaluationTaskRun_402658058 = ref object of OpenApiRestCall_402656044
proc url_StartMLEvaluationTaskRun_402658060(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartMLEvaluationTaskRun_402658059(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658061 = header.getOrDefault("X-Amz-Target")
  valid_402658061 = validateParameter(valid_402658061, JString, required = true, default = newJString(
      "AWSGlue.StartMLEvaluationTaskRun"))
  if valid_402658061 != nil:
    section.add "X-Amz-Target", valid_402658061
  var valid_402658062 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658062 = validateParameter(valid_402658062, JString,
                                      required = false, default = nil)
  if valid_402658062 != nil:
    section.add "X-Amz-Security-Token", valid_402658062
  var valid_402658063 = header.getOrDefault("X-Amz-Signature")
  valid_402658063 = validateParameter(valid_402658063, JString,
                                      required = false, default = nil)
  if valid_402658063 != nil:
    section.add "X-Amz-Signature", valid_402658063
  var valid_402658064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658064 = validateParameter(valid_402658064, JString,
                                      required = false, default = nil)
  if valid_402658064 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658064
  var valid_402658065 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658065 = validateParameter(valid_402658065, JString,
                                      required = false, default = nil)
  if valid_402658065 != nil:
    section.add "X-Amz-Algorithm", valid_402658065
  var valid_402658066 = header.getOrDefault("X-Amz-Date")
  valid_402658066 = validateParameter(valid_402658066, JString,
                                      required = false, default = nil)
  if valid_402658066 != nil:
    section.add "X-Amz-Date", valid_402658066
  var valid_402658067 = header.getOrDefault("X-Amz-Credential")
  valid_402658067 = validateParameter(valid_402658067, JString,
                                      required = false, default = nil)
  if valid_402658067 != nil:
    section.add "X-Amz-Credential", valid_402658067
  var valid_402658068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658068 = validateParameter(valid_402658068, JString,
                                      required = false, default = nil)
  if valid_402658068 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658070: Call_StartMLEvaluationTaskRun_402658058;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
                                                                                         ## 
  let valid = call_402658070.validator(path, query, header, formData, body, _)
  let scheme = call_402658070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658070.makeUrl(scheme.get, call_402658070.host, call_402658070.base,
                                   call_402658070.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658070, uri, valid, _)

proc call*(call_402658071: Call_StartMLEvaluationTaskRun_402658058;
           body: JsonNode): Recallable =
  ## startMLEvaluationTaskRun
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402658072 = newJObject()
  if body != nil:
    body_402658072 = body
  result = call_402658071.call(nil, nil, nil, nil, body_402658072)

var startMLEvaluationTaskRun* = Call_StartMLEvaluationTaskRun_402658058(
    name: "startMLEvaluationTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartMLEvaluationTaskRun",
    validator: validate_StartMLEvaluationTaskRun_402658059, base: "/",
    makeUrl: url_StartMLEvaluationTaskRun_402658060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMLLabelingSetGenerationTaskRun_402658073 = ref object of OpenApiRestCall_402656044
proc url_StartMLLabelingSetGenerationTaskRun_402658075(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartMLLabelingSetGenerationTaskRun_402658074(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658076 = header.getOrDefault("X-Amz-Target")
  valid_402658076 = validateParameter(valid_402658076, JString, required = true, default = newJString(
      "AWSGlue.StartMLLabelingSetGenerationTaskRun"))
  if valid_402658076 != nil:
    section.add "X-Amz-Target", valid_402658076
  var valid_402658077 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658077 = validateParameter(valid_402658077, JString,
                                      required = false, default = nil)
  if valid_402658077 != nil:
    section.add "X-Amz-Security-Token", valid_402658077
  var valid_402658078 = header.getOrDefault("X-Amz-Signature")
  valid_402658078 = validateParameter(valid_402658078, JString,
                                      required = false, default = nil)
  if valid_402658078 != nil:
    section.add "X-Amz-Signature", valid_402658078
  var valid_402658079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658079 = validateParameter(valid_402658079, JString,
                                      required = false, default = nil)
  if valid_402658079 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658079
  var valid_402658080 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658080 = validateParameter(valid_402658080, JString,
                                      required = false, default = nil)
  if valid_402658080 != nil:
    section.add "X-Amz-Algorithm", valid_402658080
  var valid_402658081 = header.getOrDefault("X-Amz-Date")
  valid_402658081 = validateParameter(valid_402658081, JString,
                                      required = false, default = nil)
  if valid_402658081 != nil:
    section.add "X-Amz-Date", valid_402658081
  var valid_402658082 = header.getOrDefault("X-Amz-Credential")
  valid_402658082 = validateParameter(valid_402658082, JString,
                                      required = false, default = nil)
  if valid_402658082 != nil:
    section.add "X-Amz-Credential", valid_402658082
  var valid_402658083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658083 = validateParameter(valid_402658083, JString,
                                      required = false, default = nil)
  if valid_402658083 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658085: Call_StartMLLabelingSetGenerationTaskRun_402658073;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
                                                                                         ## 
  let valid = call_402658085.validator(path, query, header, formData, body, _)
  let scheme = call_402658085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658085.makeUrl(scheme.get, call_402658085.host, call_402658085.base,
                                   call_402658085.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658085, uri, valid, _)

proc call*(call_402658086: Call_StartMLLabelingSetGenerationTaskRun_402658073;
           body: JsonNode): Recallable =
  ## startMLLabelingSetGenerationTaskRun
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402658087 = newJObject()
  if body != nil:
    body_402658087 = body
  result = call_402658086.call(nil, nil, nil, nil, body_402658087)

var startMLLabelingSetGenerationTaskRun* = Call_StartMLLabelingSetGenerationTaskRun_402658073(
    name: "startMLLabelingSetGenerationTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartMLLabelingSetGenerationTaskRun",
    validator: validate_StartMLLabelingSetGenerationTaskRun_402658074,
    base: "/", makeUrl: url_StartMLLabelingSetGenerationTaskRun_402658075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTrigger_402658088 = ref object of OpenApiRestCall_402656044
proc url_StartTrigger_402658090(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartTrigger_402658089(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658091 = header.getOrDefault("X-Amz-Target")
  valid_402658091 = validateParameter(valid_402658091, JString, required = true, default = newJString(
      "AWSGlue.StartTrigger"))
  if valid_402658091 != nil:
    section.add "X-Amz-Target", valid_402658091
  var valid_402658092 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658092 = validateParameter(valid_402658092, JString,
                                      required = false, default = nil)
  if valid_402658092 != nil:
    section.add "X-Amz-Security-Token", valid_402658092
  var valid_402658093 = header.getOrDefault("X-Amz-Signature")
  valid_402658093 = validateParameter(valid_402658093, JString,
                                      required = false, default = nil)
  if valid_402658093 != nil:
    section.add "X-Amz-Signature", valid_402658093
  var valid_402658094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658094 = validateParameter(valid_402658094, JString,
                                      required = false, default = nil)
  if valid_402658094 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658094
  var valid_402658095 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658095 = validateParameter(valid_402658095, JString,
                                      required = false, default = nil)
  if valid_402658095 != nil:
    section.add "X-Amz-Algorithm", valid_402658095
  var valid_402658096 = header.getOrDefault("X-Amz-Date")
  valid_402658096 = validateParameter(valid_402658096, JString,
                                      required = false, default = nil)
  if valid_402658096 != nil:
    section.add "X-Amz-Date", valid_402658096
  var valid_402658097 = header.getOrDefault("X-Amz-Credential")
  valid_402658097 = validateParameter(valid_402658097, JString,
                                      required = false, default = nil)
  if valid_402658097 != nil:
    section.add "X-Amz-Credential", valid_402658097
  var valid_402658098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658098 = validateParameter(valid_402658098, JString,
                                      required = false, default = nil)
  if valid_402658098 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658100: Call_StartTrigger_402658088; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
                                                                                         ## 
  let valid = call_402658100.validator(path, query, header, formData, body, _)
  let scheme = call_402658100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658100.makeUrl(scheme.get, call_402658100.host, call_402658100.base,
                                   call_402658100.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658100, uri, valid, _)

proc call*(call_402658101: Call_StartTrigger_402658088; body: JsonNode): Recallable =
  ## startTrigger
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
  ##   
                                                                                                                                                                                                ## body: JObject (required)
  var body_402658102 = newJObject()
  if body != nil:
    body_402658102 = body
  result = call_402658101.call(nil, nil, nil, nil, body_402658102)

var startTrigger* = Call_StartTrigger_402658088(name: "startTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartTrigger",
    validator: validate_StartTrigger_402658089, base: "/",
    makeUrl: url_StartTrigger_402658090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartWorkflowRun_402658103 = ref object of OpenApiRestCall_402656044
proc url_StartWorkflowRun_402658105(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartWorkflowRun_402658104(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Starts a new run of the specified workflow.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658106 = header.getOrDefault("X-Amz-Target")
  valid_402658106 = validateParameter(valid_402658106, JString, required = true, default = newJString(
      "AWSGlue.StartWorkflowRun"))
  if valid_402658106 != nil:
    section.add "X-Amz-Target", valid_402658106
  var valid_402658107 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658107 = validateParameter(valid_402658107, JString,
                                      required = false, default = nil)
  if valid_402658107 != nil:
    section.add "X-Amz-Security-Token", valid_402658107
  var valid_402658108 = header.getOrDefault("X-Amz-Signature")
  valid_402658108 = validateParameter(valid_402658108, JString,
                                      required = false, default = nil)
  if valid_402658108 != nil:
    section.add "X-Amz-Signature", valid_402658108
  var valid_402658109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658109 = validateParameter(valid_402658109, JString,
                                      required = false, default = nil)
  if valid_402658109 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658109
  var valid_402658110 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658110 = validateParameter(valid_402658110, JString,
                                      required = false, default = nil)
  if valid_402658110 != nil:
    section.add "X-Amz-Algorithm", valid_402658110
  var valid_402658111 = header.getOrDefault("X-Amz-Date")
  valid_402658111 = validateParameter(valid_402658111, JString,
                                      required = false, default = nil)
  if valid_402658111 != nil:
    section.add "X-Amz-Date", valid_402658111
  var valid_402658112 = header.getOrDefault("X-Amz-Credential")
  valid_402658112 = validateParameter(valid_402658112, JString,
                                      required = false, default = nil)
  if valid_402658112 != nil:
    section.add "X-Amz-Credential", valid_402658112
  var valid_402658113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658113 = validateParameter(valid_402658113, JString,
                                      required = false, default = nil)
  if valid_402658113 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658115: Call_StartWorkflowRun_402658103;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts a new run of the specified workflow.
                                                                                         ## 
  let valid = call_402658115.validator(path, query, header, formData, body, _)
  let scheme = call_402658115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658115.makeUrl(scheme.get, call_402658115.host, call_402658115.base,
                                   call_402658115.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658115, uri, valid, _)

proc call*(call_402658116: Call_StartWorkflowRun_402658103; body: JsonNode): Recallable =
  ## startWorkflowRun
  ## Starts a new run of the specified workflow.
  ##   body: JObject (required)
  var body_402658117 = newJObject()
  if body != nil:
    body_402658117 = body
  result = call_402658116.call(nil, nil, nil, nil, body_402658117)

var startWorkflowRun* = Call_StartWorkflowRun_402658103(
    name: "startWorkflowRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartWorkflowRun",
    validator: validate_StartWorkflowRun_402658104, base: "/",
    makeUrl: url_StartWorkflowRun_402658105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCrawler_402658118 = ref object of OpenApiRestCall_402656044
proc url_StopCrawler_402658120(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopCrawler_402658119(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## If the specified crawler is running, stops the crawl.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658121 = header.getOrDefault("X-Amz-Target")
  valid_402658121 = validateParameter(valid_402658121, JString, required = true, default = newJString(
      "AWSGlue.StopCrawler"))
  if valid_402658121 != nil:
    section.add "X-Amz-Target", valid_402658121
  var valid_402658122 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658122 = validateParameter(valid_402658122, JString,
                                      required = false, default = nil)
  if valid_402658122 != nil:
    section.add "X-Amz-Security-Token", valid_402658122
  var valid_402658123 = header.getOrDefault("X-Amz-Signature")
  valid_402658123 = validateParameter(valid_402658123, JString,
                                      required = false, default = nil)
  if valid_402658123 != nil:
    section.add "X-Amz-Signature", valid_402658123
  var valid_402658124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658124 = validateParameter(valid_402658124, JString,
                                      required = false, default = nil)
  if valid_402658124 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658124
  var valid_402658125 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658125 = validateParameter(valid_402658125, JString,
                                      required = false, default = nil)
  if valid_402658125 != nil:
    section.add "X-Amz-Algorithm", valid_402658125
  var valid_402658126 = header.getOrDefault("X-Amz-Date")
  valid_402658126 = validateParameter(valid_402658126, JString,
                                      required = false, default = nil)
  if valid_402658126 != nil:
    section.add "X-Amz-Date", valid_402658126
  var valid_402658127 = header.getOrDefault("X-Amz-Credential")
  valid_402658127 = validateParameter(valid_402658127, JString,
                                      required = false, default = nil)
  if valid_402658127 != nil:
    section.add "X-Amz-Credential", valid_402658127
  var valid_402658128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658128 = validateParameter(valid_402658128, JString,
                                      required = false, default = nil)
  if valid_402658128 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658130: Call_StopCrawler_402658118; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## If the specified crawler is running, stops the crawl.
                                                                                         ## 
  let valid = call_402658130.validator(path, query, header, formData, body, _)
  let scheme = call_402658130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658130.makeUrl(scheme.get, call_402658130.host, call_402658130.base,
                                   call_402658130.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658130, uri, valid, _)

proc call*(call_402658131: Call_StopCrawler_402658118; body: JsonNode): Recallable =
  ## stopCrawler
  ## If the specified crawler is running, stops the crawl.
  ##   body: JObject (required)
  var body_402658132 = newJObject()
  if body != nil:
    body_402658132 = body
  result = call_402658131.call(nil, nil, nil, nil, body_402658132)

var stopCrawler* = Call_StopCrawler_402658118(name: "stopCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StopCrawler",
    validator: validate_StopCrawler_402658119, base: "/",
    makeUrl: url_StopCrawler_402658120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCrawlerSchedule_402658133 = ref object of OpenApiRestCall_402656044
proc url_StopCrawlerSchedule_402658135(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopCrawlerSchedule_402658134(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658136 = header.getOrDefault("X-Amz-Target")
  valid_402658136 = validateParameter(valid_402658136, JString, required = true, default = newJString(
      "AWSGlue.StopCrawlerSchedule"))
  if valid_402658136 != nil:
    section.add "X-Amz-Target", valid_402658136
  var valid_402658137 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658137 = validateParameter(valid_402658137, JString,
                                      required = false, default = nil)
  if valid_402658137 != nil:
    section.add "X-Amz-Security-Token", valid_402658137
  var valid_402658138 = header.getOrDefault("X-Amz-Signature")
  valid_402658138 = validateParameter(valid_402658138, JString,
                                      required = false, default = nil)
  if valid_402658138 != nil:
    section.add "X-Amz-Signature", valid_402658138
  var valid_402658139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658139 = validateParameter(valid_402658139, JString,
                                      required = false, default = nil)
  if valid_402658139 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658139
  var valid_402658140 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658140 = validateParameter(valid_402658140, JString,
                                      required = false, default = nil)
  if valid_402658140 != nil:
    section.add "X-Amz-Algorithm", valid_402658140
  var valid_402658141 = header.getOrDefault("X-Amz-Date")
  valid_402658141 = validateParameter(valid_402658141, JString,
                                      required = false, default = nil)
  if valid_402658141 != nil:
    section.add "X-Amz-Date", valid_402658141
  var valid_402658142 = header.getOrDefault("X-Amz-Credential")
  valid_402658142 = validateParameter(valid_402658142, JString,
                                      required = false, default = nil)
  if valid_402658142 != nil:
    section.add "X-Amz-Credential", valid_402658142
  var valid_402658143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658143 = validateParameter(valid_402658143, JString,
                                      required = false, default = nil)
  if valid_402658143 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658145: Call_StopCrawlerSchedule_402658133;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
                                                                                         ## 
  let valid = call_402658145.validator(path, query, header, formData, body, _)
  let scheme = call_402658145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658145.makeUrl(scheme.get, call_402658145.host, call_402658145.base,
                                   call_402658145.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658145, uri, valid, _)

proc call*(call_402658146: Call_StopCrawlerSchedule_402658133; body: JsonNode): Recallable =
  ## stopCrawlerSchedule
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
  ##   
                                                                                                                                            ## body: JObject (required)
  var body_402658147 = newJObject()
  if body != nil:
    body_402658147 = body
  result = call_402658146.call(nil, nil, nil, nil, body_402658147)

var stopCrawlerSchedule* = Call_StopCrawlerSchedule_402658133(
    name: "stopCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StopCrawlerSchedule",
    validator: validate_StopCrawlerSchedule_402658134, base: "/",
    makeUrl: url_StopCrawlerSchedule_402658135,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrigger_402658148 = ref object of OpenApiRestCall_402656044
proc url_StopTrigger_402658150(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopTrigger_402658149(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Stops a specified trigger.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658151 = header.getOrDefault("X-Amz-Target")
  valid_402658151 = validateParameter(valid_402658151, JString, required = true, default = newJString(
      "AWSGlue.StopTrigger"))
  if valid_402658151 != nil:
    section.add "X-Amz-Target", valid_402658151
  var valid_402658152 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658152 = validateParameter(valid_402658152, JString,
                                      required = false, default = nil)
  if valid_402658152 != nil:
    section.add "X-Amz-Security-Token", valid_402658152
  var valid_402658153 = header.getOrDefault("X-Amz-Signature")
  valid_402658153 = validateParameter(valid_402658153, JString,
                                      required = false, default = nil)
  if valid_402658153 != nil:
    section.add "X-Amz-Signature", valid_402658153
  var valid_402658154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658154 = validateParameter(valid_402658154, JString,
                                      required = false, default = nil)
  if valid_402658154 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658154
  var valid_402658155 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658155 = validateParameter(valid_402658155, JString,
                                      required = false, default = nil)
  if valid_402658155 != nil:
    section.add "X-Amz-Algorithm", valid_402658155
  var valid_402658156 = header.getOrDefault("X-Amz-Date")
  valid_402658156 = validateParameter(valid_402658156, JString,
                                      required = false, default = nil)
  if valid_402658156 != nil:
    section.add "X-Amz-Date", valid_402658156
  var valid_402658157 = header.getOrDefault("X-Amz-Credential")
  valid_402658157 = validateParameter(valid_402658157, JString,
                                      required = false, default = nil)
  if valid_402658157 != nil:
    section.add "X-Amz-Credential", valid_402658157
  var valid_402658158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658158 = validateParameter(valid_402658158, JString,
                                      required = false, default = nil)
  if valid_402658158 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658160: Call_StopTrigger_402658148; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops a specified trigger.
                                                                                         ## 
  let valid = call_402658160.validator(path, query, header, formData, body, _)
  let scheme = call_402658160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658160.makeUrl(scheme.get, call_402658160.host, call_402658160.base,
                                   call_402658160.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658160, uri, valid, _)

proc call*(call_402658161: Call_StopTrigger_402658148; body: JsonNode): Recallable =
  ## stopTrigger
  ## Stops a specified trigger.
  ##   body: JObject (required)
  var body_402658162 = newJObject()
  if body != nil:
    body_402658162 = body
  result = call_402658161.call(nil, nil, nil, nil, body_402658162)

var stopTrigger* = Call_StopTrigger_402658148(name: "stopTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StopTrigger",
    validator: validate_StopTrigger_402658149, base: "/",
    makeUrl: url_StopTrigger_402658150, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402658163 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402658165(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_402658164(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658166 = header.getOrDefault("X-Amz-Target")
  valid_402658166 = validateParameter(valid_402658166, JString, required = true, default = newJString(
      "AWSGlue.TagResource"))
  if valid_402658166 != nil:
    section.add "X-Amz-Target", valid_402658166
  var valid_402658167 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658167 = validateParameter(valid_402658167, JString,
                                      required = false, default = nil)
  if valid_402658167 != nil:
    section.add "X-Amz-Security-Token", valid_402658167
  var valid_402658168 = header.getOrDefault("X-Amz-Signature")
  valid_402658168 = validateParameter(valid_402658168, JString,
                                      required = false, default = nil)
  if valid_402658168 != nil:
    section.add "X-Amz-Signature", valid_402658168
  var valid_402658169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658169 = validateParameter(valid_402658169, JString,
                                      required = false, default = nil)
  if valid_402658169 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658169
  var valid_402658170 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658170 = validateParameter(valid_402658170, JString,
                                      required = false, default = nil)
  if valid_402658170 != nil:
    section.add "X-Amz-Algorithm", valid_402658170
  var valid_402658171 = header.getOrDefault("X-Amz-Date")
  valid_402658171 = validateParameter(valid_402658171, JString,
                                      required = false, default = nil)
  if valid_402658171 != nil:
    section.add "X-Amz-Date", valid_402658171
  var valid_402658172 = header.getOrDefault("X-Amz-Credential")
  valid_402658172 = validateParameter(valid_402658172, JString,
                                      required = false, default = nil)
  if valid_402658172 != nil:
    section.add "X-Amz-Credential", valid_402658172
  var valid_402658173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658173 = validateParameter(valid_402658173, JString,
                                      required = false, default = nil)
  if valid_402658173 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658175: Call_TagResource_402658163; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
                                                                                         ## 
  let valid = call_402658175.validator(path, query, header, formData, body, _)
  let scheme = call_402658175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658175.makeUrl(scheme.get, call_402658175.host, call_402658175.base,
                                   call_402658175.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658175, uri, valid, _)

proc call*(call_402658176: Call_TagResource_402658163; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
  ##   
                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402658177 = newJObject()
  if body != nil:
    body_402658177 = body
  result = call_402658176.call(nil, nil, nil, nil, body_402658177)

var tagResource* = Call_TagResource_402658163(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.TagResource",
    validator: validate_TagResource_402658164, base: "/",
    makeUrl: url_TagResource_402658165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402658178 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402658180(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_402658179(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes tags from a resource.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658181 = header.getOrDefault("X-Amz-Target")
  valid_402658181 = validateParameter(valid_402658181, JString, required = true, default = newJString(
      "AWSGlue.UntagResource"))
  if valid_402658181 != nil:
    section.add "X-Amz-Target", valid_402658181
  var valid_402658182 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658182 = validateParameter(valid_402658182, JString,
                                      required = false, default = nil)
  if valid_402658182 != nil:
    section.add "X-Amz-Security-Token", valid_402658182
  var valid_402658183 = header.getOrDefault("X-Amz-Signature")
  valid_402658183 = validateParameter(valid_402658183, JString,
                                      required = false, default = nil)
  if valid_402658183 != nil:
    section.add "X-Amz-Signature", valid_402658183
  var valid_402658184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658184 = validateParameter(valid_402658184, JString,
                                      required = false, default = nil)
  if valid_402658184 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658184
  var valid_402658185 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658185 = validateParameter(valid_402658185, JString,
                                      required = false, default = nil)
  if valid_402658185 != nil:
    section.add "X-Amz-Algorithm", valid_402658185
  var valid_402658186 = header.getOrDefault("X-Amz-Date")
  valid_402658186 = validateParameter(valid_402658186, JString,
                                      required = false, default = nil)
  if valid_402658186 != nil:
    section.add "X-Amz-Date", valid_402658186
  var valid_402658187 = header.getOrDefault("X-Amz-Credential")
  valid_402658187 = validateParameter(valid_402658187, JString,
                                      required = false, default = nil)
  if valid_402658187 != nil:
    section.add "X-Amz-Credential", valid_402658187
  var valid_402658188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658188 = validateParameter(valid_402658188, JString,
                                      required = false, default = nil)
  if valid_402658188 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658190: Call_UntagResource_402658178; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes tags from a resource.
                                                                                         ## 
  let valid = call_402658190.validator(path, query, header, formData, body, _)
  let scheme = call_402658190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658190.makeUrl(scheme.get, call_402658190.host, call_402658190.base,
                                   call_402658190.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658190, uri, valid, _)

proc call*(call_402658191: Call_UntagResource_402658178; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   body: JObject (required)
  var body_402658192 = newJObject()
  if body != nil:
    body_402658192 = body
  result = call_402658191.call(nil, nil, nil, nil, body_402658192)

var untagResource* = Call_UntagResource_402658178(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UntagResource",
    validator: validate_UntagResource_402658179, base: "/",
    makeUrl: url_UntagResource_402658180, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClassifier_402658193 = ref object of OpenApiRestCall_402656044
proc url_UpdateClassifier_402658195(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateClassifier_402658194(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658196 = header.getOrDefault("X-Amz-Target")
  valid_402658196 = validateParameter(valid_402658196, JString, required = true, default = newJString(
      "AWSGlue.UpdateClassifier"))
  if valid_402658196 != nil:
    section.add "X-Amz-Target", valid_402658196
  var valid_402658197 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658197 = validateParameter(valid_402658197, JString,
                                      required = false, default = nil)
  if valid_402658197 != nil:
    section.add "X-Amz-Security-Token", valid_402658197
  var valid_402658198 = header.getOrDefault("X-Amz-Signature")
  valid_402658198 = validateParameter(valid_402658198, JString,
                                      required = false, default = nil)
  if valid_402658198 != nil:
    section.add "X-Amz-Signature", valid_402658198
  var valid_402658199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658199 = validateParameter(valid_402658199, JString,
                                      required = false, default = nil)
  if valid_402658199 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658199
  var valid_402658200 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658200 = validateParameter(valid_402658200, JString,
                                      required = false, default = nil)
  if valid_402658200 != nil:
    section.add "X-Amz-Algorithm", valid_402658200
  var valid_402658201 = header.getOrDefault("X-Amz-Date")
  valid_402658201 = validateParameter(valid_402658201, JString,
                                      required = false, default = nil)
  if valid_402658201 != nil:
    section.add "X-Amz-Date", valid_402658201
  var valid_402658202 = header.getOrDefault("X-Amz-Credential")
  valid_402658202 = validateParameter(valid_402658202, JString,
                                      required = false, default = nil)
  if valid_402658202 != nil:
    section.add "X-Amz-Credential", valid_402658202
  var valid_402658203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658203 = validateParameter(valid_402658203, JString,
                                      required = false, default = nil)
  if valid_402658203 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658205: Call_UpdateClassifier_402658193;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
                                                                                         ## 
  let valid = call_402658205.validator(path, query, header, formData, body, _)
  let scheme = call_402658205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658205.makeUrl(scheme.get, call_402658205.host, call_402658205.base,
                                   call_402658205.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658205, uri, valid, _)

proc call*(call_402658206: Call_UpdateClassifier_402658193; body: JsonNode): Recallable =
  ## updateClassifier
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
  ##   
                                                                                                                                                                                                         ## body: JObject (required)
  var body_402658207 = newJObject()
  if body != nil:
    body_402658207 = body
  result = call_402658206.call(nil, nil, nil, nil, body_402658207)

var updateClassifier* = Call_UpdateClassifier_402658193(
    name: "updateClassifier", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateClassifier",
    validator: validate_UpdateClassifier_402658194, base: "/",
    makeUrl: url_UpdateClassifier_402658195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnection_402658208 = ref object of OpenApiRestCall_402656044
proc url_UpdateConnection_402658210(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateConnection_402658209(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a connection definition in the Data Catalog.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658211 = header.getOrDefault("X-Amz-Target")
  valid_402658211 = validateParameter(valid_402658211, JString, required = true, default = newJString(
      "AWSGlue.UpdateConnection"))
  if valid_402658211 != nil:
    section.add "X-Amz-Target", valid_402658211
  var valid_402658212 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658212 = validateParameter(valid_402658212, JString,
                                      required = false, default = nil)
  if valid_402658212 != nil:
    section.add "X-Amz-Security-Token", valid_402658212
  var valid_402658213 = header.getOrDefault("X-Amz-Signature")
  valid_402658213 = validateParameter(valid_402658213, JString,
                                      required = false, default = nil)
  if valid_402658213 != nil:
    section.add "X-Amz-Signature", valid_402658213
  var valid_402658214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658214 = validateParameter(valid_402658214, JString,
                                      required = false, default = nil)
  if valid_402658214 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658214
  var valid_402658215 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658215 = validateParameter(valid_402658215, JString,
                                      required = false, default = nil)
  if valid_402658215 != nil:
    section.add "X-Amz-Algorithm", valid_402658215
  var valid_402658216 = header.getOrDefault("X-Amz-Date")
  valid_402658216 = validateParameter(valid_402658216, JString,
                                      required = false, default = nil)
  if valid_402658216 != nil:
    section.add "X-Amz-Date", valid_402658216
  var valid_402658217 = header.getOrDefault("X-Amz-Credential")
  valid_402658217 = validateParameter(valid_402658217, JString,
                                      required = false, default = nil)
  if valid_402658217 != nil:
    section.add "X-Amz-Credential", valid_402658217
  var valid_402658218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658218 = validateParameter(valid_402658218, JString,
                                      required = false, default = nil)
  if valid_402658218 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658220: Call_UpdateConnection_402658208;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a connection definition in the Data Catalog.
                                                                                         ## 
  let valid = call_402658220.validator(path, query, header, formData, body, _)
  let scheme = call_402658220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658220.makeUrl(scheme.get, call_402658220.host, call_402658220.base,
                                   call_402658220.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658220, uri, valid, _)

proc call*(call_402658221: Call_UpdateConnection_402658208; body: JsonNode): Recallable =
  ## updateConnection
  ## Updates a connection definition in the Data Catalog.
  ##   body: JObject (required)
  var body_402658222 = newJObject()
  if body != nil:
    body_402658222 = body
  result = call_402658221.call(nil, nil, nil, nil, body_402658222)

var updateConnection* = Call_UpdateConnection_402658208(
    name: "updateConnection", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateConnection",
    validator: validate_UpdateConnection_402658209, base: "/",
    makeUrl: url_UpdateConnection_402658210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCrawler_402658223 = ref object of OpenApiRestCall_402656044
proc url_UpdateCrawler_402658225(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateCrawler_402658224(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658226 = header.getOrDefault("X-Amz-Target")
  valid_402658226 = validateParameter(valid_402658226, JString, required = true, default = newJString(
      "AWSGlue.UpdateCrawler"))
  if valid_402658226 != nil:
    section.add "X-Amz-Target", valid_402658226
  var valid_402658227 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658227 = validateParameter(valid_402658227, JString,
                                      required = false, default = nil)
  if valid_402658227 != nil:
    section.add "X-Amz-Security-Token", valid_402658227
  var valid_402658228 = header.getOrDefault("X-Amz-Signature")
  valid_402658228 = validateParameter(valid_402658228, JString,
                                      required = false, default = nil)
  if valid_402658228 != nil:
    section.add "X-Amz-Signature", valid_402658228
  var valid_402658229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658229 = validateParameter(valid_402658229, JString,
                                      required = false, default = nil)
  if valid_402658229 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658229
  var valid_402658230 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658230 = validateParameter(valid_402658230, JString,
                                      required = false, default = nil)
  if valid_402658230 != nil:
    section.add "X-Amz-Algorithm", valid_402658230
  var valid_402658231 = header.getOrDefault("X-Amz-Date")
  valid_402658231 = validateParameter(valid_402658231, JString,
                                      required = false, default = nil)
  if valid_402658231 != nil:
    section.add "X-Amz-Date", valid_402658231
  var valid_402658232 = header.getOrDefault("X-Amz-Credential")
  valid_402658232 = validateParameter(valid_402658232, JString,
                                      required = false, default = nil)
  if valid_402658232 != nil:
    section.add "X-Amz-Credential", valid_402658232
  var valid_402658233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658233 = validateParameter(valid_402658233, JString,
                                      required = false, default = nil)
  if valid_402658233 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658235: Call_UpdateCrawler_402658223; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
                                                                                         ## 
  let valid = call_402658235.validator(path, query, header, formData, body, _)
  let scheme = call_402658235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658235.makeUrl(scheme.get, call_402658235.host, call_402658235.base,
                                   call_402658235.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658235, uri, valid, _)

proc call*(call_402658236: Call_UpdateCrawler_402658223; body: JsonNode): Recallable =
  ## updateCrawler
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
  ##   
                                                                                                                    ## body: JObject (required)
  var body_402658237 = newJObject()
  if body != nil:
    body_402658237 = body
  result = call_402658236.call(nil, nil, nil, nil, body_402658237)

var updateCrawler* = Call_UpdateCrawler_402658223(name: "updateCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateCrawler",
    validator: validate_UpdateCrawler_402658224, base: "/",
    makeUrl: url_UpdateCrawler_402658225, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCrawlerSchedule_402658238 = ref object of OpenApiRestCall_402656044
proc url_UpdateCrawlerSchedule_402658240(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateCrawlerSchedule_402658239(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658241 = header.getOrDefault("X-Amz-Target")
  valid_402658241 = validateParameter(valid_402658241, JString, required = true, default = newJString(
      "AWSGlue.UpdateCrawlerSchedule"))
  if valid_402658241 != nil:
    section.add "X-Amz-Target", valid_402658241
  var valid_402658242 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658242 = validateParameter(valid_402658242, JString,
                                      required = false, default = nil)
  if valid_402658242 != nil:
    section.add "X-Amz-Security-Token", valid_402658242
  var valid_402658243 = header.getOrDefault("X-Amz-Signature")
  valid_402658243 = validateParameter(valid_402658243, JString,
                                      required = false, default = nil)
  if valid_402658243 != nil:
    section.add "X-Amz-Signature", valid_402658243
  var valid_402658244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658244 = validateParameter(valid_402658244, JString,
                                      required = false, default = nil)
  if valid_402658244 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658244
  var valid_402658245 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658245 = validateParameter(valid_402658245, JString,
                                      required = false, default = nil)
  if valid_402658245 != nil:
    section.add "X-Amz-Algorithm", valid_402658245
  var valid_402658246 = header.getOrDefault("X-Amz-Date")
  valid_402658246 = validateParameter(valid_402658246, JString,
                                      required = false, default = nil)
  if valid_402658246 != nil:
    section.add "X-Amz-Date", valid_402658246
  var valid_402658247 = header.getOrDefault("X-Amz-Credential")
  valid_402658247 = validateParameter(valid_402658247, JString,
                                      required = false, default = nil)
  if valid_402658247 != nil:
    section.add "X-Amz-Credential", valid_402658247
  var valid_402658248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658248 = validateParameter(valid_402658248, JString,
                                      required = false, default = nil)
  if valid_402658248 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658250: Call_UpdateCrawlerSchedule_402658238;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
                                                                                         ## 
  let valid = call_402658250.validator(path, query, header, formData, body, _)
  let scheme = call_402658250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658250.makeUrl(scheme.get, call_402658250.host, call_402658250.base,
                                   call_402658250.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658250, uri, valid, _)

proc call*(call_402658251: Call_UpdateCrawlerSchedule_402658238; body: JsonNode): Recallable =
  ## updateCrawlerSchedule
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
  ##   
                                                                             ## body: JObject (required)
  var body_402658252 = newJObject()
  if body != nil:
    body_402658252 = body
  result = call_402658251.call(nil, nil, nil, nil, body_402658252)

var updateCrawlerSchedule* = Call_UpdateCrawlerSchedule_402658238(
    name: "updateCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateCrawlerSchedule",
    validator: validate_UpdateCrawlerSchedule_402658239, base: "/",
    makeUrl: url_UpdateCrawlerSchedule_402658240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDatabase_402658253 = ref object of OpenApiRestCall_402656044
proc url_UpdateDatabase_402658255(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDatabase_402658254(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an existing database definition in a Data Catalog.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658256 = header.getOrDefault("X-Amz-Target")
  valid_402658256 = validateParameter(valid_402658256, JString, required = true, default = newJString(
      "AWSGlue.UpdateDatabase"))
  if valid_402658256 != nil:
    section.add "X-Amz-Target", valid_402658256
  var valid_402658257 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658257 = validateParameter(valid_402658257, JString,
                                      required = false, default = nil)
  if valid_402658257 != nil:
    section.add "X-Amz-Security-Token", valid_402658257
  var valid_402658258 = header.getOrDefault("X-Amz-Signature")
  valid_402658258 = validateParameter(valid_402658258, JString,
                                      required = false, default = nil)
  if valid_402658258 != nil:
    section.add "X-Amz-Signature", valid_402658258
  var valid_402658259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658259 = validateParameter(valid_402658259, JString,
                                      required = false, default = nil)
  if valid_402658259 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658259
  var valid_402658260 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658260 = validateParameter(valid_402658260, JString,
                                      required = false, default = nil)
  if valid_402658260 != nil:
    section.add "X-Amz-Algorithm", valid_402658260
  var valid_402658261 = header.getOrDefault("X-Amz-Date")
  valid_402658261 = validateParameter(valid_402658261, JString,
                                      required = false, default = nil)
  if valid_402658261 != nil:
    section.add "X-Amz-Date", valid_402658261
  var valid_402658262 = header.getOrDefault("X-Amz-Credential")
  valid_402658262 = validateParameter(valid_402658262, JString,
                                      required = false, default = nil)
  if valid_402658262 != nil:
    section.add "X-Amz-Credential", valid_402658262
  var valid_402658263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658263 = validateParameter(valid_402658263, JString,
                                      required = false, default = nil)
  if valid_402658263 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658265: Call_UpdateDatabase_402658253; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing database definition in a Data Catalog.
                                                                                         ## 
  let valid = call_402658265.validator(path, query, header, formData, body, _)
  let scheme = call_402658265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658265.makeUrl(scheme.get, call_402658265.host, call_402658265.base,
                                   call_402658265.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658265, uri, valid, _)

proc call*(call_402658266: Call_UpdateDatabase_402658253; body: JsonNode): Recallable =
  ## updateDatabase
  ## Updates an existing database definition in a Data Catalog.
  ##   body: JObject (required)
  var body_402658267 = newJObject()
  if body != nil:
    body_402658267 = body
  result = call_402658266.call(nil, nil, nil, nil, body_402658267)

var updateDatabase* = Call_UpdateDatabase_402658253(name: "updateDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateDatabase",
    validator: validate_UpdateDatabase_402658254, base: "/",
    makeUrl: url_UpdateDatabase_402658255, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevEndpoint_402658268 = ref object of OpenApiRestCall_402656044
proc url_UpdateDevEndpoint_402658270(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDevEndpoint_402658269(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a specified development endpoint.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658271 = header.getOrDefault("X-Amz-Target")
  valid_402658271 = validateParameter(valid_402658271, JString, required = true, default = newJString(
      "AWSGlue.UpdateDevEndpoint"))
  if valid_402658271 != nil:
    section.add "X-Amz-Target", valid_402658271
  var valid_402658272 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658272 = validateParameter(valid_402658272, JString,
                                      required = false, default = nil)
  if valid_402658272 != nil:
    section.add "X-Amz-Security-Token", valid_402658272
  var valid_402658273 = header.getOrDefault("X-Amz-Signature")
  valid_402658273 = validateParameter(valid_402658273, JString,
                                      required = false, default = nil)
  if valid_402658273 != nil:
    section.add "X-Amz-Signature", valid_402658273
  var valid_402658274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658274 = validateParameter(valid_402658274, JString,
                                      required = false, default = nil)
  if valid_402658274 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658274
  var valid_402658275 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658275 = validateParameter(valid_402658275, JString,
                                      required = false, default = nil)
  if valid_402658275 != nil:
    section.add "X-Amz-Algorithm", valid_402658275
  var valid_402658276 = header.getOrDefault("X-Amz-Date")
  valid_402658276 = validateParameter(valid_402658276, JString,
                                      required = false, default = nil)
  if valid_402658276 != nil:
    section.add "X-Amz-Date", valid_402658276
  var valid_402658277 = header.getOrDefault("X-Amz-Credential")
  valid_402658277 = validateParameter(valid_402658277, JString,
                                      required = false, default = nil)
  if valid_402658277 != nil:
    section.add "X-Amz-Credential", valid_402658277
  var valid_402658278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658278 = validateParameter(valid_402658278, JString,
                                      required = false, default = nil)
  if valid_402658278 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658280: Call_UpdateDevEndpoint_402658268;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a specified development endpoint.
                                                                                         ## 
  let valid = call_402658280.validator(path, query, header, formData, body, _)
  let scheme = call_402658280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658280.makeUrl(scheme.get, call_402658280.host, call_402658280.base,
                                   call_402658280.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658280, uri, valid, _)

proc call*(call_402658281: Call_UpdateDevEndpoint_402658268; body: JsonNode): Recallable =
  ## updateDevEndpoint
  ## Updates a specified development endpoint.
  ##   body: JObject (required)
  var body_402658282 = newJObject()
  if body != nil:
    body_402658282 = body
  result = call_402658281.call(nil, nil, nil, nil, body_402658282)

var updateDevEndpoint* = Call_UpdateDevEndpoint_402658268(
    name: "updateDevEndpoint", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateDevEndpoint",
    validator: validate_UpdateDevEndpoint_402658269, base: "/",
    makeUrl: url_UpdateDevEndpoint_402658270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJob_402658283 = ref object of OpenApiRestCall_402656044
proc url_UpdateJob_402658285(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateJob_402658284(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an existing job definition.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658286 = header.getOrDefault("X-Amz-Target")
  valid_402658286 = validateParameter(valid_402658286, JString, required = true,
                                      default = newJString("AWSGlue.UpdateJob"))
  if valid_402658286 != nil:
    section.add "X-Amz-Target", valid_402658286
  var valid_402658287 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658287 = validateParameter(valid_402658287, JString,
                                      required = false, default = nil)
  if valid_402658287 != nil:
    section.add "X-Amz-Security-Token", valid_402658287
  var valid_402658288 = header.getOrDefault("X-Amz-Signature")
  valid_402658288 = validateParameter(valid_402658288, JString,
                                      required = false, default = nil)
  if valid_402658288 != nil:
    section.add "X-Amz-Signature", valid_402658288
  var valid_402658289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658289 = validateParameter(valid_402658289, JString,
                                      required = false, default = nil)
  if valid_402658289 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658289
  var valid_402658290 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658290 = validateParameter(valid_402658290, JString,
                                      required = false, default = nil)
  if valid_402658290 != nil:
    section.add "X-Amz-Algorithm", valid_402658290
  var valid_402658291 = header.getOrDefault("X-Amz-Date")
  valid_402658291 = validateParameter(valid_402658291, JString,
                                      required = false, default = nil)
  if valid_402658291 != nil:
    section.add "X-Amz-Date", valid_402658291
  var valid_402658292 = header.getOrDefault("X-Amz-Credential")
  valid_402658292 = validateParameter(valid_402658292, JString,
                                      required = false, default = nil)
  if valid_402658292 != nil:
    section.add "X-Amz-Credential", valid_402658292
  var valid_402658293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658293 = validateParameter(valid_402658293, JString,
                                      required = false, default = nil)
  if valid_402658293 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658295: Call_UpdateJob_402658283; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing job definition.
                                                                                         ## 
  let valid = call_402658295.validator(path, query, header, formData, body, _)
  let scheme = call_402658295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658295.makeUrl(scheme.get, call_402658295.host, call_402658295.base,
                                   call_402658295.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658295, uri, valid, _)

proc call*(call_402658296: Call_UpdateJob_402658283; body: JsonNode): Recallable =
  ## updateJob
  ## Updates an existing job definition.
  ##   body: JObject (required)
  var body_402658297 = newJObject()
  if body != nil:
    body_402658297 = body
  result = call_402658296.call(nil, nil, nil, nil, body_402658297)

var updateJob* = Call_UpdateJob_402658283(name: "updateJob",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateJob", validator: validate_UpdateJob_402658284,
    base: "/", makeUrl: url_UpdateJob_402658285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMLTransform_402658298 = ref object of OpenApiRestCall_402656044
proc url_UpdateMLTransform_402658300(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateMLTransform_402658299(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658301 = header.getOrDefault("X-Amz-Target")
  valid_402658301 = validateParameter(valid_402658301, JString, required = true, default = newJString(
      "AWSGlue.UpdateMLTransform"))
  if valid_402658301 != nil:
    section.add "X-Amz-Target", valid_402658301
  var valid_402658302 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658302 = validateParameter(valid_402658302, JString,
                                      required = false, default = nil)
  if valid_402658302 != nil:
    section.add "X-Amz-Security-Token", valid_402658302
  var valid_402658303 = header.getOrDefault("X-Amz-Signature")
  valid_402658303 = validateParameter(valid_402658303, JString,
                                      required = false, default = nil)
  if valid_402658303 != nil:
    section.add "X-Amz-Signature", valid_402658303
  var valid_402658304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658304 = validateParameter(valid_402658304, JString,
                                      required = false, default = nil)
  if valid_402658304 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658304
  var valid_402658305 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658305 = validateParameter(valid_402658305, JString,
                                      required = false, default = nil)
  if valid_402658305 != nil:
    section.add "X-Amz-Algorithm", valid_402658305
  var valid_402658306 = header.getOrDefault("X-Amz-Date")
  valid_402658306 = validateParameter(valid_402658306, JString,
                                      required = false, default = nil)
  if valid_402658306 != nil:
    section.add "X-Amz-Date", valid_402658306
  var valid_402658307 = header.getOrDefault("X-Amz-Credential")
  valid_402658307 = validateParameter(valid_402658307, JString,
                                      required = false, default = nil)
  if valid_402658307 != nil:
    section.add "X-Amz-Credential", valid_402658307
  var valid_402658308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658308 = validateParameter(valid_402658308, JString,
                                      required = false, default = nil)
  if valid_402658308 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658310: Call_UpdateMLTransform_402658298;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
                                                                                         ## 
  let valid = call_402658310.validator(path, query, header, formData, body, _)
  let scheme = call_402658310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658310.makeUrl(scheme.get, call_402658310.host, call_402658310.base,
                                   call_402658310.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658310, uri, valid, _)

proc call*(call_402658311: Call_UpdateMLTransform_402658298; body: JsonNode): Recallable =
  ## updateMLTransform
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402658312 = newJObject()
  if body != nil:
    body_402658312 = body
  result = call_402658311.call(nil, nil, nil, nil, body_402658312)

var updateMLTransform* = Call_UpdateMLTransform_402658298(
    name: "updateMLTransform", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateMLTransform",
    validator: validate_UpdateMLTransform_402658299, base: "/",
    makeUrl: url_UpdateMLTransform_402658300,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePartition_402658313 = ref object of OpenApiRestCall_402656044
proc url_UpdatePartition_402658315(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePartition_402658314(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a partition.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658316 = header.getOrDefault("X-Amz-Target")
  valid_402658316 = validateParameter(valid_402658316, JString, required = true, default = newJString(
      "AWSGlue.UpdatePartition"))
  if valid_402658316 != nil:
    section.add "X-Amz-Target", valid_402658316
  var valid_402658317 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658317 = validateParameter(valid_402658317, JString,
                                      required = false, default = nil)
  if valid_402658317 != nil:
    section.add "X-Amz-Security-Token", valid_402658317
  var valid_402658318 = header.getOrDefault("X-Amz-Signature")
  valid_402658318 = validateParameter(valid_402658318, JString,
                                      required = false, default = nil)
  if valid_402658318 != nil:
    section.add "X-Amz-Signature", valid_402658318
  var valid_402658319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658319 = validateParameter(valid_402658319, JString,
                                      required = false, default = nil)
  if valid_402658319 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658319
  var valid_402658320 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658320 = validateParameter(valid_402658320, JString,
                                      required = false, default = nil)
  if valid_402658320 != nil:
    section.add "X-Amz-Algorithm", valid_402658320
  var valid_402658321 = header.getOrDefault("X-Amz-Date")
  valid_402658321 = validateParameter(valid_402658321, JString,
                                      required = false, default = nil)
  if valid_402658321 != nil:
    section.add "X-Amz-Date", valid_402658321
  var valid_402658322 = header.getOrDefault("X-Amz-Credential")
  valid_402658322 = validateParameter(valid_402658322, JString,
                                      required = false, default = nil)
  if valid_402658322 != nil:
    section.add "X-Amz-Credential", valid_402658322
  var valid_402658323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658323 = validateParameter(valid_402658323, JString,
                                      required = false, default = nil)
  if valid_402658323 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658325: Call_UpdatePartition_402658313; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a partition.
                                                                                         ## 
  let valid = call_402658325.validator(path, query, header, formData, body, _)
  let scheme = call_402658325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658325.makeUrl(scheme.get, call_402658325.host, call_402658325.base,
                                   call_402658325.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658325, uri, valid, _)

proc call*(call_402658326: Call_UpdatePartition_402658313; body: JsonNode): Recallable =
  ## updatePartition
  ## Updates a partition.
  ##   body: JObject (required)
  var body_402658327 = newJObject()
  if body != nil:
    body_402658327 = body
  result = call_402658326.call(nil, nil, nil, nil, body_402658327)

var updatePartition* = Call_UpdatePartition_402658313(name: "updatePartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdatePartition",
    validator: validate_UpdatePartition_402658314, base: "/",
    makeUrl: url_UpdatePartition_402658315, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTable_402658328 = ref object of OpenApiRestCall_402656044
proc url_UpdateTable_402658330(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTable_402658329(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a metadata table in the Data Catalog.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658331 = header.getOrDefault("X-Amz-Target")
  valid_402658331 = validateParameter(valid_402658331, JString, required = true, default = newJString(
      "AWSGlue.UpdateTable"))
  if valid_402658331 != nil:
    section.add "X-Amz-Target", valid_402658331
  var valid_402658332 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658332 = validateParameter(valid_402658332, JString,
                                      required = false, default = nil)
  if valid_402658332 != nil:
    section.add "X-Amz-Security-Token", valid_402658332
  var valid_402658333 = header.getOrDefault("X-Amz-Signature")
  valid_402658333 = validateParameter(valid_402658333, JString,
                                      required = false, default = nil)
  if valid_402658333 != nil:
    section.add "X-Amz-Signature", valid_402658333
  var valid_402658334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658334 = validateParameter(valid_402658334, JString,
                                      required = false, default = nil)
  if valid_402658334 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658334
  var valid_402658335 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658335 = validateParameter(valid_402658335, JString,
                                      required = false, default = nil)
  if valid_402658335 != nil:
    section.add "X-Amz-Algorithm", valid_402658335
  var valid_402658336 = header.getOrDefault("X-Amz-Date")
  valid_402658336 = validateParameter(valid_402658336, JString,
                                      required = false, default = nil)
  if valid_402658336 != nil:
    section.add "X-Amz-Date", valid_402658336
  var valid_402658337 = header.getOrDefault("X-Amz-Credential")
  valid_402658337 = validateParameter(valid_402658337, JString,
                                      required = false, default = nil)
  if valid_402658337 != nil:
    section.add "X-Amz-Credential", valid_402658337
  var valid_402658338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658338 = validateParameter(valid_402658338, JString,
                                      required = false, default = nil)
  if valid_402658338 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658340: Call_UpdateTable_402658328; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a metadata table in the Data Catalog.
                                                                                         ## 
  let valid = call_402658340.validator(path, query, header, formData, body, _)
  let scheme = call_402658340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658340.makeUrl(scheme.get, call_402658340.host, call_402658340.base,
                                   call_402658340.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658340, uri, valid, _)

proc call*(call_402658341: Call_UpdateTable_402658328; body: JsonNode): Recallable =
  ## updateTable
  ## Updates a metadata table in the Data Catalog.
  ##   body: JObject (required)
  var body_402658342 = newJObject()
  if body != nil:
    body_402658342 = body
  result = call_402658341.call(nil, nil, nil, nil, body_402658342)

var updateTable* = Call_UpdateTable_402658328(name: "updateTable",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateTable",
    validator: validate_UpdateTable_402658329, base: "/",
    makeUrl: url_UpdateTable_402658330, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrigger_402658343 = ref object of OpenApiRestCall_402656044
proc url_UpdateTrigger_402658345(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTrigger_402658344(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a trigger definition.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658346 = header.getOrDefault("X-Amz-Target")
  valid_402658346 = validateParameter(valid_402658346, JString, required = true, default = newJString(
      "AWSGlue.UpdateTrigger"))
  if valid_402658346 != nil:
    section.add "X-Amz-Target", valid_402658346
  var valid_402658347 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658347 = validateParameter(valid_402658347, JString,
                                      required = false, default = nil)
  if valid_402658347 != nil:
    section.add "X-Amz-Security-Token", valid_402658347
  var valid_402658348 = header.getOrDefault("X-Amz-Signature")
  valid_402658348 = validateParameter(valid_402658348, JString,
                                      required = false, default = nil)
  if valid_402658348 != nil:
    section.add "X-Amz-Signature", valid_402658348
  var valid_402658349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658349 = validateParameter(valid_402658349, JString,
                                      required = false, default = nil)
  if valid_402658349 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658349
  var valid_402658350 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658350 = validateParameter(valid_402658350, JString,
                                      required = false, default = nil)
  if valid_402658350 != nil:
    section.add "X-Amz-Algorithm", valid_402658350
  var valid_402658351 = header.getOrDefault("X-Amz-Date")
  valid_402658351 = validateParameter(valid_402658351, JString,
                                      required = false, default = nil)
  if valid_402658351 != nil:
    section.add "X-Amz-Date", valid_402658351
  var valid_402658352 = header.getOrDefault("X-Amz-Credential")
  valid_402658352 = validateParameter(valid_402658352, JString,
                                      required = false, default = nil)
  if valid_402658352 != nil:
    section.add "X-Amz-Credential", valid_402658352
  var valid_402658353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658353 = validateParameter(valid_402658353, JString,
                                      required = false, default = nil)
  if valid_402658353 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658355: Call_UpdateTrigger_402658343; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a trigger definition.
                                                                                         ## 
  let valid = call_402658355.validator(path, query, header, formData, body, _)
  let scheme = call_402658355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658355.makeUrl(scheme.get, call_402658355.host, call_402658355.base,
                                   call_402658355.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658355, uri, valid, _)

proc call*(call_402658356: Call_UpdateTrigger_402658343; body: JsonNode): Recallable =
  ## updateTrigger
  ## Updates a trigger definition.
  ##   body: JObject (required)
  var body_402658357 = newJObject()
  if body != nil:
    body_402658357 = body
  result = call_402658356.call(nil, nil, nil, nil, body_402658357)

var updateTrigger* = Call_UpdateTrigger_402658343(name: "updateTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateTrigger",
    validator: validate_UpdateTrigger_402658344, base: "/",
    makeUrl: url_UpdateTrigger_402658345, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserDefinedFunction_402658358 = ref object of OpenApiRestCall_402656044
proc url_UpdateUserDefinedFunction_402658360(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserDefinedFunction_402658359(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Updates an existing function definition in the Data Catalog.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658361 = header.getOrDefault("X-Amz-Target")
  valid_402658361 = validateParameter(valid_402658361, JString, required = true, default = newJString(
      "AWSGlue.UpdateUserDefinedFunction"))
  if valid_402658361 != nil:
    section.add "X-Amz-Target", valid_402658361
  var valid_402658362 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658362 = validateParameter(valid_402658362, JString,
                                      required = false, default = nil)
  if valid_402658362 != nil:
    section.add "X-Amz-Security-Token", valid_402658362
  var valid_402658363 = header.getOrDefault("X-Amz-Signature")
  valid_402658363 = validateParameter(valid_402658363, JString,
                                      required = false, default = nil)
  if valid_402658363 != nil:
    section.add "X-Amz-Signature", valid_402658363
  var valid_402658364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658364 = validateParameter(valid_402658364, JString,
                                      required = false, default = nil)
  if valid_402658364 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658364
  var valid_402658365 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658365 = validateParameter(valid_402658365, JString,
                                      required = false, default = nil)
  if valid_402658365 != nil:
    section.add "X-Amz-Algorithm", valid_402658365
  var valid_402658366 = header.getOrDefault("X-Amz-Date")
  valid_402658366 = validateParameter(valid_402658366, JString,
                                      required = false, default = nil)
  if valid_402658366 != nil:
    section.add "X-Amz-Date", valid_402658366
  var valid_402658367 = header.getOrDefault("X-Amz-Credential")
  valid_402658367 = validateParameter(valid_402658367, JString,
                                      required = false, default = nil)
  if valid_402658367 != nil:
    section.add "X-Amz-Credential", valid_402658367
  var valid_402658368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658368 = validateParameter(valid_402658368, JString,
                                      required = false, default = nil)
  if valid_402658368 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658370: Call_UpdateUserDefinedFunction_402658358;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing function definition in the Data Catalog.
                                                                                         ## 
  let valid = call_402658370.validator(path, query, header, formData, body, _)
  let scheme = call_402658370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658370.makeUrl(scheme.get, call_402658370.host, call_402658370.base,
                                   call_402658370.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658370, uri, valid, _)

proc call*(call_402658371: Call_UpdateUserDefinedFunction_402658358;
           body: JsonNode): Recallable =
  ## updateUserDefinedFunction
  ## Updates an existing function definition in the Data Catalog.
  ##   body: JObject (required)
  var body_402658372 = newJObject()
  if body != nil:
    body_402658372 = body
  result = call_402658371.call(nil, nil, nil, nil, body_402658372)

var updateUserDefinedFunction* = Call_UpdateUserDefinedFunction_402658358(
    name: "updateUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateUserDefinedFunction",
    validator: validate_UpdateUserDefinedFunction_402658359, base: "/",
    makeUrl: url_UpdateUserDefinedFunction_402658360,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkflow_402658373 = ref object of OpenApiRestCall_402656044
proc url_UpdateWorkflow_402658375(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateWorkflow_402658374(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an existing workflow.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658376 = header.getOrDefault("X-Amz-Target")
  valid_402658376 = validateParameter(valid_402658376, JString, required = true, default = newJString(
      "AWSGlue.UpdateWorkflow"))
  if valid_402658376 != nil:
    section.add "X-Amz-Target", valid_402658376
  var valid_402658377 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658377 = validateParameter(valid_402658377, JString,
                                      required = false, default = nil)
  if valid_402658377 != nil:
    section.add "X-Amz-Security-Token", valid_402658377
  var valid_402658378 = header.getOrDefault("X-Amz-Signature")
  valid_402658378 = validateParameter(valid_402658378, JString,
                                      required = false, default = nil)
  if valid_402658378 != nil:
    section.add "X-Amz-Signature", valid_402658378
  var valid_402658379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658379 = validateParameter(valid_402658379, JString,
                                      required = false, default = nil)
  if valid_402658379 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658379
  var valid_402658380 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658380 = validateParameter(valid_402658380, JString,
                                      required = false, default = nil)
  if valid_402658380 != nil:
    section.add "X-Amz-Algorithm", valid_402658380
  var valid_402658381 = header.getOrDefault("X-Amz-Date")
  valid_402658381 = validateParameter(valid_402658381, JString,
                                      required = false, default = nil)
  if valid_402658381 != nil:
    section.add "X-Amz-Date", valid_402658381
  var valid_402658382 = header.getOrDefault("X-Amz-Credential")
  valid_402658382 = validateParameter(valid_402658382, JString,
                                      required = false, default = nil)
  if valid_402658382 != nil:
    section.add "X-Amz-Credential", valid_402658382
  var valid_402658383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658383 = validateParameter(valid_402658383, JString,
                                      required = false, default = nil)
  if valid_402658383 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658385: Call_UpdateWorkflow_402658373; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing workflow.
                                                                                         ## 
  let valid = call_402658385.validator(path, query, header, formData, body, _)
  let scheme = call_402658385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658385.makeUrl(scheme.get, call_402658385.host, call_402658385.base,
                                   call_402658385.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658385, uri, valid, _)

proc call*(call_402658386: Call_UpdateWorkflow_402658373; body: JsonNode): Recallable =
  ## updateWorkflow
  ## Updates an existing workflow.
  ##   body: JObject (required)
  var body_402658387 = newJObject()
  if body != nil:
    body_402658387 = body
  result = call_402658386.call(nil, nil, nil, nil, body_402658387)

var updateWorkflow* = Call_UpdateWorkflow_402658373(name: "updateWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateWorkflow",
    validator: validate_UpdateWorkflow_402658374, base: "/",
    makeUrl: url_UpdateWorkflow_402658375, schemes: {Scheme.Https, Scheme.Http})
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
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
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