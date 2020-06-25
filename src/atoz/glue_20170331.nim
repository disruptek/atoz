
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "glue.ap-northeast-1.amazonaws.com", "ap-southeast-1": "glue.ap-southeast-1.amazonaws.com",
                           "us-west-2": "glue.us-west-2.amazonaws.com",
                           "eu-west-2": "glue.eu-west-2.amazonaws.com", "ap-northeast-3": "glue.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "glue.eu-central-1.amazonaws.com",
                           "us-east-2": "glue.us-east-2.amazonaws.com",
                           "us-east-1": "glue.us-east-1.amazonaws.com", "cn-northwest-1": "glue.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "glue.ap-south-1.amazonaws.com",
                           "eu-north-1": "glue.eu-north-1.amazonaws.com", "ap-northeast-2": "glue.ap-northeast-2.amazonaws.com",
                           "us-west-1": "glue.us-west-1.amazonaws.com",
                           "us-gov-east-1": "glue.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "glue.eu-west-3.amazonaws.com",
                           "cn-north-1": "glue.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "glue.sa-east-1.amazonaws.com",
                           "eu-west-1": "glue.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "glue.us-gov-west-1.amazonaws.com", "ap-southeast-2": "glue.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "glue.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_BatchCreatePartition_21625779 = ref object of OpenApiRestCall_21625435
proc url_BatchCreatePartition_21625781(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchCreatePartition_21625780(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625882 = header.getOrDefault("X-Amz-Date")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Date", valid_21625882
  var valid_21625883 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Security-Token", valid_21625883
  var valid_21625898 = header.getOrDefault("X-Amz-Target")
  valid_21625898 = validateParameter(valid_21625898, JString, required = true, default = newJString(
      "AWSGlue.BatchCreatePartition"))
  if valid_21625898 != nil:
    section.add "X-Amz-Target", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Algorithm", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Signature")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Signature", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Credential")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Credential", valid_21625903
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

proc call*(call_21625929: Call_BatchCreatePartition_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates one or more partitions in a batch operation.
  ## 
  let valid = call_21625929.validator(path, query, header, formData, body, _)
  let scheme = call_21625929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625929.makeUrl(scheme.get, call_21625929.host, call_21625929.base,
                               call_21625929.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625929, uri, valid, _)

proc call*(call_21625992: Call_BatchCreatePartition_21625779; body: JsonNode): Recallable =
  ## batchCreatePartition
  ## Creates one or more partitions in a batch operation.
  ##   body: JObject (required)
  var body_21625993 = newJObject()
  if body != nil:
    body_21625993 = body
  result = call_21625992.call(nil, nil, nil, nil, body_21625993)

var batchCreatePartition* = Call_BatchCreatePartition_21625779(
    name: "batchCreatePartition", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchCreatePartition",
    validator: validate_BatchCreatePartition_21625780, base: "/",
    makeUrl: url_BatchCreatePartition_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteConnection_21626029 = ref object of OpenApiRestCall_21625435
proc url_BatchDeleteConnection_21626031(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDeleteConnection_21626030(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626032 = header.getOrDefault("X-Amz-Date")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-Date", valid_21626032
  var valid_21626033 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Security-Token", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-Target")
  valid_21626034 = validateParameter(valid_21626034, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteConnection"))
  if valid_21626034 != nil:
    section.add "X-Amz-Target", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Algorithm", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Signature")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Signature", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Credential")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Credential", valid_21626039
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

proc call*(call_21626041: Call_BatchDeleteConnection_21626029;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a list of connection definitions from the Data Catalog.
  ## 
  let valid = call_21626041.validator(path, query, header, formData, body, _)
  let scheme = call_21626041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626041.makeUrl(scheme.get, call_21626041.host, call_21626041.base,
                               call_21626041.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626041, uri, valid, _)

proc call*(call_21626042: Call_BatchDeleteConnection_21626029; body: JsonNode): Recallable =
  ## batchDeleteConnection
  ## Deletes a list of connection definitions from the Data Catalog.
  ##   body: JObject (required)
  var body_21626043 = newJObject()
  if body != nil:
    body_21626043 = body
  result = call_21626042.call(nil, nil, nil, nil, body_21626043)

var batchDeleteConnection* = Call_BatchDeleteConnection_21626029(
    name: "batchDeleteConnection", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteConnection",
    validator: validate_BatchDeleteConnection_21626030, base: "/",
    makeUrl: url_BatchDeleteConnection_21626031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeletePartition_21626044 = ref object of OpenApiRestCall_21625435
proc url_BatchDeletePartition_21626046(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDeletePartition_21626045(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626047 = header.getOrDefault("X-Amz-Date")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Date", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Security-Token", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Target")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true, default = newJString(
      "AWSGlue.BatchDeletePartition"))
  if valid_21626049 != nil:
    section.add "X-Amz-Target", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Algorithm", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Signature")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Signature", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Credential")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Credential", valid_21626054
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

proc call*(call_21626056: Call_BatchDeletePartition_21626044; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes one or more partitions in a batch operation.
  ## 
  let valid = call_21626056.validator(path, query, header, formData, body, _)
  let scheme = call_21626056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626056.makeUrl(scheme.get, call_21626056.host, call_21626056.base,
                               call_21626056.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626056, uri, valid, _)

proc call*(call_21626057: Call_BatchDeletePartition_21626044; body: JsonNode): Recallable =
  ## batchDeletePartition
  ## Deletes one or more partitions in a batch operation.
  ##   body: JObject (required)
  var body_21626058 = newJObject()
  if body != nil:
    body_21626058 = body
  result = call_21626057.call(nil, nil, nil, nil, body_21626058)

var batchDeletePartition* = Call_BatchDeletePartition_21626044(
    name: "batchDeletePartition", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeletePartition",
    validator: validate_BatchDeletePartition_21626045, base: "/",
    makeUrl: url_BatchDeletePartition_21626046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteTable_21626059 = ref object of OpenApiRestCall_21625435
proc url_BatchDeleteTable_21626061(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDeleteTable_21626060(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626062 = header.getOrDefault("X-Amz-Date")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Date", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Security-Token", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Target")
  valid_21626064 = validateParameter(valid_21626064, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteTable"))
  if valid_21626064 != nil:
    section.add "X-Amz-Target", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Algorithm", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Signature")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Signature", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Credential")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Credential", valid_21626069
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

proc call*(call_21626071: Call_BatchDeleteTable_21626059; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ## 
  let valid = call_21626071.validator(path, query, header, formData, body, _)
  let scheme = call_21626071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626071.makeUrl(scheme.get, call_21626071.host, call_21626071.base,
                               call_21626071.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626071, uri, valid, _)

proc call*(call_21626072: Call_BatchDeleteTable_21626059; body: JsonNode): Recallable =
  ## batchDeleteTable
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ##   body: JObject (required)
  var body_21626073 = newJObject()
  if body != nil:
    body_21626073 = body
  result = call_21626072.call(nil, nil, nil, nil, body_21626073)

var batchDeleteTable* = Call_BatchDeleteTable_21626059(name: "batchDeleteTable",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteTable",
    validator: validate_BatchDeleteTable_21626060, base: "/",
    makeUrl: url_BatchDeleteTable_21626061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteTableVersion_21626074 = ref object of OpenApiRestCall_21625435
proc url_BatchDeleteTableVersion_21626076(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDeleteTableVersion_21626075(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626077 = header.getOrDefault("X-Amz-Date")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Date", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Security-Token", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Target")
  valid_21626079 = validateParameter(valid_21626079, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteTableVersion"))
  if valid_21626079 != nil:
    section.add "X-Amz-Target", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Algorithm", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Signature")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Signature", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Credential")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Credential", valid_21626084
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

proc call*(call_21626086: Call_BatchDeleteTableVersion_21626074;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified batch of versions of a table.
  ## 
  let valid = call_21626086.validator(path, query, header, formData, body, _)
  let scheme = call_21626086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626086.makeUrl(scheme.get, call_21626086.host, call_21626086.base,
                               call_21626086.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626086, uri, valid, _)

proc call*(call_21626087: Call_BatchDeleteTableVersion_21626074; body: JsonNode): Recallable =
  ## batchDeleteTableVersion
  ## Deletes a specified batch of versions of a table.
  ##   body: JObject (required)
  var body_21626088 = newJObject()
  if body != nil:
    body_21626088 = body
  result = call_21626087.call(nil, nil, nil, nil, body_21626088)

var batchDeleteTableVersion* = Call_BatchDeleteTableVersion_21626074(
    name: "batchDeleteTableVersion", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteTableVersion",
    validator: validate_BatchDeleteTableVersion_21626075, base: "/",
    makeUrl: url_BatchDeleteTableVersion_21626076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetCrawlers_21626089 = ref object of OpenApiRestCall_21625435
proc url_BatchGetCrawlers_21626091(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetCrawlers_21626090(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626092 = header.getOrDefault("X-Amz-Date")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Date", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Security-Token", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Target")
  valid_21626094 = validateParameter(valid_21626094, JString, required = true, default = newJString(
      "AWSGlue.BatchGetCrawlers"))
  if valid_21626094 != nil:
    section.add "X-Amz-Target", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Algorithm", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Signature")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Signature", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Credential")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Credential", valid_21626099
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

proc call*(call_21626101: Call_BatchGetCrawlers_21626089; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_21626101.validator(path, query, header, formData, body, _)
  let scheme = call_21626101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626101.makeUrl(scheme.get, call_21626101.host, call_21626101.base,
                               call_21626101.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626101, uri, valid, _)

proc call*(call_21626102: Call_BatchGetCrawlers_21626089; body: JsonNode): Recallable =
  ## batchGetCrawlers
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_21626103 = newJObject()
  if body != nil:
    body_21626103 = body
  result = call_21626102.call(nil, nil, nil, nil, body_21626103)

var batchGetCrawlers* = Call_BatchGetCrawlers_21626089(name: "batchGetCrawlers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetCrawlers",
    validator: validate_BatchGetCrawlers_21626090, base: "/",
    makeUrl: url_BatchGetCrawlers_21626091, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDevEndpoints_21626104 = ref object of OpenApiRestCall_21625435
proc url_BatchGetDevEndpoints_21626106(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetDevEndpoints_21626105(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626107 = header.getOrDefault("X-Amz-Date")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Date", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Security-Token", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-Target")
  valid_21626109 = validateParameter(valid_21626109, JString, required = true, default = newJString(
      "AWSGlue.BatchGetDevEndpoints"))
  if valid_21626109 != nil:
    section.add "X-Amz-Target", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Algorithm", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Signature")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Signature", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Credential")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Credential", valid_21626114
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

proc call*(call_21626116: Call_BatchGetDevEndpoints_21626104; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_21626116.validator(path, query, header, formData, body, _)
  let scheme = call_21626116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626116.makeUrl(scheme.get, call_21626116.host, call_21626116.base,
                               call_21626116.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626116, uri, valid, _)

proc call*(call_21626117: Call_BatchGetDevEndpoints_21626104; body: JsonNode): Recallable =
  ## batchGetDevEndpoints
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_21626118 = newJObject()
  if body != nil:
    body_21626118 = body
  result = call_21626117.call(nil, nil, nil, nil, body_21626118)

var batchGetDevEndpoints* = Call_BatchGetDevEndpoints_21626104(
    name: "batchGetDevEndpoints", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetDevEndpoints",
    validator: validate_BatchGetDevEndpoints_21626105, base: "/",
    makeUrl: url_BatchGetDevEndpoints_21626106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetJobs_21626119 = ref object of OpenApiRestCall_21625435
proc url_BatchGetJobs_21626121(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetJobs_21626120(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626122 = header.getOrDefault("X-Amz-Date")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Date", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Security-Token", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Target")
  valid_21626124 = validateParameter(valid_21626124, JString, required = true,
                                   default = newJString("AWSGlue.BatchGetJobs"))
  if valid_21626124 != nil:
    section.add "X-Amz-Target", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Algorithm", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Signature")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Signature", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Credential")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Credential", valid_21626129
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

proc call*(call_21626131: Call_BatchGetJobs_21626119; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
  ## 
  let valid = call_21626131.validator(path, query, header, formData, body, _)
  let scheme = call_21626131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626131.makeUrl(scheme.get, call_21626131.host, call_21626131.base,
                               call_21626131.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626131, uri, valid, _)

proc call*(call_21626132: Call_BatchGetJobs_21626119; body: JsonNode): Recallable =
  ## batchGetJobs
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
  ##   body: JObject (required)
  var body_21626133 = newJObject()
  if body != nil:
    body_21626133 = body
  result = call_21626132.call(nil, nil, nil, nil, body_21626133)

var batchGetJobs* = Call_BatchGetJobs_21626119(name: "batchGetJobs",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetJobs",
    validator: validate_BatchGetJobs_21626120, base: "/", makeUrl: url_BatchGetJobs_21626121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetPartition_21626134 = ref object of OpenApiRestCall_21625435
proc url_BatchGetPartition_21626136(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetPartition_21626135(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626137 = header.getOrDefault("X-Amz-Date")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Date", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Security-Token", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Target")
  valid_21626139 = validateParameter(valid_21626139, JString, required = true, default = newJString(
      "AWSGlue.BatchGetPartition"))
  if valid_21626139 != nil:
    section.add "X-Amz-Target", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Algorithm", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Signature")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Signature", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Credential")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Credential", valid_21626144
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

proc call*(call_21626146: Call_BatchGetPartition_21626134; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves partitions in a batch request.
  ## 
  let valid = call_21626146.validator(path, query, header, formData, body, _)
  let scheme = call_21626146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626146.makeUrl(scheme.get, call_21626146.host, call_21626146.base,
                               call_21626146.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626146, uri, valid, _)

proc call*(call_21626147: Call_BatchGetPartition_21626134; body: JsonNode): Recallable =
  ## batchGetPartition
  ## Retrieves partitions in a batch request.
  ##   body: JObject (required)
  var body_21626148 = newJObject()
  if body != nil:
    body_21626148 = body
  result = call_21626147.call(nil, nil, nil, nil, body_21626148)

var batchGetPartition* = Call_BatchGetPartition_21626134(name: "batchGetPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetPartition",
    validator: validate_BatchGetPartition_21626135, base: "/",
    makeUrl: url_BatchGetPartition_21626136, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetTriggers_21626149 = ref object of OpenApiRestCall_21625435
proc url_BatchGetTriggers_21626151(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetTriggers_21626150(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626152 = header.getOrDefault("X-Amz-Date")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Date", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Security-Token", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Target")
  valid_21626154 = validateParameter(valid_21626154, JString, required = true, default = newJString(
      "AWSGlue.BatchGetTriggers"))
  if valid_21626154 != nil:
    section.add "X-Amz-Target", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Algorithm", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Signature")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Signature", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Credential")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Credential", valid_21626159
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

proc call*(call_21626161: Call_BatchGetTriggers_21626149; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_21626161.validator(path, query, header, formData, body, _)
  let scheme = call_21626161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626161.makeUrl(scheme.get, call_21626161.host, call_21626161.base,
                               call_21626161.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626161, uri, valid, _)

proc call*(call_21626162: Call_BatchGetTriggers_21626149; body: JsonNode): Recallable =
  ## batchGetTriggers
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_21626163 = newJObject()
  if body != nil:
    body_21626163 = body
  result = call_21626162.call(nil, nil, nil, nil, body_21626163)

var batchGetTriggers* = Call_BatchGetTriggers_21626149(name: "batchGetTriggers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetTriggers",
    validator: validate_BatchGetTriggers_21626150, base: "/",
    makeUrl: url_BatchGetTriggers_21626151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetWorkflows_21626164 = ref object of OpenApiRestCall_21625435
proc url_BatchGetWorkflows_21626166(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetWorkflows_21626165(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626167 = header.getOrDefault("X-Amz-Date")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Date", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Security-Token", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Target")
  valid_21626169 = validateParameter(valid_21626169, JString, required = true, default = newJString(
      "AWSGlue.BatchGetWorkflows"))
  if valid_21626169 != nil:
    section.add "X-Amz-Target", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Algorithm", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Signature")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Signature", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Credential")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Credential", valid_21626174
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

proc call*(call_21626176: Call_BatchGetWorkflows_21626164; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_21626176.validator(path, query, header, formData, body, _)
  let scheme = call_21626176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626176.makeUrl(scheme.get, call_21626176.host, call_21626176.base,
                               call_21626176.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626176, uri, valid, _)

proc call*(call_21626177: Call_BatchGetWorkflows_21626164; body: JsonNode): Recallable =
  ## batchGetWorkflows
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_21626178 = newJObject()
  if body != nil:
    body_21626178 = body
  result = call_21626177.call(nil, nil, nil, nil, body_21626178)

var batchGetWorkflows* = Call_BatchGetWorkflows_21626164(name: "batchGetWorkflows",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetWorkflows",
    validator: validate_BatchGetWorkflows_21626165, base: "/",
    makeUrl: url_BatchGetWorkflows_21626166, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchStopJobRun_21626179 = ref object of OpenApiRestCall_21625435
proc url_BatchStopJobRun_21626181(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchStopJobRun_21626180(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626182 = header.getOrDefault("X-Amz-Date")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Date", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Security-Token", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Target")
  valid_21626184 = validateParameter(valid_21626184, JString, required = true, default = newJString(
      "AWSGlue.BatchStopJobRun"))
  if valid_21626184 != nil:
    section.add "X-Amz-Target", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Algorithm", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Signature")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Signature", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Credential")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Credential", valid_21626189
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

proc call*(call_21626191: Call_BatchStopJobRun_21626179; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops one or more job runs for a specified job definition.
  ## 
  let valid = call_21626191.validator(path, query, header, formData, body, _)
  let scheme = call_21626191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626191.makeUrl(scheme.get, call_21626191.host, call_21626191.base,
                               call_21626191.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626191, uri, valid, _)

proc call*(call_21626192: Call_BatchStopJobRun_21626179; body: JsonNode): Recallable =
  ## batchStopJobRun
  ## Stops one or more job runs for a specified job definition.
  ##   body: JObject (required)
  var body_21626193 = newJObject()
  if body != nil:
    body_21626193 = body
  result = call_21626192.call(nil, nil, nil, nil, body_21626193)

var batchStopJobRun* = Call_BatchStopJobRun_21626179(name: "batchStopJobRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchStopJobRun",
    validator: validate_BatchStopJobRun_21626180, base: "/",
    makeUrl: url_BatchStopJobRun_21626181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelMLTaskRun_21626194 = ref object of OpenApiRestCall_21625435
proc url_CancelMLTaskRun_21626196(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelMLTaskRun_21626195(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626197 = header.getOrDefault("X-Amz-Date")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Date", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Security-Token", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Target")
  valid_21626199 = validateParameter(valid_21626199, JString, required = true, default = newJString(
      "AWSGlue.CancelMLTaskRun"))
  if valid_21626199 != nil:
    section.add "X-Amz-Target", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Algorithm", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Signature")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Signature", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Credential")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Credential", valid_21626204
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

proc call*(call_21626206: Call_CancelMLTaskRun_21626194; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
  ## 
  let valid = call_21626206.validator(path, query, header, formData, body, _)
  let scheme = call_21626206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626206.makeUrl(scheme.get, call_21626206.host, call_21626206.base,
                               call_21626206.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626206, uri, valid, _)

proc call*(call_21626207: Call_CancelMLTaskRun_21626194; body: JsonNode): Recallable =
  ## cancelMLTaskRun
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
  ##   body: JObject (required)
  var body_21626208 = newJObject()
  if body != nil:
    body_21626208 = body
  result = call_21626207.call(nil, nil, nil, nil, body_21626208)

var cancelMLTaskRun* = Call_CancelMLTaskRun_21626194(name: "cancelMLTaskRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CancelMLTaskRun",
    validator: validate_CancelMLTaskRun_21626195, base: "/",
    makeUrl: url_CancelMLTaskRun_21626196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateClassifier_21626209 = ref object of OpenApiRestCall_21625435
proc url_CreateClassifier_21626211(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateClassifier_21626210(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626212 = header.getOrDefault("X-Amz-Date")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Date", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Security-Token", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Target")
  valid_21626214 = validateParameter(valid_21626214, JString, required = true, default = newJString(
      "AWSGlue.CreateClassifier"))
  if valid_21626214 != nil:
    section.add "X-Amz-Target", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Algorithm", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Signature")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Signature", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Credential")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Credential", valid_21626219
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

proc call*(call_21626221: Call_CreateClassifier_21626209; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
  ## 
  let valid = call_21626221.validator(path, query, header, formData, body, _)
  let scheme = call_21626221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626221.makeUrl(scheme.get, call_21626221.host, call_21626221.base,
                               call_21626221.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626221, uri, valid, _)

proc call*(call_21626222: Call_CreateClassifier_21626209; body: JsonNode): Recallable =
  ## createClassifier
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
  ##   body: JObject (required)
  var body_21626223 = newJObject()
  if body != nil:
    body_21626223 = body
  result = call_21626222.call(nil, nil, nil, nil, body_21626223)

var createClassifier* = Call_CreateClassifier_21626209(name: "createClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateClassifier",
    validator: validate_CreateClassifier_21626210, base: "/",
    makeUrl: url_CreateClassifier_21626211, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnection_21626224 = ref object of OpenApiRestCall_21625435
proc url_CreateConnection_21626226(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConnection_21626225(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626227 = header.getOrDefault("X-Amz-Date")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Date", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Security-Token", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Target")
  valid_21626229 = validateParameter(valid_21626229, JString, required = true, default = newJString(
      "AWSGlue.CreateConnection"))
  if valid_21626229 != nil:
    section.add "X-Amz-Target", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Algorithm", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Signature")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Signature", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Credential")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Credential", valid_21626234
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

proc call*(call_21626236: Call_CreateConnection_21626224; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a connection definition in the Data Catalog.
  ## 
  let valid = call_21626236.validator(path, query, header, formData, body, _)
  let scheme = call_21626236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626236.makeUrl(scheme.get, call_21626236.host, call_21626236.base,
                               call_21626236.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626236, uri, valid, _)

proc call*(call_21626237: Call_CreateConnection_21626224; body: JsonNode): Recallable =
  ## createConnection
  ## Creates a connection definition in the Data Catalog.
  ##   body: JObject (required)
  var body_21626238 = newJObject()
  if body != nil:
    body_21626238 = body
  result = call_21626237.call(nil, nil, nil, nil, body_21626238)

var createConnection* = Call_CreateConnection_21626224(name: "createConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateConnection",
    validator: validate_CreateConnection_21626225, base: "/",
    makeUrl: url_CreateConnection_21626226, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCrawler_21626239 = ref object of OpenApiRestCall_21625435
proc url_CreateCrawler_21626241(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCrawler_21626240(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626242 = header.getOrDefault("X-Amz-Date")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "X-Amz-Date", valid_21626242
  var valid_21626243 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Security-Token", valid_21626243
  var valid_21626244 = header.getOrDefault("X-Amz-Target")
  valid_21626244 = validateParameter(valid_21626244, JString, required = true, default = newJString(
      "AWSGlue.CreateCrawler"))
  if valid_21626244 != nil:
    section.add "X-Amz-Target", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Algorithm", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Signature")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Signature", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Credential")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Credential", valid_21626249
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

proc call*(call_21626251: Call_CreateCrawler_21626239; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
  ## 
  let valid = call_21626251.validator(path, query, header, formData, body, _)
  let scheme = call_21626251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626251.makeUrl(scheme.get, call_21626251.host, call_21626251.base,
                               call_21626251.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626251, uri, valid, _)

proc call*(call_21626252: Call_CreateCrawler_21626239; body: JsonNode): Recallable =
  ## createCrawler
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
  ##   body: JObject (required)
  var body_21626253 = newJObject()
  if body != nil:
    body_21626253 = body
  result = call_21626252.call(nil, nil, nil, nil, body_21626253)

var createCrawler* = Call_CreateCrawler_21626239(name: "createCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateCrawler",
    validator: validate_CreateCrawler_21626240, base: "/",
    makeUrl: url_CreateCrawler_21626241, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatabase_21626254 = ref object of OpenApiRestCall_21625435
proc url_CreateDatabase_21626256(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDatabase_21626255(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626257 = header.getOrDefault("X-Amz-Date")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-Date", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Security-Token", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-Target")
  valid_21626259 = validateParameter(valid_21626259, JString, required = true, default = newJString(
      "AWSGlue.CreateDatabase"))
  if valid_21626259 != nil:
    section.add "X-Amz-Target", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-Algorithm", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Signature")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Signature", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Credential")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Credential", valid_21626264
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

proc call*(call_21626266: Call_CreateDatabase_21626254; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new database in a Data Catalog.
  ## 
  let valid = call_21626266.validator(path, query, header, formData, body, _)
  let scheme = call_21626266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626266.makeUrl(scheme.get, call_21626266.host, call_21626266.base,
                               call_21626266.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626266, uri, valid, _)

proc call*(call_21626267: Call_CreateDatabase_21626254; body: JsonNode): Recallable =
  ## createDatabase
  ## Creates a new database in a Data Catalog.
  ##   body: JObject (required)
  var body_21626268 = newJObject()
  if body != nil:
    body_21626268 = body
  result = call_21626267.call(nil, nil, nil, nil, body_21626268)

var createDatabase* = Call_CreateDatabase_21626254(name: "createDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateDatabase",
    validator: validate_CreateDatabase_21626255, base: "/",
    makeUrl: url_CreateDatabase_21626256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDevEndpoint_21626269 = ref object of OpenApiRestCall_21625435
proc url_CreateDevEndpoint_21626271(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDevEndpoint_21626270(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626272 = header.getOrDefault("X-Amz-Date")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Date", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Security-Token", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-Target")
  valid_21626274 = validateParameter(valid_21626274, JString, required = true, default = newJString(
      "AWSGlue.CreateDevEndpoint"))
  if valid_21626274 != nil:
    section.add "X-Amz-Target", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Algorithm", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-Signature")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Signature", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-Credential")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Credential", valid_21626279
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

proc call*(call_21626281: Call_CreateDevEndpoint_21626269; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new development endpoint.
  ## 
  let valid = call_21626281.validator(path, query, header, formData, body, _)
  let scheme = call_21626281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626281.makeUrl(scheme.get, call_21626281.host, call_21626281.base,
                               call_21626281.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626281, uri, valid, _)

proc call*(call_21626282: Call_CreateDevEndpoint_21626269; body: JsonNode): Recallable =
  ## createDevEndpoint
  ## Creates a new development endpoint.
  ##   body: JObject (required)
  var body_21626283 = newJObject()
  if body != nil:
    body_21626283 = body
  result = call_21626282.call(nil, nil, nil, nil, body_21626283)

var createDevEndpoint* = Call_CreateDevEndpoint_21626269(name: "createDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateDevEndpoint",
    validator: validate_CreateDevEndpoint_21626270, base: "/",
    makeUrl: url_CreateDevEndpoint_21626271, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_21626284 = ref object of OpenApiRestCall_21625435
proc url_CreateJob_21626286(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateJob_21626285(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626287 = header.getOrDefault("X-Amz-Date")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Date", valid_21626287
  var valid_21626288 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-Security-Token", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-Target")
  valid_21626289 = validateParameter(valid_21626289, JString, required = true,
                                   default = newJString("AWSGlue.CreateJob"))
  if valid_21626289 != nil:
    section.add "X-Amz-Target", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626290
  var valid_21626291 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "X-Amz-Algorithm", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-Signature")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Signature", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Credential")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Credential", valid_21626294
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

proc call*(call_21626296: Call_CreateJob_21626284; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new job definition.
  ## 
  let valid = call_21626296.validator(path, query, header, formData, body, _)
  let scheme = call_21626296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626296.makeUrl(scheme.get, call_21626296.host, call_21626296.base,
                               call_21626296.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626296, uri, valid, _)

proc call*(call_21626297: Call_CreateJob_21626284; body: JsonNode): Recallable =
  ## createJob
  ## Creates a new job definition.
  ##   body: JObject (required)
  var body_21626298 = newJObject()
  if body != nil:
    body_21626298 = body
  result = call_21626297.call(nil, nil, nil, nil, body_21626298)

var createJob* = Call_CreateJob_21626284(name: "createJob",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.CreateJob",
                                      validator: validate_CreateJob_21626285,
                                      base: "/", makeUrl: url_CreateJob_21626286,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMLTransform_21626299 = ref object of OpenApiRestCall_21625435
proc url_CreateMLTransform_21626301(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMLTransform_21626300(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626302 = header.getOrDefault("X-Amz-Date")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-Date", valid_21626302
  var valid_21626303 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-Security-Token", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Target")
  valid_21626304 = validateParameter(valid_21626304, JString, required = true, default = newJString(
      "AWSGlue.CreateMLTransform"))
  if valid_21626304 != nil:
    section.add "X-Amz-Target", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "X-Amz-Algorithm", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Signature")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Signature", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Credential")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Credential", valid_21626309
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

proc call*(call_21626311: Call_CreateMLTransform_21626299; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
  ## 
  let valid = call_21626311.validator(path, query, header, formData, body, _)
  let scheme = call_21626311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626311.makeUrl(scheme.get, call_21626311.host, call_21626311.base,
                               call_21626311.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626311, uri, valid, _)

proc call*(call_21626312: Call_CreateMLTransform_21626299; body: JsonNode): Recallable =
  ## createMLTransform
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
  ##   body: JObject (required)
  var body_21626313 = newJObject()
  if body != nil:
    body_21626313 = body
  result = call_21626312.call(nil, nil, nil, nil, body_21626313)

var createMLTransform* = Call_CreateMLTransform_21626299(name: "createMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateMLTransform",
    validator: validate_CreateMLTransform_21626300, base: "/",
    makeUrl: url_CreateMLTransform_21626301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePartition_21626314 = ref object of OpenApiRestCall_21625435
proc url_CreatePartition_21626316(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePartition_21626315(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626317 = header.getOrDefault("X-Amz-Date")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Date", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-Security-Token", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Target")
  valid_21626319 = validateParameter(valid_21626319, JString, required = true, default = newJString(
      "AWSGlue.CreatePartition"))
  if valid_21626319 != nil:
    section.add "X-Amz-Target", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-Algorithm", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Signature")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Signature", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Credential")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Credential", valid_21626324
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

proc call*(call_21626326: Call_CreatePartition_21626314; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new partition.
  ## 
  let valid = call_21626326.validator(path, query, header, formData, body, _)
  let scheme = call_21626326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626326.makeUrl(scheme.get, call_21626326.host, call_21626326.base,
                               call_21626326.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626326, uri, valid, _)

proc call*(call_21626327: Call_CreatePartition_21626314; body: JsonNode): Recallable =
  ## createPartition
  ## Creates a new partition.
  ##   body: JObject (required)
  var body_21626328 = newJObject()
  if body != nil:
    body_21626328 = body
  result = call_21626327.call(nil, nil, nil, nil, body_21626328)

var createPartition* = Call_CreatePartition_21626314(name: "createPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreatePartition",
    validator: validate_CreatePartition_21626315, base: "/",
    makeUrl: url_CreatePartition_21626316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateScript_21626329 = ref object of OpenApiRestCall_21625435
proc url_CreateScript_21626331(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateScript_21626330(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Transforms a directed acyclic graph (DAG) into code.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626332 = header.getOrDefault("X-Amz-Date")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Date", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Security-Token", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Target")
  valid_21626334 = validateParameter(valid_21626334, JString, required = true,
                                   default = newJString("AWSGlue.CreateScript"))
  if valid_21626334 != nil:
    section.add "X-Amz-Target", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Algorithm", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Signature")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Signature", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Credential")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Credential", valid_21626339
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

proc call*(call_21626341: Call_CreateScript_21626329; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Transforms a directed acyclic graph (DAG) into code.
  ## 
  let valid = call_21626341.validator(path, query, header, formData, body, _)
  let scheme = call_21626341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626341.makeUrl(scheme.get, call_21626341.host, call_21626341.base,
                               call_21626341.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626341, uri, valid, _)

proc call*(call_21626342: Call_CreateScript_21626329; body: JsonNode): Recallable =
  ## createScript
  ## Transforms a directed acyclic graph (DAG) into code.
  ##   body: JObject (required)
  var body_21626343 = newJObject()
  if body != nil:
    body_21626343 = body
  result = call_21626342.call(nil, nil, nil, nil, body_21626343)

var createScript* = Call_CreateScript_21626329(name: "createScript",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateScript",
    validator: validate_CreateScript_21626330, base: "/", makeUrl: url_CreateScript_21626331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSecurityConfiguration_21626344 = ref object of OpenApiRestCall_21625435
proc url_CreateSecurityConfiguration_21626346(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSecurityConfiguration_21626345(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626347 = header.getOrDefault("X-Amz-Date")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Date", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Security-Token", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Target")
  valid_21626349 = validateParameter(valid_21626349, JString, required = true, default = newJString(
      "AWSGlue.CreateSecurityConfiguration"))
  if valid_21626349 != nil:
    section.add "X-Amz-Target", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Algorithm", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Signature")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Signature", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Credential")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Credential", valid_21626354
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

proc call*(call_21626356: Call_CreateSecurityConfiguration_21626344;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
  ## 
  let valid = call_21626356.validator(path, query, header, formData, body, _)
  let scheme = call_21626356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626356.makeUrl(scheme.get, call_21626356.host, call_21626356.base,
                               call_21626356.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626356, uri, valid, _)

proc call*(call_21626357: Call_CreateSecurityConfiguration_21626344; body: JsonNode): Recallable =
  ## createSecurityConfiguration
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
  ##   body: JObject (required)
  var body_21626358 = newJObject()
  if body != nil:
    body_21626358 = body
  result = call_21626357.call(nil, nil, nil, nil, body_21626358)

var createSecurityConfiguration* = Call_CreateSecurityConfiguration_21626344(
    name: "createSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateSecurityConfiguration",
    validator: validate_CreateSecurityConfiguration_21626345, base: "/",
    makeUrl: url_CreateSecurityConfiguration_21626346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTable_21626359 = ref object of OpenApiRestCall_21625435
proc url_CreateTable_21626361(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTable_21626360(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626362 = header.getOrDefault("X-Amz-Date")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Date", valid_21626362
  var valid_21626363 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626363 = validateParameter(valid_21626363, JString, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "X-Amz-Security-Token", valid_21626363
  var valid_21626364 = header.getOrDefault("X-Amz-Target")
  valid_21626364 = validateParameter(valid_21626364, JString, required = true,
                                   default = newJString("AWSGlue.CreateTable"))
  if valid_21626364 != nil:
    section.add "X-Amz-Target", valid_21626364
  var valid_21626365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Algorithm", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-Signature")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Signature", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Credential")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Credential", valid_21626369
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

proc call*(call_21626371: Call_CreateTable_21626359; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new table definition in the Data Catalog.
  ## 
  let valid = call_21626371.validator(path, query, header, formData, body, _)
  let scheme = call_21626371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626371.makeUrl(scheme.get, call_21626371.host, call_21626371.base,
                               call_21626371.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626371, uri, valid, _)

proc call*(call_21626372: Call_CreateTable_21626359; body: JsonNode): Recallable =
  ## createTable
  ## Creates a new table definition in the Data Catalog.
  ##   body: JObject (required)
  var body_21626373 = newJObject()
  if body != nil:
    body_21626373 = body
  result = call_21626372.call(nil, nil, nil, nil, body_21626373)

var createTable* = Call_CreateTable_21626359(name: "createTable",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateTable", validator: validate_CreateTable_21626360,
    base: "/", makeUrl: url_CreateTable_21626361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrigger_21626374 = ref object of OpenApiRestCall_21625435
proc url_CreateTrigger_21626376(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTrigger_21626375(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates a new trigger.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626377 = header.getOrDefault("X-Amz-Date")
  valid_21626377 = validateParameter(valid_21626377, JString, required = false,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "X-Amz-Date", valid_21626377
  var valid_21626378 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626378 = validateParameter(valid_21626378, JString, required = false,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "X-Amz-Security-Token", valid_21626378
  var valid_21626379 = header.getOrDefault("X-Amz-Target")
  valid_21626379 = validateParameter(valid_21626379, JString, required = true, default = newJString(
      "AWSGlue.CreateTrigger"))
  if valid_21626379 != nil:
    section.add "X-Amz-Target", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-Algorithm", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Signature")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Signature", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Credential")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Credential", valid_21626384
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

proc call*(call_21626386: Call_CreateTrigger_21626374; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new trigger.
  ## 
  let valid = call_21626386.validator(path, query, header, formData, body, _)
  let scheme = call_21626386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626386.makeUrl(scheme.get, call_21626386.host, call_21626386.base,
                               call_21626386.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626386, uri, valid, _)

proc call*(call_21626387: Call_CreateTrigger_21626374; body: JsonNode): Recallable =
  ## createTrigger
  ## Creates a new trigger.
  ##   body: JObject (required)
  var body_21626388 = newJObject()
  if body != nil:
    body_21626388 = body
  result = call_21626387.call(nil, nil, nil, nil, body_21626388)

var createTrigger* = Call_CreateTrigger_21626374(name: "createTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateTrigger",
    validator: validate_CreateTrigger_21626375, base: "/",
    makeUrl: url_CreateTrigger_21626376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserDefinedFunction_21626389 = ref object of OpenApiRestCall_21625435
proc url_CreateUserDefinedFunction_21626391(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserDefinedFunction_21626390(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new function definition in the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626392 = header.getOrDefault("X-Amz-Date")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "X-Amz-Date", valid_21626392
  var valid_21626393 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626393 = validateParameter(valid_21626393, JString, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "X-Amz-Security-Token", valid_21626393
  var valid_21626394 = header.getOrDefault("X-Amz-Target")
  valid_21626394 = validateParameter(valid_21626394, JString, required = true, default = newJString(
      "AWSGlue.CreateUserDefinedFunction"))
  if valid_21626394 != nil:
    section.add "X-Amz-Target", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-Algorithm", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Signature")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Signature", valid_21626397
  var valid_21626398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-Credential")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-Credential", valid_21626399
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

proc call*(call_21626401: Call_CreateUserDefinedFunction_21626389;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new function definition in the Data Catalog.
  ## 
  let valid = call_21626401.validator(path, query, header, formData, body, _)
  let scheme = call_21626401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626401.makeUrl(scheme.get, call_21626401.host, call_21626401.base,
                               call_21626401.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626401, uri, valid, _)

proc call*(call_21626402: Call_CreateUserDefinedFunction_21626389; body: JsonNode): Recallable =
  ## createUserDefinedFunction
  ## Creates a new function definition in the Data Catalog.
  ##   body: JObject (required)
  var body_21626403 = newJObject()
  if body != nil:
    body_21626403 = body
  result = call_21626402.call(nil, nil, nil, nil, body_21626403)

var createUserDefinedFunction* = Call_CreateUserDefinedFunction_21626389(
    name: "createUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateUserDefinedFunction",
    validator: validate_CreateUserDefinedFunction_21626390, base: "/",
    makeUrl: url_CreateUserDefinedFunction_21626391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkflow_21626404 = ref object of OpenApiRestCall_21625435
proc url_CreateWorkflow_21626406(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateWorkflow_21626405(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626407 = header.getOrDefault("X-Amz-Date")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "X-Amz-Date", valid_21626407
  var valid_21626408 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626408 = validateParameter(valid_21626408, JString, required = false,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "X-Amz-Security-Token", valid_21626408
  var valid_21626409 = header.getOrDefault("X-Amz-Target")
  valid_21626409 = validateParameter(valid_21626409, JString, required = true, default = newJString(
      "AWSGlue.CreateWorkflow"))
  if valid_21626409 != nil:
    section.add "X-Amz-Target", valid_21626409
  var valid_21626410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626410 = validateParameter(valid_21626410, JString, required = false,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626410
  var valid_21626411 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "X-Amz-Algorithm", valid_21626411
  var valid_21626412 = header.getOrDefault("X-Amz-Signature")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "X-Amz-Signature", valid_21626412
  var valid_21626413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626413 = validateParameter(valid_21626413, JString, required = false,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626413
  var valid_21626414 = header.getOrDefault("X-Amz-Credential")
  valid_21626414 = validateParameter(valid_21626414, JString, required = false,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "X-Amz-Credential", valid_21626414
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

proc call*(call_21626416: Call_CreateWorkflow_21626404; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new workflow.
  ## 
  let valid = call_21626416.validator(path, query, header, formData, body, _)
  let scheme = call_21626416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626416.makeUrl(scheme.get, call_21626416.host, call_21626416.base,
                               call_21626416.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626416, uri, valid, _)

proc call*(call_21626417: Call_CreateWorkflow_21626404; body: JsonNode): Recallable =
  ## createWorkflow
  ## Creates a new workflow.
  ##   body: JObject (required)
  var body_21626418 = newJObject()
  if body != nil:
    body_21626418 = body
  result = call_21626417.call(nil, nil, nil, nil, body_21626418)

var createWorkflow* = Call_CreateWorkflow_21626404(name: "createWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateWorkflow",
    validator: validate_CreateWorkflow_21626405, base: "/",
    makeUrl: url_CreateWorkflow_21626406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteClassifier_21626419 = ref object of OpenApiRestCall_21625435
proc url_DeleteClassifier_21626421(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteClassifier_21626420(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626422 = header.getOrDefault("X-Amz-Date")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-Date", valid_21626422
  var valid_21626423 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-Security-Token", valid_21626423
  var valid_21626424 = header.getOrDefault("X-Amz-Target")
  valid_21626424 = validateParameter(valid_21626424, JString, required = true, default = newJString(
      "AWSGlue.DeleteClassifier"))
  if valid_21626424 != nil:
    section.add "X-Amz-Target", valid_21626424
  var valid_21626425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626425 = validateParameter(valid_21626425, JString, required = false,
                                   default = nil)
  if valid_21626425 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626425
  var valid_21626426 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626426 = validateParameter(valid_21626426, JString, required = false,
                                   default = nil)
  if valid_21626426 != nil:
    section.add "X-Amz-Algorithm", valid_21626426
  var valid_21626427 = header.getOrDefault("X-Amz-Signature")
  valid_21626427 = validateParameter(valid_21626427, JString, required = false,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "X-Amz-Signature", valid_21626427
  var valid_21626428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626428 = validateParameter(valid_21626428, JString, required = false,
                                   default = nil)
  if valid_21626428 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626428
  var valid_21626429 = header.getOrDefault("X-Amz-Credential")
  valid_21626429 = validateParameter(valid_21626429, JString, required = false,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "X-Amz-Credential", valid_21626429
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

proc call*(call_21626431: Call_DeleteClassifier_21626419; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a classifier from the Data Catalog.
  ## 
  let valid = call_21626431.validator(path, query, header, formData, body, _)
  let scheme = call_21626431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626431.makeUrl(scheme.get, call_21626431.host, call_21626431.base,
                               call_21626431.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626431, uri, valid, _)

proc call*(call_21626432: Call_DeleteClassifier_21626419; body: JsonNode): Recallable =
  ## deleteClassifier
  ## Removes a classifier from the Data Catalog.
  ##   body: JObject (required)
  var body_21626433 = newJObject()
  if body != nil:
    body_21626433 = body
  result = call_21626432.call(nil, nil, nil, nil, body_21626433)

var deleteClassifier* = Call_DeleteClassifier_21626419(name: "deleteClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteClassifier",
    validator: validate_DeleteClassifier_21626420, base: "/",
    makeUrl: url_DeleteClassifier_21626421, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_21626434 = ref object of OpenApiRestCall_21625435
proc url_DeleteConnection_21626436(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteConnection_21626435(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626437 = header.getOrDefault("X-Amz-Date")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Date", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-Security-Token", valid_21626438
  var valid_21626439 = header.getOrDefault("X-Amz-Target")
  valid_21626439 = validateParameter(valid_21626439, JString, required = true, default = newJString(
      "AWSGlue.DeleteConnection"))
  if valid_21626439 != nil:
    section.add "X-Amz-Target", valid_21626439
  var valid_21626440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626440 = validateParameter(valid_21626440, JString, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626440
  var valid_21626441 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626441 = validateParameter(valid_21626441, JString, required = false,
                                   default = nil)
  if valid_21626441 != nil:
    section.add "X-Amz-Algorithm", valid_21626441
  var valid_21626442 = header.getOrDefault("X-Amz-Signature")
  valid_21626442 = validateParameter(valid_21626442, JString, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "X-Amz-Signature", valid_21626442
  var valid_21626443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626443 = validateParameter(valid_21626443, JString, required = false,
                                   default = nil)
  if valid_21626443 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626443
  var valid_21626444 = header.getOrDefault("X-Amz-Credential")
  valid_21626444 = validateParameter(valid_21626444, JString, required = false,
                                   default = nil)
  if valid_21626444 != nil:
    section.add "X-Amz-Credential", valid_21626444
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

proc call*(call_21626446: Call_DeleteConnection_21626434; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a connection from the Data Catalog.
  ## 
  let valid = call_21626446.validator(path, query, header, formData, body, _)
  let scheme = call_21626446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626446.makeUrl(scheme.get, call_21626446.host, call_21626446.base,
                               call_21626446.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626446, uri, valid, _)

proc call*(call_21626447: Call_DeleteConnection_21626434; body: JsonNode): Recallable =
  ## deleteConnection
  ## Deletes a connection from the Data Catalog.
  ##   body: JObject (required)
  var body_21626448 = newJObject()
  if body != nil:
    body_21626448 = body
  result = call_21626447.call(nil, nil, nil, nil, body_21626448)

var deleteConnection* = Call_DeleteConnection_21626434(name: "deleteConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteConnection",
    validator: validate_DeleteConnection_21626435, base: "/",
    makeUrl: url_DeleteConnection_21626436, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCrawler_21626449 = ref object of OpenApiRestCall_21625435
proc url_DeleteCrawler_21626451(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteCrawler_21626450(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626452 = header.getOrDefault("X-Amz-Date")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Date", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-Security-Token", valid_21626453
  var valid_21626454 = header.getOrDefault("X-Amz-Target")
  valid_21626454 = validateParameter(valid_21626454, JString, required = true, default = newJString(
      "AWSGlue.DeleteCrawler"))
  if valid_21626454 != nil:
    section.add "X-Amz-Target", valid_21626454
  var valid_21626455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626455
  var valid_21626456 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amz-Algorithm", valid_21626456
  var valid_21626457 = header.getOrDefault("X-Amz-Signature")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Signature", valid_21626457
  var valid_21626458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626458 = validateParameter(valid_21626458, JString, required = false,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626458
  var valid_21626459 = header.getOrDefault("X-Amz-Credential")
  valid_21626459 = validateParameter(valid_21626459, JString, required = false,
                                   default = nil)
  if valid_21626459 != nil:
    section.add "X-Amz-Credential", valid_21626459
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

proc call*(call_21626461: Call_DeleteCrawler_21626449; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
  ## 
  let valid = call_21626461.validator(path, query, header, formData, body, _)
  let scheme = call_21626461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626461.makeUrl(scheme.get, call_21626461.host, call_21626461.base,
                               call_21626461.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626461, uri, valid, _)

proc call*(call_21626462: Call_DeleteCrawler_21626449; body: JsonNode): Recallable =
  ## deleteCrawler
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
  ##   body: JObject (required)
  var body_21626463 = newJObject()
  if body != nil:
    body_21626463 = body
  result = call_21626462.call(nil, nil, nil, nil, body_21626463)

var deleteCrawler* = Call_DeleteCrawler_21626449(name: "deleteCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteCrawler",
    validator: validate_DeleteCrawler_21626450, base: "/",
    makeUrl: url_DeleteCrawler_21626451, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatabase_21626464 = ref object of OpenApiRestCall_21625435
proc url_DeleteDatabase_21626466(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDatabase_21626465(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626467 = header.getOrDefault("X-Amz-Date")
  valid_21626467 = validateParameter(valid_21626467, JString, required = false,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "X-Amz-Date", valid_21626467
  var valid_21626468 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626468 = validateParameter(valid_21626468, JString, required = false,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "X-Amz-Security-Token", valid_21626468
  var valid_21626469 = header.getOrDefault("X-Amz-Target")
  valid_21626469 = validateParameter(valid_21626469, JString, required = true, default = newJString(
      "AWSGlue.DeleteDatabase"))
  if valid_21626469 != nil:
    section.add "X-Amz-Target", valid_21626469
  var valid_21626470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626470
  var valid_21626471 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626471 = validateParameter(valid_21626471, JString, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "X-Amz-Algorithm", valid_21626471
  var valid_21626472 = header.getOrDefault("X-Amz-Signature")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Signature", valid_21626472
  var valid_21626473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626473
  var valid_21626474 = header.getOrDefault("X-Amz-Credential")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-Credential", valid_21626474
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

proc call*(call_21626476: Call_DeleteDatabase_21626464; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
  ## 
  let valid = call_21626476.validator(path, query, header, formData, body, _)
  let scheme = call_21626476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626476.makeUrl(scheme.get, call_21626476.host, call_21626476.base,
                               call_21626476.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626476, uri, valid, _)

proc call*(call_21626477: Call_DeleteDatabase_21626464; body: JsonNode): Recallable =
  ## deleteDatabase
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
  ##   body: JObject (required)
  var body_21626478 = newJObject()
  if body != nil:
    body_21626478 = body
  result = call_21626477.call(nil, nil, nil, nil, body_21626478)

var deleteDatabase* = Call_DeleteDatabase_21626464(name: "deleteDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteDatabase",
    validator: validate_DeleteDatabase_21626465, base: "/",
    makeUrl: url_DeleteDatabase_21626466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevEndpoint_21626479 = ref object of OpenApiRestCall_21625435
proc url_DeleteDevEndpoint_21626481(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDevEndpoint_21626480(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626482 = header.getOrDefault("X-Amz-Date")
  valid_21626482 = validateParameter(valid_21626482, JString, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "X-Amz-Date", valid_21626482
  var valid_21626483 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626483 = validateParameter(valid_21626483, JString, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "X-Amz-Security-Token", valid_21626483
  var valid_21626484 = header.getOrDefault("X-Amz-Target")
  valid_21626484 = validateParameter(valid_21626484, JString, required = true, default = newJString(
      "AWSGlue.DeleteDevEndpoint"))
  if valid_21626484 != nil:
    section.add "X-Amz-Target", valid_21626484
  var valid_21626485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626485 = validateParameter(valid_21626485, JString, required = false,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626485
  var valid_21626486 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626486 = validateParameter(valid_21626486, JString, required = false,
                                   default = nil)
  if valid_21626486 != nil:
    section.add "X-Amz-Algorithm", valid_21626486
  var valid_21626487 = header.getOrDefault("X-Amz-Signature")
  valid_21626487 = validateParameter(valid_21626487, JString, required = false,
                                   default = nil)
  if valid_21626487 != nil:
    section.add "X-Amz-Signature", valid_21626487
  var valid_21626488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626488 = validateParameter(valid_21626488, JString, required = false,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626488
  var valid_21626489 = header.getOrDefault("X-Amz-Credential")
  valid_21626489 = validateParameter(valid_21626489, JString, required = false,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "X-Amz-Credential", valid_21626489
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

proc call*(call_21626491: Call_DeleteDevEndpoint_21626479; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified development endpoint.
  ## 
  let valid = call_21626491.validator(path, query, header, formData, body, _)
  let scheme = call_21626491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626491.makeUrl(scheme.get, call_21626491.host, call_21626491.base,
                               call_21626491.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626491, uri, valid, _)

proc call*(call_21626492: Call_DeleteDevEndpoint_21626479; body: JsonNode): Recallable =
  ## deleteDevEndpoint
  ## Deletes a specified development endpoint.
  ##   body: JObject (required)
  var body_21626493 = newJObject()
  if body != nil:
    body_21626493 = body
  result = call_21626492.call(nil, nil, nil, nil, body_21626493)

var deleteDevEndpoint* = Call_DeleteDevEndpoint_21626479(name: "deleteDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteDevEndpoint",
    validator: validate_DeleteDevEndpoint_21626480, base: "/",
    makeUrl: url_DeleteDevEndpoint_21626481, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJob_21626494 = ref object of OpenApiRestCall_21625435
proc url_DeleteJob_21626496(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteJob_21626495(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626497 = header.getOrDefault("X-Amz-Date")
  valid_21626497 = validateParameter(valid_21626497, JString, required = false,
                                   default = nil)
  if valid_21626497 != nil:
    section.add "X-Amz-Date", valid_21626497
  var valid_21626498 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626498 = validateParameter(valid_21626498, JString, required = false,
                                   default = nil)
  if valid_21626498 != nil:
    section.add "X-Amz-Security-Token", valid_21626498
  var valid_21626499 = header.getOrDefault("X-Amz-Target")
  valid_21626499 = validateParameter(valid_21626499, JString, required = true,
                                   default = newJString("AWSGlue.DeleteJob"))
  if valid_21626499 != nil:
    section.add "X-Amz-Target", valid_21626499
  var valid_21626500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626500 = validateParameter(valid_21626500, JString, required = false,
                                   default = nil)
  if valid_21626500 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626500
  var valid_21626501 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626501 = validateParameter(valid_21626501, JString, required = false,
                                   default = nil)
  if valid_21626501 != nil:
    section.add "X-Amz-Algorithm", valid_21626501
  var valid_21626502 = header.getOrDefault("X-Amz-Signature")
  valid_21626502 = validateParameter(valid_21626502, JString, required = false,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "X-Amz-Signature", valid_21626502
  var valid_21626503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626503 = validateParameter(valid_21626503, JString, required = false,
                                   default = nil)
  if valid_21626503 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626503
  var valid_21626504 = header.getOrDefault("X-Amz-Credential")
  valid_21626504 = validateParameter(valid_21626504, JString, required = false,
                                   default = nil)
  if valid_21626504 != nil:
    section.add "X-Amz-Credential", valid_21626504
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

proc call*(call_21626506: Call_DeleteJob_21626494; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
  ## 
  let valid = call_21626506.validator(path, query, header, formData, body, _)
  let scheme = call_21626506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626506.makeUrl(scheme.get, call_21626506.host, call_21626506.base,
                               call_21626506.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626506, uri, valid, _)

proc call*(call_21626507: Call_DeleteJob_21626494; body: JsonNode): Recallable =
  ## deleteJob
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
  ##   body: JObject (required)
  var body_21626508 = newJObject()
  if body != nil:
    body_21626508 = body
  result = call_21626507.call(nil, nil, nil, nil, body_21626508)

var deleteJob* = Call_DeleteJob_21626494(name: "deleteJob",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.DeleteJob",
                                      validator: validate_DeleteJob_21626495,
                                      base: "/", makeUrl: url_DeleteJob_21626496,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMLTransform_21626509 = ref object of OpenApiRestCall_21625435
proc url_DeleteMLTransform_21626511(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteMLTransform_21626510(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626512 = header.getOrDefault("X-Amz-Date")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-Date", valid_21626512
  var valid_21626513 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626513 = validateParameter(valid_21626513, JString, required = false,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "X-Amz-Security-Token", valid_21626513
  var valid_21626514 = header.getOrDefault("X-Amz-Target")
  valid_21626514 = validateParameter(valid_21626514, JString, required = true, default = newJString(
      "AWSGlue.DeleteMLTransform"))
  if valid_21626514 != nil:
    section.add "X-Amz-Target", valid_21626514
  var valid_21626515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626515 = validateParameter(valid_21626515, JString, required = false,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626515
  var valid_21626516 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "X-Amz-Algorithm", valid_21626516
  var valid_21626517 = header.getOrDefault("X-Amz-Signature")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-Signature", valid_21626517
  var valid_21626518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626518 = validateParameter(valid_21626518, JString, required = false,
                                   default = nil)
  if valid_21626518 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626518
  var valid_21626519 = header.getOrDefault("X-Amz-Credential")
  valid_21626519 = validateParameter(valid_21626519, JString, required = false,
                                   default = nil)
  if valid_21626519 != nil:
    section.add "X-Amz-Credential", valid_21626519
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

proc call*(call_21626521: Call_DeleteMLTransform_21626509; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
  ## 
  let valid = call_21626521.validator(path, query, header, formData, body, _)
  let scheme = call_21626521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626521.makeUrl(scheme.get, call_21626521.host, call_21626521.base,
                               call_21626521.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626521, uri, valid, _)

proc call*(call_21626522: Call_DeleteMLTransform_21626509; body: JsonNode): Recallable =
  ## deleteMLTransform
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
  ##   body: JObject (required)
  var body_21626523 = newJObject()
  if body != nil:
    body_21626523 = body
  result = call_21626522.call(nil, nil, nil, nil, body_21626523)

var deleteMLTransform* = Call_DeleteMLTransform_21626509(name: "deleteMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteMLTransform",
    validator: validate_DeleteMLTransform_21626510, base: "/",
    makeUrl: url_DeleteMLTransform_21626511, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePartition_21626524 = ref object of OpenApiRestCall_21625435
proc url_DeletePartition_21626526(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePartition_21626525(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626527 = header.getOrDefault("X-Amz-Date")
  valid_21626527 = validateParameter(valid_21626527, JString, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "X-Amz-Date", valid_21626527
  var valid_21626528 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626528 = validateParameter(valid_21626528, JString, required = false,
                                   default = nil)
  if valid_21626528 != nil:
    section.add "X-Amz-Security-Token", valid_21626528
  var valid_21626529 = header.getOrDefault("X-Amz-Target")
  valid_21626529 = validateParameter(valid_21626529, JString, required = true, default = newJString(
      "AWSGlue.DeletePartition"))
  if valid_21626529 != nil:
    section.add "X-Amz-Target", valid_21626529
  var valid_21626530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626530 = validateParameter(valid_21626530, JString, required = false,
                                   default = nil)
  if valid_21626530 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626530
  var valid_21626531 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626531 = validateParameter(valid_21626531, JString, required = false,
                                   default = nil)
  if valid_21626531 != nil:
    section.add "X-Amz-Algorithm", valid_21626531
  var valid_21626532 = header.getOrDefault("X-Amz-Signature")
  valid_21626532 = validateParameter(valid_21626532, JString, required = false,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "X-Amz-Signature", valid_21626532
  var valid_21626533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626533 = validateParameter(valid_21626533, JString, required = false,
                                   default = nil)
  if valid_21626533 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626533
  var valid_21626534 = header.getOrDefault("X-Amz-Credential")
  valid_21626534 = validateParameter(valid_21626534, JString, required = false,
                                   default = nil)
  if valid_21626534 != nil:
    section.add "X-Amz-Credential", valid_21626534
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

proc call*(call_21626536: Call_DeletePartition_21626524; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified partition.
  ## 
  let valid = call_21626536.validator(path, query, header, formData, body, _)
  let scheme = call_21626536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626536.makeUrl(scheme.get, call_21626536.host, call_21626536.base,
                               call_21626536.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626536, uri, valid, _)

proc call*(call_21626537: Call_DeletePartition_21626524; body: JsonNode): Recallable =
  ## deletePartition
  ## Deletes a specified partition.
  ##   body: JObject (required)
  var body_21626538 = newJObject()
  if body != nil:
    body_21626538 = body
  result = call_21626537.call(nil, nil, nil, nil, body_21626538)

var deletePartition* = Call_DeletePartition_21626524(name: "deletePartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeletePartition",
    validator: validate_DeletePartition_21626525, base: "/",
    makeUrl: url_DeletePartition_21626526, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourcePolicy_21626539 = ref object of OpenApiRestCall_21625435
proc url_DeleteResourcePolicy_21626541(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteResourcePolicy_21626540(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626542 = header.getOrDefault("X-Amz-Date")
  valid_21626542 = validateParameter(valid_21626542, JString, required = false,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "X-Amz-Date", valid_21626542
  var valid_21626543 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626543 = validateParameter(valid_21626543, JString, required = false,
                                   default = nil)
  if valid_21626543 != nil:
    section.add "X-Amz-Security-Token", valid_21626543
  var valid_21626544 = header.getOrDefault("X-Amz-Target")
  valid_21626544 = validateParameter(valid_21626544, JString, required = true, default = newJString(
      "AWSGlue.DeleteResourcePolicy"))
  if valid_21626544 != nil:
    section.add "X-Amz-Target", valid_21626544
  var valid_21626545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "X-Amz-Algorithm", valid_21626546
  var valid_21626547 = header.getOrDefault("X-Amz-Signature")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-Signature", valid_21626547
  var valid_21626548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626548
  var valid_21626549 = header.getOrDefault("X-Amz-Credential")
  valid_21626549 = validateParameter(valid_21626549, JString, required = false,
                                   default = nil)
  if valid_21626549 != nil:
    section.add "X-Amz-Credential", valid_21626549
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

proc call*(call_21626551: Call_DeleteResourcePolicy_21626539; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified policy.
  ## 
  let valid = call_21626551.validator(path, query, header, formData, body, _)
  let scheme = call_21626551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626551.makeUrl(scheme.get, call_21626551.host, call_21626551.base,
                               call_21626551.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626551, uri, valid, _)

proc call*(call_21626552: Call_DeleteResourcePolicy_21626539; body: JsonNode): Recallable =
  ## deleteResourcePolicy
  ## Deletes a specified policy.
  ##   body: JObject (required)
  var body_21626553 = newJObject()
  if body != nil:
    body_21626553 = body
  result = call_21626552.call(nil, nil, nil, nil, body_21626553)

var deleteResourcePolicy* = Call_DeleteResourcePolicy_21626539(
    name: "deleteResourcePolicy", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteResourcePolicy",
    validator: validate_DeleteResourcePolicy_21626540, base: "/",
    makeUrl: url_DeleteResourcePolicy_21626541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSecurityConfiguration_21626554 = ref object of OpenApiRestCall_21625435
proc url_DeleteSecurityConfiguration_21626556(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSecurityConfiguration_21626555(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a specified security configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626557 = header.getOrDefault("X-Amz-Date")
  valid_21626557 = validateParameter(valid_21626557, JString, required = false,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "X-Amz-Date", valid_21626557
  var valid_21626558 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626558 = validateParameter(valid_21626558, JString, required = false,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "X-Amz-Security-Token", valid_21626558
  var valid_21626559 = header.getOrDefault("X-Amz-Target")
  valid_21626559 = validateParameter(valid_21626559, JString, required = true, default = newJString(
      "AWSGlue.DeleteSecurityConfiguration"))
  if valid_21626559 != nil:
    section.add "X-Amz-Target", valid_21626559
  var valid_21626560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626560 = validateParameter(valid_21626560, JString, required = false,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626560
  var valid_21626561 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626561 = validateParameter(valid_21626561, JString, required = false,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "X-Amz-Algorithm", valid_21626561
  var valid_21626562 = header.getOrDefault("X-Amz-Signature")
  valid_21626562 = validateParameter(valid_21626562, JString, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "X-Amz-Signature", valid_21626562
  var valid_21626563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626563 = validateParameter(valid_21626563, JString, required = false,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626563
  var valid_21626564 = header.getOrDefault("X-Amz-Credential")
  valid_21626564 = validateParameter(valid_21626564, JString, required = false,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "X-Amz-Credential", valid_21626564
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

proc call*(call_21626566: Call_DeleteSecurityConfiguration_21626554;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified security configuration.
  ## 
  let valid = call_21626566.validator(path, query, header, formData, body, _)
  let scheme = call_21626566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626566.makeUrl(scheme.get, call_21626566.host, call_21626566.base,
                               call_21626566.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626566, uri, valid, _)

proc call*(call_21626567: Call_DeleteSecurityConfiguration_21626554; body: JsonNode): Recallable =
  ## deleteSecurityConfiguration
  ## Deletes a specified security configuration.
  ##   body: JObject (required)
  var body_21626568 = newJObject()
  if body != nil:
    body_21626568 = body
  result = call_21626567.call(nil, nil, nil, nil, body_21626568)

var deleteSecurityConfiguration* = Call_DeleteSecurityConfiguration_21626554(
    name: "deleteSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteSecurityConfiguration",
    validator: validate_DeleteSecurityConfiguration_21626555, base: "/",
    makeUrl: url_DeleteSecurityConfiguration_21626556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTable_21626569 = ref object of OpenApiRestCall_21625435
proc url_DeleteTable_21626571(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTable_21626570(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626572 = header.getOrDefault("X-Amz-Date")
  valid_21626572 = validateParameter(valid_21626572, JString, required = false,
                                   default = nil)
  if valid_21626572 != nil:
    section.add "X-Amz-Date", valid_21626572
  var valid_21626573 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626573 = validateParameter(valid_21626573, JString, required = false,
                                   default = nil)
  if valid_21626573 != nil:
    section.add "X-Amz-Security-Token", valid_21626573
  var valid_21626574 = header.getOrDefault("X-Amz-Target")
  valid_21626574 = validateParameter(valid_21626574, JString, required = true,
                                   default = newJString("AWSGlue.DeleteTable"))
  if valid_21626574 != nil:
    section.add "X-Amz-Target", valid_21626574
  var valid_21626575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626575 = validateParameter(valid_21626575, JString, required = false,
                                   default = nil)
  if valid_21626575 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626575
  var valid_21626576 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626576 = validateParameter(valid_21626576, JString, required = false,
                                   default = nil)
  if valid_21626576 != nil:
    section.add "X-Amz-Algorithm", valid_21626576
  var valid_21626577 = header.getOrDefault("X-Amz-Signature")
  valid_21626577 = validateParameter(valid_21626577, JString, required = false,
                                   default = nil)
  if valid_21626577 != nil:
    section.add "X-Amz-Signature", valid_21626577
  var valid_21626578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626578 = validateParameter(valid_21626578, JString, required = false,
                                   default = nil)
  if valid_21626578 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626578
  var valid_21626579 = header.getOrDefault("X-Amz-Credential")
  valid_21626579 = validateParameter(valid_21626579, JString, required = false,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "X-Amz-Credential", valid_21626579
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

proc call*(call_21626581: Call_DeleteTable_21626569; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ## 
  let valid = call_21626581.validator(path, query, header, formData, body, _)
  let scheme = call_21626581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626581.makeUrl(scheme.get, call_21626581.host, call_21626581.base,
                               call_21626581.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626581, uri, valid, _)

proc call*(call_21626582: Call_DeleteTable_21626569; body: JsonNode): Recallable =
  ## deleteTable
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ##   body: JObject (required)
  var body_21626583 = newJObject()
  if body != nil:
    body_21626583 = body
  result = call_21626582.call(nil, nil, nil, nil, body_21626583)

var deleteTable* = Call_DeleteTable_21626569(name: "deleteTable",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTable", validator: validate_DeleteTable_21626570,
    base: "/", makeUrl: url_DeleteTable_21626571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTableVersion_21626584 = ref object of OpenApiRestCall_21625435
proc url_DeleteTableVersion_21626586(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTableVersion_21626585(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626587 = header.getOrDefault("X-Amz-Date")
  valid_21626587 = validateParameter(valid_21626587, JString, required = false,
                                   default = nil)
  if valid_21626587 != nil:
    section.add "X-Amz-Date", valid_21626587
  var valid_21626588 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626588 = validateParameter(valid_21626588, JString, required = false,
                                   default = nil)
  if valid_21626588 != nil:
    section.add "X-Amz-Security-Token", valid_21626588
  var valid_21626589 = header.getOrDefault("X-Amz-Target")
  valid_21626589 = validateParameter(valid_21626589, JString, required = true, default = newJString(
      "AWSGlue.DeleteTableVersion"))
  if valid_21626589 != nil:
    section.add "X-Amz-Target", valid_21626589
  var valid_21626590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626590 = validateParameter(valid_21626590, JString, required = false,
                                   default = nil)
  if valid_21626590 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626590
  var valid_21626591 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626591 = validateParameter(valid_21626591, JString, required = false,
                                   default = nil)
  if valid_21626591 != nil:
    section.add "X-Amz-Algorithm", valid_21626591
  var valid_21626592 = header.getOrDefault("X-Amz-Signature")
  valid_21626592 = validateParameter(valid_21626592, JString, required = false,
                                   default = nil)
  if valid_21626592 != nil:
    section.add "X-Amz-Signature", valid_21626592
  var valid_21626593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626593 = validateParameter(valid_21626593, JString, required = false,
                                   default = nil)
  if valid_21626593 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626593
  var valid_21626594 = header.getOrDefault("X-Amz-Credential")
  valid_21626594 = validateParameter(valid_21626594, JString, required = false,
                                   default = nil)
  if valid_21626594 != nil:
    section.add "X-Amz-Credential", valid_21626594
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

proc call*(call_21626596: Call_DeleteTableVersion_21626584; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified version of a table.
  ## 
  let valid = call_21626596.validator(path, query, header, formData, body, _)
  let scheme = call_21626596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626596.makeUrl(scheme.get, call_21626596.host, call_21626596.base,
                               call_21626596.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626596, uri, valid, _)

proc call*(call_21626597: Call_DeleteTableVersion_21626584; body: JsonNode): Recallable =
  ## deleteTableVersion
  ## Deletes a specified version of a table.
  ##   body: JObject (required)
  var body_21626598 = newJObject()
  if body != nil:
    body_21626598 = body
  result = call_21626597.call(nil, nil, nil, nil, body_21626598)

var deleteTableVersion* = Call_DeleteTableVersion_21626584(
    name: "deleteTableVersion", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTableVersion",
    validator: validate_DeleteTableVersion_21626585, base: "/",
    makeUrl: url_DeleteTableVersion_21626586, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrigger_21626599 = ref object of OpenApiRestCall_21625435
proc url_DeleteTrigger_21626601(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTrigger_21626600(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626602 = header.getOrDefault("X-Amz-Date")
  valid_21626602 = validateParameter(valid_21626602, JString, required = false,
                                   default = nil)
  if valid_21626602 != nil:
    section.add "X-Amz-Date", valid_21626602
  var valid_21626603 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626603 = validateParameter(valid_21626603, JString, required = false,
                                   default = nil)
  if valid_21626603 != nil:
    section.add "X-Amz-Security-Token", valid_21626603
  var valid_21626604 = header.getOrDefault("X-Amz-Target")
  valid_21626604 = validateParameter(valid_21626604, JString, required = true, default = newJString(
      "AWSGlue.DeleteTrigger"))
  if valid_21626604 != nil:
    section.add "X-Amz-Target", valid_21626604
  var valid_21626605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626605 = validateParameter(valid_21626605, JString, required = false,
                                   default = nil)
  if valid_21626605 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626605
  var valid_21626606 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626606 = validateParameter(valid_21626606, JString, required = false,
                                   default = nil)
  if valid_21626606 != nil:
    section.add "X-Amz-Algorithm", valid_21626606
  var valid_21626607 = header.getOrDefault("X-Amz-Signature")
  valid_21626607 = validateParameter(valid_21626607, JString, required = false,
                                   default = nil)
  if valid_21626607 != nil:
    section.add "X-Amz-Signature", valid_21626607
  var valid_21626608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626608 = validateParameter(valid_21626608, JString, required = false,
                                   default = nil)
  if valid_21626608 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626608
  var valid_21626609 = header.getOrDefault("X-Amz-Credential")
  valid_21626609 = validateParameter(valid_21626609, JString, required = false,
                                   default = nil)
  if valid_21626609 != nil:
    section.add "X-Amz-Credential", valid_21626609
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

proc call*(call_21626611: Call_DeleteTrigger_21626599; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
  ## 
  let valid = call_21626611.validator(path, query, header, formData, body, _)
  let scheme = call_21626611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626611.makeUrl(scheme.get, call_21626611.host, call_21626611.base,
                               call_21626611.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626611, uri, valid, _)

proc call*(call_21626612: Call_DeleteTrigger_21626599; body: JsonNode): Recallable =
  ## deleteTrigger
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
  ##   body: JObject (required)
  var body_21626613 = newJObject()
  if body != nil:
    body_21626613 = body
  result = call_21626612.call(nil, nil, nil, nil, body_21626613)

var deleteTrigger* = Call_DeleteTrigger_21626599(name: "deleteTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTrigger",
    validator: validate_DeleteTrigger_21626600, base: "/",
    makeUrl: url_DeleteTrigger_21626601, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserDefinedFunction_21626614 = ref object of OpenApiRestCall_21625435
proc url_DeleteUserDefinedFunction_21626616(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserDefinedFunction_21626615(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an existing function definition from the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626617 = header.getOrDefault("X-Amz-Date")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-Date", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-Security-Token", valid_21626618
  var valid_21626619 = header.getOrDefault("X-Amz-Target")
  valid_21626619 = validateParameter(valid_21626619, JString, required = true, default = newJString(
      "AWSGlue.DeleteUserDefinedFunction"))
  if valid_21626619 != nil:
    section.add "X-Amz-Target", valid_21626619
  var valid_21626620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626620 = validateParameter(valid_21626620, JString, required = false,
                                   default = nil)
  if valid_21626620 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626620
  var valid_21626621 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626621 = validateParameter(valid_21626621, JString, required = false,
                                   default = nil)
  if valid_21626621 != nil:
    section.add "X-Amz-Algorithm", valid_21626621
  var valid_21626622 = header.getOrDefault("X-Amz-Signature")
  valid_21626622 = validateParameter(valid_21626622, JString, required = false,
                                   default = nil)
  if valid_21626622 != nil:
    section.add "X-Amz-Signature", valid_21626622
  var valid_21626623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626623 = validateParameter(valid_21626623, JString, required = false,
                                   default = nil)
  if valid_21626623 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626623
  var valid_21626624 = header.getOrDefault("X-Amz-Credential")
  valid_21626624 = validateParameter(valid_21626624, JString, required = false,
                                   default = nil)
  if valid_21626624 != nil:
    section.add "X-Amz-Credential", valid_21626624
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

proc call*(call_21626626: Call_DeleteUserDefinedFunction_21626614;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing function definition from the Data Catalog.
  ## 
  let valid = call_21626626.validator(path, query, header, formData, body, _)
  let scheme = call_21626626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626626.makeUrl(scheme.get, call_21626626.host, call_21626626.base,
                               call_21626626.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626626, uri, valid, _)

proc call*(call_21626627: Call_DeleteUserDefinedFunction_21626614; body: JsonNode): Recallable =
  ## deleteUserDefinedFunction
  ## Deletes an existing function definition from the Data Catalog.
  ##   body: JObject (required)
  var body_21626628 = newJObject()
  if body != nil:
    body_21626628 = body
  result = call_21626627.call(nil, nil, nil, nil, body_21626628)

var deleteUserDefinedFunction* = Call_DeleteUserDefinedFunction_21626614(
    name: "deleteUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteUserDefinedFunction",
    validator: validate_DeleteUserDefinedFunction_21626615, base: "/",
    makeUrl: url_DeleteUserDefinedFunction_21626616,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkflow_21626629 = ref object of OpenApiRestCall_21625435
proc url_DeleteWorkflow_21626631(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteWorkflow_21626630(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626632 = header.getOrDefault("X-Amz-Date")
  valid_21626632 = validateParameter(valid_21626632, JString, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "X-Amz-Date", valid_21626632
  var valid_21626633 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-Security-Token", valid_21626633
  var valid_21626634 = header.getOrDefault("X-Amz-Target")
  valid_21626634 = validateParameter(valid_21626634, JString, required = true, default = newJString(
      "AWSGlue.DeleteWorkflow"))
  if valid_21626634 != nil:
    section.add "X-Amz-Target", valid_21626634
  var valid_21626635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626635 = validateParameter(valid_21626635, JString, required = false,
                                   default = nil)
  if valid_21626635 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626635
  var valid_21626636 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626636 = validateParameter(valid_21626636, JString, required = false,
                                   default = nil)
  if valid_21626636 != nil:
    section.add "X-Amz-Algorithm", valid_21626636
  var valid_21626637 = header.getOrDefault("X-Amz-Signature")
  valid_21626637 = validateParameter(valid_21626637, JString, required = false,
                                   default = nil)
  if valid_21626637 != nil:
    section.add "X-Amz-Signature", valid_21626637
  var valid_21626638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626638 = validateParameter(valid_21626638, JString, required = false,
                                   default = nil)
  if valid_21626638 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626638
  var valid_21626639 = header.getOrDefault("X-Amz-Credential")
  valid_21626639 = validateParameter(valid_21626639, JString, required = false,
                                   default = nil)
  if valid_21626639 != nil:
    section.add "X-Amz-Credential", valid_21626639
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

proc call*(call_21626641: Call_DeleteWorkflow_21626629; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a workflow.
  ## 
  let valid = call_21626641.validator(path, query, header, formData, body, _)
  let scheme = call_21626641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626641.makeUrl(scheme.get, call_21626641.host, call_21626641.base,
                               call_21626641.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626641, uri, valid, _)

proc call*(call_21626642: Call_DeleteWorkflow_21626629; body: JsonNode): Recallable =
  ## deleteWorkflow
  ## Deletes a workflow.
  ##   body: JObject (required)
  var body_21626643 = newJObject()
  if body != nil:
    body_21626643 = body
  result = call_21626642.call(nil, nil, nil, nil, body_21626643)

var deleteWorkflow* = Call_DeleteWorkflow_21626629(name: "deleteWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteWorkflow",
    validator: validate_DeleteWorkflow_21626630, base: "/",
    makeUrl: url_DeleteWorkflow_21626631, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCatalogImportStatus_21626644 = ref object of OpenApiRestCall_21625435
proc url_GetCatalogImportStatus_21626646(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCatalogImportStatus_21626645(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626647 = header.getOrDefault("X-Amz-Date")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-Date", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-Security-Token", valid_21626648
  var valid_21626649 = header.getOrDefault("X-Amz-Target")
  valid_21626649 = validateParameter(valid_21626649, JString, required = true, default = newJString(
      "AWSGlue.GetCatalogImportStatus"))
  if valid_21626649 != nil:
    section.add "X-Amz-Target", valid_21626649
  var valid_21626650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626650 = validateParameter(valid_21626650, JString, required = false,
                                   default = nil)
  if valid_21626650 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626650
  var valid_21626651 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626651 = validateParameter(valid_21626651, JString, required = false,
                                   default = nil)
  if valid_21626651 != nil:
    section.add "X-Amz-Algorithm", valid_21626651
  var valid_21626652 = header.getOrDefault("X-Amz-Signature")
  valid_21626652 = validateParameter(valid_21626652, JString, required = false,
                                   default = nil)
  if valid_21626652 != nil:
    section.add "X-Amz-Signature", valid_21626652
  var valid_21626653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626653 = validateParameter(valid_21626653, JString, required = false,
                                   default = nil)
  if valid_21626653 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626653
  var valid_21626654 = header.getOrDefault("X-Amz-Credential")
  valid_21626654 = validateParameter(valid_21626654, JString, required = false,
                                   default = nil)
  if valid_21626654 != nil:
    section.add "X-Amz-Credential", valid_21626654
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

proc call*(call_21626656: Call_GetCatalogImportStatus_21626644;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the status of a migration operation.
  ## 
  let valid = call_21626656.validator(path, query, header, formData, body, _)
  let scheme = call_21626656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626656.makeUrl(scheme.get, call_21626656.host, call_21626656.base,
                               call_21626656.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626656, uri, valid, _)

proc call*(call_21626657: Call_GetCatalogImportStatus_21626644; body: JsonNode): Recallable =
  ## getCatalogImportStatus
  ## Retrieves the status of a migration operation.
  ##   body: JObject (required)
  var body_21626658 = newJObject()
  if body != nil:
    body_21626658 = body
  result = call_21626657.call(nil, nil, nil, nil, body_21626658)

var getCatalogImportStatus* = Call_GetCatalogImportStatus_21626644(
    name: "getCatalogImportStatus", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCatalogImportStatus",
    validator: validate_GetCatalogImportStatus_21626645, base: "/",
    makeUrl: url_GetCatalogImportStatus_21626646,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClassifier_21626659 = ref object of OpenApiRestCall_21625435
proc url_GetClassifier_21626661(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetClassifier_21626660(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Retrieve a classifier by name.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626662 = header.getOrDefault("X-Amz-Date")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "X-Amz-Date", valid_21626662
  var valid_21626663 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "X-Amz-Security-Token", valid_21626663
  var valid_21626664 = header.getOrDefault("X-Amz-Target")
  valid_21626664 = validateParameter(valid_21626664, JString, required = true, default = newJString(
      "AWSGlue.GetClassifier"))
  if valid_21626664 != nil:
    section.add "X-Amz-Target", valid_21626664
  var valid_21626665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626665 = validateParameter(valid_21626665, JString, required = false,
                                   default = nil)
  if valid_21626665 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626665
  var valid_21626666 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626666 = validateParameter(valid_21626666, JString, required = false,
                                   default = nil)
  if valid_21626666 != nil:
    section.add "X-Amz-Algorithm", valid_21626666
  var valid_21626667 = header.getOrDefault("X-Amz-Signature")
  valid_21626667 = validateParameter(valid_21626667, JString, required = false,
                                   default = nil)
  if valid_21626667 != nil:
    section.add "X-Amz-Signature", valid_21626667
  var valid_21626668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626668 = validateParameter(valid_21626668, JString, required = false,
                                   default = nil)
  if valid_21626668 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626668
  var valid_21626669 = header.getOrDefault("X-Amz-Credential")
  valid_21626669 = validateParameter(valid_21626669, JString, required = false,
                                   default = nil)
  if valid_21626669 != nil:
    section.add "X-Amz-Credential", valid_21626669
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

proc call*(call_21626671: Call_GetClassifier_21626659; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve a classifier by name.
  ## 
  let valid = call_21626671.validator(path, query, header, formData, body, _)
  let scheme = call_21626671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626671.makeUrl(scheme.get, call_21626671.host, call_21626671.base,
                               call_21626671.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626671, uri, valid, _)

proc call*(call_21626672: Call_GetClassifier_21626659; body: JsonNode): Recallable =
  ## getClassifier
  ## Retrieve a classifier by name.
  ##   body: JObject (required)
  var body_21626673 = newJObject()
  if body != nil:
    body_21626673 = body
  result = call_21626672.call(nil, nil, nil, nil, body_21626673)

var getClassifier* = Call_GetClassifier_21626659(name: "getClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetClassifier",
    validator: validate_GetClassifier_21626660, base: "/",
    makeUrl: url_GetClassifier_21626661, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClassifiers_21626674 = ref object of OpenApiRestCall_21625435
proc url_GetClassifiers_21626676(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetClassifiers_21626675(path: JsonNode; query: JsonNode;
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
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626677 = query.getOrDefault("NextToken")
  valid_21626677 = validateParameter(valid_21626677, JString, required = false,
                                   default = nil)
  if valid_21626677 != nil:
    section.add "NextToken", valid_21626677
  var valid_21626678 = query.getOrDefault("MaxResults")
  valid_21626678 = validateParameter(valid_21626678, JString, required = false,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "MaxResults", valid_21626678
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626679 = header.getOrDefault("X-Amz-Date")
  valid_21626679 = validateParameter(valid_21626679, JString, required = false,
                                   default = nil)
  if valid_21626679 != nil:
    section.add "X-Amz-Date", valid_21626679
  var valid_21626680 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626680 = validateParameter(valid_21626680, JString, required = false,
                                   default = nil)
  if valid_21626680 != nil:
    section.add "X-Amz-Security-Token", valid_21626680
  var valid_21626681 = header.getOrDefault("X-Amz-Target")
  valid_21626681 = validateParameter(valid_21626681, JString, required = true, default = newJString(
      "AWSGlue.GetClassifiers"))
  if valid_21626681 != nil:
    section.add "X-Amz-Target", valid_21626681
  var valid_21626682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626682 = validateParameter(valid_21626682, JString, required = false,
                                   default = nil)
  if valid_21626682 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626682
  var valid_21626683 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626683 = validateParameter(valid_21626683, JString, required = false,
                                   default = nil)
  if valid_21626683 != nil:
    section.add "X-Amz-Algorithm", valid_21626683
  var valid_21626684 = header.getOrDefault("X-Amz-Signature")
  valid_21626684 = validateParameter(valid_21626684, JString, required = false,
                                   default = nil)
  if valid_21626684 != nil:
    section.add "X-Amz-Signature", valid_21626684
  var valid_21626685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626685 = validateParameter(valid_21626685, JString, required = false,
                                   default = nil)
  if valid_21626685 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626685
  var valid_21626686 = header.getOrDefault("X-Amz-Credential")
  valid_21626686 = validateParameter(valid_21626686, JString, required = false,
                                   default = nil)
  if valid_21626686 != nil:
    section.add "X-Amz-Credential", valid_21626686
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

proc call*(call_21626688: Call_GetClassifiers_21626674; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all classifier objects in the Data Catalog.
  ## 
  let valid = call_21626688.validator(path, query, header, formData, body, _)
  let scheme = call_21626688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626688.makeUrl(scheme.get, call_21626688.host, call_21626688.base,
                               call_21626688.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626688, uri, valid, _)

proc call*(call_21626689: Call_GetClassifiers_21626674; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getClassifiers
  ## Lists all classifier objects in the Data Catalog.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626691 = newJObject()
  var body_21626692 = newJObject()
  add(query_21626691, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626692 = body
  add(query_21626691, "MaxResults", newJString(MaxResults))
  result = call_21626689.call(nil, query_21626691, nil, nil, body_21626692)

var getClassifiers* = Call_GetClassifiers_21626674(name: "getClassifiers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetClassifiers",
    validator: validate_GetClassifiers_21626675, base: "/",
    makeUrl: url_GetClassifiers_21626676, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnection_21626696 = ref object of OpenApiRestCall_21625435
proc url_GetConnection_21626698(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConnection_21626697(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves a connection definition from the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626699 = header.getOrDefault("X-Amz-Date")
  valid_21626699 = validateParameter(valid_21626699, JString, required = false,
                                   default = nil)
  if valid_21626699 != nil:
    section.add "X-Amz-Date", valid_21626699
  var valid_21626700 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626700 = validateParameter(valid_21626700, JString, required = false,
                                   default = nil)
  if valid_21626700 != nil:
    section.add "X-Amz-Security-Token", valid_21626700
  var valid_21626701 = header.getOrDefault("X-Amz-Target")
  valid_21626701 = validateParameter(valid_21626701, JString, required = true, default = newJString(
      "AWSGlue.GetConnection"))
  if valid_21626701 != nil:
    section.add "X-Amz-Target", valid_21626701
  var valid_21626702 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626702 = validateParameter(valid_21626702, JString, required = false,
                                   default = nil)
  if valid_21626702 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626702
  var valid_21626703 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626703 = validateParameter(valid_21626703, JString, required = false,
                                   default = nil)
  if valid_21626703 != nil:
    section.add "X-Amz-Algorithm", valid_21626703
  var valid_21626704 = header.getOrDefault("X-Amz-Signature")
  valid_21626704 = validateParameter(valid_21626704, JString, required = false,
                                   default = nil)
  if valid_21626704 != nil:
    section.add "X-Amz-Signature", valid_21626704
  var valid_21626705 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626705 = validateParameter(valid_21626705, JString, required = false,
                                   default = nil)
  if valid_21626705 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626705
  var valid_21626706 = header.getOrDefault("X-Amz-Credential")
  valid_21626706 = validateParameter(valid_21626706, JString, required = false,
                                   default = nil)
  if valid_21626706 != nil:
    section.add "X-Amz-Credential", valid_21626706
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

proc call*(call_21626708: Call_GetConnection_21626696; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a connection definition from the Data Catalog.
  ## 
  let valid = call_21626708.validator(path, query, header, formData, body, _)
  let scheme = call_21626708.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626708.makeUrl(scheme.get, call_21626708.host, call_21626708.base,
                               call_21626708.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626708, uri, valid, _)

proc call*(call_21626709: Call_GetConnection_21626696; body: JsonNode): Recallable =
  ## getConnection
  ## Retrieves a connection definition from the Data Catalog.
  ##   body: JObject (required)
  var body_21626710 = newJObject()
  if body != nil:
    body_21626710 = body
  result = call_21626709.call(nil, nil, nil, nil, body_21626710)

var getConnection* = Call_GetConnection_21626696(name: "getConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetConnection",
    validator: validate_GetConnection_21626697, base: "/",
    makeUrl: url_GetConnection_21626698, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnections_21626711 = ref object of OpenApiRestCall_21625435
proc url_GetConnections_21626713(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConnections_21626712(path: JsonNode; query: JsonNode;
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
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626714 = query.getOrDefault("NextToken")
  valid_21626714 = validateParameter(valid_21626714, JString, required = false,
                                   default = nil)
  if valid_21626714 != nil:
    section.add "NextToken", valid_21626714
  var valid_21626715 = query.getOrDefault("MaxResults")
  valid_21626715 = validateParameter(valid_21626715, JString, required = false,
                                   default = nil)
  if valid_21626715 != nil:
    section.add "MaxResults", valid_21626715
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626716 = header.getOrDefault("X-Amz-Date")
  valid_21626716 = validateParameter(valid_21626716, JString, required = false,
                                   default = nil)
  if valid_21626716 != nil:
    section.add "X-Amz-Date", valid_21626716
  var valid_21626717 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626717 = validateParameter(valid_21626717, JString, required = false,
                                   default = nil)
  if valid_21626717 != nil:
    section.add "X-Amz-Security-Token", valid_21626717
  var valid_21626718 = header.getOrDefault("X-Amz-Target")
  valid_21626718 = validateParameter(valid_21626718, JString, required = true, default = newJString(
      "AWSGlue.GetConnections"))
  if valid_21626718 != nil:
    section.add "X-Amz-Target", valid_21626718
  var valid_21626719 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626719 = validateParameter(valid_21626719, JString, required = false,
                                   default = nil)
  if valid_21626719 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626719
  var valid_21626720 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626720 = validateParameter(valid_21626720, JString, required = false,
                                   default = nil)
  if valid_21626720 != nil:
    section.add "X-Amz-Algorithm", valid_21626720
  var valid_21626721 = header.getOrDefault("X-Amz-Signature")
  valid_21626721 = validateParameter(valid_21626721, JString, required = false,
                                   default = nil)
  if valid_21626721 != nil:
    section.add "X-Amz-Signature", valid_21626721
  var valid_21626722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626722 = validateParameter(valid_21626722, JString, required = false,
                                   default = nil)
  if valid_21626722 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626722
  var valid_21626723 = header.getOrDefault("X-Amz-Credential")
  valid_21626723 = validateParameter(valid_21626723, JString, required = false,
                                   default = nil)
  if valid_21626723 != nil:
    section.add "X-Amz-Credential", valid_21626723
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

proc call*(call_21626725: Call_GetConnections_21626711; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of connection definitions from the Data Catalog.
  ## 
  let valid = call_21626725.validator(path, query, header, formData, body, _)
  let scheme = call_21626725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626725.makeUrl(scheme.get, call_21626725.host, call_21626725.base,
                               call_21626725.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626725, uri, valid, _)

proc call*(call_21626726: Call_GetConnections_21626711; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getConnections
  ## Retrieves a list of connection definitions from the Data Catalog.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626727 = newJObject()
  var body_21626728 = newJObject()
  add(query_21626727, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626728 = body
  add(query_21626727, "MaxResults", newJString(MaxResults))
  result = call_21626726.call(nil, query_21626727, nil, nil, body_21626728)

var getConnections* = Call_GetConnections_21626711(name: "getConnections",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetConnections",
    validator: validate_GetConnections_21626712, base: "/",
    makeUrl: url_GetConnections_21626713, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawler_21626729 = ref object of OpenApiRestCall_21625435
proc url_GetCrawler_21626731(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCrawler_21626730(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626732 = header.getOrDefault("X-Amz-Date")
  valid_21626732 = validateParameter(valid_21626732, JString, required = false,
                                   default = nil)
  if valid_21626732 != nil:
    section.add "X-Amz-Date", valid_21626732
  var valid_21626733 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626733 = validateParameter(valid_21626733, JString, required = false,
                                   default = nil)
  if valid_21626733 != nil:
    section.add "X-Amz-Security-Token", valid_21626733
  var valid_21626734 = header.getOrDefault("X-Amz-Target")
  valid_21626734 = validateParameter(valid_21626734, JString, required = true,
                                   default = newJString("AWSGlue.GetCrawler"))
  if valid_21626734 != nil:
    section.add "X-Amz-Target", valid_21626734
  var valid_21626735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626735 = validateParameter(valid_21626735, JString, required = false,
                                   default = nil)
  if valid_21626735 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626735
  var valid_21626736 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626736 = validateParameter(valid_21626736, JString, required = false,
                                   default = nil)
  if valid_21626736 != nil:
    section.add "X-Amz-Algorithm", valid_21626736
  var valid_21626737 = header.getOrDefault("X-Amz-Signature")
  valid_21626737 = validateParameter(valid_21626737, JString, required = false,
                                   default = nil)
  if valid_21626737 != nil:
    section.add "X-Amz-Signature", valid_21626737
  var valid_21626738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626738 = validateParameter(valid_21626738, JString, required = false,
                                   default = nil)
  if valid_21626738 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626738
  var valid_21626739 = header.getOrDefault("X-Amz-Credential")
  valid_21626739 = validateParameter(valid_21626739, JString, required = false,
                                   default = nil)
  if valid_21626739 != nil:
    section.add "X-Amz-Credential", valid_21626739
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

proc call*(call_21626741: Call_GetCrawler_21626729; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves metadata for a specified crawler.
  ## 
  let valid = call_21626741.validator(path, query, header, formData, body, _)
  let scheme = call_21626741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626741.makeUrl(scheme.get, call_21626741.host, call_21626741.base,
                               call_21626741.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626741, uri, valid, _)

proc call*(call_21626742: Call_GetCrawler_21626729; body: JsonNode): Recallable =
  ## getCrawler
  ## Retrieves metadata for a specified crawler.
  ##   body: JObject (required)
  var body_21626743 = newJObject()
  if body != nil:
    body_21626743 = body
  result = call_21626742.call(nil, nil, nil, nil, body_21626743)

var getCrawler* = Call_GetCrawler_21626729(name: "getCrawler",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetCrawler",
                                        validator: validate_GetCrawler_21626730,
                                        base: "/", makeUrl: url_GetCrawler_21626731,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawlerMetrics_21626744 = ref object of OpenApiRestCall_21625435
proc url_GetCrawlerMetrics_21626746(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCrawlerMetrics_21626745(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves metrics about specified crawlers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626747 = query.getOrDefault("NextToken")
  valid_21626747 = validateParameter(valid_21626747, JString, required = false,
                                   default = nil)
  if valid_21626747 != nil:
    section.add "NextToken", valid_21626747
  var valid_21626748 = query.getOrDefault("MaxResults")
  valid_21626748 = validateParameter(valid_21626748, JString, required = false,
                                   default = nil)
  if valid_21626748 != nil:
    section.add "MaxResults", valid_21626748
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626749 = header.getOrDefault("X-Amz-Date")
  valid_21626749 = validateParameter(valid_21626749, JString, required = false,
                                   default = nil)
  if valid_21626749 != nil:
    section.add "X-Amz-Date", valid_21626749
  var valid_21626750 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626750 = validateParameter(valid_21626750, JString, required = false,
                                   default = nil)
  if valid_21626750 != nil:
    section.add "X-Amz-Security-Token", valid_21626750
  var valid_21626751 = header.getOrDefault("X-Amz-Target")
  valid_21626751 = validateParameter(valid_21626751, JString, required = true, default = newJString(
      "AWSGlue.GetCrawlerMetrics"))
  if valid_21626751 != nil:
    section.add "X-Amz-Target", valid_21626751
  var valid_21626752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626752 = validateParameter(valid_21626752, JString, required = false,
                                   default = nil)
  if valid_21626752 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626752
  var valid_21626753 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626753 = validateParameter(valid_21626753, JString, required = false,
                                   default = nil)
  if valid_21626753 != nil:
    section.add "X-Amz-Algorithm", valid_21626753
  var valid_21626754 = header.getOrDefault("X-Amz-Signature")
  valid_21626754 = validateParameter(valid_21626754, JString, required = false,
                                   default = nil)
  if valid_21626754 != nil:
    section.add "X-Amz-Signature", valid_21626754
  var valid_21626755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626755 = validateParameter(valid_21626755, JString, required = false,
                                   default = nil)
  if valid_21626755 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626755
  var valid_21626756 = header.getOrDefault("X-Amz-Credential")
  valid_21626756 = validateParameter(valid_21626756, JString, required = false,
                                   default = nil)
  if valid_21626756 != nil:
    section.add "X-Amz-Credential", valid_21626756
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

proc call*(call_21626758: Call_GetCrawlerMetrics_21626744; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves metrics about specified crawlers.
  ## 
  let valid = call_21626758.validator(path, query, header, formData, body, _)
  let scheme = call_21626758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626758.makeUrl(scheme.get, call_21626758.host, call_21626758.base,
                               call_21626758.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626758, uri, valid, _)

proc call*(call_21626759: Call_GetCrawlerMetrics_21626744; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getCrawlerMetrics
  ## Retrieves metrics about specified crawlers.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626760 = newJObject()
  var body_21626761 = newJObject()
  add(query_21626760, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626761 = body
  add(query_21626760, "MaxResults", newJString(MaxResults))
  result = call_21626759.call(nil, query_21626760, nil, nil, body_21626761)

var getCrawlerMetrics* = Call_GetCrawlerMetrics_21626744(name: "getCrawlerMetrics",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCrawlerMetrics",
    validator: validate_GetCrawlerMetrics_21626745, base: "/",
    makeUrl: url_GetCrawlerMetrics_21626746, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawlers_21626762 = ref object of OpenApiRestCall_21625435
proc url_GetCrawlers_21626764(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCrawlers_21626763(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves metadata for all crawlers defined in the customer account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626765 = query.getOrDefault("NextToken")
  valid_21626765 = validateParameter(valid_21626765, JString, required = false,
                                   default = nil)
  if valid_21626765 != nil:
    section.add "NextToken", valid_21626765
  var valid_21626766 = query.getOrDefault("MaxResults")
  valid_21626766 = validateParameter(valid_21626766, JString, required = false,
                                   default = nil)
  if valid_21626766 != nil:
    section.add "MaxResults", valid_21626766
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626767 = header.getOrDefault("X-Amz-Date")
  valid_21626767 = validateParameter(valid_21626767, JString, required = false,
                                   default = nil)
  if valid_21626767 != nil:
    section.add "X-Amz-Date", valid_21626767
  var valid_21626768 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626768 = validateParameter(valid_21626768, JString, required = false,
                                   default = nil)
  if valid_21626768 != nil:
    section.add "X-Amz-Security-Token", valid_21626768
  var valid_21626769 = header.getOrDefault("X-Amz-Target")
  valid_21626769 = validateParameter(valid_21626769, JString, required = true,
                                   default = newJString("AWSGlue.GetCrawlers"))
  if valid_21626769 != nil:
    section.add "X-Amz-Target", valid_21626769
  var valid_21626770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626770 = validateParameter(valid_21626770, JString, required = false,
                                   default = nil)
  if valid_21626770 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626770
  var valid_21626771 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626771 = validateParameter(valid_21626771, JString, required = false,
                                   default = nil)
  if valid_21626771 != nil:
    section.add "X-Amz-Algorithm", valid_21626771
  var valid_21626772 = header.getOrDefault("X-Amz-Signature")
  valid_21626772 = validateParameter(valid_21626772, JString, required = false,
                                   default = nil)
  if valid_21626772 != nil:
    section.add "X-Amz-Signature", valid_21626772
  var valid_21626773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626773 = validateParameter(valid_21626773, JString, required = false,
                                   default = nil)
  if valid_21626773 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626773
  var valid_21626774 = header.getOrDefault("X-Amz-Credential")
  valid_21626774 = validateParameter(valid_21626774, JString, required = false,
                                   default = nil)
  if valid_21626774 != nil:
    section.add "X-Amz-Credential", valid_21626774
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

proc call*(call_21626776: Call_GetCrawlers_21626762; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves metadata for all crawlers defined in the customer account.
  ## 
  let valid = call_21626776.validator(path, query, header, formData, body, _)
  let scheme = call_21626776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626776.makeUrl(scheme.get, call_21626776.host, call_21626776.base,
                               call_21626776.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626776, uri, valid, _)

proc call*(call_21626777: Call_GetCrawlers_21626762; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getCrawlers
  ## Retrieves metadata for all crawlers defined in the customer account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626778 = newJObject()
  var body_21626779 = newJObject()
  add(query_21626778, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626779 = body
  add(query_21626778, "MaxResults", newJString(MaxResults))
  result = call_21626777.call(nil, query_21626778, nil, nil, body_21626779)

var getCrawlers* = Call_GetCrawlers_21626762(name: "getCrawlers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCrawlers", validator: validate_GetCrawlers_21626763,
    base: "/", makeUrl: url_GetCrawlers_21626764,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataCatalogEncryptionSettings_21626780 = ref object of OpenApiRestCall_21625435
proc url_GetDataCatalogEncryptionSettings_21626782(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDataCatalogEncryptionSettings_21626781(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626783 = header.getOrDefault("X-Amz-Date")
  valid_21626783 = validateParameter(valid_21626783, JString, required = false,
                                   default = nil)
  if valid_21626783 != nil:
    section.add "X-Amz-Date", valid_21626783
  var valid_21626784 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626784 = validateParameter(valid_21626784, JString, required = false,
                                   default = nil)
  if valid_21626784 != nil:
    section.add "X-Amz-Security-Token", valid_21626784
  var valid_21626785 = header.getOrDefault("X-Amz-Target")
  valid_21626785 = validateParameter(valid_21626785, JString, required = true, default = newJString(
      "AWSGlue.GetDataCatalogEncryptionSettings"))
  if valid_21626785 != nil:
    section.add "X-Amz-Target", valid_21626785
  var valid_21626786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626786 = validateParameter(valid_21626786, JString, required = false,
                                   default = nil)
  if valid_21626786 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626786
  var valid_21626787 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626787 = validateParameter(valid_21626787, JString, required = false,
                                   default = nil)
  if valid_21626787 != nil:
    section.add "X-Amz-Algorithm", valid_21626787
  var valid_21626788 = header.getOrDefault("X-Amz-Signature")
  valid_21626788 = validateParameter(valid_21626788, JString, required = false,
                                   default = nil)
  if valid_21626788 != nil:
    section.add "X-Amz-Signature", valid_21626788
  var valid_21626789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626789 = validateParameter(valid_21626789, JString, required = false,
                                   default = nil)
  if valid_21626789 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626789
  var valid_21626790 = header.getOrDefault("X-Amz-Credential")
  valid_21626790 = validateParameter(valid_21626790, JString, required = false,
                                   default = nil)
  if valid_21626790 != nil:
    section.add "X-Amz-Credential", valid_21626790
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

proc call*(call_21626792: Call_GetDataCatalogEncryptionSettings_21626780;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the security configuration for a specified catalog.
  ## 
  let valid = call_21626792.validator(path, query, header, formData, body, _)
  let scheme = call_21626792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626792.makeUrl(scheme.get, call_21626792.host, call_21626792.base,
                               call_21626792.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626792, uri, valid, _)

proc call*(call_21626793: Call_GetDataCatalogEncryptionSettings_21626780;
          body: JsonNode): Recallable =
  ## getDataCatalogEncryptionSettings
  ## Retrieves the security configuration for a specified catalog.
  ##   body: JObject (required)
  var body_21626794 = newJObject()
  if body != nil:
    body_21626794 = body
  result = call_21626793.call(nil, nil, nil, nil, body_21626794)

var getDataCatalogEncryptionSettings* = Call_GetDataCatalogEncryptionSettings_21626780(
    name: "getDataCatalogEncryptionSettings", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDataCatalogEncryptionSettings",
    validator: validate_GetDataCatalogEncryptionSettings_21626781, base: "/",
    makeUrl: url_GetDataCatalogEncryptionSettings_21626782,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatabase_21626795 = ref object of OpenApiRestCall_21625435
proc url_GetDatabase_21626797(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDatabase_21626796(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626798 = header.getOrDefault("X-Amz-Date")
  valid_21626798 = validateParameter(valid_21626798, JString, required = false,
                                   default = nil)
  if valid_21626798 != nil:
    section.add "X-Amz-Date", valid_21626798
  var valid_21626799 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626799 = validateParameter(valid_21626799, JString, required = false,
                                   default = nil)
  if valid_21626799 != nil:
    section.add "X-Amz-Security-Token", valid_21626799
  var valid_21626800 = header.getOrDefault("X-Amz-Target")
  valid_21626800 = validateParameter(valid_21626800, JString, required = true,
                                   default = newJString("AWSGlue.GetDatabase"))
  if valid_21626800 != nil:
    section.add "X-Amz-Target", valid_21626800
  var valid_21626801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626801 = validateParameter(valid_21626801, JString, required = false,
                                   default = nil)
  if valid_21626801 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626801
  var valid_21626802 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626802 = validateParameter(valid_21626802, JString, required = false,
                                   default = nil)
  if valid_21626802 != nil:
    section.add "X-Amz-Algorithm", valid_21626802
  var valid_21626803 = header.getOrDefault("X-Amz-Signature")
  valid_21626803 = validateParameter(valid_21626803, JString, required = false,
                                   default = nil)
  if valid_21626803 != nil:
    section.add "X-Amz-Signature", valid_21626803
  var valid_21626804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626804 = validateParameter(valid_21626804, JString, required = false,
                                   default = nil)
  if valid_21626804 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626804
  var valid_21626805 = header.getOrDefault("X-Amz-Credential")
  valid_21626805 = validateParameter(valid_21626805, JString, required = false,
                                   default = nil)
  if valid_21626805 != nil:
    section.add "X-Amz-Credential", valid_21626805
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

proc call*(call_21626807: Call_GetDatabase_21626795; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the definition of a specified database.
  ## 
  let valid = call_21626807.validator(path, query, header, formData, body, _)
  let scheme = call_21626807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626807.makeUrl(scheme.get, call_21626807.host, call_21626807.base,
                               call_21626807.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626807, uri, valid, _)

proc call*(call_21626808: Call_GetDatabase_21626795; body: JsonNode): Recallable =
  ## getDatabase
  ## Retrieves the definition of a specified database.
  ##   body: JObject (required)
  var body_21626809 = newJObject()
  if body != nil:
    body_21626809 = body
  result = call_21626808.call(nil, nil, nil, nil, body_21626809)

var getDatabase* = Call_GetDatabase_21626795(name: "getDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDatabase", validator: validate_GetDatabase_21626796,
    base: "/", makeUrl: url_GetDatabase_21626797,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatabases_21626810 = ref object of OpenApiRestCall_21625435
proc url_GetDatabases_21626812(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDatabases_21626811(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves all databases defined in a given Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626813 = query.getOrDefault("NextToken")
  valid_21626813 = validateParameter(valid_21626813, JString, required = false,
                                   default = nil)
  if valid_21626813 != nil:
    section.add "NextToken", valid_21626813
  var valid_21626814 = query.getOrDefault("MaxResults")
  valid_21626814 = validateParameter(valid_21626814, JString, required = false,
                                   default = nil)
  if valid_21626814 != nil:
    section.add "MaxResults", valid_21626814
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626815 = header.getOrDefault("X-Amz-Date")
  valid_21626815 = validateParameter(valid_21626815, JString, required = false,
                                   default = nil)
  if valid_21626815 != nil:
    section.add "X-Amz-Date", valid_21626815
  var valid_21626816 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626816 = validateParameter(valid_21626816, JString, required = false,
                                   default = nil)
  if valid_21626816 != nil:
    section.add "X-Amz-Security-Token", valid_21626816
  var valid_21626817 = header.getOrDefault("X-Amz-Target")
  valid_21626817 = validateParameter(valid_21626817, JString, required = true,
                                   default = newJString("AWSGlue.GetDatabases"))
  if valid_21626817 != nil:
    section.add "X-Amz-Target", valid_21626817
  var valid_21626818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626818 = validateParameter(valid_21626818, JString, required = false,
                                   default = nil)
  if valid_21626818 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626818
  var valid_21626819 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626819 = validateParameter(valid_21626819, JString, required = false,
                                   default = nil)
  if valid_21626819 != nil:
    section.add "X-Amz-Algorithm", valid_21626819
  var valid_21626820 = header.getOrDefault("X-Amz-Signature")
  valid_21626820 = validateParameter(valid_21626820, JString, required = false,
                                   default = nil)
  if valid_21626820 != nil:
    section.add "X-Amz-Signature", valid_21626820
  var valid_21626821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626821 = validateParameter(valid_21626821, JString, required = false,
                                   default = nil)
  if valid_21626821 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626821
  var valid_21626822 = header.getOrDefault("X-Amz-Credential")
  valid_21626822 = validateParameter(valid_21626822, JString, required = false,
                                   default = nil)
  if valid_21626822 != nil:
    section.add "X-Amz-Credential", valid_21626822
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

proc call*(call_21626824: Call_GetDatabases_21626810; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves all databases defined in a given Data Catalog.
  ## 
  let valid = call_21626824.validator(path, query, header, formData, body, _)
  let scheme = call_21626824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626824.makeUrl(scheme.get, call_21626824.host, call_21626824.base,
                               call_21626824.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626824, uri, valid, _)

proc call*(call_21626825: Call_GetDatabases_21626810; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getDatabases
  ## Retrieves all databases defined in a given Data Catalog.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626826 = newJObject()
  var body_21626827 = newJObject()
  add(query_21626826, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626827 = body
  add(query_21626826, "MaxResults", newJString(MaxResults))
  result = call_21626825.call(nil, query_21626826, nil, nil, body_21626827)

var getDatabases* = Call_GetDatabases_21626810(name: "getDatabases",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDatabases",
    validator: validate_GetDatabases_21626811, base: "/", makeUrl: url_GetDatabases_21626812,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataflowGraph_21626828 = ref object of OpenApiRestCall_21625435
proc url_GetDataflowGraph_21626830(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDataflowGraph_21626829(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626831 = header.getOrDefault("X-Amz-Date")
  valid_21626831 = validateParameter(valid_21626831, JString, required = false,
                                   default = nil)
  if valid_21626831 != nil:
    section.add "X-Amz-Date", valid_21626831
  var valid_21626832 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626832 = validateParameter(valid_21626832, JString, required = false,
                                   default = nil)
  if valid_21626832 != nil:
    section.add "X-Amz-Security-Token", valid_21626832
  var valid_21626833 = header.getOrDefault("X-Amz-Target")
  valid_21626833 = validateParameter(valid_21626833, JString, required = true, default = newJString(
      "AWSGlue.GetDataflowGraph"))
  if valid_21626833 != nil:
    section.add "X-Amz-Target", valid_21626833
  var valid_21626834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626834 = validateParameter(valid_21626834, JString, required = false,
                                   default = nil)
  if valid_21626834 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626834
  var valid_21626835 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626835 = validateParameter(valid_21626835, JString, required = false,
                                   default = nil)
  if valid_21626835 != nil:
    section.add "X-Amz-Algorithm", valid_21626835
  var valid_21626836 = header.getOrDefault("X-Amz-Signature")
  valid_21626836 = validateParameter(valid_21626836, JString, required = false,
                                   default = nil)
  if valid_21626836 != nil:
    section.add "X-Amz-Signature", valid_21626836
  var valid_21626837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626837 = validateParameter(valid_21626837, JString, required = false,
                                   default = nil)
  if valid_21626837 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626837
  var valid_21626838 = header.getOrDefault("X-Amz-Credential")
  valid_21626838 = validateParameter(valid_21626838, JString, required = false,
                                   default = nil)
  if valid_21626838 != nil:
    section.add "X-Amz-Credential", valid_21626838
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

proc call*(call_21626840: Call_GetDataflowGraph_21626828; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Transforms a Python script into a directed acyclic graph (DAG). 
  ## 
  let valid = call_21626840.validator(path, query, header, formData, body, _)
  let scheme = call_21626840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626840.makeUrl(scheme.get, call_21626840.host, call_21626840.base,
                               call_21626840.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626840, uri, valid, _)

proc call*(call_21626841: Call_GetDataflowGraph_21626828; body: JsonNode): Recallable =
  ## getDataflowGraph
  ## Transforms a Python script into a directed acyclic graph (DAG). 
  ##   body: JObject (required)
  var body_21626842 = newJObject()
  if body != nil:
    body_21626842 = body
  result = call_21626841.call(nil, nil, nil, nil, body_21626842)

var getDataflowGraph* = Call_GetDataflowGraph_21626828(name: "getDataflowGraph",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDataflowGraph",
    validator: validate_GetDataflowGraph_21626829, base: "/",
    makeUrl: url_GetDataflowGraph_21626830, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevEndpoint_21626843 = ref object of OpenApiRestCall_21625435
proc url_GetDevEndpoint_21626845(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevEndpoint_21626844(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626846 = header.getOrDefault("X-Amz-Date")
  valid_21626846 = validateParameter(valid_21626846, JString, required = false,
                                   default = nil)
  if valid_21626846 != nil:
    section.add "X-Amz-Date", valid_21626846
  var valid_21626847 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626847 = validateParameter(valid_21626847, JString, required = false,
                                   default = nil)
  if valid_21626847 != nil:
    section.add "X-Amz-Security-Token", valid_21626847
  var valid_21626848 = header.getOrDefault("X-Amz-Target")
  valid_21626848 = validateParameter(valid_21626848, JString, required = true, default = newJString(
      "AWSGlue.GetDevEndpoint"))
  if valid_21626848 != nil:
    section.add "X-Amz-Target", valid_21626848
  var valid_21626849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626849 = validateParameter(valid_21626849, JString, required = false,
                                   default = nil)
  if valid_21626849 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626849
  var valid_21626850 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626850 = validateParameter(valid_21626850, JString, required = false,
                                   default = nil)
  if valid_21626850 != nil:
    section.add "X-Amz-Algorithm", valid_21626850
  var valid_21626851 = header.getOrDefault("X-Amz-Signature")
  valid_21626851 = validateParameter(valid_21626851, JString, required = false,
                                   default = nil)
  if valid_21626851 != nil:
    section.add "X-Amz-Signature", valid_21626851
  var valid_21626852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626852 = validateParameter(valid_21626852, JString, required = false,
                                   default = nil)
  if valid_21626852 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626852
  var valid_21626853 = header.getOrDefault("X-Amz-Credential")
  valid_21626853 = validateParameter(valid_21626853, JString, required = false,
                                   default = nil)
  if valid_21626853 != nil:
    section.add "X-Amz-Credential", valid_21626853
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

proc call*(call_21626855: Call_GetDevEndpoint_21626843; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  let valid = call_21626855.validator(path, query, header, formData, body, _)
  let scheme = call_21626855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626855.makeUrl(scheme.get, call_21626855.host, call_21626855.base,
                               call_21626855.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626855, uri, valid, _)

proc call*(call_21626856: Call_GetDevEndpoint_21626843; body: JsonNode): Recallable =
  ## getDevEndpoint
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ##   body: JObject (required)
  var body_21626857 = newJObject()
  if body != nil:
    body_21626857 = body
  result = call_21626856.call(nil, nil, nil, nil, body_21626857)

var getDevEndpoint* = Call_GetDevEndpoint_21626843(name: "getDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDevEndpoint",
    validator: validate_GetDevEndpoint_21626844, base: "/",
    makeUrl: url_GetDevEndpoint_21626845, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevEndpoints_21626858 = ref object of OpenApiRestCall_21625435
proc url_GetDevEndpoints_21626860(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevEndpoints_21626859(path: JsonNode; query: JsonNode;
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
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626861 = query.getOrDefault("NextToken")
  valid_21626861 = validateParameter(valid_21626861, JString, required = false,
                                   default = nil)
  if valid_21626861 != nil:
    section.add "NextToken", valid_21626861
  var valid_21626862 = query.getOrDefault("MaxResults")
  valid_21626862 = validateParameter(valid_21626862, JString, required = false,
                                   default = nil)
  if valid_21626862 != nil:
    section.add "MaxResults", valid_21626862
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626863 = header.getOrDefault("X-Amz-Date")
  valid_21626863 = validateParameter(valid_21626863, JString, required = false,
                                   default = nil)
  if valid_21626863 != nil:
    section.add "X-Amz-Date", valid_21626863
  var valid_21626864 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626864 = validateParameter(valid_21626864, JString, required = false,
                                   default = nil)
  if valid_21626864 != nil:
    section.add "X-Amz-Security-Token", valid_21626864
  var valid_21626865 = header.getOrDefault("X-Amz-Target")
  valid_21626865 = validateParameter(valid_21626865, JString, required = true, default = newJString(
      "AWSGlue.GetDevEndpoints"))
  if valid_21626865 != nil:
    section.add "X-Amz-Target", valid_21626865
  var valid_21626866 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626866 = validateParameter(valid_21626866, JString, required = false,
                                   default = nil)
  if valid_21626866 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626866
  var valid_21626867 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626867 = validateParameter(valid_21626867, JString, required = false,
                                   default = nil)
  if valid_21626867 != nil:
    section.add "X-Amz-Algorithm", valid_21626867
  var valid_21626868 = header.getOrDefault("X-Amz-Signature")
  valid_21626868 = validateParameter(valid_21626868, JString, required = false,
                                   default = nil)
  if valid_21626868 != nil:
    section.add "X-Amz-Signature", valid_21626868
  var valid_21626869 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626869 = validateParameter(valid_21626869, JString, required = false,
                                   default = nil)
  if valid_21626869 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626869
  var valid_21626870 = header.getOrDefault("X-Amz-Credential")
  valid_21626870 = validateParameter(valid_21626870, JString, required = false,
                                   default = nil)
  if valid_21626870 != nil:
    section.add "X-Amz-Credential", valid_21626870
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

proc call*(call_21626872: Call_GetDevEndpoints_21626858; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  let valid = call_21626872.validator(path, query, header, formData, body, _)
  let scheme = call_21626872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626872.makeUrl(scheme.get, call_21626872.host, call_21626872.base,
                               call_21626872.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626872, uri, valid, _)

proc call*(call_21626873: Call_GetDevEndpoints_21626858; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getDevEndpoints
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626874 = newJObject()
  var body_21626875 = newJObject()
  add(query_21626874, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626875 = body
  add(query_21626874, "MaxResults", newJString(MaxResults))
  result = call_21626873.call(nil, query_21626874, nil, nil, body_21626875)

var getDevEndpoints* = Call_GetDevEndpoints_21626858(name: "getDevEndpoints",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDevEndpoints",
    validator: validate_GetDevEndpoints_21626859, base: "/",
    makeUrl: url_GetDevEndpoints_21626860, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_21626876 = ref object of OpenApiRestCall_21625435
proc url_GetJob_21626878(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJob_21626877(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626879 = header.getOrDefault("X-Amz-Date")
  valid_21626879 = validateParameter(valid_21626879, JString, required = false,
                                   default = nil)
  if valid_21626879 != nil:
    section.add "X-Amz-Date", valid_21626879
  var valid_21626880 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626880 = validateParameter(valid_21626880, JString, required = false,
                                   default = nil)
  if valid_21626880 != nil:
    section.add "X-Amz-Security-Token", valid_21626880
  var valid_21626881 = header.getOrDefault("X-Amz-Target")
  valid_21626881 = validateParameter(valid_21626881, JString, required = true,
                                   default = newJString("AWSGlue.GetJob"))
  if valid_21626881 != nil:
    section.add "X-Amz-Target", valid_21626881
  var valid_21626882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626882 = validateParameter(valid_21626882, JString, required = false,
                                   default = nil)
  if valid_21626882 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626882
  var valid_21626883 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626883 = validateParameter(valid_21626883, JString, required = false,
                                   default = nil)
  if valid_21626883 != nil:
    section.add "X-Amz-Algorithm", valid_21626883
  var valid_21626884 = header.getOrDefault("X-Amz-Signature")
  valid_21626884 = validateParameter(valid_21626884, JString, required = false,
                                   default = nil)
  if valid_21626884 != nil:
    section.add "X-Amz-Signature", valid_21626884
  var valid_21626885 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626885 = validateParameter(valid_21626885, JString, required = false,
                                   default = nil)
  if valid_21626885 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626885
  var valid_21626886 = header.getOrDefault("X-Amz-Credential")
  valid_21626886 = validateParameter(valid_21626886, JString, required = false,
                                   default = nil)
  if valid_21626886 != nil:
    section.add "X-Amz-Credential", valid_21626886
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

proc call*(call_21626888: Call_GetJob_21626876; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves an existing job definition.
  ## 
  let valid = call_21626888.validator(path, query, header, formData, body, _)
  let scheme = call_21626888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626888.makeUrl(scheme.get, call_21626888.host, call_21626888.base,
                               call_21626888.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626888, uri, valid, _)

proc call*(call_21626889: Call_GetJob_21626876; body: JsonNode): Recallable =
  ## getJob
  ## Retrieves an existing job definition.
  ##   body: JObject (required)
  var body_21626890 = newJObject()
  if body != nil:
    body_21626890 = body
  result = call_21626889.call(nil, nil, nil, nil, body_21626890)

var getJob* = Call_GetJob_21626876(name: "getJob", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetJob",
                                validator: validate_GetJob_21626877, base: "/",
                                makeUrl: url_GetJob_21626878,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobBookmark_21626891 = ref object of OpenApiRestCall_21625435
proc url_GetJobBookmark_21626893(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJobBookmark_21626892(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626894 = header.getOrDefault("X-Amz-Date")
  valid_21626894 = validateParameter(valid_21626894, JString, required = false,
                                   default = nil)
  if valid_21626894 != nil:
    section.add "X-Amz-Date", valid_21626894
  var valid_21626895 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626895 = validateParameter(valid_21626895, JString, required = false,
                                   default = nil)
  if valid_21626895 != nil:
    section.add "X-Amz-Security-Token", valid_21626895
  var valid_21626896 = header.getOrDefault("X-Amz-Target")
  valid_21626896 = validateParameter(valid_21626896, JString, required = true, default = newJString(
      "AWSGlue.GetJobBookmark"))
  if valid_21626896 != nil:
    section.add "X-Amz-Target", valid_21626896
  var valid_21626897 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626897 = validateParameter(valid_21626897, JString, required = false,
                                   default = nil)
  if valid_21626897 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626897
  var valid_21626898 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626898 = validateParameter(valid_21626898, JString, required = false,
                                   default = nil)
  if valid_21626898 != nil:
    section.add "X-Amz-Algorithm", valid_21626898
  var valid_21626899 = header.getOrDefault("X-Amz-Signature")
  valid_21626899 = validateParameter(valid_21626899, JString, required = false,
                                   default = nil)
  if valid_21626899 != nil:
    section.add "X-Amz-Signature", valid_21626899
  var valid_21626900 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626900 = validateParameter(valid_21626900, JString, required = false,
                                   default = nil)
  if valid_21626900 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626900
  var valid_21626901 = header.getOrDefault("X-Amz-Credential")
  valid_21626901 = validateParameter(valid_21626901, JString, required = false,
                                   default = nil)
  if valid_21626901 != nil:
    section.add "X-Amz-Credential", valid_21626901
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

proc call*(call_21626903: Call_GetJobBookmark_21626891; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information on a job bookmark entry.
  ## 
  let valid = call_21626903.validator(path, query, header, formData, body, _)
  let scheme = call_21626903.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626903.makeUrl(scheme.get, call_21626903.host, call_21626903.base,
                               call_21626903.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626903, uri, valid, _)

proc call*(call_21626904: Call_GetJobBookmark_21626891; body: JsonNode): Recallable =
  ## getJobBookmark
  ## Returns information on a job bookmark entry.
  ##   body: JObject (required)
  var body_21626905 = newJObject()
  if body != nil:
    body_21626905 = body
  result = call_21626904.call(nil, nil, nil, nil, body_21626905)

var getJobBookmark* = Call_GetJobBookmark_21626891(name: "getJobBookmark",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetJobBookmark",
    validator: validate_GetJobBookmark_21626892, base: "/",
    makeUrl: url_GetJobBookmark_21626893, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobRun_21626906 = ref object of OpenApiRestCall_21625435
proc url_GetJobRun_21626908(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJobRun_21626907(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626909 = header.getOrDefault("X-Amz-Date")
  valid_21626909 = validateParameter(valid_21626909, JString, required = false,
                                   default = nil)
  if valid_21626909 != nil:
    section.add "X-Amz-Date", valid_21626909
  var valid_21626910 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626910 = validateParameter(valid_21626910, JString, required = false,
                                   default = nil)
  if valid_21626910 != nil:
    section.add "X-Amz-Security-Token", valid_21626910
  var valid_21626911 = header.getOrDefault("X-Amz-Target")
  valid_21626911 = validateParameter(valid_21626911, JString, required = true,
                                   default = newJString("AWSGlue.GetJobRun"))
  if valid_21626911 != nil:
    section.add "X-Amz-Target", valid_21626911
  var valid_21626912 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626912 = validateParameter(valid_21626912, JString, required = false,
                                   default = nil)
  if valid_21626912 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626912
  var valid_21626913 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626913 = validateParameter(valid_21626913, JString, required = false,
                                   default = nil)
  if valid_21626913 != nil:
    section.add "X-Amz-Algorithm", valid_21626913
  var valid_21626914 = header.getOrDefault("X-Amz-Signature")
  valid_21626914 = validateParameter(valid_21626914, JString, required = false,
                                   default = nil)
  if valid_21626914 != nil:
    section.add "X-Amz-Signature", valid_21626914
  var valid_21626915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626915 = validateParameter(valid_21626915, JString, required = false,
                                   default = nil)
  if valid_21626915 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626915
  var valid_21626916 = header.getOrDefault("X-Amz-Credential")
  valid_21626916 = validateParameter(valid_21626916, JString, required = false,
                                   default = nil)
  if valid_21626916 != nil:
    section.add "X-Amz-Credential", valid_21626916
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

proc call*(call_21626918: Call_GetJobRun_21626906; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the metadata for a given job run.
  ## 
  let valid = call_21626918.validator(path, query, header, formData, body, _)
  let scheme = call_21626918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626918.makeUrl(scheme.get, call_21626918.host, call_21626918.base,
                               call_21626918.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626918, uri, valid, _)

proc call*(call_21626919: Call_GetJobRun_21626906; body: JsonNode): Recallable =
  ## getJobRun
  ## Retrieves the metadata for a given job run.
  ##   body: JObject (required)
  var body_21626920 = newJObject()
  if body != nil:
    body_21626920 = body
  result = call_21626919.call(nil, nil, nil, nil, body_21626920)

var getJobRun* = Call_GetJobRun_21626906(name: "getJobRun",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetJobRun",
                                      validator: validate_GetJobRun_21626907,
                                      base: "/", makeUrl: url_GetJobRun_21626908,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobRuns_21626921 = ref object of OpenApiRestCall_21625435
proc url_GetJobRuns_21626923(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJobRuns_21626922(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves metadata for all runs of a given job definition.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626924 = query.getOrDefault("NextToken")
  valid_21626924 = validateParameter(valid_21626924, JString, required = false,
                                   default = nil)
  if valid_21626924 != nil:
    section.add "NextToken", valid_21626924
  var valid_21626925 = query.getOrDefault("MaxResults")
  valid_21626925 = validateParameter(valid_21626925, JString, required = false,
                                   default = nil)
  if valid_21626925 != nil:
    section.add "MaxResults", valid_21626925
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626926 = header.getOrDefault("X-Amz-Date")
  valid_21626926 = validateParameter(valid_21626926, JString, required = false,
                                   default = nil)
  if valid_21626926 != nil:
    section.add "X-Amz-Date", valid_21626926
  var valid_21626927 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626927 = validateParameter(valid_21626927, JString, required = false,
                                   default = nil)
  if valid_21626927 != nil:
    section.add "X-Amz-Security-Token", valid_21626927
  var valid_21626928 = header.getOrDefault("X-Amz-Target")
  valid_21626928 = validateParameter(valid_21626928, JString, required = true,
                                   default = newJString("AWSGlue.GetJobRuns"))
  if valid_21626928 != nil:
    section.add "X-Amz-Target", valid_21626928
  var valid_21626929 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626929 = validateParameter(valid_21626929, JString, required = false,
                                   default = nil)
  if valid_21626929 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626929
  var valid_21626930 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626930 = validateParameter(valid_21626930, JString, required = false,
                                   default = nil)
  if valid_21626930 != nil:
    section.add "X-Amz-Algorithm", valid_21626930
  var valid_21626931 = header.getOrDefault("X-Amz-Signature")
  valid_21626931 = validateParameter(valid_21626931, JString, required = false,
                                   default = nil)
  if valid_21626931 != nil:
    section.add "X-Amz-Signature", valid_21626931
  var valid_21626932 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626932 = validateParameter(valid_21626932, JString, required = false,
                                   default = nil)
  if valid_21626932 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626932
  var valid_21626933 = header.getOrDefault("X-Amz-Credential")
  valid_21626933 = validateParameter(valid_21626933, JString, required = false,
                                   default = nil)
  if valid_21626933 != nil:
    section.add "X-Amz-Credential", valid_21626933
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

proc call*(call_21626935: Call_GetJobRuns_21626921; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves metadata for all runs of a given job definition.
  ## 
  let valid = call_21626935.validator(path, query, header, formData, body, _)
  let scheme = call_21626935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626935.makeUrl(scheme.get, call_21626935.host, call_21626935.base,
                               call_21626935.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626935, uri, valid, _)

proc call*(call_21626936: Call_GetJobRuns_21626921; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getJobRuns
  ## Retrieves metadata for all runs of a given job definition.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626937 = newJObject()
  var body_21626938 = newJObject()
  add(query_21626937, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626938 = body
  add(query_21626937, "MaxResults", newJString(MaxResults))
  result = call_21626936.call(nil, query_21626937, nil, nil, body_21626938)

var getJobRuns* = Call_GetJobRuns_21626921(name: "getJobRuns",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetJobRuns",
                                        validator: validate_GetJobRuns_21626922,
                                        base: "/", makeUrl: url_GetJobRuns_21626923,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobs_21626939 = ref object of OpenApiRestCall_21625435
proc url_GetJobs_21626941(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJobs_21626940(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves all current job definitions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626942 = query.getOrDefault("NextToken")
  valid_21626942 = validateParameter(valid_21626942, JString, required = false,
                                   default = nil)
  if valid_21626942 != nil:
    section.add "NextToken", valid_21626942
  var valid_21626943 = query.getOrDefault("MaxResults")
  valid_21626943 = validateParameter(valid_21626943, JString, required = false,
                                   default = nil)
  if valid_21626943 != nil:
    section.add "MaxResults", valid_21626943
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626944 = header.getOrDefault("X-Amz-Date")
  valid_21626944 = validateParameter(valid_21626944, JString, required = false,
                                   default = nil)
  if valid_21626944 != nil:
    section.add "X-Amz-Date", valid_21626944
  var valid_21626945 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626945 = validateParameter(valid_21626945, JString, required = false,
                                   default = nil)
  if valid_21626945 != nil:
    section.add "X-Amz-Security-Token", valid_21626945
  var valid_21626946 = header.getOrDefault("X-Amz-Target")
  valid_21626946 = validateParameter(valid_21626946, JString, required = true,
                                   default = newJString("AWSGlue.GetJobs"))
  if valid_21626946 != nil:
    section.add "X-Amz-Target", valid_21626946
  var valid_21626947 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626947 = validateParameter(valid_21626947, JString, required = false,
                                   default = nil)
  if valid_21626947 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626947
  var valid_21626948 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626948 = validateParameter(valid_21626948, JString, required = false,
                                   default = nil)
  if valid_21626948 != nil:
    section.add "X-Amz-Algorithm", valid_21626948
  var valid_21626949 = header.getOrDefault("X-Amz-Signature")
  valid_21626949 = validateParameter(valid_21626949, JString, required = false,
                                   default = nil)
  if valid_21626949 != nil:
    section.add "X-Amz-Signature", valid_21626949
  var valid_21626950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626950 = validateParameter(valid_21626950, JString, required = false,
                                   default = nil)
  if valid_21626950 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626950
  var valid_21626951 = header.getOrDefault("X-Amz-Credential")
  valid_21626951 = validateParameter(valid_21626951, JString, required = false,
                                   default = nil)
  if valid_21626951 != nil:
    section.add "X-Amz-Credential", valid_21626951
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

proc call*(call_21626953: Call_GetJobs_21626939; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves all current job definitions.
  ## 
  let valid = call_21626953.validator(path, query, header, formData, body, _)
  let scheme = call_21626953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626953.makeUrl(scheme.get, call_21626953.host, call_21626953.base,
                               call_21626953.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626953, uri, valid, _)

proc call*(call_21626954: Call_GetJobs_21626939; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getJobs
  ## Retrieves all current job definitions.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626955 = newJObject()
  var body_21626956 = newJObject()
  add(query_21626955, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626956 = body
  add(query_21626955, "MaxResults", newJString(MaxResults))
  result = call_21626954.call(nil, query_21626955, nil, nil, body_21626956)

var getJobs* = Call_GetJobs_21626939(name: "getJobs", meth: HttpMethod.HttpPost,
                                  host: "glue.amazonaws.com",
                                  route: "/#X-Amz-Target=AWSGlue.GetJobs",
                                  validator: validate_GetJobs_21626940, base: "/",
                                  makeUrl: url_GetJobs_21626941,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTaskRun_21626957 = ref object of OpenApiRestCall_21625435
proc url_GetMLTaskRun_21626959(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMLTaskRun_21626958(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626960 = header.getOrDefault("X-Amz-Date")
  valid_21626960 = validateParameter(valid_21626960, JString, required = false,
                                   default = nil)
  if valid_21626960 != nil:
    section.add "X-Amz-Date", valid_21626960
  var valid_21626961 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626961 = validateParameter(valid_21626961, JString, required = false,
                                   default = nil)
  if valid_21626961 != nil:
    section.add "X-Amz-Security-Token", valid_21626961
  var valid_21626962 = header.getOrDefault("X-Amz-Target")
  valid_21626962 = validateParameter(valid_21626962, JString, required = true,
                                   default = newJString("AWSGlue.GetMLTaskRun"))
  if valid_21626962 != nil:
    section.add "X-Amz-Target", valid_21626962
  var valid_21626963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626963 = validateParameter(valid_21626963, JString, required = false,
                                   default = nil)
  if valid_21626963 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626963
  var valid_21626964 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626964 = validateParameter(valid_21626964, JString, required = false,
                                   default = nil)
  if valid_21626964 != nil:
    section.add "X-Amz-Algorithm", valid_21626964
  var valid_21626965 = header.getOrDefault("X-Amz-Signature")
  valid_21626965 = validateParameter(valid_21626965, JString, required = false,
                                   default = nil)
  if valid_21626965 != nil:
    section.add "X-Amz-Signature", valid_21626965
  var valid_21626966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626966 = validateParameter(valid_21626966, JString, required = false,
                                   default = nil)
  if valid_21626966 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626966
  var valid_21626967 = header.getOrDefault("X-Amz-Credential")
  valid_21626967 = validateParameter(valid_21626967, JString, required = false,
                                   default = nil)
  if valid_21626967 != nil:
    section.add "X-Amz-Credential", valid_21626967
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

proc call*(call_21626969: Call_GetMLTaskRun_21626957; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
  ## 
  let valid = call_21626969.validator(path, query, header, formData, body, _)
  let scheme = call_21626969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626969.makeUrl(scheme.get, call_21626969.host, call_21626969.base,
                               call_21626969.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626969, uri, valid, _)

proc call*(call_21626970: Call_GetMLTaskRun_21626957; body: JsonNode): Recallable =
  ## getMLTaskRun
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
  ##   body: JObject (required)
  var body_21626971 = newJObject()
  if body != nil:
    body_21626971 = body
  result = call_21626970.call(nil, nil, nil, nil, body_21626971)

var getMLTaskRun* = Call_GetMLTaskRun_21626957(name: "getMLTaskRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTaskRun",
    validator: validate_GetMLTaskRun_21626958, base: "/", makeUrl: url_GetMLTaskRun_21626959,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTaskRuns_21626972 = ref object of OpenApiRestCall_21625435
proc url_GetMLTaskRuns_21626974(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMLTaskRuns_21626973(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626975 = query.getOrDefault("NextToken")
  valid_21626975 = validateParameter(valid_21626975, JString, required = false,
                                   default = nil)
  if valid_21626975 != nil:
    section.add "NextToken", valid_21626975
  var valid_21626976 = query.getOrDefault("MaxResults")
  valid_21626976 = validateParameter(valid_21626976, JString, required = false,
                                   default = nil)
  if valid_21626976 != nil:
    section.add "MaxResults", valid_21626976
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626977 = header.getOrDefault("X-Amz-Date")
  valid_21626977 = validateParameter(valid_21626977, JString, required = false,
                                   default = nil)
  if valid_21626977 != nil:
    section.add "X-Amz-Date", valid_21626977
  var valid_21626978 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626978 = validateParameter(valid_21626978, JString, required = false,
                                   default = nil)
  if valid_21626978 != nil:
    section.add "X-Amz-Security-Token", valid_21626978
  var valid_21626979 = header.getOrDefault("X-Amz-Target")
  valid_21626979 = validateParameter(valid_21626979, JString, required = true, default = newJString(
      "AWSGlue.GetMLTaskRuns"))
  if valid_21626979 != nil:
    section.add "X-Amz-Target", valid_21626979
  var valid_21626980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626980 = validateParameter(valid_21626980, JString, required = false,
                                   default = nil)
  if valid_21626980 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626980
  var valid_21626981 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626981 = validateParameter(valid_21626981, JString, required = false,
                                   default = nil)
  if valid_21626981 != nil:
    section.add "X-Amz-Algorithm", valid_21626981
  var valid_21626982 = header.getOrDefault("X-Amz-Signature")
  valid_21626982 = validateParameter(valid_21626982, JString, required = false,
                                   default = nil)
  if valid_21626982 != nil:
    section.add "X-Amz-Signature", valid_21626982
  var valid_21626983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626983 = validateParameter(valid_21626983, JString, required = false,
                                   default = nil)
  if valid_21626983 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626983
  var valid_21626984 = header.getOrDefault("X-Amz-Credential")
  valid_21626984 = validateParameter(valid_21626984, JString, required = false,
                                   default = nil)
  if valid_21626984 != nil:
    section.add "X-Amz-Credential", valid_21626984
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

proc call*(call_21626986: Call_GetMLTaskRuns_21626972; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ## 
  let valid = call_21626986.validator(path, query, header, formData, body, _)
  let scheme = call_21626986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626986.makeUrl(scheme.get, call_21626986.host, call_21626986.base,
                               call_21626986.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626986, uri, valid, _)

proc call*(call_21626987: Call_GetMLTaskRuns_21626972; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getMLTaskRuns
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626988 = newJObject()
  var body_21626989 = newJObject()
  add(query_21626988, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626989 = body
  add(query_21626988, "MaxResults", newJString(MaxResults))
  result = call_21626987.call(nil, query_21626988, nil, nil, body_21626989)

var getMLTaskRuns* = Call_GetMLTaskRuns_21626972(name: "getMLTaskRuns",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTaskRuns",
    validator: validate_GetMLTaskRuns_21626973, base: "/",
    makeUrl: url_GetMLTaskRuns_21626974, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTransform_21626990 = ref object of OpenApiRestCall_21625435
proc url_GetMLTransform_21626992(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMLTransform_21626991(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626993 = header.getOrDefault("X-Amz-Date")
  valid_21626993 = validateParameter(valid_21626993, JString, required = false,
                                   default = nil)
  if valid_21626993 != nil:
    section.add "X-Amz-Date", valid_21626993
  var valid_21626994 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626994 = validateParameter(valid_21626994, JString, required = false,
                                   default = nil)
  if valid_21626994 != nil:
    section.add "X-Amz-Security-Token", valid_21626994
  var valid_21626995 = header.getOrDefault("X-Amz-Target")
  valid_21626995 = validateParameter(valid_21626995, JString, required = true, default = newJString(
      "AWSGlue.GetMLTransform"))
  if valid_21626995 != nil:
    section.add "X-Amz-Target", valid_21626995
  var valid_21626996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626996 = validateParameter(valid_21626996, JString, required = false,
                                   default = nil)
  if valid_21626996 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626996
  var valid_21626997 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626997 = validateParameter(valid_21626997, JString, required = false,
                                   default = nil)
  if valid_21626997 != nil:
    section.add "X-Amz-Algorithm", valid_21626997
  var valid_21626998 = header.getOrDefault("X-Amz-Signature")
  valid_21626998 = validateParameter(valid_21626998, JString, required = false,
                                   default = nil)
  if valid_21626998 != nil:
    section.add "X-Amz-Signature", valid_21626998
  var valid_21626999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626999 = validateParameter(valid_21626999, JString, required = false,
                                   default = nil)
  if valid_21626999 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626999
  var valid_21627000 = header.getOrDefault("X-Amz-Credential")
  valid_21627000 = validateParameter(valid_21627000, JString, required = false,
                                   default = nil)
  if valid_21627000 != nil:
    section.add "X-Amz-Credential", valid_21627000
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

proc call*(call_21627002: Call_GetMLTransform_21626990; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
  ## 
  let valid = call_21627002.validator(path, query, header, formData, body, _)
  let scheme = call_21627002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627002.makeUrl(scheme.get, call_21627002.host, call_21627002.base,
                               call_21627002.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627002, uri, valid, _)

proc call*(call_21627003: Call_GetMLTransform_21626990; body: JsonNode): Recallable =
  ## getMLTransform
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
  ##   body: JObject (required)
  var body_21627004 = newJObject()
  if body != nil:
    body_21627004 = body
  result = call_21627003.call(nil, nil, nil, nil, body_21627004)

var getMLTransform* = Call_GetMLTransform_21626990(name: "getMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTransform",
    validator: validate_GetMLTransform_21626991, base: "/",
    makeUrl: url_GetMLTransform_21626992, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTransforms_21627005 = ref object of OpenApiRestCall_21625435
proc url_GetMLTransforms_21627007(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMLTransforms_21627006(path: JsonNode; query: JsonNode;
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
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627008 = query.getOrDefault("NextToken")
  valid_21627008 = validateParameter(valid_21627008, JString, required = false,
                                   default = nil)
  if valid_21627008 != nil:
    section.add "NextToken", valid_21627008
  var valid_21627009 = query.getOrDefault("MaxResults")
  valid_21627009 = validateParameter(valid_21627009, JString, required = false,
                                   default = nil)
  if valid_21627009 != nil:
    section.add "MaxResults", valid_21627009
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627010 = header.getOrDefault("X-Amz-Date")
  valid_21627010 = validateParameter(valid_21627010, JString, required = false,
                                   default = nil)
  if valid_21627010 != nil:
    section.add "X-Amz-Date", valid_21627010
  var valid_21627011 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627011 = validateParameter(valid_21627011, JString, required = false,
                                   default = nil)
  if valid_21627011 != nil:
    section.add "X-Amz-Security-Token", valid_21627011
  var valid_21627012 = header.getOrDefault("X-Amz-Target")
  valid_21627012 = validateParameter(valid_21627012, JString, required = true, default = newJString(
      "AWSGlue.GetMLTransforms"))
  if valid_21627012 != nil:
    section.add "X-Amz-Target", valid_21627012
  var valid_21627013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627013 = validateParameter(valid_21627013, JString, required = false,
                                   default = nil)
  if valid_21627013 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627013
  var valid_21627014 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627014 = validateParameter(valid_21627014, JString, required = false,
                                   default = nil)
  if valid_21627014 != nil:
    section.add "X-Amz-Algorithm", valid_21627014
  var valid_21627015 = header.getOrDefault("X-Amz-Signature")
  valid_21627015 = validateParameter(valid_21627015, JString, required = false,
                                   default = nil)
  if valid_21627015 != nil:
    section.add "X-Amz-Signature", valid_21627015
  var valid_21627016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627016 = validateParameter(valid_21627016, JString, required = false,
                                   default = nil)
  if valid_21627016 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627016
  var valid_21627017 = header.getOrDefault("X-Amz-Credential")
  valid_21627017 = validateParameter(valid_21627017, JString, required = false,
                                   default = nil)
  if valid_21627017 != nil:
    section.add "X-Amz-Credential", valid_21627017
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

proc call*(call_21627019: Call_GetMLTransforms_21627005; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ## 
  let valid = call_21627019.validator(path, query, header, formData, body, _)
  let scheme = call_21627019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627019.makeUrl(scheme.get, call_21627019.host, call_21627019.base,
                               call_21627019.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627019, uri, valid, _)

proc call*(call_21627020: Call_GetMLTransforms_21627005; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getMLTransforms
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627021 = newJObject()
  var body_21627022 = newJObject()
  add(query_21627021, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627022 = body
  add(query_21627021, "MaxResults", newJString(MaxResults))
  result = call_21627020.call(nil, query_21627021, nil, nil, body_21627022)

var getMLTransforms* = Call_GetMLTransforms_21627005(name: "getMLTransforms",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTransforms",
    validator: validate_GetMLTransforms_21627006, base: "/",
    makeUrl: url_GetMLTransforms_21627007, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMapping_21627023 = ref object of OpenApiRestCall_21625435
proc url_GetMapping_21627025(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMapping_21627024(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627026 = header.getOrDefault("X-Amz-Date")
  valid_21627026 = validateParameter(valid_21627026, JString, required = false,
                                   default = nil)
  if valid_21627026 != nil:
    section.add "X-Amz-Date", valid_21627026
  var valid_21627027 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627027 = validateParameter(valid_21627027, JString, required = false,
                                   default = nil)
  if valid_21627027 != nil:
    section.add "X-Amz-Security-Token", valid_21627027
  var valid_21627028 = header.getOrDefault("X-Amz-Target")
  valid_21627028 = validateParameter(valid_21627028, JString, required = true,
                                   default = newJString("AWSGlue.GetMapping"))
  if valid_21627028 != nil:
    section.add "X-Amz-Target", valid_21627028
  var valid_21627029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627029 = validateParameter(valid_21627029, JString, required = false,
                                   default = nil)
  if valid_21627029 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627029
  var valid_21627030 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627030 = validateParameter(valid_21627030, JString, required = false,
                                   default = nil)
  if valid_21627030 != nil:
    section.add "X-Amz-Algorithm", valid_21627030
  var valid_21627031 = header.getOrDefault("X-Amz-Signature")
  valid_21627031 = validateParameter(valid_21627031, JString, required = false,
                                   default = nil)
  if valid_21627031 != nil:
    section.add "X-Amz-Signature", valid_21627031
  var valid_21627032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627032 = validateParameter(valid_21627032, JString, required = false,
                                   default = nil)
  if valid_21627032 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627032
  var valid_21627033 = header.getOrDefault("X-Amz-Credential")
  valid_21627033 = validateParameter(valid_21627033, JString, required = false,
                                   default = nil)
  if valid_21627033 != nil:
    section.add "X-Amz-Credential", valid_21627033
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

proc call*(call_21627035: Call_GetMapping_21627023; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates mappings.
  ## 
  let valid = call_21627035.validator(path, query, header, formData, body, _)
  let scheme = call_21627035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627035.makeUrl(scheme.get, call_21627035.host, call_21627035.base,
                               call_21627035.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627035, uri, valid, _)

proc call*(call_21627036: Call_GetMapping_21627023; body: JsonNode): Recallable =
  ## getMapping
  ## Creates mappings.
  ##   body: JObject (required)
  var body_21627037 = newJObject()
  if body != nil:
    body_21627037 = body
  result = call_21627036.call(nil, nil, nil, nil, body_21627037)

var getMapping* = Call_GetMapping_21627023(name: "getMapping",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetMapping",
                                        validator: validate_GetMapping_21627024,
                                        base: "/", makeUrl: url_GetMapping_21627025,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPartition_21627038 = ref object of OpenApiRestCall_21625435
proc url_GetPartition_21627040(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPartition_21627039(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about a specified partition.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627041 = header.getOrDefault("X-Amz-Date")
  valid_21627041 = validateParameter(valid_21627041, JString, required = false,
                                   default = nil)
  if valid_21627041 != nil:
    section.add "X-Amz-Date", valid_21627041
  var valid_21627042 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627042 = validateParameter(valid_21627042, JString, required = false,
                                   default = nil)
  if valid_21627042 != nil:
    section.add "X-Amz-Security-Token", valid_21627042
  var valid_21627043 = header.getOrDefault("X-Amz-Target")
  valid_21627043 = validateParameter(valid_21627043, JString, required = true,
                                   default = newJString("AWSGlue.GetPartition"))
  if valid_21627043 != nil:
    section.add "X-Amz-Target", valid_21627043
  var valid_21627044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627044 = validateParameter(valid_21627044, JString, required = false,
                                   default = nil)
  if valid_21627044 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627044
  var valid_21627045 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627045 = validateParameter(valid_21627045, JString, required = false,
                                   default = nil)
  if valid_21627045 != nil:
    section.add "X-Amz-Algorithm", valid_21627045
  var valid_21627046 = header.getOrDefault("X-Amz-Signature")
  valid_21627046 = validateParameter(valid_21627046, JString, required = false,
                                   default = nil)
  if valid_21627046 != nil:
    section.add "X-Amz-Signature", valid_21627046
  var valid_21627047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627047 = validateParameter(valid_21627047, JString, required = false,
                                   default = nil)
  if valid_21627047 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627047
  var valid_21627048 = header.getOrDefault("X-Amz-Credential")
  valid_21627048 = validateParameter(valid_21627048, JString, required = false,
                                   default = nil)
  if valid_21627048 != nil:
    section.add "X-Amz-Credential", valid_21627048
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

proc call*(call_21627050: Call_GetPartition_21627038; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a specified partition.
  ## 
  let valid = call_21627050.validator(path, query, header, formData, body, _)
  let scheme = call_21627050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627050.makeUrl(scheme.get, call_21627050.host, call_21627050.base,
                               call_21627050.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627050, uri, valid, _)

proc call*(call_21627051: Call_GetPartition_21627038; body: JsonNode): Recallable =
  ## getPartition
  ## Retrieves information about a specified partition.
  ##   body: JObject (required)
  var body_21627052 = newJObject()
  if body != nil:
    body_21627052 = body
  result = call_21627051.call(nil, nil, nil, nil, body_21627052)

var getPartition* = Call_GetPartition_21627038(name: "getPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetPartition",
    validator: validate_GetPartition_21627039, base: "/", makeUrl: url_GetPartition_21627040,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPartitions_21627053 = ref object of OpenApiRestCall_21625435
proc url_GetPartitions_21627055(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPartitions_21627054(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about the partitions in a table.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627056 = query.getOrDefault("NextToken")
  valid_21627056 = validateParameter(valid_21627056, JString, required = false,
                                   default = nil)
  if valid_21627056 != nil:
    section.add "NextToken", valid_21627056
  var valid_21627057 = query.getOrDefault("MaxResults")
  valid_21627057 = validateParameter(valid_21627057, JString, required = false,
                                   default = nil)
  if valid_21627057 != nil:
    section.add "MaxResults", valid_21627057
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627058 = header.getOrDefault("X-Amz-Date")
  valid_21627058 = validateParameter(valid_21627058, JString, required = false,
                                   default = nil)
  if valid_21627058 != nil:
    section.add "X-Amz-Date", valid_21627058
  var valid_21627059 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627059 = validateParameter(valid_21627059, JString, required = false,
                                   default = nil)
  if valid_21627059 != nil:
    section.add "X-Amz-Security-Token", valid_21627059
  var valid_21627060 = header.getOrDefault("X-Amz-Target")
  valid_21627060 = validateParameter(valid_21627060, JString, required = true, default = newJString(
      "AWSGlue.GetPartitions"))
  if valid_21627060 != nil:
    section.add "X-Amz-Target", valid_21627060
  var valid_21627061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627061 = validateParameter(valid_21627061, JString, required = false,
                                   default = nil)
  if valid_21627061 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627061
  var valid_21627062 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627062 = validateParameter(valid_21627062, JString, required = false,
                                   default = nil)
  if valid_21627062 != nil:
    section.add "X-Amz-Algorithm", valid_21627062
  var valid_21627063 = header.getOrDefault("X-Amz-Signature")
  valid_21627063 = validateParameter(valid_21627063, JString, required = false,
                                   default = nil)
  if valid_21627063 != nil:
    section.add "X-Amz-Signature", valid_21627063
  var valid_21627064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627064 = validateParameter(valid_21627064, JString, required = false,
                                   default = nil)
  if valid_21627064 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627064
  var valid_21627065 = header.getOrDefault("X-Amz-Credential")
  valid_21627065 = validateParameter(valid_21627065, JString, required = false,
                                   default = nil)
  if valid_21627065 != nil:
    section.add "X-Amz-Credential", valid_21627065
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

proc call*(call_21627067: Call_GetPartitions_21627053; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the partitions in a table.
  ## 
  let valid = call_21627067.validator(path, query, header, formData, body, _)
  let scheme = call_21627067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627067.makeUrl(scheme.get, call_21627067.host, call_21627067.base,
                               call_21627067.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627067, uri, valid, _)

proc call*(call_21627068: Call_GetPartitions_21627053; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getPartitions
  ## Retrieves information about the partitions in a table.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627069 = newJObject()
  var body_21627070 = newJObject()
  add(query_21627069, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627070 = body
  add(query_21627069, "MaxResults", newJString(MaxResults))
  result = call_21627068.call(nil, query_21627069, nil, nil, body_21627070)

var getPartitions* = Call_GetPartitions_21627053(name: "getPartitions",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetPartitions",
    validator: validate_GetPartitions_21627054, base: "/",
    makeUrl: url_GetPartitions_21627055, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPlan_21627071 = ref object of OpenApiRestCall_21625435
proc url_GetPlan_21627073(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPlan_21627072(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627074 = header.getOrDefault("X-Amz-Date")
  valid_21627074 = validateParameter(valid_21627074, JString, required = false,
                                   default = nil)
  if valid_21627074 != nil:
    section.add "X-Amz-Date", valid_21627074
  var valid_21627075 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627075 = validateParameter(valid_21627075, JString, required = false,
                                   default = nil)
  if valid_21627075 != nil:
    section.add "X-Amz-Security-Token", valid_21627075
  var valid_21627076 = header.getOrDefault("X-Amz-Target")
  valid_21627076 = validateParameter(valid_21627076, JString, required = true,
                                   default = newJString("AWSGlue.GetPlan"))
  if valid_21627076 != nil:
    section.add "X-Amz-Target", valid_21627076
  var valid_21627077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627077 = validateParameter(valid_21627077, JString, required = false,
                                   default = nil)
  if valid_21627077 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627077
  var valid_21627078 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627078 = validateParameter(valid_21627078, JString, required = false,
                                   default = nil)
  if valid_21627078 != nil:
    section.add "X-Amz-Algorithm", valid_21627078
  var valid_21627079 = header.getOrDefault("X-Amz-Signature")
  valid_21627079 = validateParameter(valid_21627079, JString, required = false,
                                   default = nil)
  if valid_21627079 != nil:
    section.add "X-Amz-Signature", valid_21627079
  var valid_21627080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627080 = validateParameter(valid_21627080, JString, required = false,
                                   default = nil)
  if valid_21627080 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627080
  var valid_21627081 = header.getOrDefault("X-Amz-Credential")
  valid_21627081 = validateParameter(valid_21627081, JString, required = false,
                                   default = nil)
  if valid_21627081 != nil:
    section.add "X-Amz-Credential", valid_21627081
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

proc call*(call_21627083: Call_GetPlan_21627071; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets code to perform a specified mapping.
  ## 
  let valid = call_21627083.validator(path, query, header, formData, body, _)
  let scheme = call_21627083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627083.makeUrl(scheme.get, call_21627083.host, call_21627083.base,
                               call_21627083.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627083, uri, valid, _)

proc call*(call_21627084: Call_GetPlan_21627071; body: JsonNode): Recallable =
  ## getPlan
  ## Gets code to perform a specified mapping.
  ##   body: JObject (required)
  var body_21627085 = newJObject()
  if body != nil:
    body_21627085 = body
  result = call_21627084.call(nil, nil, nil, nil, body_21627085)

var getPlan* = Call_GetPlan_21627071(name: "getPlan", meth: HttpMethod.HttpPost,
                                  host: "glue.amazonaws.com",
                                  route: "/#X-Amz-Target=AWSGlue.GetPlan",
                                  validator: validate_GetPlan_21627072, base: "/",
                                  makeUrl: url_GetPlan_21627073,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicy_21627086 = ref object of OpenApiRestCall_21625435
proc url_GetResourcePolicy_21627088(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResourcePolicy_21627087(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627089 = header.getOrDefault("X-Amz-Date")
  valid_21627089 = validateParameter(valid_21627089, JString, required = false,
                                   default = nil)
  if valid_21627089 != nil:
    section.add "X-Amz-Date", valid_21627089
  var valid_21627090 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627090 = validateParameter(valid_21627090, JString, required = false,
                                   default = nil)
  if valid_21627090 != nil:
    section.add "X-Amz-Security-Token", valid_21627090
  var valid_21627091 = header.getOrDefault("X-Amz-Target")
  valid_21627091 = validateParameter(valid_21627091, JString, required = true, default = newJString(
      "AWSGlue.GetResourcePolicy"))
  if valid_21627091 != nil:
    section.add "X-Amz-Target", valid_21627091
  var valid_21627092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627092 = validateParameter(valid_21627092, JString, required = false,
                                   default = nil)
  if valid_21627092 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627092
  var valid_21627093 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627093 = validateParameter(valid_21627093, JString, required = false,
                                   default = nil)
  if valid_21627093 != nil:
    section.add "X-Amz-Algorithm", valid_21627093
  var valid_21627094 = header.getOrDefault("X-Amz-Signature")
  valid_21627094 = validateParameter(valid_21627094, JString, required = false,
                                   default = nil)
  if valid_21627094 != nil:
    section.add "X-Amz-Signature", valid_21627094
  var valid_21627095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627095 = validateParameter(valid_21627095, JString, required = false,
                                   default = nil)
  if valid_21627095 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627095
  var valid_21627096 = header.getOrDefault("X-Amz-Credential")
  valid_21627096 = validateParameter(valid_21627096, JString, required = false,
                                   default = nil)
  if valid_21627096 != nil:
    section.add "X-Amz-Credential", valid_21627096
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

proc call*(call_21627098: Call_GetResourcePolicy_21627086; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a specified resource policy.
  ## 
  let valid = call_21627098.validator(path, query, header, formData, body, _)
  let scheme = call_21627098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627098.makeUrl(scheme.get, call_21627098.host, call_21627098.base,
                               call_21627098.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627098, uri, valid, _)

proc call*(call_21627099: Call_GetResourcePolicy_21627086; body: JsonNode): Recallable =
  ## getResourcePolicy
  ## Retrieves a specified resource policy.
  ##   body: JObject (required)
  var body_21627100 = newJObject()
  if body != nil:
    body_21627100 = body
  result = call_21627099.call(nil, nil, nil, nil, body_21627100)

var getResourcePolicy* = Call_GetResourcePolicy_21627086(name: "getResourcePolicy",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetResourcePolicy",
    validator: validate_GetResourcePolicy_21627087, base: "/",
    makeUrl: url_GetResourcePolicy_21627088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecurityConfiguration_21627101 = ref object of OpenApiRestCall_21625435
proc url_GetSecurityConfiguration_21627103(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSecurityConfiguration_21627102(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a specified security configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627104 = header.getOrDefault("X-Amz-Date")
  valid_21627104 = validateParameter(valid_21627104, JString, required = false,
                                   default = nil)
  if valid_21627104 != nil:
    section.add "X-Amz-Date", valid_21627104
  var valid_21627105 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627105 = validateParameter(valid_21627105, JString, required = false,
                                   default = nil)
  if valid_21627105 != nil:
    section.add "X-Amz-Security-Token", valid_21627105
  var valid_21627106 = header.getOrDefault("X-Amz-Target")
  valid_21627106 = validateParameter(valid_21627106, JString, required = true, default = newJString(
      "AWSGlue.GetSecurityConfiguration"))
  if valid_21627106 != nil:
    section.add "X-Amz-Target", valid_21627106
  var valid_21627107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627107 = validateParameter(valid_21627107, JString, required = false,
                                   default = nil)
  if valid_21627107 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627107
  var valid_21627108 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627108 = validateParameter(valid_21627108, JString, required = false,
                                   default = nil)
  if valid_21627108 != nil:
    section.add "X-Amz-Algorithm", valid_21627108
  var valid_21627109 = header.getOrDefault("X-Amz-Signature")
  valid_21627109 = validateParameter(valid_21627109, JString, required = false,
                                   default = nil)
  if valid_21627109 != nil:
    section.add "X-Amz-Signature", valid_21627109
  var valid_21627110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627110 = validateParameter(valid_21627110, JString, required = false,
                                   default = nil)
  if valid_21627110 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627110
  var valid_21627111 = header.getOrDefault("X-Amz-Credential")
  valid_21627111 = validateParameter(valid_21627111, JString, required = false,
                                   default = nil)
  if valid_21627111 != nil:
    section.add "X-Amz-Credential", valid_21627111
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

proc call*(call_21627113: Call_GetSecurityConfiguration_21627101;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a specified security configuration.
  ## 
  let valid = call_21627113.validator(path, query, header, formData, body, _)
  let scheme = call_21627113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627113.makeUrl(scheme.get, call_21627113.host, call_21627113.base,
                               call_21627113.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627113, uri, valid, _)

proc call*(call_21627114: Call_GetSecurityConfiguration_21627101; body: JsonNode): Recallable =
  ## getSecurityConfiguration
  ## Retrieves a specified security configuration.
  ##   body: JObject (required)
  var body_21627115 = newJObject()
  if body != nil:
    body_21627115 = body
  result = call_21627114.call(nil, nil, nil, nil, body_21627115)

var getSecurityConfiguration* = Call_GetSecurityConfiguration_21627101(
    name: "getSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetSecurityConfiguration",
    validator: validate_GetSecurityConfiguration_21627102, base: "/",
    makeUrl: url_GetSecurityConfiguration_21627103,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecurityConfigurations_21627116 = ref object of OpenApiRestCall_21625435
proc url_GetSecurityConfigurations_21627118(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSecurityConfigurations_21627117(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of all security configurations.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627119 = query.getOrDefault("NextToken")
  valid_21627119 = validateParameter(valid_21627119, JString, required = false,
                                   default = nil)
  if valid_21627119 != nil:
    section.add "NextToken", valid_21627119
  var valid_21627120 = query.getOrDefault("MaxResults")
  valid_21627120 = validateParameter(valid_21627120, JString, required = false,
                                   default = nil)
  if valid_21627120 != nil:
    section.add "MaxResults", valid_21627120
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627121 = header.getOrDefault("X-Amz-Date")
  valid_21627121 = validateParameter(valid_21627121, JString, required = false,
                                   default = nil)
  if valid_21627121 != nil:
    section.add "X-Amz-Date", valid_21627121
  var valid_21627122 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627122 = validateParameter(valid_21627122, JString, required = false,
                                   default = nil)
  if valid_21627122 != nil:
    section.add "X-Amz-Security-Token", valid_21627122
  var valid_21627123 = header.getOrDefault("X-Amz-Target")
  valid_21627123 = validateParameter(valid_21627123, JString, required = true, default = newJString(
      "AWSGlue.GetSecurityConfigurations"))
  if valid_21627123 != nil:
    section.add "X-Amz-Target", valid_21627123
  var valid_21627124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627124 = validateParameter(valid_21627124, JString, required = false,
                                   default = nil)
  if valid_21627124 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627124
  var valid_21627125 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627125 = validateParameter(valid_21627125, JString, required = false,
                                   default = nil)
  if valid_21627125 != nil:
    section.add "X-Amz-Algorithm", valid_21627125
  var valid_21627126 = header.getOrDefault("X-Amz-Signature")
  valid_21627126 = validateParameter(valid_21627126, JString, required = false,
                                   default = nil)
  if valid_21627126 != nil:
    section.add "X-Amz-Signature", valid_21627126
  var valid_21627127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627127 = validateParameter(valid_21627127, JString, required = false,
                                   default = nil)
  if valid_21627127 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627127
  var valid_21627128 = header.getOrDefault("X-Amz-Credential")
  valid_21627128 = validateParameter(valid_21627128, JString, required = false,
                                   default = nil)
  if valid_21627128 != nil:
    section.add "X-Amz-Credential", valid_21627128
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

proc call*(call_21627130: Call_GetSecurityConfigurations_21627116;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of all security configurations.
  ## 
  let valid = call_21627130.validator(path, query, header, formData, body, _)
  let scheme = call_21627130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627130.makeUrl(scheme.get, call_21627130.host, call_21627130.base,
                               call_21627130.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627130, uri, valid, _)

proc call*(call_21627131: Call_GetSecurityConfigurations_21627116; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getSecurityConfigurations
  ## Retrieves a list of all security configurations.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627132 = newJObject()
  var body_21627133 = newJObject()
  add(query_21627132, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627133 = body
  add(query_21627132, "MaxResults", newJString(MaxResults))
  result = call_21627131.call(nil, query_21627132, nil, nil, body_21627133)

var getSecurityConfigurations* = Call_GetSecurityConfigurations_21627116(
    name: "getSecurityConfigurations", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetSecurityConfigurations",
    validator: validate_GetSecurityConfigurations_21627117, base: "/",
    makeUrl: url_GetSecurityConfigurations_21627118,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTable_21627134 = ref object of OpenApiRestCall_21625435
proc url_GetTable_21627136(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTable_21627135(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627137 = header.getOrDefault("X-Amz-Date")
  valid_21627137 = validateParameter(valid_21627137, JString, required = false,
                                   default = nil)
  if valid_21627137 != nil:
    section.add "X-Amz-Date", valid_21627137
  var valid_21627138 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627138 = validateParameter(valid_21627138, JString, required = false,
                                   default = nil)
  if valid_21627138 != nil:
    section.add "X-Amz-Security-Token", valid_21627138
  var valid_21627139 = header.getOrDefault("X-Amz-Target")
  valid_21627139 = validateParameter(valid_21627139, JString, required = true,
                                   default = newJString("AWSGlue.GetTable"))
  if valid_21627139 != nil:
    section.add "X-Amz-Target", valid_21627139
  var valid_21627140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627140 = validateParameter(valid_21627140, JString, required = false,
                                   default = nil)
  if valid_21627140 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627140
  var valid_21627141 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627141 = validateParameter(valid_21627141, JString, required = false,
                                   default = nil)
  if valid_21627141 != nil:
    section.add "X-Amz-Algorithm", valid_21627141
  var valid_21627142 = header.getOrDefault("X-Amz-Signature")
  valid_21627142 = validateParameter(valid_21627142, JString, required = false,
                                   default = nil)
  if valid_21627142 != nil:
    section.add "X-Amz-Signature", valid_21627142
  var valid_21627143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627143 = validateParameter(valid_21627143, JString, required = false,
                                   default = nil)
  if valid_21627143 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627143
  var valid_21627144 = header.getOrDefault("X-Amz-Credential")
  valid_21627144 = validateParameter(valid_21627144, JString, required = false,
                                   default = nil)
  if valid_21627144 != nil:
    section.add "X-Amz-Credential", valid_21627144
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

proc call*(call_21627146: Call_GetTable_21627134; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
  ## 
  let valid = call_21627146.validator(path, query, header, formData, body, _)
  let scheme = call_21627146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627146.makeUrl(scheme.get, call_21627146.host, call_21627146.base,
                               call_21627146.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627146, uri, valid, _)

proc call*(call_21627147: Call_GetTable_21627134; body: JsonNode): Recallable =
  ## getTable
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
  ##   body: JObject (required)
  var body_21627148 = newJObject()
  if body != nil:
    body_21627148 = body
  result = call_21627147.call(nil, nil, nil, nil, body_21627148)

var getTable* = Call_GetTable_21627134(name: "getTable", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.GetTable",
                                    validator: validate_GetTable_21627135,
                                    base: "/", makeUrl: url_GetTable_21627136,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTableVersion_21627149 = ref object of OpenApiRestCall_21625435
proc url_GetTableVersion_21627151(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTableVersion_21627150(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627152 = header.getOrDefault("X-Amz-Date")
  valid_21627152 = validateParameter(valid_21627152, JString, required = false,
                                   default = nil)
  if valid_21627152 != nil:
    section.add "X-Amz-Date", valid_21627152
  var valid_21627153 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627153 = validateParameter(valid_21627153, JString, required = false,
                                   default = nil)
  if valid_21627153 != nil:
    section.add "X-Amz-Security-Token", valid_21627153
  var valid_21627154 = header.getOrDefault("X-Amz-Target")
  valid_21627154 = validateParameter(valid_21627154, JString, required = true, default = newJString(
      "AWSGlue.GetTableVersion"))
  if valid_21627154 != nil:
    section.add "X-Amz-Target", valid_21627154
  var valid_21627155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627155 = validateParameter(valid_21627155, JString, required = false,
                                   default = nil)
  if valid_21627155 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627155
  var valid_21627156 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627156 = validateParameter(valid_21627156, JString, required = false,
                                   default = nil)
  if valid_21627156 != nil:
    section.add "X-Amz-Algorithm", valid_21627156
  var valid_21627157 = header.getOrDefault("X-Amz-Signature")
  valid_21627157 = validateParameter(valid_21627157, JString, required = false,
                                   default = nil)
  if valid_21627157 != nil:
    section.add "X-Amz-Signature", valid_21627157
  var valid_21627158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627158 = validateParameter(valid_21627158, JString, required = false,
                                   default = nil)
  if valid_21627158 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627158
  var valid_21627159 = header.getOrDefault("X-Amz-Credential")
  valid_21627159 = validateParameter(valid_21627159, JString, required = false,
                                   default = nil)
  if valid_21627159 != nil:
    section.add "X-Amz-Credential", valid_21627159
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

proc call*(call_21627161: Call_GetTableVersion_21627149; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a specified version of a table.
  ## 
  let valid = call_21627161.validator(path, query, header, formData, body, _)
  let scheme = call_21627161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627161.makeUrl(scheme.get, call_21627161.host, call_21627161.base,
                               call_21627161.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627161, uri, valid, _)

proc call*(call_21627162: Call_GetTableVersion_21627149; body: JsonNode): Recallable =
  ## getTableVersion
  ## Retrieves a specified version of a table.
  ##   body: JObject (required)
  var body_21627163 = newJObject()
  if body != nil:
    body_21627163 = body
  result = call_21627162.call(nil, nil, nil, nil, body_21627163)

var getTableVersion* = Call_GetTableVersion_21627149(name: "getTableVersion",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTableVersion",
    validator: validate_GetTableVersion_21627150, base: "/",
    makeUrl: url_GetTableVersion_21627151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTableVersions_21627164 = ref object of OpenApiRestCall_21625435
proc url_GetTableVersions_21627166(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTableVersions_21627165(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of strings that identify available versions of a specified table.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627167 = query.getOrDefault("NextToken")
  valid_21627167 = validateParameter(valid_21627167, JString, required = false,
                                   default = nil)
  if valid_21627167 != nil:
    section.add "NextToken", valid_21627167
  var valid_21627168 = query.getOrDefault("MaxResults")
  valid_21627168 = validateParameter(valid_21627168, JString, required = false,
                                   default = nil)
  if valid_21627168 != nil:
    section.add "MaxResults", valid_21627168
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627169 = header.getOrDefault("X-Amz-Date")
  valid_21627169 = validateParameter(valid_21627169, JString, required = false,
                                   default = nil)
  if valid_21627169 != nil:
    section.add "X-Amz-Date", valid_21627169
  var valid_21627170 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627170 = validateParameter(valid_21627170, JString, required = false,
                                   default = nil)
  if valid_21627170 != nil:
    section.add "X-Amz-Security-Token", valid_21627170
  var valid_21627171 = header.getOrDefault("X-Amz-Target")
  valid_21627171 = validateParameter(valid_21627171, JString, required = true, default = newJString(
      "AWSGlue.GetTableVersions"))
  if valid_21627171 != nil:
    section.add "X-Amz-Target", valid_21627171
  var valid_21627172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627172 = validateParameter(valid_21627172, JString, required = false,
                                   default = nil)
  if valid_21627172 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627172
  var valid_21627173 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627173 = validateParameter(valid_21627173, JString, required = false,
                                   default = nil)
  if valid_21627173 != nil:
    section.add "X-Amz-Algorithm", valid_21627173
  var valid_21627174 = header.getOrDefault("X-Amz-Signature")
  valid_21627174 = validateParameter(valid_21627174, JString, required = false,
                                   default = nil)
  if valid_21627174 != nil:
    section.add "X-Amz-Signature", valid_21627174
  var valid_21627175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627175 = validateParameter(valid_21627175, JString, required = false,
                                   default = nil)
  if valid_21627175 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627175
  var valid_21627176 = header.getOrDefault("X-Amz-Credential")
  valid_21627176 = validateParameter(valid_21627176, JString, required = false,
                                   default = nil)
  if valid_21627176 != nil:
    section.add "X-Amz-Credential", valid_21627176
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

proc call*(call_21627178: Call_GetTableVersions_21627164; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of strings that identify available versions of a specified table.
  ## 
  let valid = call_21627178.validator(path, query, header, formData, body, _)
  let scheme = call_21627178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627178.makeUrl(scheme.get, call_21627178.host, call_21627178.base,
                               call_21627178.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627178, uri, valid, _)

proc call*(call_21627179: Call_GetTableVersions_21627164; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getTableVersions
  ## Retrieves a list of strings that identify available versions of a specified table.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627180 = newJObject()
  var body_21627181 = newJObject()
  add(query_21627180, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627181 = body
  add(query_21627180, "MaxResults", newJString(MaxResults))
  result = call_21627179.call(nil, query_21627180, nil, nil, body_21627181)

var getTableVersions* = Call_GetTableVersions_21627164(name: "getTableVersions",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTableVersions",
    validator: validate_GetTableVersions_21627165, base: "/",
    makeUrl: url_GetTableVersions_21627166, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTables_21627182 = ref object of OpenApiRestCall_21625435
proc url_GetTables_21627184(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTables_21627183(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627185 = query.getOrDefault("NextToken")
  valid_21627185 = validateParameter(valid_21627185, JString, required = false,
                                   default = nil)
  if valid_21627185 != nil:
    section.add "NextToken", valid_21627185
  var valid_21627186 = query.getOrDefault("MaxResults")
  valid_21627186 = validateParameter(valid_21627186, JString, required = false,
                                   default = nil)
  if valid_21627186 != nil:
    section.add "MaxResults", valid_21627186
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627187 = header.getOrDefault("X-Amz-Date")
  valid_21627187 = validateParameter(valid_21627187, JString, required = false,
                                   default = nil)
  if valid_21627187 != nil:
    section.add "X-Amz-Date", valid_21627187
  var valid_21627188 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627188 = validateParameter(valid_21627188, JString, required = false,
                                   default = nil)
  if valid_21627188 != nil:
    section.add "X-Amz-Security-Token", valid_21627188
  var valid_21627189 = header.getOrDefault("X-Amz-Target")
  valid_21627189 = validateParameter(valid_21627189, JString, required = true,
                                   default = newJString("AWSGlue.GetTables"))
  if valid_21627189 != nil:
    section.add "X-Amz-Target", valid_21627189
  var valid_21627190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627190 = validateParameter(valid_21627190, JString, required = false,
                                   default = nil)
  if valid_21627190 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627190
  var valid_21627191 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627191 = validateParameter(valid_21627191, JString, required = false,
                                   default = nil)
  if valid_21627191 != nil:
    section.add "X-Amz-Algorithm", valid_21627191
  var valid_21627192 = header.getOrDefault("X-Amz-Signature")
  valid_21627192 = validateParameter(valid_21627192, JString, required = false,
                                   default = nil)
  if valid_21627192 != nil:
    section.add "X-Amz-Signature", valid_21627192
  var valid_21627193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627193 = validateParameter(valid_21627193, JString, required = false,
                                   default = nil)
  if valid_21627193 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627193
  var valid_21627194 = header.getOrDefault("X-Amz-Credential")
  valid_21627194 = validateParameter(valid_21627194, JString, required = false,
                                   default = nil)
  if valid_21627194 != nil:
    section.add "X-Amz-Credential", valid_21627194
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

proc call*(call_21627196: Call_GetTables_21627182; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ## 
  let valid = call_21627196.validator(path, query, header, formData, body, _)
  let scheme = call_21627196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627196.makeUrl(scheme.get, call_21627196.host, call_21627196.base,
                               call_21627196.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627196, uri, valid, _)

proc call*(call_21627197: Call_GetTables_21627182; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getTables
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627198 = newJObject()
  var body_21627199 = newJObject()
  add(query_21627198, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627199 = body
  add(query_21627198, "MaxResults", newJString(MaxResults))
  result = call_21627197.call(nil, query_21627198, nil, nil, body_21627199)

var getTables* = Call_GetTables_21627182(name: "getTables",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetTables",
                                      validator: validate_GetTables_21627183,
                                      base: "/", makeUrl: url_GetTables_21627184,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_21627200 = ref object of OpenApiRestCall_21625435
proc url_GetTags_21627202(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTags_21627201(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627203 = header.getOrDefault("X-Amz-Date")
  valid_21627203 = validateParameter(valid_21627203, JString, required = false,
                                   default = nil)
  if valid_21627203 != nil:
    section.add "X-Amz-Date", valid_21627203
  var valid_21627204 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627204 = validateParameter(valid_21627204, JString, required = false,
                                   default = nil)
  if valid_21627204 != nil:
    section.add "X-Amz-Security-Token", valid_21627204
  var valid_21627205 = header.getOrDefault("X-Amz-Target")
  valid_21627205 = validateParameter(valid_21627205, JString, required = true,
                                   default = newJString("AWSGlue.GetTags"))
  if valid_21627205 != nil:
    section.add "X-Amz-Target", valid_21627205
  var valid_21627206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627206 = validateParameter(valid_21627206, JString, required = false,
                                   default = nil)
  if valid_21627206 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627206
  var valid_21627207 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627207 = validateParameter(valid_21627207, JString, required = false,
                                   default = nil)
  if valid_21627207 != nil:
    section.add "X-Amz-Algorithm", valid_21627207
  var valid_21627208 = header.getOrDefault("X-Amz-Signature")
  valid_21627208 = validateParameter(valid_21627208, JString, required = false,
                                   default = nil)
  if valid_21627208 != nil:
    section.add "X-Amz-Signature", valid_21627208
  var valid_21627209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627209 = validateParameter(valid_21627209, JString, required = false,
                                   default = nil)
  if valid_21627209 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627209
  var valid_21627210 = header.getOrDefault("X-Amz-Credential")
  valid_21627210 = validateParameter(valid_21627210, JString, required = false,
                                   default = nil)
  if valid_21627210 != nil:
    section.add "X-Amz-Credential", valid_21627210
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

proc call*(call_21627212: Call_GetTags_21627200; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of tags associated with a resource.
  ## 
  let valid = call_21627212.validator(path, query, header, formData, body, _)
  let scheme = call_21627212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627212.makeUrl(scheme.get, call_21627212.host, call_21627212.base,
                               call_21627212.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627212, uri, valid, _)

proc call*(call_21627213: Call_GetTags_21627200; body: JsonNode): Recallable =
  ## getTags
  ## Retrieves a list of tags associated with a resource.
  ##   body: JObject (required)
  var body_21627214 = newJObject()
  if body != nil:
    body_21627214 = body
  result = call_21627213.call(nil, nil, nil, nil, body_21627214)

var getTags* = Call_GetTags_21627200(name: "getTags", meth: HttpMethod.HttpPost,
                                  host: "glue.amazonaws.com",
                                  route: "/#X-Amz-Target=AWSGlue.GetTags",
                                  validator: validate_GetTags_21627201, base: "/",
                                  makeUrl: url_GetTags_21627202,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrigger_21627215 = ref object of OpenApiRestCall_21625435
proc url_GetTrigger_21627217(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTrigger_21627216(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627218 = header.getOrDefault("X-Amz-Date")
  valid_21627218 = validateParameter(valid_21627218, JString, required = false,
                                   default = nil)
  if valid_21627218 != nil:
    section.add "X-Amz-Date", valid_21627218
  var valid_21627219 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627219 = validateParameter(valid_21627219, JString, required = false,
                                   default = nil)
  if valid_21627219 != nil:
    section.add "X-Amz-Security-Token", valid_21627219
  var valid_21627220 = header.getOrDefault("X-Amz-Target")
  valid_21627220 = validateParameter(valid_21627220, JString, required = true,
                                   default = newJString("AWSGlue.GetTrigger"))
  if valid_21627220 != nil:
    section.add "X-Amz-Target", valid_21627220
  var valid_21627221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627221 = validateParameter(valid_21627221, JString, required = false,
                                   default = nil)
  if valid_21627221 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627221
  var valid_21627222 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627222 = validateParameter(valid_21627222, JString, required = false,
                                   default = nil)
  if valid_21627222 != nil:
    section.add "X-Amz-Algorithm", valid_21627222
  var valid_21627223 = header.getOrDefault("X-Amz-Signature")
  valid_21627223 = validateParameter(valid_21627223, JString, required = false,
                                   default = nil)
  if valid_21627223 != nil:
    section.add "X-Amz-Signature", valid_21627223
  var valid_21627224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627224 = validateParameter(valid_21627224, JString, required = false,
                                   default = nil)
  if valid_21627224 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627224
  var valid_21627225 = header.getOrDefault("X-Amz-Credential")
  valid_21627225 = validateParameter(valid_21627225, JString, required = false,
                                   default = nil)
  if valid_21627225 != nil:
    section.add "X-Amz-Credential", valid_21627225
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

proc call*(call_21627227: Call_GetTrigger_21627215; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the definition of a trigger.
  ## 
  let valid = call_21627227.validator(path, query, header, formData, body, _)
  let scheme = call_21627227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627227.makeUrl(scheme.get, call_21627227.host, call_21627227.base,
                               call_21627227.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627227, uri, valid, _)

proc call*(call_21627228: Call_GetTrigger_21627215; body: JsonNode): Recallable =
  ## getTrigger
  ## Retrieves the definition of a trigger.
  ##   body: JObject (required)
  var body_21627229 = newJObject()
  if body != nil:
    body_21627229 = body
  result = call_21627228.call(nil, nil, nil, nil, body_21627229)

var getTrigger* = Call_GetTrigger_21627215(name: "getTrigger",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetTrigger",
                                        validator: validate_GetTrigger_21627216,
                                        base: "/", makeUrl: url_GetTrigger_21627217,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTriggers_21627230 = ref object of OpenApiRestCall_21625435
proc url_GetTriggers_21627232(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTriggers_21627231(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets all the triggers associated with a job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627233 = query.getOrDefault("NextToken")
  valid_21627233 = validateParameter(valid_21627233, JString, required = false,
                                   default = nil)
  if valid_21627233 != nil:
    section.add "NextToken", valid_21627233
  var valid_21627234 = query.getOrDefault("MaxResults")
  valid_21627234 = validateParameter(valid_21627234, JString, required = false,
                                   default = nil)
  if valid_21627234 != nil:
    section.add "MaxResults", valid_21627234
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627235 = header.getOrDefault("X-Amz-Date")
  valid_21627235 = validateParameter(valid_21627235, JString, required = false,
                                   default = nil)
  if valid_21627235 != nil:
    section.add "X-Amz-Date", valid_21627235
  var valid_21627236 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627236 = validateParameter(valid_21627236, JString, required = false,
                                   default = nil)
  if valid_21627236 != nil:
    section.add "X-Amz-Security-Token", valid_21627236
  var valid_21627237 = header.getOrDefault("X-Amz-Target")
  valid_21627237 = validateParameter(valid_21627237, JString, required = true,
                                   default = newJString("AWSGlue.GetTriggers"))
  if valid_21627237 != nil:
    section.add "X-Amz-Target", valid_21627237
  var valid_21627238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627238 = validateParameter(valid_21627238, JString, required = false,
                                   default = nil)
  if valid_21627238 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627238
  var valid_21627239 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627239 = validateParameter(valid_21627239, JString, required = false,
                                   default = nil)
  if valid_21627239 != nil:
    section.add "X-Amz-Algorithm", valid_21627239
  var valid_21627240 = header.getOrDefault("X-Amz-Signature")
  valid_21627240 = validateParameter(valid_21627240, JString, required = false,
                                   default = nil)
  if valid_21627240 != nil:
    section.add "X-Amz-Signature", valid_21627240
  var valid_21627241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627241 = validateParameter(valid_21627241, JString, required = false,
                                   default = nil)
  if valid_21627241 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627241
  var valid_21627242 = header.getOrDefault("X-Amz-Credential")
  valid_21627242 = validateParameter(valid_21627242, JString, required = false,
                                   default = nil)
  if valid_21627242 != nil:
    section.add "X-Amz-Credential", valid_21627242
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

proc call*(call_21627244: Call_GetTriggers_21627230; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets all the triggers associated with a job.
  ## 
  let valid = call_21627244.validator(path, query, header, formData, body, _)
  let scheme = call_21627244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627244.makeUrl(scheme.get, call_21627244.host, call_21627244.base,
                               call_21627244.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627244, uri, valid, _)

proc call*(call_21627245: Call_GetTriggers_21627230; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getTriggers
  ## Gets all the triggers associated with a job.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627246 = newJObject()
  var body_21627247 = newJObject()
  add(query_21627246, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627247 = body
  add(query_21627246, "MaxResults", newJString(MaxResults))
  result = call_21627245.call(nil, query_21627246, nil, nil, body_21627247)

var getTriggers* = Call_GetTriggers_21627230(name: "getTriggers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTriggers", validator: validate_GetTriggers_21627231,
    base: "/", makeUrl: url_GetTriggers_21627232,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserDefinedFunction_21627248 = ref object of OpenApiRestCall_21625435
proc url_GetUserDefinedFunction_21627250(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUserDefinedFunction_21627249(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627251 = header.getOrDefault("X-Amz-Date")
  valid_21627251 = validateParameter(valid_21627251, JString, required = false,
                                   default = nil)
  if valid_21627251 != nil:
    section.add "X-Amz-Date", valid_21627251
  var valid_21627252 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627252 = validateParameter(valid_21627252, JString, required = false,
                                   default = nil)
  if valid_21627252 != nil:
    section.add "X-Amz-Security-Token", valid_21627252
  var valid_21627253 = header.getOrDefault("X-Amz-Target")
  valid_21627253 = validateParameter(valid_21627253, JString, required = true, default = newJString(
      "AWSGlue.GetUserDefinedFunction"))
  if valid_21627253 != nil:
    section.add "X-Amz-Target", valid_21627253
  var valid_21627254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627254 = validateParameter(valid_21627254, JString, required = false,
                                   default = nil)
  if valid_21627254 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627254
  var valid_21627255 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627255 = validateParameter(valid_21627255, JString, required = false,
                                   default = nil)
  if valid_21627255 != nil:
    section.add "X-Amz-Algorithm", valid_21627255
  var valid_21627256 = header.getOrDefault("X-Amz-Signature")
  valid_21627256 = validateParameter(valid_21627256, JString, required = false,
                                   default = nil)
  if valid_21627256 != nil:
    section.add "X-Amz-Signature", valid_21627256
  var valid_21627257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627257 = validateParameter(valid_21627257, JString, required = false,
                                   default = nil)
  if valid_21627257 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627257
  var valid_21627258 = header.getOrDefault("X-Amz-Credential")
  valid_21627258 = validateParameter(valid_21627258, JString, required = false,
                                   default = nil)
  if valid_21627258 != nil:
    section.add "X-Amz-Credential", valid_21627258
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

proc call*(call_21627260: Call_GetUserDefinedFunction_21627248;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a specified function definition from the Data Catalog.
  ## 
  let valid = call_21627260.validator(path, query, header, formData, body, _)
  let scheme = call_21627260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627260.makeUrl(scheme.get, call_21627260.host, call_21627260.base,
                               call_21627260.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627260, uri, valid, _)

proc call*(call_21627261: Call_GetUserDefinedFunction_21627248; body: JsonNode): Recallable =
  ## getUserDefinedFunction
  ## Retrieves a specified function definition from the Data Catalog.
  ##   body: JObject (required)
  var body_21627262 = newJObject()
  if body != nil:
    body_21627262 = body
  result = call_21627261.call(nil, nil, nil, nil, body_21627262)

var getUserDefinedFunction* = Call_GetUserDefinedFunction_21627248(
    name: "getUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetUserDefinedFunction",
    validator: validate_GetUserDefinedFunction_21627249, base: "/",
    makeUrl: url_GetUserDefinedFunction_21627250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserDefinedFunctions_21627263 = ref object of OpenApiRestCall_21625435
proc url_GetUserDefinedFunctions_21627265(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUserDefinedFunctions_21627264(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves multiple function definitions from the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627266 = query.getOrDefault("NextToken")
  valid_21627266 = validateParameter(valid_21627266, JString, required = false,
                                   default = nil)
  if valid_21627266 != nil:
    section.add "NextToken", valid_21627266
  var valid_21627267 = query.getOrDefault("MaxResults")
  valid_21627267 = validateParameter(valid_21627267, JString, required = false,
                                   default = nil)
  if valid_21627267 != nil:
    section.add "MaxResults", valid_21627267
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627268 = header.getOrDefault("X-Amz-Date")
  valid_21627268 = validateParameter(valid_21627268, JString, required = false,
                                   default = nil)
  if valid_21627268 != nil:
    section.add "X-Amz-Date", valid_21627268
  var valid_21627269 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627269 = validateParameter(valid_21627269, JString, required = false,
                                   default = nil)
  if valid_21627269 != nil:
    section.add "X-Amz-Security-Token", valid_21627269
  var valid_21627270 = header.getOrDefault("X-Amz-Target")
  valid_21627270 = validateParameter(valid_21627270, JString, required = true, default = newJString(
      "AWSGlue.GetUserDefinedFunctions"))
  if valid_21627270 != nil:
    section.add "X-Amz-Target", valid_21627270
  var valid_21627271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627271 = validateParameter(valid_21627271, JString, required = false,
                                   default = nil)
  if valid_21627271 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627271
  var valid_21627272 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627272 = validateParameter(valid_21627272, JString, required = false,
                                   default = nil)
  if valid_21627272 != nil:
    section.add "X-Amz-Algorithm", valid_21627272
  var valid_21627273 = header.getOrDefault("X-Amz-Signature")
  valid_21627273 = validateParameter(valid_21627273, JString, required = false,
                                   default = nil)
  if valid_21627273 != nil:
    section.add "X-Amz-Signature", valid_21627273
  var valid_21627274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627274 = validateParameter(valid_21627274, JString, required = false,
                                   default = nil)
  if valid_21627274 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627274
  var valid_21627275 = header.getOrDefault("X-Amz-Credential")
  valid_21627275 = validateParameter(valid_21627275, JString, required = false,
                                   default = nil)
  if valid_21627275 != nil:
    section.add "X-Amz-Credential", valid_21627275
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

proc call*(call_21627277: Call_GetUserDefinedFunctions_21627263;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves multiple function definitions from the Data Catalog.
  ## 
  let valid = call_21627277.validator(path, query, header, formData, body, _)
  let scheme = call_21627277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627277.makeUrl(scheme.get, call_21627277.host, call_21627277.base,
                               call_21627277.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627277, uri, valid, _)

proc call*(call_21627278: Call_GetUserDefinedFunctions_21627263; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getUserDefinedFunctions
  ## Retrieves multiple function definitions from the Data Catalog.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627279 = newJObject()
  var body_21627280 = newJObject()
  add(query_21627279, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627280 = body
  add(query_21627279, "MaxResults", newJString(MaxResults))
  result = call_21627278.call(nil, query_21627279, nil, nil, body_21627280)

var getUserDefinedFunctions* = Call_GetUserDefinedFunctions_21627263(
    name: "getUserDefinedFunctions", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetUserDefinedFunctions",
    validator: validate_GetUserDefinedFunctions_21627264, base: "/",
    makeUrl: url_GetUserDefinedFunctions_21627265,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflow_21627281 = ref object of OpenApiRestCall_21625435
proc url_GetWorkflow_21627283(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetWorkflow_21627282(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627284 = header.getOrDefault("X-Amz-Date")
  valid_21627284 = validateParameter(valid_21627284, JString, required = false,
                                   default = nil)
  if valid_21627284 != nil:
    section.add "X-Amz-Date", valid_21627284
  var valid_21627285 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627285 = validateParameter(valid_21627285, JString, required = false,
                                   default = nil)
  if valid_21627285 != nil:
    section.add "X-Amz-Security-Token", valid_21627285
  var valid_21627286 = header.getOrDefault("X-Amz-Target")
  valid_21627286 = validateParameter(valid_21627286, JString, required = true,
                                   default = newJString("AWSGlue.GetWorkflow"))
  if valid_21627286 != nil:
    section.add "X-Amz-Target", valid_21627286
  var valid_21627287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627287 = validateParameter(valid_21627287, JString, required = false,
                                   default = nil)
  if valid_21627287 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627287
  var valid_21627288 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627288 = validateParameter(valid_21627288, JString, required = false,
                                   default = nil)
  if valid_21627288 != nil:
    section.add "X-Amz-Algorithm", valid_21627288
  var valid_21627289 = header.getOrDefault("X-Amz-Signature")
  valid_21627289 = validateParameter(valid_21627289, JString, required = false,
                                   default = nil)
  if valid_21627289 != nil:
    section.add "X-Amz-Signature", valid_21627289
  var valid_21627290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627290 = validateParameter(valid_21627290, JString, required = false,
                                   default = nil)
  if valid_21627290 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627290
  var valid_21627291 = header.getOrDefault("X-Amz-Credential")
  valid_21627291 = validateParameter(valid_21627291, JString, required = false,
                                   default = nil)
  if valid_21627291 != nil:
    section.add "X-Amz-Credential", valid_21627291
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

proc call*(call_21627293: Call_GetWorkflow_21627281; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves resource metadata for a workflow.
  ## 
  let valid = call_21627293.validator(path, query, header, formData, body, _)
  let scheme = call_21627293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627293.makeUrl(scheme.get, call_21627293.host, call_21627293.base,
                               call_21627293.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627293, uri, valid, _)

proc call*(call_21627294: Call_GetWorkflow_21627281; body: JsonNode): Recallable =
  ## getWorkflow
  ## Retrieves resource metadata for a workflow.
  ##   body: JObject (required)
  var body_21627295 = newJObject()
  if body != nil:
    body_21627295 = body
  result = call_21627294.call(nil, nil, nil, nil, body_21627295)

var getWorkflow* = Call_GetWorkflow_21627281(name: "getWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflow", validator: validate_GetWorkflow_21627282,
    base: "/", makeUrl: url_GetWorkflow_21627283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRun_21627296 = ref object of OpenApiRestCall_21625435
proc url_GetWorkflowRun_21627298(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetWorkflowRun_21627297(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627299 = header.getOrDefault("X-Amz-Date")
  valid_21627299 = validateParameter(valid_21627299, JString, required = false,
                                   default = nil)
  if valid_21627299 != nil:
    section.add "X-Amz-Date", valid_21627299
  var valid_21627300 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627300 = validateParameter(valid_21627300, JString, required = false,
                                   default = nil)
  if valid_21627300 != nil:
    section.add "X-Amz-Security-Token", valid_21627300
  var valid_21627301 = header.getOrDefault("X-Amz-Target")
  valid_21627301 = validateParameter(valid_21627301, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRun"))
  if valid_21627301 != nil:
    section.add "X-Amz-Target", valid_21627301
  var valid_21627302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627302 = validateParameter(valid_21627302, JString, required = false,
                                   default = nil)
  if valid_21627302 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627302
  var valid_21627303 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627303 = validateParameter(valid_21627303, JString, required = false,
                                   default = nil)
  if valid_21627303 != nil:
    section.add "X-Amz-Algorithm", valid_21627303
  var valid_21627304 = header.getOrDefault("X-Amz-Signature")
  valid_21627304 = validateParameter(valid_21627304, JString, required = false,
                                   default = nil)
  if valid_21627304 != nil:
    section.add "X-Amz-Signature", valid_21627304
  var valid_21627305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627305 = validateParameter(valid_21627305, JString, required = false,
                                   default = nil)
  if valid_21627305 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627305
  var valid_21627306 = header.getOrDefault("X-Amz-Credential")
  valid_21627306 = validateParameter(valid_21627306, JString, required = false,
                                   default = nil)
  if valid_21627306 != nil:
    section.add "X-Amz-Credential", valid_21627306
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

proc call*(call_21627308: Call_GetWorkflowRun_21627296; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the metadata for a given workflow run. 
  ## 
  let valid = call_21627308.validator(path, query, header, formData, body, _)
  let scheme = call_21627308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627308.makeUrl(scheme.get, call_21627308.host, call_21627308.base,
                               call_21627308.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627308, uri, valid, _)

proc call*(call_21627309: Call_GetWorkflowRun_21627296; body: JsonNode): Recallable =
  ## getWorkflowRun
  ## Retrieves the metadata for a given workflow run. 
  ##   body: JObject (required)
  var body_21627310 = newJObject()
  if body != nil:
    body_21627310 = body
  result = call_21627309.call(nil, nil, nil, nil, body_21627310)

var getWorkflowRun* = Call_GetWorkflowRun_21627296(name: "getWorkflowRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRun",
    validator: validate_GetWorkflowRun_21627297, base: "/",
    makeUrl: url_GetWorkflowRun_21627298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRunProperties_21627311 = ref object of OpenApiRestCall_21625435
proc url_GetWorkflowRunProperties_21627313(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetWorkflowRunProperties_21627312(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the workflow run properties which were set during the run.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627314 = header.getOrDefault("X-Amz-Date")
  valid_21627314 = validateParameter(valid_21627314, JString, required = false,
                                   default = nil)
  if valid_21627314 != nil:
    section.add "X-Amz-Date", valid_21627314
  var valid_21627315 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627315 = validateParameter(valid_21627315, JString, required = false,
                                   default = nil)
  if valid_21627315 != nil:
    section.add "X-Amz-Security-Token", valid_21627315
  var valid_21627316 = header.getOrDefault("X-Amz-Target")
  valid_21627316 = validateParameter(valid_21627316, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRunProperties"))
  if valid_21627316 != nil:
    section.add "X-Amz-Target", valid_21627316
  var valid_21627317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627317 = validateParameter(valid_21627317, JString, required = false,
                                   default = nil)
  if valid_21627317 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627317
  var valid_21627318 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627318 = validateParameter(valid_21627318, JString, required = false,
                                   default = nil)
  if valid_21627318 != nil:
    section.add "X-Amz-Algorithm", valid_21627318
  var valid_21627319 = header.getOrDefault("X-Amz-Signature")
  valid_21627319 = validateParameter(valid_21627319, JString, required = false,
                                   default = nil)
  if valid_21627319 != nil:
    section.add "X-Amz-Signature", valid_21627319
  var valid_21627320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627320 = validateParameter(valid_21627320, JString, required = false,
                                   default = nil)
  if valid_21627320 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627320
  var valid_21627321 = header.getOrDefault("X-Amz-Credential")
  valid_21627321 = validateParameter(valid_21627321, JString, required = false,
                                   default = nil)
  if valid_21627321 != nil:
    section.add "X-Amz-Credential", valid_21627321
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

proc call*(call_21627323: Call_GetWorkflowRunProperties_21627311;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the workflow run properties which were set during the run.
  ## 
  let valid = call_21627323.validator(path, query, header, formData, body, _)
  let scheme = call_21627323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627323.makeUrl(scheme.get, call_21627323.host, call_21627323.base,
                               call_21627323.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627323, uri, valid, _)

proc call*(call_21627324: Call_GetWorkflowRunProperties_21627311; body: JsonNode): Recallable =
  ## getWorkflowRunProperties
  ## Retrieves the workflow run properties which were set during the run.
  ##   body: JObject (required)
  var body_21627325 = newJObject()
  if body != nil:
    body_21627325 = body
  result = call_21627324.call(nil, nil, nil, nil, body_21627325)

var getWorkflowRunProperties* = Call_GetWorkflowRunProperties_21627311(
    name: "getWorkflowRunProperties", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRunProperties",
    validator: validate_GetWorkflowRunProperties_21627312, base: "/",
    makeUrl: url_GetWorkflowRunProperties_21627313,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRuns_21627326 = ref object of OpenApiRestCall_21625435
proc url_GetWorkflowRuns_21627328(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetWorkflowRuns_21627327(path: JsonNode; query: JsonNode;
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
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627329 = query.getOrDefault("NextToken")
  valid_21627329 = validateParameter(valid_21627329, JString, required = false,
                                   default = nil)
  if valid_21627329 != nil:
    section.add "NextToken", valid_21627329
  var valid_21627330 = query.getOrDefault("MaxResults")
  valid_21627330 = validateParameter(valid_21627330, JString, required = false,
                                   default = nil)
  if valid_21627330 != nil:
    section.add "MaxResults", valid_21627330
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627331 = header.getOrDefault("X-Amz-Date")
  valid_21627331 = validateParameter(valid_21627331, JString, required = false,
                                   default = nil)
  if valid_21627331 != nil:
    section.add "X-Amz-Date", valid_21627331
  var valid_21627332 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627332 = validateParameter(valid_21627332, JString, required = false,
                                   default = nil)
  if valid_21627332 != nil:
    section.add "X-Amz-Security-Token", valid_21627332
  var valid_21627333 = header.getOrDefault("X-Amz-Target")
  valid_21627333 = validateParameter(valid_21627333, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRuns"))
  if valid_21627333 != nil:
    section.add "X-Amz-Target", valid_21627333
  var valid_21627334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627334 = validateParameter(valid_21627334, JString, required = false,
                                   default = nil)
  if valid_21627334 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627334
  var valid_21627335 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627335 = validateParameter(valid_21627335, JString, required = false,
                                   default = nil)
  if valid_21627335 != nil:
    section.add "X-Amz-Algorithm", valid_21627335
  var valid_21627336 = header.getOrDefault("X-Amz-Signature")
  valid_21627336 = validateParameter(valid_21627336, JString, required = false,
                                   default = nil)
  if valid_21627336 != nil:
    section.add "X-Amz-Signature", valid_21627336
  var valid_21627337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627337 = validateParameter(valid_21627337, JString, required = false,
                                   default = nil)
  if valid_21627337 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627337
  var valid_21627338 = header.getOrDefault("X-Amz-Credential")
  valid_21627338 = validateParameter(valid_21627338, JString, required = false,
                                   default = nil)
  if valid_21627338 != nil:
    section.add "X-Amz-Credential", valid_21627338
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

proc call*(call_21627340: Call_GetWorkflowRuns_21627326; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves metadata for all runs of a given workflow.
  ## 
  let valid = call_21627340.validator(path, query, header, formData, body, _)
  let scheme = call_21627340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627340.makeUrl(scheme.get, call_21627340.host, call_21627340.base,
                               call_21627340.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627340, uri, valid, _)

proc call*(call_21627341: Call_GetWorkflowRuns_21627326; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getWorkflowRuns
  ## Retrieves metadata for all runs of a given workflow.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627342 = newJObject()
  var body_21627343 = newJObject()
  add(query_21627342, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627343 = body
  add(query_21627342, "MaxResults", newJString(MaxResults))
  result = call_21627341.call(nil, query_21627342, nil, nil, body_21627343)

var getWorkflowRuns* = Call_GetWorkflowRuns_21627326(name: "getWorkflowRuns",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRuns",
    validator: validate_GetWorkflowRuns_21627327, base: "/",
    makeUrl: url_GetWorkflowRuns_21627328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportCatalogToGlue_21627344 = ref object of OpenApiRestCall_21625435
proc url_ImportCatalogToGlue_21627346(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportCatalogToGlue_21627345(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627347 = header.getOrDefault("X-Amz-Date")
  valid_21627347 = validateParameter(valid_21627347, JString, required = false,
                                   default = nil)
  if valid_21627347 != nil:
    section.add "X-Amz-Date", valid_21627347
  var valid_21627348 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627348 = validateParameter(valid_21627348, JString, required = false,
                                   default = nil)
  if valid_21627348 != nil:
    section.add "X-Amz-Security-Token", valid_21627348
  var valid_21627349 = header.getOrDefault("X-Amz-Target")
  valid_21627349 = validateParameter(valid_21627349, JString, required = true, default = newJString(
      "AWSGlue.ImportCatalogToGlue"))
  if valid_21627349 != nil:
    section.add "X-Amz-Target", valid_21627349
  var valid_21627350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627350 = validateParameter(valid_21627350, JString, required = false,
                                   default = nil)
  if valid_21627350 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627350
  var valid_21627351 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627351 = validateParameter(valid_21627351, JString, required = false,
                                   default = nil)
  if valid_21627351 != nil:
    section.add "X-Amz-Algorithm", valid_21627351
  var valid_21627352 = header.getOrDefault("X-Amz-Signature")
  valid_21627352 = validateParameter(valid_21627352, JString, required = false,
                                   default = nil)
  if valid_21627352 != nil:
    section.add "X-Amz-Signature", valid_21627352
  var valid_21627353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627353 = validateParameter(valid_21627353, JString, required = false,
                                   default = nil)
  if valid_21627353 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627353
  var valid_21627354 = header.getOrDefault("X-Amz-Credential")
  valid_21627354 = validateParameter(valid_21627354, JString, required = false,
                                   default = nil)
  if valid_21627354 != nil:
    section.add "X-Amz-Credential", valid_21627354
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

proc call*(call_21627356: Call_ImportCatalogToGlue_21627344; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
  ## 
  let valid = call_21627356.validator(path, query, header, formData, body, _)
  let scheme = call_21627356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627356.makeUrl(scheme.get, call_21627356.host, call_21627356.base,
                               call_21627356.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627356, uri, valid, _)

proc call*(call_21627357: Call_ImportCatalogToGlue_21627344; body: JsonNode): Recallable =
  ## importCatalogToGlue
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
  ##   body: JObject (required)
  var body_21627358 = newJObject()
  if body != nil:
    body_21627358 = body
  result = call_21627357.call(nil, nil, nil, nil, body_21627358)

var importCatalogToGlue* = Call_ImportCatalogToGlue_21627344(
    name: "importCatalogToGlue", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ImportCatalogToGlue",
    validator: validate_ImportCatalogToGlue_21627345, base: "/",
    makeUrl: url_ImportCatalogToGlue_21627346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCrawlers_21627359 = ref object of OpenApiRestCall_21625435
proc url_ListCrawlers_21627361(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCrawlers_21627360(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627362 = query.getOrDefault("NextToken")
  valid_21627362 = validateParameter(valid_21627362, JString, required = false,
                                   default = nil)
  if valid_21627362 != nil:
    section.add "NextToken", valid_21627362
  var valid_21627363 = query.getOrDefault("MaxResults")
  valid_21627363 = validateParameter(valid_21627363, JString, required = false,
                                   default = nil)
  if valid_21627363 != nil:
    section.add "MaxResults", valid_21627363
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627364 = header.getOrDefault("X-Amz-Date")
  valid_21627364 = validateParameter(valid_21627364, JString, required = false,
                                   default = nil)
  if valid_21627364 != nil:
    section.add "X-Amz-Date", valid_21627364
  var valid_21627365 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627365 = validateParameter(valid_21627365, JString, required = false,
                                   default = nil)
  if valid_21627365 != nil:
    section.add "X-Amz-Security-Token", valid_21627365
  var valid_21627366 = header.getOrDefault("X-Amz-Target")
  valid_21627366 = validateParameter(valid_21627366, JString, required = true,
                                   default = newJString("AWSGlue.ListCrawlers"))
  if valid_21627366 != nil:
    section.add "X-Amz-Target", valid_21627366
  var valid_21627367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627367 = validateParameter(valid_21627367, JString, required = false,
                                   default = nil)
  if valid_21627367 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627367
  var valid_21627368 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627368 = validateParameter(valid_21627368, JString, required = false,
                                   default = nil)
  if valid_21627368 != nil:
    section.add "X-Amz-Algorithm", valid_21627368
  var valid_21627369 = header.getOrDefault("X-Amz-Signature")
  valid_21627369 = validateParameter(valid_21627369, JString, required = false,
                                   default = nil)
  if valid_21627369 != nil:
    section.add "X-Amz-Signature", valid_21627369
  var valid_21627370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627370 = validateParameter(valid_21627370, JString, required = false,
                                   default = nil)
  if valid_21627370 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627370
  var valid_21627371 = header.getOrDefault("X-Amz-Credential")
  valid_21627371 = validateParameter(valid_21627371, JString, required = false,
                                   default = nil)
  if valid_21627371 != nil:
    section.add "X-Amz-Credential", valid_21627371
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

proc call*(call_21627373: Call_ListCrawlers_21627359; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_21627373.validator(path, query, header, formData, body, _)
  let scheme = call_21627373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627373.makeUrl(scheme.get, call_21627373.host, call_21627373.base,
                               call_21627373.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627373, uri, valid, _)

proc call*(call_21627374: Call_ListCrawlers_21627359; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCrawlers
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627375 = newJObject()
  var body_21627376 = newJObject()
  add(query_21627375, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627376 = body
  add(query_21627375, "MaxResults", newJString(MaxResults))
  result = call_21627374.call(nil, query_21627375, nil, nil, body_21627376)

var listCrawlers* = Call_ListCrawlers_21627359(name: "listCrawlers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListCrawlers",
    validator: validate_ListCrawlers_21627360, base: "/", makeUrl: url_ListCrawlers_21627361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevEndpoints_21627377 = ref object of OpenApiRestCall_21625435
proc url_ListDevEndpoints_21627379(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevEndpoints_21627378(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627380 = query.getOrDefault("NextToken")
  valid_21627380 = validateParameter(valid_21627380, JString, required = false,
                                   default = nil)
  if valid_21627380 != nil:
    section.add "NextToken", valid_21627380
  var valid_21627381 = query.getOrDefault("MaxResults")
  valid_21627381 = validateParameter(valid_21627381, JString, required = false,
                                   default = nil)
  if valid_21627381 != nil:
    section.add "MaxResults", valid_21627381
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627382 = header.getOrDefault("X-Amz-Date")
  valid_21627382 = validateParameter(valid_21627382, JString, required = false,
                                   default = nil)
  if valid_21627382 != nil:
    section.add "X-Amz-Date", valid_21627382
  var valid_21627383 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627383 = validateParameter(valid_21627383, JString, required = false,
                                   default = nil)
  if valid_21627383 != nil:
    section.add "X-Amz-Security-Token", valid_21627383
  var valid_21627384 = header.getOrDefault("X-Amz-Target")
  valid_21627384 = validateParameter(valid_21627384, JString, required = true, default = newJString(
      "AWSGlue.ListDevEndpoints"))
  if valid_21627384 != nil:
    section.add "X-Amz-Target", valid_21627384
  var valid_21627385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627385 = validateParameter(valid_21627385, JString, required = false,
                                   default = nil)
  if valid_21627385 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627385
  var valid_21627386 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627386 = validateParameter(valid_21627386, JString, required = false,
                                   default = nil)
  if valid_21627386 != nil:
    section.add "X-Amz-Algorithm", valid_21627386
  var valid_21627387 = header.getOrDefault("X-Amz-Signature")
  valid_21627387 = validateParameter(valid_21627387, JString, required = false,
                                   default = nil)
  if valid_21627387 != nil:
    section.add "X-Amz-Signature", valid_21627387
  var valid_21627388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627388 = validateParameter(valid_21627388, JString, required = false,
                                   default = nil)
  if valid_21627388 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627388
  var valid_21627389 = header.getOrDefault("X-Amz-Credential")
  valid_21627389 = validateParameter(valid_21627389, JString, required = false,
                                   default = nil)
  if valid_21627389 != nil:
    section.add "X-Amz-Credential", valid_21627389
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

proc call*(call_21627391: Call_ListDevEndpoints_21627377; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_21627391.validator(path, query, header, formData, body, _)
  let scheme = call_21627391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627391.makeUrl(scheme.get, call_21627391.host, call_21627391.base,
                               call_21627391.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627391, uri, valid, _)

proc call*(call_21627392: Call_ListDevEndpoints_21627377; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDevEndpoints
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627393 = newJObject()
  var body_21627394 = newJObject()
  add(query_21627393, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627394 = body
  add(query_21627393, "MaxResults", newJString(MaxResults))
  result = call_21627392.call(nil, query_21627393, nil, nil, body_21627394)

var listDevEndpoints* = Call_ListDevEndpoints_21627377(name: "listDevEndpoints",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListDevEndpoints",
    validator: validate_ListDevEndpoints_21627378, base: "/",
    makeUrl: url_ListDevEndpoints_21627379, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_21627395 = ref object of OpenApiRestCall_21625435
proc url_ListJobs_21627397(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobs_21627396(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627398 = query.getOrDefault("NextToken")
  valid_21627398 = validateParameter(valid_21627398, JString, required = false,
                                   default = nil)
  if valid_21627398 != nil:
    section.add "NextToken", valid_21627398
  var valid_21627399 = query.getOrDefault("MaxResults")
  valid_21627399 = validateParameter(valid_21627399, JString, required = false,
                                   default = nil)
  if valid_21627399 != nil:
    section.add "MaxResults", valid_21627399
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627400 = header.getOrDefault("X-Amz-Date")
  valid_21627400 = validateParameter(valid_21627400, JString, required = false,
                                   default = nil)
  if valid_21627400 != nil:
    section.add "X-Amz-Date", valid_21627400
  var valid_21627401 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627401 = validateParameter(valid_21627401, JString, required = false,
                                   default = nil)
  if valid_21627401 != nil:
    section.add "X-Amz-Security-Token", valid_21627401
  var valid_21627402 = header.getOrDefault("X-Amz-Target")
  valid_21627402 = validateParameter(valid_21627402, JString, required = true,
                                   default = newJString("AWSGlue.ListJobs"))
  if valid_21627402 != nil:
    section.add "X-Amz-Target", valid_21627402
  var valid_21627403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627403 = validateParameter(valid_21627403, JString, required = false,
                                   default = nil)
  if valid_21627403 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627403
  var valid_21627404 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627404 = validateParameter(valid_21627404, JString, required = false,
                                   default = nil)
  if valid_21627404 != nil:
    section.add "X-Amz-Algorithm", valid_21627404
  var valid_21627405 = header.getOrDefault("X-Amz-Signature")
  valid_21627405 = validateParameter(valid_21627405, JString, required = false,
                                   default = nil)
  if valid_21627405 != nil:
    section.add "X-Amz-Signature", valid_21627405
  var valid_21627406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627406 = validateParameter(valid_21627406, JString, required = false,
                                   default = nil)
  if valid_21627406 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627406
  var valid_21627407 = header.getOrDefault("X-Amz-Credential")
  valid_21627407 = validateParameter(valid_21627407, JString, required = false,
                                   default = nil)
  if valid_21627407 != nil:
    section.add "X-Amz-Credential", valid_21627407
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

proc call*(call_21627409: Call_ListJobs_21627395; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_21627409.validator(path, query, header, formData, body, _)
  let scheme = call_21627409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627409.makeUrl(scheme.get, call_21627409.host, call_21627409.base,
                               call_21627409.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627409, uri, valid, _)

proc call*(call_21627410: Call_ListJobs_21627395; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listJobs
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627411 = newJObject()
  var body_21627412 = newJObject()
  add(query_21627411, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627412 = body
  add(query_21627411, "MaxResults", newJString(MaxResults))
  result = call_21627410.call(nil, query_21627411, nil, nil, body_21627412)

var listJobs* = Call_ListJobs_21627395(name: "listJobs", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.ListJobs",
                                    validator: validate_ListJobs_21627396,
                                    base: "/", makeUrl: url_ListJobs_21627397,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTriggers_21627413 = ref object of OpenApiRestCall_21625435
proc url_ListTriggers_21627415(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTriggers_21627414(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627416 = query.getOrDefault("NextToken")
  valid_21627416 = validateParameter(valid_21627416, JString, required = false,
                                   default = nil)
  if valid_21627416 != nil:
    section.add "NextToken", valid_21627416
  var valid_21627417 = query.getOrDefault("MaxResults")
  valid_21627417 = validateParameter(valid_21627417, JString, required = false,
                                   default = nil)
  if valid_21627417 != nil:
    section.add "MaxResults", valid_21627417
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627418 = header.getOrDefault("X-Amz-Date")
  valid_21627418 = validateParameter(valid_21627418, JString, required = false,
                                   default = nil)
  if valid_21627418 != nil:
    section.add "X-Amz-Date", valid_21627418
  var valid_21627419 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627419 = validateParameter(valid_21627419, JString, required = false,
                                   default = nil)
  if valid_21627419 != nil:
    section.add "X-Amz-Security-Token", valid_21627419
  var valid_21627420 = header.getOrDefault("X-Amz-Target")
  valid_21627420 = validateParameter(valid_21627420, JString, required = true,
                                   default = newJString("AWSGlue.ListTriggers"))
  if valid_21627420 != nil:
    section.add "X-Amz-Target", valid_21627420
  var valid_21627421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627421 = validateParameter(valid_21627421, JString, required = false,
                                   default = nil)
  if valid_21627421 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627421
  var valid_21627422 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627422 = validateParameter(valid_21627422, JString, required = false,
                                   default = nil)
  if valid_21627422 != nil:
    section.add "X-Amz-Algorithm", valid_21627422
  var valid_21627423 = header.getOrDefault("X-Amz-Signature")
  valid_21627423 = validateParameter(valid_21627423, JString, required = false,
                                   default = nil)
  if valid_21627423 != nil:
    section.add "X-Amz-Signature", valid_21627423
  var valid_21627424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627424 = validateParameter(valid_21627424, JString, required = false,
                                   default = nil)
  if valid_21627424 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627424
  var valid_21627425 = header.getOrDefault("X-Amz-Credential")
  valid_21627425 = validateParameter(valid_21627425, JString, required = false,
                                   default = nil)
  if valid_21627425 != nil:
    section.add "X-Amz-Credential", valid_21627425
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

proc call*(call_21627427: Call_ListTriggers_21627413; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_21627427.validator(path, query, header, formData, body, _)
  let scheme = call_21627427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627427.makeUrl(scheme.get, call_21627427.host, call_21627427.base,
                               call_21627427.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627427, uri, valid, _)

proc call*(call_21627428: Call_ListTriggers_21627413; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTriggers
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627429 = newJObject()
  var body_21627430 = newJObject()
  add(query_21627429, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627430 = body
  add(query_21627429, "MaxResults", newJString(MaxResults))
  result = call_21627428.call(nil, query_21627429, nil, nil, body_21627430)

var listTriggers* = Call_ListTriggers_21627413(name: "listTriggers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListTriggers",
    validator: validate_ListTriggers_21627414, base: "/", makeUrl: url_ListTriggers_21627415,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkflows_21627431 = ref object of OpenApiRestCall_21625435
proc url_ListWorkflows_21627433(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListWorkflows_21627432(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Lists names of workflows created in the account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627434 = query.getOrDefault("NextToken")
  valid_21627434 = validateParameter(valid_21627434, JString, required = false,
                                   default = nil)
  if valid_21627434 != nil:
    section.add "NextToken", valid_21627434
  var valid_21627435 = query.getOrDefault("MaxResults")
  valid_21627435 = validateParameter(valid_21627435, JString, required = false,
                                   default = nil)
  if valid_21627435 != nil:
    section.add "MaxResults", valid_21627435
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627436 = header.getOrDefault("X-Amz-Date")
  valid_21627436 = validateParameter(valid_21627436, JString, required = false,
                                   default = nil)
  if valid_21627436 != nil:
    section.add "X-Amz-Date", valid_21627436
  var valid_21627437 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627437 = validateParameter(valid_21627437, JString, required = false,
                                   default = nil)
  if valid_21627437 != nil:
    section.add "X-Amz-Security-Token", valid_21627437
  var valid_21627438 = header.getOrDefault("X-Amz-Target")
  valid_21627438 = validateParameter(valid_21627438, JString, required = true, default = newJString(
      "AWSGlue.ListWorkflows"))
  if valid_21627438 != nil:
    section.add "X-Amz-Target", valid_21627438
  var valid_21627439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627439 = validateParameter(valid_21627439, JString, required = false,
                                   default = nil)
  if valid_21627439 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627439
  var valid_21627440 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627440 = validateParameter(valid_21627440, JString, required = false,
                                   default = nil)
  if valid_21627440 != nil:
    section.add "X-Amz-Algorithm", valid_21627440
  var valid_21627441 = header.getOrDefault("X-Amz-Signature")
  valid_21627441 = validateParameter(valid_21627441, JString, required = false,
                                   default = nil)
  if valid_21627441 != nil:
    section.add "X-Amz-Signature", valid_21627441
  var valid_21627442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627442 = validateParameter(valid_21627442, JString, required = false,
                                   default = nil)
  if valid_21627442 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627442
  var valid_21627443 = header.getOrDefault("X-Amz-Credential")
  valid_21627443 = validateParameter(valid_21627443, JString, required = false,
                                   default = nil)
  if valid_21627443 != nil:
    section.add "X-Amz-Credential", valid_21627443
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

proc call*(call_21627445: Call_ListWorkflows_21627431; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists names of workflows created in the account.
  ## 
  let valid = call_21627445.validator(path, query, header, formData, body, _)
  let scheme = call_21627445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627445.makeUrl(scheme.get, call_21627445.host, call_21627445.base,
                               call_21627445.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627445, uri, valid, _)

proc call*(call_21627446: Call_ListWorkflows_21627431; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listWorkflows
  ## Lists names of workflows created in the account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627447 = newJObject()
  var body_21627448 = newJObject()
  add(query_21627447, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627448 = body
  add(query_21627447, "MaxResults", newJString(MaxResults))
  result = call_21627446.call(nil, query_21627447, nil, nil, body_21627448)

var listWorkflows* = Call_ListWorkflows_21627431(name: "listWorkflows",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListWorkflows",
    validator: validate_ListWorkflows_21627432, base: "/",
    makeUrl: url_ListWorkflows_21627433, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDataCatalogEncryptionSettings_21627449 = ref object of OpenApiRestCall_21625435
proc url_PutDataCatalogEncryptionSettings_21627451(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutDataCatalogEncryptionSettings_21627450(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627452 = header.getOrDefault("X-Amz-Date")
  valid_21627452 = validateParameter(valid_21627452, JString, required = false,
                                   default = nil)
  if valid_21627452 != nil:
    section.add "X-Amz-Date", valid_21627452
  var valid_21627453 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627453 = validateParameter(valid_21627453, JString, required = false,
                                   default = nil)
  if valid_21627453 != nil:
    section.add "X-Amz-Security-Token", valid_21627453
  var valid_21627454 = header.getOrDefault("X-Amz-Target")
  valid_21627454 = validateParameter(valid_21627454, JString, required = true, default = newJString(
      "AWSGlue.PutDataCatalogEncryptionSettings"))
  if valid_21627454 != nil:
    section.add "X-Amz-Target", valid_21627454
  var valid_21627455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627455 = validateParameter(valid_21627455, JString, required = false,
                                   default = nil)
  if valid_21627455 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627455
  var valid_21627456 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627456 = validateParameter(valid_21627456, JString, required = false,
                                   default = nil)
  if valid_21627456 != nil:
    section.add "X-Amz-Algorithm", valid_21627456
  var valid_21627457 = header.getOrDefault("X-Amz-Signature")
  valid_21627457 = validateParameter(valid_21627457, JString, required = false,
                                   default = nil)
  if valid_21627457 != nil:
    section.add "X-Amz-Signature", valid_21627457
  var valid_21627458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627458 = validateParameter(valid_21627458, JString, required = false,
                                   default = nil)
  if valid_21627458 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627458
  var valid_21627459 = header.getOrDefault("X-Amz-Credential")
  valid_21627459 = validateParameter(valid_21627459, JString, required = false,
                                   default = nil)
  if valid_21627459 != nil:
    section.add "X-Amz-Credential", valid_21627459
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

proc call*(call_21627461: Call_PutDataCatalogEncryptionSettings_21627449;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
  ## 
  let valid = call_21627461.validator(path, query, header, formData, body, _)
  let scheme = call_21627461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627461.makeUrl(scheme.get, call_21627461.host, call_21627461.base,
                               call_21627461.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627461, uri, valid, _)

proc call*(call_21627462: Call_PutDataCatalogEncryptionSettings_21627449;
          body: JsonNode): Recallable =
  ## putDataCatalogEncryptionSettings
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
  ##   body: JObject (required)
  var body_21627463 = newJObject()
  if body != nil:
    body_21627463 = body
  result = call_21627462.call(nil, nil, nil, nil, body_21627463)

var putDataCatalogEncryptionSettings* = Call_PutDataCatalogEncryptionSettings_21627449(
    name: "putDataCatalogEncryptionSettings", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutDataCatalogEncryptionSettings",
    validator: validate_PutDataCatalogEncryptionSettings_21627450, base: "/",
    makeUrl: url_PutDataCatalogEncryptionSettings_21627451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResourcePolicy_21627464 = ref object of OpenApiRestCall_21625435
proc url_PutResourcePolicy_21627466(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutResourcePolicy_21627465(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627467 = header.getOrDefault("X-Amz-Date")
  valid_21627467 = validateParameter(valid_21627467, JString, required = false,
                                   default = nil)
  if valid_21627467 != nil:
    section.add "X-Amz-Date", valid_21627467
  var valid_21627468 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627468 = validateParameter(valid_21627468, JString, required = false,
                                   default = nil)
  if valid_21627468 != nil:
    section.add "X-Amz-Security-Token", valid_21627468
  var valid_21627469 = header.getOrDefault("X-Amz-Target")
  valid_21627469 = validateParameter(valid_21627469, JString, required = true, default = newJString(
      "AWSGlue.PutResourcePolicy"))
  if valid_21627469 != nil:
    section.add "X-Amz-Target", valid_21627469
  var valid_21627470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627470 = validateParameter(valid_21627470, JString, required = false,
                                   default = nil)
  if valid_21627470 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627470
  var valid_21627471 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627471 = validateParameter(valid_21627471, JString, required = false,
                                   default = nil)
  if valid_21627471 != nil:
    section.add "X-Amz-Algorithm", valid_21627471
  var valid_21627472 = header.getOrDefault("X-Amz-Signature")
  valid_21627472 = validateParameter(valid_21627472, JString, required = false,
                                   default = nil)
  if valid_21627472 != nil:
    section.add "X-Amz-Signature", valid_21627472
  var valid_21627473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627473 = validateParameter(valid_21627473, JString, required = false,
                                   default = nil)
  if valid_21627473 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627473
  var valid_21627474 = header.getOrDefault("X-Amz-Credential")
  valid_21627474 = validateParameter(valid_21627474, JString, required = false,
                                   default = nil)
  if valid_21627474 != nil:
    section.add "X-Amz-Credential", valid_21627474
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

proc call*(call_21627476: Call_PutResourcePolicy_21627464; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets the Data Catalog resource policy for access control.
  ## 
  let valid = call_21627476.validator(path, query, header, formData, body, _)
  let scheme = call_21627476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627476.makeUrl(scheme.get, call_21627476.host, call_21627476.base,
                               call_21627476.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627476, uri, valid, _)

proc call*(call_21627477: Call_PutResourcePolicy_21627464; body: JsonNode): Recallable =
  ## putResourcePolicy
  ## Sets the Data Catalog resource policy for access control.
  ##   body: JObject (required)
  var body_21627478 = newJObject()
  if body != nil:
    body_21627478 = body
  result = call_21627477.call(nil, nil, nil, nil, body_21627478)

var putResourcePolicy* = Call_PutResourcePolicy_21627464(name: "putResourcePolicy",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutResourcePolicy",
    validator: validate_PutResourcePolicy_21627465, base: "/",
    makeUrl: url_PutResourcePolicy_21627466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutWorkflowRunProperties_21627479 = ref object of OpenApiRestCall_21625435
proc url_PutWorkflowRunProperties_21627481(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutWorkflowRunProperties_21627480(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627482 = header.getOrDefault("X-Amz-Date")
  valid_21627482 = validateParameter(valid_21627482, JString, required = false,
                                   default = nil)
  if valid_21627482 != nil:
    section.add "X-Amz-Date", valid_21627482
  var valid_21627483 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627483 = validateParameter(valid_21627483, JString, required = false,
                                   default = nil)
  if valid_21627483 != nil:
    section.add "X-Amz-Security-Token", valid_21627483
  var valid_21627484 = header.getOrDefault("X-Amz-Target")
  valid_21627484 = validateParameter(valid_21627484, JString, required = true, default = newJString(
      "AWSGlue.PutWorkflowRunProperties"))
  if valid_21627484 != nil:
    section.add "X-Amz-Target", valid_21627484
  var valid_21627485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627485 = validateParameter(valid_21627485, JString, required = false,
                                   default = nil)
  if valid_21627485 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627485
  var valid_21627486 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627486 = validateParameter(valid_21627486, JString, required = false,
                                   default = nil)
  if valid_21627486 != nil:
    section.add "X-Amz-Algorithm", valid_21627486
  var valid_21627487 = header.getOrDefault("X-Amz-Signature")
  valid_21627487 = validateParameter(valid_21627487, JString, required = false,
                                   default = nil)
  if valid_21627487 != nil:
    section.add "X-Amz-Signature", valid_21627487
  var valid_21627488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627488 = validateParameter(valid_21627488, JString, required = false,
                                   default = nil)
  if valid_21627488 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627488
  var valid_21627489 = header.getOrDefault("X-Amz-Credential")
  valid_21627489 = validateParameter(valid_21627489, JString, required = false,
                                   default = nil)
  if valid_21627489 != nil:
    section.add "X-Amz-Credential", valid_21627489
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

proc call*(call_21627491: Call_PutWorkflowRunProperties_21627479;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
  ## 
  let valid = call_21627491.validator(path, query, header, formData, body, _)
  let scheme = call_21627491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627491.makeUrl(scheme.get, call_21627491.host, call_21627491.base,
                               call_21627491.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627491, uri, valid, _)

proc call*(call_21627492: Call_PutWorkflowRunProperties_21627479; body: JsonNode): Recallable =
  ## putWorkflowRunProperties
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
  ##   body: JObject (required)
  var body_21627493 = newJObject()
  if body != nil:
    body_21627493 = body
  result = call_21627492.call(nil, nil, nil, nil, body_21627493)

var putWorkflowRunProperties* = Call_PutWorkflowRunProperties_21627479(
    name: "putWorkflowRunProperties", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutWorkflowRunProperties",
    validator: validate_PutWorkflowRunProperties_21627480, base: "/",
    makeUrl: url_PutWorkflowRunProperties_21627481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetJobBookmark_21627494 = ref object of OpenApiRestCall_21625435
proc url_ResetJobBookmark_21627496(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ResetJobBookmark_21627495(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627497 = header.getOrDefault("X-Amz-Date")
  valid_21627497 = validateParameter(valid_21627497, JString, required = false,
                                   default = nil)
  if valid_21627497 != nil:
    section.add "X-Amz-Date", valid_21627497
  var valid_21627498 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627498 = validateParameter(valid_21627498, JString, required = false,
                                   default = nil)
  if valid_21627498 != nil:
    section.add "X-Amz-Security-Token", valid_21627498
  var valid_21627499 = header.getOrDefault("X-Amz-Target")
  valid_21627499 = validateParameter(valid_21627499, JString, required = true, default = newJString(
      "AWSGlue.ResetJobBookmark"))
  if valid_21627499 != nil:
    section.add "X-Amz-Target", valid_21627499
  var valid_21627500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627500 = validateParameter(valid_21627500, JString, required = false,
                                   default = nil)
  if valid_21627500 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627500
  var valid_21627501 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627501 = validateParameter(valid_21627501, JString, required = false,
                                   default = nil)
  if valid_21627501 != nil:
    section.add "X-Amz-Algorithm", valid_21627501
  var valid_21627502 = header.getOrDefault("X-Amz-Signature")
  valid_21627502 = validateParameter(valid_21627502, JString, required = false,
                                   default = nil)
  if valid_21627502 != nil:
    section.add "X-Amz-Signature", valid_21627502
  var valid_21627503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627503 = validateParameter(valid_21627503, JString, required = false,
                                   default = nil)
  if valid_21627503 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627503
  var valid_21627504 = header.getOrDefault("X-Amz-Credential")
  valid_21627504 = validateParameter(valid_21627504, JString, required = false,
                                   default = nil)
  if valid_21627504 != nil:
    section.add "X-Amz-Credential", valid_21627504
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

proc call*(call_21627506: Call_ResetJobBookmark_21627494; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Resets a bookmark entry.
  ## 
  let valid = call_21627506.validator(path, query, header, formData, body, _)
  let scheme = call_21627506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627506.makeUrl(scheme.get, call_21627506.host, call_21627506.base,
                               call_21627506.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627506, uri, valid, _)

proc call*(call_21627507: Call_ResetJobBookmark_21627494; body: JsonNode): Recallable =
  ## resetJobBookmark
  ## Resets a bookmark entry.
  ##   body: JObject (required)
  var body_21627508 = newJObject()
  if body != nil:
    body_21627508 = body
  result = call_21627507.call(nil, nil, nil, nil, body_21627508)

var resetJobBookmark* = Call_ResetJobBookmark_21627494(name: "resetJobBookmark",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ResetJobBookmark",
    validator: validate_ResetJobBookmark_21627495, base: "/",
    makeUrl: url_ResetJobBookmark_21627496, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchTables_21627509 = ref object of OpenApiRestCall_21625435
proc url_SearchTables_21627511(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchTables_21627510(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627512 = query.getOrDefault("NextToken")
  valid_21627512 = validateParameter(valid_21627512, JString, required = false,
                                   default = nil)
  if valid_21627512 != nil:
    section.add "NextToken", valid_21627512
  var valid_21627513 = query.getOrDefault("MaxResults")
  valid_21627513 = validateParameter(valid_21627513, JString, required = false,
                                   default = nil)
  if valid_21627513 != nil:
    section.add "MaxResults", valid_21627513
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627514 = header.getOrDefault("X-Amz-Date")
  valid_21627514 = validateParameter(valid_21627514, JString, required = false,
                                   default = nil)
  if valid_21627514 != nil:
    section.add "X-Amz-Date", valid_21627514
  var valid_21627515 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627515 = validateParameter(valid_21627515, JString, required = false,
                                   default = nil)
  if valid_21627515 != nil:
    section.add "X-Amz-Security-Token", valid_21627515
  var valid_21627516 = header.getOrDefault("X-Amz-Target")
  valid_21627516 = validateParameter(valid_21627516, JString, required = true,
                                   default = newJString("AWSGlue.SearchTables"))
  if valid_21627516 != nil:
    section.add "X-Amz-Target", valid_21627516
  var valid_21627517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627517 = validateParameter(valid_21627517, JString, required = false,
                                   default = nil)
  if valid_21627517 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627517
  var valid_21627518 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627518 = validateParameter(valid_21627518, JString, required = false,
                                   default = nil)
  if valid_21627518 != nil:
    section.add "X-Amz-Algorithm", valid_21627518
  var valid_21627519 = header.getOrDefault("X-Amz-Signature")
  valid_21627519 = validateParameter(valid_21627519, JString, required = false,
                                   default = nil)
  if valid_21627519 != nil:
    section.add "X-Amz-Signature", valid_21627519
  var valid_21627520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627520 = validateParameter(valid_21627520, JString, required = false,
                                   default = nil)
  if valid_21627520 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627520
  var valid_21627521 = header.getOrDefault("X-Amz-Credential")
  valid_21627521 = validateParameter(valid_21627521, JString, required = false,
                                   default = nil)
  if valid_21627521 != nil:
    section.add "X-Amz-Credential", valid_21627521
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

proc call*(call_21627523: Call_SearchTables_21627509; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ## 
  let valid = call_21627523.validator(path, query, header, formData, body, _)
  let scheme = call_21627523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627523.makeUrl(scheme.get, call_21627523.host, call_21627523.base,
                               call_21627523.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627523, uri, valid, _)

proc call*(call_21627524: Call_SearchTables_21627509; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchTables
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627525 = newJObject()
  var body_21627526 = newJObject()
  add(query_21627525, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627526 = body
  add(query_21627525, "MaxResults", newJString(MaxResults))
  result = call_21627524.call(nil, query_21627525, nil, nil, body_21627526)

var searchTables* = Call_SearchTables_21627509(name: "searchTables",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.SearchTables",
    validator: validate_SearchTables_21627510, base: "/", makeUrl: url_SearchTables_21627511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCrawler_21627527 = ref object of OpenApiRestCall_21625435
proc url_StartCrawler_21627529(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartCrawler_21627528(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627530 = header.getOrDefault("X-Amz-Date")
  valid_21627530 = validateParameter(valid_21627530, JString, required = false,
                                   default = nil)
  if valid_21627530 != nil:
    section.add "X-Amz-Date", valid_21627530
  var valid_21627531 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627531 = validateParameter(valid_21627531, JString, required = false,
                                   default = nil)
  if valid_21627531 != nil:
    section.add "X-Amz-Security-Token", valid_21627531
  var valid_21627532 = header.getOrDefault("X-Amz-Target")
  valid_21627532 = validateParameter(valid_21627532, JString, required = true,
                                   default = newJString("AWSGlue.StartCrawler"))
  if valid_21627532 != nil:
    section.add "X-Amz-Target", valid_21627532
  var valid_21627533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627533 = validateParameter(valid_21627533, JString, required = false,
                                   default = nil)
  if valid_21627533 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627533
  var valid_21627534 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627534 = validateParameter(valid_21627534, JString, required = false,
                                   default = nil)
  if valid_21627534 != nil:
    section.add "X-Amz-Algorithm", valid_21627534
  var valid_21627535 = header.getOrDefault("X-Amz-Signature")
  valid_21627535 = validateParameter(valid_21627535, JString, required = false,
                                   default = nil)
  if valid_21627535 != nil:
    section.add "X-Amz-Signature", valid_21627535
  var valid_21627536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627536 = validateParameter(valid_21627536, JString, required = false,
                                   default = nil)
  if valid_21627536 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627536
  var valid_21627537 = header.getOrDefault("X-Amz-Credential")
  valid_21627537 = validateParameter(valid_21627537, JString, required = false,
                                   default = nil)
  if valid_21627537 != nil:
    section.add "X-Amz-Credential", valid_21627537
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

proc call*(call_21627539: Call_StartCrawler_21627527; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
  ## 
  let valid = call_21627539.validator(path, query, header, formData, body, _)
  let scheme = call_21627539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627539.makeUrl(scheme.get, call_21627539.host, call_21627539.base,
                               call_21627539.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627539, uri, valid, _)

proc call*(call_21627540: Call_StartCrawler_21627527; body: JsonNode): Recallable =
  ## startCrawler
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
  ##   body: JObject (required)
  var body_21627541 = newJObject()
  if body != nil:
    body_21627541 = body
  result = call_21627540.call(nil, nil, nil, nil, body_21627541)

var startCrawler* = Call_StartCrawler_21627527(name: "startCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartCrawler",
    validator: validate_StartCrawler_21627528, base: "/", makeUrl: url_StartCrawler_21627529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCrawlerSchedule_21627542 = ref object of OpenApiRestCall_21625435
proc url_StartCrawlerSchedule_21627544(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartCrawlerSchedule_21627543(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627545 = header.getOrDefault("X-Amz-Date")
  valid_21627545 = validateParameter(valid_21627545, JString, required = false,
                                   default = nil)
  if valid_21627545 != nil:
    section.add "X-Amz-Date", valid_21627545
  var valid_21627546 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627546 = validateParameter(valid_21627546, JString, required = false,
                                   default = nil)
  if valid_21627546 != nil:
    section.add "X-Amz-Security-Token", valid_21627546
  var valid_21627547 = header.getOrDefault("X-Amz-Target")
  valid_21627547 = validateParameter(valid_21627547, JString, required = true, default = newJString(
      "AWSGlue.StartCrawlerSchedule"))
  if valid_21627547 != nil:
    section.add "X-Amz-Target", valid_21627547
  var valid_21627548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627548 = validateParameter(valid_21627548, JString, required = false,
                                   default = nil)
  if valid_21627548 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627548
  var valid_21627549 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627549 = validateParameter(valid_21627549, JString, required = false,
                                   default = nil)
  if valid_21627549 != nil:
    section.add "X-Amz-Algorithm", valid_21627549
  var valid_21627550 = header.getOrDefault("X-Amz-Signature")
  valid_21627550 = validateParameter(valid_21627550, JString, required = false,
                                   default = nil)
  if valid_21627550 != nil:
    section.add "X-Amz-Signature", valid_21627550
  var valid_21627551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627551 = validateParameter(valid_21627551, JString, required = false,
                                   default = nil)
  if valid_21627551 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627551
  var valid_21627552 = header.getOrDefault("X-Amz-Credential")
  valid_21627552 = validateParameter(valid_21627552, JString, required = false,
                                   default = nil)
  if valid_21627552 != nil:
    section.add "X-Amz-Credential", valid_21627552
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

proc call*(call_21627554: Call_StartCrawlerSchedule_21627542; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
  ## 
  let valid = call_21627554.validator(path, query, header, formData, body, _)
  let scheme = call_21627554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627554.makeUrl(scheme.get, call_21627554.host, call_21627554.base,
                               call_21627554.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627554, uri, valid, _)

proc call*(call_21627555: Call_StartCrawlerSchedule_21627542; body: JsonNode): Recallable =
  ## startCrawlerSchedule
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
  ##   body: JObject (required)
  var body_21627556 = newJObject()
  if body != nil:
    body_21627556 = body
  result = call_21627555.call(nil, nil, nil, nil, body_21627556)

var startCrawlerSchedule* = Call_StartCrawlerSchedule_21627542(
    name: "startCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartCrawlerSchedule",
    validator: validate_StartCrawlerSchedule_21627543, base: "/",
    makeUrl: url_StartCrawlerSchedule_21627544,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartExportLabelsTaskRun_21627557 = ref object of OpenApiRestCall_21625435
proc url_StartExportLabelsTaskRun_21627559(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartExportLabelsTaskRun_21627558(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627560 = header.getOrDefault("X-Amz-Date")
  valid_21627560 = validateParameter(valid_21627560, JString, required = false,
                                   default = nil)
  if valid_21627560 != nil:
    section.add "X-Amz-Date", valid_21627560
  var valid_21627561 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627561 = validateParameter(valid_21627561, JString, required = false,
                                   default = nil)
  if valid_21627561 != nil:
    section.add "X-Amz-Security-Token", valid_21627561
  var valid_21627562 = header.getOrDefault("X-Amz-Target")
  valid_21627562 = validateParameter(valid_21627562, JString, required = true, default = newJString(
      "AWSGlue.StartExportLabelsTaskRun"))
  if valid_21627562 != nil:
    section.add "X-Amz-Target", valid_21627562
  var valid_21627563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627563 = validateParameter(valid_21627563, JString, required = false,
                                   default = nil)
  if valid_21627563 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627563
  var valid_21627564 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627564 = validateParameter(valid_21627564, JString, required = false,
                                   default = nil)
  if valid_21627564 != nil:
    section.add "X-Amz-Algorithm", valid_21627564
  var valid_21627565 = header.getOrDefault("X-Amz-Signature")
  valid_21627565 = validateParameter(valid_21627565, JString, required = false,
                                   default = nil)
  if valid_21627565 != nil:
    section.add "X-Amz-Signature", valid_21627565
  var valid_21627566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627566 = validateParameter(valid_21627566, JString, required = false,
                                   default = nil)
  if valid_21627566 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627566
  var valid_21627567 = header.getOrDefault("X-Amz-Credential")
  valid_21627567 = validateParameter(valid_21627567, JString, required = false,
                                   default = nil)
  if valid_21627567 != nil:
    section.add "X-Amz-Credential", valid_21627567
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

proc call*(call_21627569: Call_StartExportLabelsTaskRun_21627557;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
  ## 
  let valid = call_21627569.validator(path, query, header, formData, body, _)
  let scheme = call_21627569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627569.makeUrl(scheme.get, call_21627569.host, call_21627569.base,
                               call_21627569.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627569, uri, valid, _)

proc call*(call_21627570: Call_StartExportLabelsTaskRun_21627557; body: JsonNode): Recallable =
  ## startExportLabelsTaskRun
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
  ##   body: JObject (required)
  var body_21627571 = newJObject()
  if body != nil:
    body_21627571 = body
  result = call_21627570.call(nil, nil, nil, nil, body_21627571)

var startExportLabelsTaskRun* = Call_StartExportLabelsTaskRun_21627557(
    name: "startExportLabelsTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartExportLabelsTaskRun",
    validator: validate_StartExportLabelsTaskRun_21627558, base: "/",
    makeUrl: url_StartExportLabelsTaskRun_21627559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImportLabelsTaskRun_21627572 = ref object of OpenApiRestCall_21625435
proc url_StartImportLabelsTaskRun_21627574(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartImportLabelsTaskRun_21627573(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627575 = header.getOrDefault("X-Amz-Date")
  valid_21627575 = validateParameter(valid_21627575, JString, required = false,
                                   default = nil)
  if valid_21627575 != nil:
    section.add "X-Amz-Date", valid_21627575
  var valid_21627576 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627576 = validateParameter(valid_21627576, JString, required = false,
                                   default = nil)
  if valid_21627576 != nil:
    section.add "X-Amz-Security-Token", valid_21627576
  var valid_21627577 = header.getOrDefault("X-Amz-Target")
  valid_21627577 = validateParameter(valid_21627577, JString, required = true, default = newJString(
      "AWSGlue.StartImportLabelsTaskRun"))
  if valid_21627577 != nil:
    section.add "X-Amz-Target", valid_21627577
  var valid_21627578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627578 = validateParameter(valid_21627578, JString, required = false,
                                   default = nil)
  if valid_21627578 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627578
  var valid_21627579 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627579 = validateParameter(valid_21627579, JString, required = false,
                                   default = nil)
  if valid_21627579 != nil:
    section.add "X-Amz-Algorithm", valid_21627579
  var valid_21627580 = header.getOrDefault("X-Amz-Signature")
  valid_21627580 = validateParameter(valid_21627580, JString, required = false,
                                   default = nil)
  if valid_21627580 != nil:
    section.add "X-Amz-Signature", valid_21627580
  var valid_21627581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627581 = validateParameter(valid_21627581, JString, required = false,
                                   default = nil)
  if valid_21627581 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627581
  var valid_21627582 = header.getOrDefault("X-Amz-Credential")
  valid_21627582 = validateParameter(valid_21627582, JString, required = false,
                                   default = nil)
  if valid_21627582 != nil:
    section.add "X-Amz-Credential", valid_21627582
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

proc call*(call_21627584: Call_StartImportLabelsTaskRun_21627572;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
  ## 
  let valid = call_21627584.validator(path, query, header, formData, body, _)
  let scheme = call_21627584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627584.makeUrl(scheme.get, call_21627584.host, call_21627584.base,
                               call_21627584.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627584, uri, valid, _)

proc call*(call_21627585: Call_StartImportLabelsTaskRun_21627572; body: JsonNode): Recallable =
  ## startImportLabelsTaskRun
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
  ##   body: JObject (required)
  var body_21627586 = newJObject()
  if body != nil:
    body_21627586 = body
  result = call_21627585.call(nil, nil, nil, nil, body_21627586)

var startImportLabelsTaskRun* = Call_StartImportLabelsTaskRun_21627572(
    name: "startImportLabelsTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartImportLabelsTaskRun",
    validator: validate_StartImportLabelsTaskRun_21627573, base: "/",
    makeUrl: url_StartImportLabelsTaskRun_21627574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJobRun_21627587 = ref object of OpenApiRestCall_21625435
proc url_StartJobRun_21627589(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartJobRun_21627588(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627590 = header.getOrDefault("X-Amz-Date")
  valid_21627590 = validateParameter(valid_21627590, JString, required = false,
                                   default = nil)
  if valid_21627590 != nil:
    section.add "X-Amz-Date", valid_21627590
  var valid_21627591 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627591 = validateParameter(valid_21627591, JString, required = false,
                                   default = nil)
  if valid_21627591 != nil:
    section.add "X-Amz-Security-Token", valid_21627591
  var valid_21627592 = header.getOrDefault("X-Amz-Target")
  valid_21627592 = validateParameter(valid_21627592, JString, required = true,
                                   default = newJString("AWSGlue.StartJobRun"))
  if valid_21627592 != nil:
    section.add "X-Amz-Target", valid_21627592
  var valid_21627593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627593 = validateParameter(valid_21627593, JString, required = false,
                                   default = nil)
  if valid_21627593 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627593
  var valid_21627594 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627594 = validateParameter(valid_21627594, JString, required = false,
                                   default = nil)
  if valid_21627594 != nil:
    section.add "X-Amz-Algorithm", valid_21627594
  var valid_21627595 = header.getOrDefault("X-Amz-Signature")
  valid_21627595 = validateParameter(valid_21627595, JString, required = false,
                                   default = nil)
  if valid_21627595 != nil:
    section.add "X-Amz-Signature", valid_21627595
  var valid_21627596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627596 = validateParameter(valid_21627596, JString, required = false,
                                   default = nil)
  if valid_21627596 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627596
  var valid_21627597 = header.getOrDefault("X-Amz-Credential")
  valid_21627597 = validateParameter(valid_21627597, JString, required = false,
                                   default = nil)
  if valid_21627597 != nil:
    section.add "X-Amz-Credential", valid_21627597
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

proc call*(call_21627599: Call_StartJobRun_21627587; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts a job run using a job definition.
  ## 
  let valid = call_21627599.validator(path, query, header, formData, body, _)
  let scheme = call_21627599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627599.makeUrl(scheme.get, call_21627599.host, call_21627599.base,
                               call_21627599.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627599, uri, valid, _)

proc call*(call_21627600: Call_StartJobRun_21627587; body: JsonNode): Recallable =
  ## startJobRun
  ## Starts a job run using a job definition.
  ##   body: JObject (required)
  var body_21627601 = newJObject()
  if body != nil:
    body_21627601 = body
  result = call_21627600.call(nil, nil, nil, nil, body_21627601)

var startJobRun* = Call_StartJobRun_21627587(name: "startJobRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartJobRun", validator: validate_StartJobRun_21627588,
    base: "/", makeUrl: url_StartJobRun_21627589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMLEvaluationTaskRun_21627602 = ref object of OpenApiRestCall_21625435
proc url_StartMLEvaluationTaskRun_21627604(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartMLEvaluationTaskRun_21627603(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627605 = header.getOrDefault("X-Amz-Date")
  valid_21627605 = validateParameter(valid_21627605, JString, required = false,
                                   default = nil)
  if valid_21627605 != nil:
    section.add "X-Amz-Date", valid_21627605
  var valid_21627606 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627606 = validateParameter(valid_21627606, JString, required = false,
                                   default = nil)
  if valid_21627606 != nil:
    section.add "X-Amz-Security-Token", valid_21627606
  var valid_21627607 = header.getOrDefault("X-Amz-Target")
  valid_21627607 = validateParameter(valid_21627607, JString, required = true, default = newJString(
      "AWSGlue.StartMLEvaluationTaskRun"))
  if valid_21627607 != nil:
    section.add "X-Amz-Target", valid_21627607
  var valid_21627608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627608 = validateParameter(valid_21627608, JString, required = false,
                                   default = nil)
  if valid_21627608 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627608
  var valid_21627609 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627609 = validateParameter(valid_21627609, JString, required = false,
                                   default = nil)
  if valid_21627609 != nil:
    section.add "X-Amz-Algorithm", valid_21627609
  var valid_21627610 = header.getOrDefault("X-Amz-Signature")
  valid_21627610 = validateParameter(valid_21627610, JString, required = false,
                                   default = nil)
  if valid_21627610 != nil:
    section.add "X-Amz-Signature", valid_21627610
  var valid_21627611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627611 = validateParameter(valid_21627611, JString, required = false,
                                   default = nil)
  if valid_21627611 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627611
  var valid_21627612 = header.getOrDefault("X-Amz-Credential")
  valid_21627612 = validateParameter(valid_21627612, JString, required = false,
                                   default = nil)
  if valid_21627612 != nil:
    section.add "X-Amz-Credential", valid_21627612
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

proc call*(call_21627614: Call_StartMLEvaluationTaskRun_21627602;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
  ## 
  let valid = call_21627614.validator(path, query, header, formData, body, _)
  let scheme = call_21627614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627614.makeUrl(scheme.get, call_21627614.host, call_21627614.base,
                               call_21627614.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627614, uri, valid, _)

proc call*(call_21627615: Call_StartMLEvaluationTaskRun_21627602; body: JsonNode): Recallable =
  ## startMLEvaluationTaskRun
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
  ##   body: JObject (required)
  var body_21627616 = newJObject()
  if body != nil:
    body_21627616 = body
  result = call_21627615.call(nil, nil, nil, nil, body_21627616)

var startMLEvaluationTaskRun* = Call_StartMLEvaluationTaskRun_21627602(
    name: "startMLEvaluationTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartMLEvaluationTaskRun",
    validator: validate_StartMLEvaluationTaskRun_21627603, base: "/",
    makeUrl: url_StartMLEvaluationTaskRun_21627604,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMLLabelingSetGenerationTaskRun_21627617 = ref object of OpenApiRestCall_21625435
proc url_StartMLLabelingSetGenerationTaskRun_21627619(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartMLLabelingSetGenerationTaskRun_21627618(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627620 = header.getOrDefault("X-Amz-Date")
  valid_21627620 = validateParameter(valid_21627620, JString, required = false,
                                   default = nil)
  if valid_21627620 != nil:
    section.add "X-Amz-Date", valid_21627620
  var valid_21627621 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627621 = validateParameter(valid_21627621, JString, required = false,
                                   default = nil)
  if valid_21627621 != nil:
    section.add "X-Amz-Security-Token", valid_21627621
  var valid_21627622 = header.getOrDefault("X-Amz-Target")
  valid_21627622 = validateParameter(valid_21627622, JString, required = true, default = newJString(
      "AWSGlue.StartMLLabelingSetGenerationTaskRun"))
  if valid_21627622 != nil:
    section.add "X-Amz-Target", valid_21627622
  var valid_21627623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627623 = validateParameter(valid_21627623, JString, required = false,
                                   default = nil)
  if valid_21627623 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627623
  var valid_21627624 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627624 = validateParameter(valid_21627624, JString, required = false,
                                   default = nil)
  if valid_21627624 != nil:
    section.add "X-Amz-Algorithm", valid_21627624
  var valid_21627625 = header.getOrDefault("X-Amz-Signature")
  valid_21627625 = validateParameter(valid_21627625, JString, required = false,
                                   default = nil)
  if valid_21627625 != nil:
    section.add "X-Amz-Signature", valid_21627625
  var valid_21627626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627626 = validateParameter(valid_21627626, JString, required = false,
                                   default = nil)
  if valid_21627626 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627626
  var valid_21627627 = header.getOrDefault("X-Amz-Credential")
  valid_21627627 = validateParameter(valid_21627627, JString, required = false,
                                   default = nil)
  if valid_21627627 != nil:
    section.add "X-Amz-Credential", valid_21627627
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

proc call*(call_21627629: Call_StartMLLabelingSetGenerationTaskRun_21627617;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
  ## 
  let valid = call_21627629.validator(path, query, header, formData, body, _)
  let scheme = call_21627629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627629.makeUrl(scheme.get, call_21627629.host, call_21627629.base,
                               call_21627629.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627629, uri, valid, _)

proc call*(call_21627630: Call_StartMLLabelingSetGenerationTaskRun_21627617;
          body: JsonNode): Recallable =
  ## startMLLabelingSetGenerationTaskRun
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
  ##   body: JObject (required)
  var body_21627631 = newJObject()
  if body != nil:
    body_21627631 = body
  result = call_21627630.call(nil, nil, nil, nil, body_21627631)

var startMLLabelingSetGenerationTaskRun* = Call_StartMLLabelingSetGenerationTaskRun_21627617(
    name: "startMLLabelingSetGenerationTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartMLLabelingSetGenerationTaskRun",
    validator: validate_StartMLLabelingSetGenerationTaskRun_21627618, base: "/",
    makeUrl: url_StartMLLabelingSetGenerationTaskRun_21627619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTrigger_21627632 = ref object of OpenApiRestCall_21625435
proc url_StartTrigger_21627634(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartTrigger_21627633(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627635 = header.getOrDefault("X-Amz-Date")
  valid_21627635 = validateParameter(valid_21627635, JString, required = false,
                                   default = nil)
  if valid_21627635 != nil:
    section.add "X-Amz-Date", valid_21627635
  var valid_21627636 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627636 = validateParameter(valid_21627636, JString, required = false,
                                   default = nil)
  if valid_21627636 != nil:
    section.add "X-Amz-Security-Token", valid_21627636
  var valid_21627637 = header.getOrDefault("X-Amz-Target")
  valid_21627637 = validateParameter(valid_21627637, JString, required = true,
                                   default = newJString("AWSGlue.StartTrigger"))
  if valid_21627637 != nil:
    section.add "X-Amz-Target", valid_21627637
  var valid_21627638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627638 = validateParameter(valid_21627638, JString, required = false,
                                   default = nil)
  if valid_21627638 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627638
  var valid_21627639 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627639 = validateParameter(valid_21627639, JString, required = false,
                                   default = nil)
  if valid_21627639 != nil:
    section.add "X-Amz-Algorithm", valid_21627639
  var valid_21627640 = header.getOrDefault("X-Amz-Signature")
  valid_21627640 = validateParameter(valid_21627640, JString, required = false,
                                   default = nil)
  if valid_21627640 != nil:
    section.add "X-Amz-Signature", valid_21627640
  var valid_21627641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627641 = validateParameter(valid_21627641, JString, required = false,
                                   default = nil)
  if valid_21627641 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627641
  var valid_21627642 = header.getOrDefault("X-Amz-Credential")
  valid_21627642 = validateParameter(valid_21627642, JString, required = false,
                                   default = nil)
  if valid_21627642 != nil:
    section.add "X-Amz-Credential", valid_21627642
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

proc call*(call_21627644: Call_StartTrigger_21627632; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
  ## 
  let valid = call_21627644.validator(path, query, header, formData, body, _)
  let scheme = call_21627644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627644.makeUrl(scheme.get, call_21627644.host, call_21627644.base,
                               call_21627644.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627644, uri, valid, _)

proc call*(call_21627645: Call_StartTrigger_21627632; body: JsonNode): Recallable =
  ## startTrigger
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
  ##   body: JObject (required)
  var body_21627646 = newJObject()
  if body != nil:
    body_21627646 = body
  result = call_21627645.call(nil, nil, nil, nil, body_21627646)

var startTrigger* = Call_StartTrigger_21627632(name: "startTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartTrigger",
    validator: validate_StartTrigger_21627633, base: "/", makeUrl: url_StartTrigger_21627634,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartWorkflowRun_21627647 = ref object of OpenApiRestCall_21625435
proc url_StartWorkflowRun_21627649(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartWorkflowRun_21627648(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627650 = header.getOrDefault("X-Amz-Date")
  valid_21627650 = validateParameter(valid_21627650, JString, required = false,
                                   default = nil)
  if valid_21627650 != nil:
    section.add "X-Amz-Date", valid_21627650
  var valid_21627651 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627651 = validateParameter(valid_21627651, JString, required = false,
                                   default = nil)
  if valid_21627651 != nil:
    section.add "X-Amz-Security-Token", valid_21627651
  var valid_21627652 = header.getOrDefault("X-Amz-Target")
  valid_21627652 = validateParameter(valid_21627652, JString, required = true, default = newJString(
      "AWSGlue.StartWorkflowRun"))
  if valid_21627652 != nil:
    section.add "X-Amz-Target", valid_21627652
  var valid_21627653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627653 = validateParameter(valid_21627653, JString, required = false,
                                   default = nil)
  if valid_21627653 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627653
  var valid_21627654 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627654 = validateParameter(valid_21627654, JString, required = false,
                                   default = nil)
  if valid_21627654 != nil:
    section.add "X-Amz-Algorithm", valid_21627654
  var valid_21627655 = header.getOrDefault("X-Amz-Signature")
  valid_21627655 = validateParameter(valid_21627655, JString, required = false,
                                   default = nil)
  if valid_21627655 != nil:
    section.add "X-Amz-Signature", valid_21627655
  var valid_21627656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627656 = validateParameter(valid_21627656, JString, required = false,
                                   default = nil)
  if valid_21627656 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627656
  var valid_21627657 = header.getOrDefault("X-Amz-Credential")
  valid_21627657 = validateParameter(valid_21627657, JString, required = false,
                                   default = nil)
  if valid_21627657 != nil:
    section.add "X-Amz-Credential", valid_21627657
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

proc call*(call_21627659: Call_StartWorkflowRun_21627647; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts a new run of the specified workflow.
  ## 
  let valid = call_21627659.validator(path, query, header, formData, body, _)
  let scheme = call_21627659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627659.makeUrl(scheme.get, call_21627659.host, call_21627659.base,
                               call_21627659.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627659, uri, valid, _)

proc call*(call_21627660: Call_StartWorkflowRun_21627647; body: JsonNode): Recallable =
  ## startWorkflowRun
  ## Starts a new run of the specified workflow.
  ##   body: JObject (required)
  var body_21627661 = newJObject()
  if body != nil:
    body_21627661 = body
  result = call_21627660.call(nil, nil, nil, nil, body_21627661)

var startWorkflowRun* = Call_StartWorkflowRun_21627647(name: "startWorkflowRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartWorkflowRun",
    validator: validate_StartWorkflowRun_21627648, base: "/",
    makeUrl: url_StartWorkflowRun_21627649, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCrawler_21627662 = ref object of OpenApiRestCall_21625435
proc url_StopCrawler_21627664(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopCrawler_21627663(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627665 = header.getOrDefault("X-Amz-Date")
  valid_21627665 = validateParameter(valid_21627665, JString, required = false,
                                   default = nil)
  if valid_21627665 != nil:
    section.add "X-Amz-Date", valid_21627665
  var valid_21627666 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627666 = validateParameter(valid_21627666, JString, required = false,
                                   default = nil)
  if valid_21627666 != nil:
    section.add "X-Amz-Security-Token", valid_21627666
  var valid_21627667 = header.getOrDefault("X-Amz-Target")
  valid_21627667 = validateParameter(valid_21627667, JString, required = true,
                                   default = newJString("AWSGlue.StopCrawler"))
  if valid_21627667 != nil:
    section.add "X-Amz-Target", valid_21627667
  var valid_21627668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627668 = validateParameter(valid_21627668, JString, required = false,
                                   default = nil)
  if valid_21627668 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627668
  var valid_21627669 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627669 = validateParameter(valid_21627669, JString, required = false,
                                   default = nil)
  if valid_21627669 != nil:
    section.add "X-Amz-Algorithm", valid_21627669
  var valid_21627670 = header.getOrDefault("X-Amz-Signature")
  valid_21627670 = validateParameter(valid_21627670, JString, required = false,
                                   default = nil)
  if valid_21627670 != nil:
    section.add "X-Amz-Signature", valid_21627670
  var valid_21627671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627671 = validateParameter(valid_21627671, JString, required = false,
                                   default = nil)
  if valid_21627671 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627671
  var valid_21627672 = header.getOrDefault("X-Amz-Credential")
  valid_21627672 = validateParameter(valid_21627672, JString, required = false,
                                   default = nil)
  if valid_21627672 != nil:
    section.add "X-Amz-Credential", valid_21627672
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

proc call*(call_21627674: Call_StopCrawler_21627662; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## If the specified crawler is running, stops the crawl.
  ## 
  let valid = call_21627674.validator(path, query, header, formData, body, _)
  let scheme = call_21627674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627674.makeUrl(scheme.get, call_21627674.host, call_21627674.base,
                               call_21627674.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627674, uri, valid, _)

proc call*(call_21627675: Call_StopCrawler_21627662; body: JsonNode): Recallable =
  ## stopCrawler
  ## If the specified crawler is running, stops the crawl.
  ##   body: JObject (required)
  var body_21627676 = newJObject()
  if body != nil:
    body_21627676 = body
  result = call_21627675.call(nil, nil, nil, nil, body_21627676)

var stopCrawler* = Call_StopCrawler_21627662(name: "stopCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StopCrawler", validator: validate_StopCrawler_21627663,
    base: "/", makeUrl: url_StopCrawler_21627664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCrawlerSchedule_21627677 = ref object of OpenApiRestCall_21625435
proc url_StopCrawlerSchedule_21627679(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopCrawlerSchedule_21627678(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627680 = header.getOrDefault("X-Amz-Date")
  valid_21627680 = validateParameter(valid_21627680, JString, required = false,
                                   default = nil)
  if valid_21627680 != nil:
    section.add "X-Amz-Date", valid_21627680
  var valid_21627681 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627681 = validateParameter(valid_21627681, JString, required = false,
                                   default = nil)
  if valid_21627681 != nil:
    section.add "X-Amz-Security-Token", valid_21627681
  var valid_21627682 = header.getOrDefault("X-Amz-Target")
  valid_21627682 = validateParameter(valid_21627682, JString, required = true, default = newJString(
      "AWSGlue.StopCrawlerSchedule"))
  if valid_21627682 != nil:
    section.add "X-Amz-Target", valid_21627682
  var valid_21627683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627683 = validateParameter(valid_21627683, JString, required = false,
                                   default = nil)
  if valid_21627683 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627683
  var valid_21627684 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627684 = validateParameter(valid_21627684, JString, required = false,
                                   default = nil)
  if valid_21627684 != nil:
    section.add "X-Amz-Algorithm", valid_21627684
  var valid_21627685 = header.getOrDefault("X-Amz-Signature")
  valid_21627685 = validateParameter(valid_21627685, JString, required = false,
                                   default = nil)
  if valid_21627685 != nil:
    section.add "X-Amz-Signature", valid_21627685
  var valid_21627686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627686 = validateParameter(valid_21627686, JString, required = false,
                                   default = nil)
  if valid_21627686 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627686
  var valid_21627687 = header.getOrDefault("X-Amz-Credential")
  valid_21627687 = validateParameter(valid_21627687, JString, required = false,
                                   default = nil)
  if valid_21627687 != nil:
    section.add "X-Amz-Credential", valid_21627687
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

proc call*(call_21627689: Call_StopCrawlerSchedule_21627677; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
  ## 
  let valid = call_21627689.validator(path, query, header, formData, body, _)
  let scheme = call_21627689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627689.makeUrl(scheme.get, call_21627689.host, call_21627689.base,
                               call_21627689.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627689, uri, valid, _)

proc call*(call_21627690: Call_StopCrawlerSchedule_21627677; body: JsonNode): Recallable =
  ## stopCrawlerSchedule
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
  ##   body: JObject (required)
  var body_21627691 = newJObject()
  if body != nil:
    body_21627691 = body
  result = call_21627690.call(nil, nil, nil, nil, body_21627691)

var stopCrawlerSchedule* = Call_StopCrawlerSchedule_21627677(
    name: "stopCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StopCrawlerSchedule",
    validator: validate_StopCrawlerSchedule_21627678, base: "/",
    makeUrl: url_StopCrawlerSchedule_21627679,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrigger_21627692 = ref object of OpenApiRestCall_21625435
proc url_StopTrigger_21627694(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopTrigger_21627693(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627695 = header.getOrDefault("X-Amz-Date")
  valid_21627695 = validateParameter(valid_21627695, JString, required = false,
                                   default = nil)
  if valid_21627695 != nil:
    section.add "X-Amz-Date", valid_21627695
  var valid_21627696 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627696 = validateParameter(valid_21627696, JString, required = false,
                                   default = nil)
  if valid_21627696 != nil:
    section.add "X-Amz-Security-Token", valid_21627696
  var valid_21627697 = header.getOrDefault("X-Amz-Target")
  valid_21627697 = validateParameter(valid_21627697, JString, required = true,
                                   default = newJString("AWSGlue.StopTrigger"))
  if valid_21627697 != nil:
    section.add "X-Amz-Target", valid_21627697
  var valid_21627698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627698 = validateParameter(valid_21627698, JString, required = false,
                                   default = nil)
  if valid_21627698 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627698
  var valid_21627699 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627699 = validateParameter(valid_21627699, JString, required = false,
                                   default = nil)
  if valid_21627699 != nil:
    section.add "X-Amz-Algorithm", valid_21627699
  var valid_21627700 = header.getOrDefault("X-Amz-Signature")
  valid_21627700 = validateParameter(valid_21627700, JString, required = false,
                                   default = nil)
  if valid_21627700 != nil:
    section.add "X-Amz-Signature", valid_21627700
  var valid_21627701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627701 = validateParameter(valid_21627701, JString, required = false,
                                   default = nil)
  if valid_21627701 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627701
  var valid_21627702 = header.getOrDefault("X-Amz-Credential")
  valid_21627702 = validateParameter(valid_21627702, JString, required = false,
                                   default = nil)
  if valid_21627702 != nil:
    section.add "X-Amz-Credential", valid_21627702
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

proc call*(call_21627704: Call_StopTrigger_21627692; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops a specified trigger.
  ## 
  let valid = call_21627704.validator(path, query, header, formData, body, _)
  let scheme = call_21627704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627704.makeUrl(scheme.get, call_21627704.host, call_21627704.base,
                               call_21627704.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627704, uri, valid, _)

proc call*(call_21627705: Call_StopTrigger_21627692; body: JsonNode): Recallable =
  ## stopTrigger
  ## Stops a specified trigger.
  ##   body: JObject (required)
  var body_21627706 = newJObject()
  if body != nil:
    body_21627706 = body
  result = call_21627705.call(nil, nil, nil, nil, body_21627706)

var stopTrigger* = Call_StopTrigger_21627692(name: "stopTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StopTrigger", validator: validate_StopTrigger_21627693,
    base: "/", makeUrl: url_StopTrigger_21627694,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21627707 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21627709(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_21627708(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627710 = header.getOrDefault("X-Amz-Date")
  valid_21627710 = validateParameter(valid_21627710, JString, required = false,
                                   default = nil)
  if valid_21627710 != nil:
    section.add "X-Amz-Date", valid_21627710
  var valid_21627711 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627711 = validateParameter(valid_21627711, JString, required = false,
                                   default = nil)
  if valid_21627711 != nil:
    section.add "X-Amz-Security-Token", valid_21627711
  var valid_21627712 = header.getOrDefault("X-Amz-Target")
  valid_21627712 = validateParameter(valid_21627712, JString, required = true,
                                   default = newJString("AWSGlue.TagResource"))
  if valid_21627712 != nil:
    section.add "X-Amz-Target", valid_21627712
  var valid_21627713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627713 = validateParameter(valid_21627713, JString, required = false,
                                   default = nil)
  if valid_21627713 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627713
  var valid_21627714 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627714 = validateParameter(valid_21627714, JString, required = false,
                                   default = nil)
  if valid_21627714 != nil:
    section.add "X-Amz-Algorithm", valid_21627714
  var valid_21627715 = header.getOrDefault("X-Amz-Signature")
  valid_21627715 = validateParameter(valid_21627715, JString, required = false,
                                   default = nil)
  if valid_21627715 != nil:
    section.add "X-Amz-Signature", valid_21627715
  var valid_21627716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627716 = validateParameter(valid_21627716, JString, required = false,
                                   default = nil)
  if valid_21627716 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627716
  var valid_21627717 = header.getOrDefault("X-Amz-Credential")
  valid_21627717 = validateParameter(valid_21627717, JString, required = false,
                                   default = nil)
  if valid_21627717 != nil:
    section.add "X-Amz-Credential", valid_21627717
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

proc call*(call_21627719: Call_TagResource_21627707; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
  ## 
  let valid = call_21627719.validator(path, query, header, formData, body, _)
  let scheme = call_21627719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627719.makeUrl(scheme.get, call_21627719.host, call_21627719.base,
                               call_21627719.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627719, uri, valid, _)

proc call*(call_21627720: Call_TagResource_21627707; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
  ##   body: JObject (required)
  var body_21627721 = newJObject()
  if body != nil:
    body_21627721 = body
  result = call_21627720.call(nil, nil, nil, nil, body_21627721)

var tagResource* = Call_TagResource_21627707(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.TagResource", validator: validate_TagResource_21627708,
    base: "/", makeUrl: url_TagResource_21627709,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21627722 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21627724(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_21627723(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Removes tags from a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627725 = header.getOrDefault("X-Amz-Date")
  valid_21627725 = validateParameter(valid_21627725, JString, required = false,
                                   default = nil)
  if valid_21627725 != nil:
    section.add "X-Amz-Date", valid_21627725
  var valid_21627726 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627726 = validateParameter(valid_21627726, JString, required = false,
                                   default = nil)
  if valid_21627726 != nil:
    section.add "X-Amz-Security-Token", valid_21627726
  var valid_21627727 = header.getOrDefault("X-Amz-Target")
  valid_21627727 = validateParameter(valid_21627727, JString, required = true, default = newJString(
      "AWSGlue.UntagResource"))
  if valid_21627727 != nil:
    section.add "X-Amz-Target", valid_21627727
  var valid_21627728 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627728 = validateParameter(valid_21627728, JString, required = false,
                                   default = nil)
  if valid_21627728 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627728
  var valid_21627729 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627729 = validateParameter(valid_21627729, JString, required = false,
                                   default = nil)
  if valid_21627729 != nil:
    section.add "X-Amz-Algorithm", valid_21627729
  var valid_21627730 = header.getOrDefault("X-Amz-Signature")
  valid_21627730 = validateParameter(valid_21627730, JString, required = false,
                                   default = nil)
  if valid_21627730 != nil:
    section.add "X-Amz-Signature", valid_21627730
  var valid_21627731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627731 = validateParameter(valid_21627731, JString, required = false,
                                   default = nil)
  if valid_21627731 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627731
  var valid_21627732 = header.getOrDefault("X-Amz-Credential")
  valid_21627732 = validateParameter(valid_21627732, JString, required = false,
                                   default = nil)
  if valid_21627732 != nil:
    section.add "X-Amz-Credential", valid_21627732
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

proc call*(call_21627734: Call_UntagResource_21627722; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes tags from a resource.
  ## 
  let valid = call_21627734.validator(path, query, header, formData, body, _)
  let scheme = call_21627734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627734.makeUrl(scheme.get, call_21627734.host, call_21627734.base,
                               call_21627734.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627734, uri, valid, _)

proc call*(call_21627735: Call_UntagResource_21627722; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   body: JObject (required)
  var body_21627736 = newJObject()
  if body != nil:
    body_21627736 = body
  result = call_21627735.call(nil, nil, nil, nil, body_21627736)

var untagResource* = Call_UntagResource_21627722(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UntagResource",
    validator: validate_UntagResource_21627723, base: "/",
    makeUrl: url_UntagResource_21627724, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClassifier_21627737 = ref object of OpenApiRestCall_21625435
proc url_UpdateClassifier_21627739(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateClassifier_21627738(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627740 = header.getOrDefault("X-Amz-Date")
  valid_21627740 = validateParameter(valid_21627740, JString, required = false,
                                   default = nil)
  if valid_21627740 != nil:
    section.add "X-Amz-Date", valid_21627740
  var valid_21627741 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627741 = validateParameter(valid_21627741, JString, required = false,
                                   default = nil)
  if valid_21627741 != nil:
    section.add "X-Amz-Security-Token", valid_21627741
  var valid_21627742 = header.getOrDefault("X-Amz-Target")
  valid_21627742 = validateParameter(valid_21627742, JString, required = true, default = newJString(
      "AWSGlue.UpdateClassifier"))
  if valid_21627742 != nil:
    section.add "X-Amz-Target", valid_21627742
  var valid_21627743 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627743 = validateParameter(valid_21627743, JString, required = false,
                                   default = nil)
  if valid_21627743 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627743
  var valid_21627744 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627744 = validateParameter(valid_21627744, JString, required = false,
                                   default = nil)
  if valid_21627744 != nil:
    section.add "X-Amz-Algorithm", valid_21627744
  var valid_21627745 = header.getOrDefault("X-Amz-Signature")
  valid_21627745 = validateParameter(valid_21627745, JString, required = false,
                                   default = nil)
  if valid_21627745 != nil:
    section.add "X-Amz-Signature", valid_21627745
  var valid_21627746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627746 = validateParameter(valid_21627746, JString, required = false,
                                   default = nil)
  if valid_21627746 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627746
  var valid_21627747 = header.getOrDefault("X-Amz-Credential")
  valid_21627747 = validateParameter(valid_21627747, JString, required = false,
                                   default = nil)
  if valid_21627747 != nil:
    section.add "X-Amz-Credential", valid_21627747
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

proc call*(call_21627749: Call_UpdateClassifier_21627737; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
  ## 
  let valid = call_21627749.validator(path, query, header, formData, body, _)
  let scheme = call_21627749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627749.makeUrl(scheme.get, call_21627749.host, call_21627749.base,
                               call_21627749.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627749, uri, valid, _)

proc call*(call_21627750: Call_UpdateClassifier_21627737; body: JsonNode): Recallable =
  ## updateClassifier
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
  ##   body: JObject (required)
  var body_21627751 = newJObject()
  if body != nil:
    body_21627751 = body
  result = call_21627750.call(nil, nil, nil, nil, body_21627751)

var updateClassifier* = Call_UpdateClassifier_21627737(name: "updateClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateClassifier",
    validator: validate_UpdateClassifier_21627738, base: "/",
    makeUrl: url_UpdateClassifier_21627739, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnection_21627752 = ref object of OpenApiRestCall_21625435
proc url_UpdateConnection_21627754(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateConnection_21627753(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627755 = header.getOrDefault("X-Amz-Date")
  valid_21627755 = validateParameter(valid_21627755, JString, required = false,
                                   default = nil)
  if valid_21627755 != nil:
    section.add "X-Amz-Date", valid_21627755
  var valid_21627756 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627756 = validateParameter(valid_21627756, JString, required = false,
                                   default = nil)
  if valid_21627756 != nil:
    section.add "X-Amz-Security-Token", valid_21627756
  var valid_21627757 = header.getOrDefault("X-Amz-Target")
  valid_21627757 = validateParameter(valid_21627757, JString, required = true, default = newJString(
      "AWSGlue.UpdateConnection"))
  if valid_21627757 != nil:
    section.add "X-Amz-Target", valid_21627757
  var valid_21627758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627758 = validateParameter(valid_21627758, JString, required = false,
                                   default = nil)
  if valid_21627758 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627758
  var valid_21627759 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627759 = validateParameter(valid_21627759, JString, required = false,
                                   default = nil)
  if valid_21627759 != nil:
    section.add "X-Amz-Algorithm", valid_21627759
  var valid_21627760 = header.getOrDefault("X-Amz-Signature")
  valid_21627760 = validateParameter(valid_21627760, JString, required = false,
                                   default = nil)
  if valid_21627760 != nil:
    section.add "X-Amz-Signature", valid_21627760
  var valid_21627761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627761 = validateParameter(valid_21627761, JString, required = false,
                                   default = nil)
  if valid_21627761 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627761
  var valid_21627762 = header.getOrDefault("X-Amz-Credential")
  valid_21627762 = validateParameter(valid_21627762, JString, required = false,
                                   default = nil)
  if valid_21627762 != nil:
    section.add "X-Amz-Credential", valid_21627762
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

proc call*(call_21627764: Call_UpdateConnection_21627752; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a connection definition in the Data Catalog.
  ## 
  let valid = call_21627764.validator(path, query, header, formData, body, _)
  let scheme = call_21627764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627764.makeUrl(scheme.get, call_21627764.host, call_21627764.base,
                               call_21627764.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627764, uri, valid, _)

proc call*(call_21627765: Call_UpdateConnection_21627752; body: JsonNode): Recallable =
  ## updateConnection
  ## Updates a connection definition in the Data Catalog.
  ##   body: JObject (required)
  var body_21627766 = newJObject()
  if body != nil:
    body_21627766 = body
  result = call_21627765.call(nil, nil, nil, nil, body_21627766)

var updateConnection* = Call_UpdateConnection_21627752(name: "updateConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateConnection",
    validator: validate_UpdateConnection_21627753, base: "/",
    makeUrl: url_UpdateConnection_21627754, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCrawler_21627767 = ref object of OpenApiRestCall_21625435
proc url_UpdateCrawler_21627769(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateCrawler_21627768(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627770 = header.getOrDefault("X-Amz-Date")
  valid_21627770 = validateParameter(valid_21627770, JString, required = false,
                                   default = nil)
  if valid_21627770 != nil:
    section.add "X-Amz-Date", valid_21627770
  var valid_21627771 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627771 = validateParameter(valid_21627771, JString, required = false,
                                   default = nil)
  if valid_21627771 != nil:
    section.add "X-Amz-Security-Token", valid_21627771
  var valid_21627772 = header.getOrDefault("X-Amz-Target")
  valid_21627772 = validateParameter(valid_21627772, JString, required = true, default = newJString(
      "AWSGlue.UpdateCrawler"))
  if valid_21627772 != nil:
    section.add "X-Amz-Target", valid_21627772
  var valid_21627773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627773 = validateParameter(valid_21627773, JString, required = false,
                                   default = nil)
  if valid_21627773 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627773
  var valid_21627774 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627774 = validateParameter(valid_21627774, JString, required = false,
                                   default = nil)
  if valid_21627774 != nil:
    section.add "X-Amz-Algorithm", valid_21627774
  var valid_21627775 = header.getOrDefault("X-Amz-Signature")
  valid_21627775 = validateParameter(valid_21627775, JString, required = false,
                                   default = nil)
  if valid_21627775 != nil:
    section.add "X-Amz-Signature", valid_21627775
  var valid_21627776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627776 = validateParameter(valid_21627776, JString, required = false,
                                   default = nil)
  if valid_21627776 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627776
  var valid_21627777 = header.getOrDefault("X-Amz-Credential")
  valid_21627777 = validateParameter(valid_21627777, JString, required = false,
                                   default = nil)
  if valid_21627777 != nil:
    section.add "X-Amz-Credential", valid_21627777
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

proc call*(call_21627779: Call_UpdateCrawler_21627767; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
  ## 
  let valid = call_21627779.validator(path, query, header, formData, body, _)
  let scheme = call_21627779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627779.makeUrl(scheme.get, call_21627779.host, call_21627779.base,
                               call_21627779.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627779, uri, valid, _)

proc call*(call_21627780: Call_UpdateCrawler_21627767; body: JsonNode): Recallable =
  ## updateCrawler
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
  ##   body: JObject (required)
  var body_21627781 = newJObject()
  if body != nil:
    body_21627781 = body
  result = call_21627780.call(nil, nil, nil, nil, body_21627781)

var updateCrawler* = Call_UpdateCrawler_21627767(name: "updateCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateCrawler",
    validator: validate_UpdateCrawler_21627768, base: "/",
    makeUrl: url_UpdateCrawler_21627769, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCrawlerSchedule_21627782 = ref object of OpenApiRestCall_21625435
proc url_UpdateCrawlerSchedule_21627784(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateCrawlerSchedule_21627783(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627785 = header.getOrDefault("X-Amz-Date")
  valid_21627785 = validateParameter(valid_21627785, JString, required = false,
                                   default = nil)
  if valid_21627785 != nil:
    section.add "X-Amz-Date", valid_21627785
  var valid_21627786 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627786 = validateParameter(valid_21627786, JString, required = false,
                                   default = nil)
  if valid_21627786 != nil:
    section.add "X-Amz-Security-Token", valid_21627786
  var valid_21627787 = header.getOrDefault("X-Amz-Target")
  valid_21627787 = validateParameter(valid_21627787, JString, required = true, default = newJString(
      "AWSGlue.UpdateCrawlerSchedule"))
  if valid_21627787 != nil:
    section.add "X-Amz-Target", valid_21627787
  var valid_21627788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627788 = validateParameter(valid_21627788, JString, required = false,
                                   default = nil)
  if valid_21627788 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627788
  var valid_21627789 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627789 = validateParameter(valid_21627789, JString, required = false,
                                   default = nil)
  if valid_21627789 != nil:
    section.add "X-Amz-Algorithm", valid_21627789
  var valid_21627790 = header.getOrDefault("X-Amz-Signature")
  valid_21627790 = validateParameter(valid_21627790, JString, required = false,
                                   default = nil)
  if valid_21627790 != nil:
    section.add "X-Amz-Signature", valid_21627790
  var valid_21627791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627791 = validateParameter(valid_21627791, JString, required = false,
                                   default = nil)
  if valid_21627791 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627791
  var valid_21627792 = header.getOrDefault("X-Amz-Credential")
  valid_21627792 = validateParameter(valid_21627792, JString, required = false,
                                   default = nil)
  if valid_21627792 != nil:
    section.add "X-Amz-Credential", valid_21627792
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

proc call*(call_21627794: Call_UpdateCrawlerSchedule_21627782;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
  ## 
  let valid = call_21627794.validator(path, query, header, formData, body, _)
  let scheme = call_21627794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627794.makeUrl(scheme.get, call_21627794.host, call_21627794.base,
                               call_21627794.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627794, uri, valid, _)

proc call*(call_21627795: Call_UpdateCrawlerSchedule_21627782; body: JsonNode): Recallable =
  ## updateCrawlerSchedule
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
  ##   body: JObject (required)
  var body_21627796 = newJObject()
  if body != nil:
    body_21627796 = body
  result = call_21627795.call(nil, nil, nil, nil, body_21627796)

var updateCrawlerSchedule* = Call_UpdateCrawlerSchedule_21627782(
    name: "updateCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateCrawlerSchedule",
    validator: validate_UpdateCrawlerSchedule_21627783, base: "/",
    makeUrl: url_UpdateCrawlerSchedule_21627784,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDatabase_21627797 = ref object of OpenApiRestCall_21625435
proc url_UpdateDatabase_21627799(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDatabase_21627798(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627800 = header.getOrDefault("X-Amz-Date")
  valid_21627800 = validateParameter(valid_21627800, JString, required = false,
                                   default = nil)
  if valid_21627800 != nil:
    section.add "X-Amz-Date", valid_21627800
  var valid_21627801 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627801 = validateParameter(valid_21627801, JString, required = false,
                                   default = nil)
  if valid_21627801 != nil:
    section.add "X-Amz-Security-Token", valid_21627801
  var valid_21627802 = header.getOrDefault("X-Amz-Target")
  valid_21627802 = validateParameter(valid_21627802, JString, required = true, default = newJString(
      "AWSGlue.UpdateDatabase"))
  if valid_21627802 != nil:
    section.add "X-Amz-Target", valid_21627802
  var valid_21627803 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627803 = validateParameter(valid_21627803, JString, required = false,
                                   default = nil)
  if valid_21627803 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627803
  var valid_21627804 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627804 = validateParameter(valid_21627804, JString, required = false,
                                   default = nil)
  if valid_21627804 != nil:
    section.add "X-Amz-Algorithm", valid_21627804
  var valid_21627805 = header.getOrDefault("X-Amz-Signature")
  valid_21627805 = validateParameter(valid_21627805, JString, required = false,
                                   default = nil)
  if valid_21627805 != nil:
    section.add "X-Amz-Signature", valid_21627805
  var valid_21627806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627806 = validateParameter(valid_21627806, JString, required = false,
                                   default = nil)
  if valid_21627806 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627806
  var valid_21627807 = header.getOrDefault("X-Amz-Credential")
  valid_21627807 = validateParameter(valid_21627807, JString, required = false,
                                   default = nil)
  if valid_21627807 != nil:
    section.add "X-Amz-Credential", valid_21627807
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

proc call*(call_21627809: Call_UpdateDatabase_21627797; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing database definition in a Data Catalog.
  ## 
  let valid = call_21627809.validator(path, query, header, formData, body, _)
  let scheme = call_21627809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627809.makeUrl(scheme.get, call_21627809.host, call_21627809.base,
                               call_21627809.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627809, uri, valid, _)

proc call*(call_21627810: Call_UpdateDatabase_21627797; body: JsonNode): Recallable =
  ## updateDatabase
  ## Updates an existing database definition in a Data Catalog.
  ##   body: JObject (required)
  var body_21627811 = newJObject()
  if body != nil:
    body_21627811 = body
  result = call_21627810.call(nil, nil, nil, nil, body_21627811)

var updateDatabase* = Call_UpdateDatabase_21627797(name: "updateDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateDatabase",
    validator: validate_UpdateDatabase_21627798, base: "/",
    makeUrl: url_UpdateDatabase_21627799, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevEndpoint_21627812 = ref object of OpenApiRestCall_21625435
proc url_UpdateDevEndpoint_21627814(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDevEndpoint_21627813(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627815 = header.getOrDefault("X-Amz-Date")
  valid_21627815 = validateParameter(valid_21627815, JString, required = false,
                                   default = nil)
  if valid_21627815 != nil:
    section.add "X-Amz-Date", valid_21627815
  var valid_21627816 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627816 = validateParameter(valid_21627816, JString, required = false,
                                   default = nil)
  if valid_21627816 != nil:
    section.add "X-Amz-Security-Token", valid_21627816
  var valid_21627817 = header.getOrDefault("X-Amz-Target")
  valid_21627817 = validateParameter(valid_21627817, JString, required = true, default = newJString(
      "AWSGlue.UpdateDevEndpoint"))
  if valid_21627817 != nil:
    section.add "X-Amz-Target", valid_21627817
  var valid_21627818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627818 = validateParameter(valid_21627818, JString, required = false,
                                   default = nil)
  if valid_21627818 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627818
  var valid_21627819 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627819 = validateParameter(valid_21627819, JString, required = false,
                                   default = nil)
  if valid_21627819 != nil:
    section.add "X-Amz-Algorithm", valid_21627819
  var valid_21627820 = header.getOrDefault("X-Amz-Signature")
  valid_21627820 = validateParameter(valid_21627820, JString, required = false,
                                   default = nil)
  if valid_21627820 != nil:
    section.add "X-Amz-Signature", valid_21627820
  var valid_21627821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627821 = validateParameter(valid_21627821, JString, required = false,
                                   default = nil)
  if valid_21627821 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627821
  var valid_21627822 = header.getOrDefault("X-Amz-Credential")
  valid_21627822 = validateParameter(valid_21627822, JString, required = false,
                                   default = nil)
  if valid_21627822 != nil:
    section.add "X-Amz-Credential", valid_21627822
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

proc call*(call_21627824: Call_UpdateDevEndpoint_21627812; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a specified development endpoint.
  ## 
  let valid = call_21627824.validator(path, query, header, formData, body, _)
  let scheme = call_21627824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627824.makeUrl(scheme.get, call_21627824.host, call_21627824.base,
                               call_21627824.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627824, uri, valid, _)

proc call*(call_21627825: Call_UpdateDevEndpoint_21627812; body: JsonNode): Recallable =
  ## updateDevEndpoint
  ## Updates a specified development endpoint.
  ##   body: JObject (required)
  var body_21627826 = newJObject()
  if body != nil:
    body_21627826 = body
  result = call_21627825.call(nil, nil, nil, nil, body_21627826)

var updateDevEndpoint* = Call_UpdateDevEndpoint_21627812(name: "updateDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateDevEndpoint",
    validator: validate_UpdateDevEndpoint_21627813, base: "/",
    makeUrl: url_UpdateDevEndpoint_21627814, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJob_21627827 = ref object of OpenApiRestCall_21625435
proc url_UpdateJob_21627829(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateJob_21627828(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627830 = header.getOrDefault("X-Amz-Date")
  valid_21627830 = validateParameter(valid_21627830, JString, required = false,
                                   default = nil)
  if valid_21627830 != nil:
    section.add "X-Amz-Date", valid_21627830
  var valid_21627831 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627831 = validateParameter(valid_21627831, JString, required = false,
                                   default = nil)
  if valid_21627831 != nil:
    section.add "X-Amz-Security-Token", valid_21627831
  var valid_21627832 = header.getOrDefault("X-Amz-Target")
  valid_21627832 = validateParameter(valid_21627832, JString, required = true,
                                   default = newJString("AWSGlue.UpdateJob"))
  if valid_21627832 != nil:
    section.add "X-Amz-Target", valid_21627832
  var valid_21627833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627833 = validateParameter(valid_21627833, JString, required = false,
                                   default = nil)
  if valid_21627833 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627833
  var valid_21627834 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627834 = validateParameter(valid_21627834, JString, required = false,
                                   default = nil)
  if valid_21627834 != nil:
    section.add "X-Amz-Algorithm", valid_21627834
  var valid_21627835 = header.getOrDefault("X-Amz-Signature")
  valid_21627835 = validateParameter(valid_21627835, JString, required = false,
                                   default = nil)
  if valid_21627835 != nil:
    section.add "X-Amz-Signature", valid_21627835
  var valid_21627836 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627836 = validateParameter(valid_21627836, JString, required = false,
                                   default = nil)
  if valid_21627836 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627836
  var valid_21627837 = header.getOrDefault("X-Amz-Credential")
  valid_21627837 = validateParameter(valid_21627837, JString, required = false,
                                   default = nil)
  if valid_21627837 != nil:
    section.add "X-Amz-Credential", valid_21627837
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

proc call*(call_21627839: Call_UpdateJob_21627827; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing job definition.
  ## 
  let valid = call_21627839.validator(path, query, header, formData, body, _)
  let scheme = call_21627839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627839.makeUrl(scheme.get, call_21627839.host, call_21627839.base,
                               call_21627839.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627839, uri, valid, _)

proc call*(call_21627840: Call_UpdateJob_21627827; body: JsonNode): Recallable =
  ## updateJob
  ## Updates an existing job definition.
  ##   body: JObject (required)
  var body_21627841 = newJObject()
  if body != nil:
    body_21627841 = body
  result = call_21627840.call(nil, nil, nil, nil, body_21627841)

var updateJob* = Call_UpdateJob_21627827(name: "updateJob",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.UpdateJob",
                                      validator: validate_UpdateJob_21627828,
                                      base: "/", makeUrl: url_UpdateJob_21627829,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMLTransform_21627842 = ref object of OpenApiRestCall_21625435
proc url_UpdateMLTransform_21627844(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateMLTransform_21627843(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627845 = header.getOrDefault("X-Amz-Date")
  valid_21627845 = validateParameter(valid_21627845, JString, required = false,
                                   default = nil)
  if valid_21627845 != nil:
    section.add "X-Amz-Date", valid_21627845
  var valid_21627846 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627846 = validateParameter(valid_21627846, JString, required = false,
                                   default = nil)
  if valid_21627846 != nil:
    section.add "X-Amz-Security-Token", valid_21627846
  var valid_21627847 = header.getOrDefault("X-Amz-Target")
  valid_21627847 = validateParameter(valid_21627847, JString, required = true, default = newJString(
      "AWSGlue.UpdateMLTransform"))
  if valid_21627847 != nil:
    section.add "X-Amz-Target", valid_21627847
  var valid_21627848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627848 = validateParameter(valid_21627848, JString, required = false,
                                   default = nil)
  if valid_21627848 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627848
  var valid_21627849 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627849 = validateParameter(valid_21627849, JString, required = false,
                                   default = nil)
  if valid_21627849 != nil:
    section.add "X-Amz-Algorithm", valid_21627849
  var valid_21627850 = header.getOrDefault("X-Amz-Signature")
  valid_21627850 = validateParameter(valid_21627850, JString, required = false,
                                   default = nil)
  if valid_21627850 != nil:
    section.add "X-Amz-Signature", valid_21627850
  var valid_21627851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627851 = validateParameter(valid_21627851, JString, required = false,
                                   default = nil)
  if valid_21627851 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627851
  var valid_21627852 = header.getOrDefault("X-Amz-Credential")
  valid_21627852 = validateParameter(valid_21627852, JString, required = false,
                                   default = nil)
  if valid_21627852 != nil:
    section.add "X-Amz-Credential", valid_21627852
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

proc call*(call_21627854: Call_UpdateMLTransform_21627842; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
  ## 
  let valid = call_21627854.validator(path, query, header, formData, body, _)
  let scheme = call_21627854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627854.makeUrl(scheme.get, call_21627854.host, call_21627854.base,
                               call_21627854.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627854, uri, valid, _)

proc call*(call_21627855: Call_UpdateMLTransform_21627842; body: JsonNode): Recallable =
  ## updateMLTransform
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
  ##   body: JObject (required)
  var body_21627856 = newJObject()
  if body != nil:
    body_21627856 = body
  result = call_21627855.call(nil, nil, nil, nil, body_21627856)

var updateMLTransform* = Call_UpdateMLTransform_21627842(name: "updateMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateMLTransform",
    validator: validate_UpdateMLTransform_21627843, base: "/",
    makeUrl: url_UpdateMLTransform_21627844, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePartition_21627857 = ref object of OpenApiRestCall_21625435
proc url_UpdatePartition_21627859(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePartition_21627858(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627860 = header.getOrDefault("X-Amz-Date")
  valid_21627860 = validateParameter(valid_21627860, JString, required = false,
                                   default = nil)
  if valid_21627860 != nil:
    section.add "X-Amz-Date", valid_21627860
  var valid_21627861 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627861 = validateParameter(valid_21627861, JString, required = false,
                                   default = nil)
  if valid_21627861 != nil:
    section.add "X-Amz-Security-Token", valid_21627861
  var valid_21627862 = header.getOrDefault("X-Amz-Target")
  valid_21627862 = validateParameter(valid_21627862, JString, required = true, default = newJString(
      "AWSGlue.UpdatePartition"))
  if valid_21627862 != nil:
    section.add "X-Amz-Target", valid_21627862
  var valid_21627863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627863 = validateParameter(valid_21627863, JString, required = false,
                                   default = nil)
  if valid_21627863 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627863
  var valid_21627864 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627864 = validateParameter(valid_21627864, JString, required = false,
                                   default = nil)
  if valid_21627864 != nil:
    section.add "X-Amz-Algorithm", valid_21627864
  var valid_21627865 = header.getOrDefault("X-Amz-Signature")
  valid_21627865 = validateParameter(valid_21627865, JString, required = false,
                                   default = nil)
  if valid_21627865 != nil:
    section.add "X-Amz-Signature", valid_21627865
  var valid_21627866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627866 = validateParameter(valid_21627866, JString, required = false,
                                   default = nil)
  if valid_21627866 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627866
  var valid_21627867 = header.getOrDefault("X-Amz-Credential")
  valid_21627867 = validateParameter(valid_21627867, JString, required = false,
                                   default = nil)
  if valid_21627867 != nil:
    section.add "X-Amz-Credential", valid_21627867
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

proc call*(call_21627869: Call_UpdatePartition_21627857; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a partition.
  ## 
  let valid = call_21627869.validator(path, query, header, formData, body, _)
  let scheme = call_21627869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627869.makeUrl(scheme.get, call_21627869.host, call_21627869.base,
                               call_21627869.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627869, uri, valid, _)

proc call*(call_21627870: Call_UpdatePartition_21627857; body: JsonNode): Recallable =
  ## updatePartition
  ## Updates a partition.
  ##   body: JObject (required)
  var body_21627871 = newJObject()
  if body != nil:
    body_21627871 = body
  result = call_21627870.call(nil, nil, nil, nil, body_21627871)

var updatePartition* = Call_UpdatePartition_21627857(name: "updatePartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdatePartition",
    validator: validate_UpdatePartition_21627858, base: "/",
    makeUrl: url_UpdatePartition_21627859, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTable_21627872 = ref object of OpenApiRestCall_21625435
proc url_UpdateTable_21627874(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTable_21627873(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627875 = header.getOrDefault("X-Amz-Date")
  valid_21627875 = validateParameter(valid_21627875, JString, required = false,
                                   default = nil)
  if valid_21627875 != nil:
    section.add "X-Amz-Date", valid_21627875
  var valid_21627876 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627876 = validateParameter(valid_21627876, JString, required = false,
                                   default = nil)
  if valid_21627876 != nil:
    section.add "X-Amz-Security-Token", valid_21627876
  var valid_21627877 = header.getOrDefault("X-Amz-Target")
  valid_21627877 = validateParameter(valid_21627877, JString, required = true,
                                   default = newJString("AWSGlue.UpdateTable"))
  if valid_21627877 != nil:
    section.add "X-Amz-Target", valid_21627877
  var valid_21627878 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627878 = validateParameter(valid_21627878, JString, required = false,
                                   default = nil)
  if valid_21627878 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627878
  var valid_21627879 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627879 = validateParameter(valid_21627879, JString, required = false,
                                   default = nil)
  if valid_21627879 != nil:
    section.add "X-Amz-Algorithm", valid_21627879
  var valid_21627880 = header.getOrDefault("X-Amz-Signature")
  valid_21627880 = validateParameter(valid_21627880, JString, required = false,
                                   default = nil)
  if valid_21627880 != nil:
    section.add "X-Amz-Signature", valid_21627880
  var valid_21627881 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627881 = validateParameter(valid_21627881, JString, required = false,
                                   default = nil)
  if valid_21627881 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627881
  var valid_21627882 = header.getOrDefault("X-Amz-Credential")
  valid_21627882 = validateParameter(valid_21627882, JString, required = false,
                                   default = nil)
  if valid_21627882 != nil:
    section.add "X-Amz-Credential", valid_21627882
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

proc call*(call_21627884: Call_UpdateTable_21627872; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a metadata table in the Data Catalog.
  ## 
  let valid = call_21627884.validator(path, query, header, formData, body, _)
  let scheme = call_21627884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627884.makeUrl(scheme.get, call_21627884.host, call_21627884.base,
                               call_21627884.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627884, uri, valid, _)

proc call*(call_21627885: Call_UpdateTable_21627872; body: JsonNode): Recallable =
  ## updateTable
  ## Updates a metadata table in the Data Catalog.
  ##   body: JObject (required)
  var body_21627886 = newJObject()
  if body != nil:
    body_21627886 = body
  result = call_21627885.call(nil, nil, nil, nil, body_21627886)

var updateTable* = Call_UpdateTable_21627872(name: "updateTable",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateTable", validator: validate_UpdateTable_21627873,
    base: "/", makeUrl: url_UpdateTable_21627874,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrigger_21627887 = ref object of OpenApiRestCall_21625435
proc url_UpdateTrigger_21627889(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTrigger_21627888(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Updates a trigger definition.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627890 = header.getOrDefault("X-Amz-Date")
  valid_21627890 = validateParameter(valid_21627890, JString, required = false,
                                   default = nil)
  if valid_21627890 != nil:
    section.add "X-Amz-Date", valid_21627890
  var valid_21627891 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627891 = validateParameter(valid_21627891, JString, required = false,
                                   default = nil)
  if valid_21627891 != nil:
    section.add "X-Amz-Security-Token", valid_21627891
  var valid_21627892 = header.getOrDefault("X-Amz-Target")
  valid_21627892 = validateParameter(valid_21627892, JString, required = true, default = newJString(
      "AWSGlue.UpdateTrigger"))
  if valid_21627892 != nil:
    section.add "X-Amz-Target", valid_21627892
  var valid_21627893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627893 = validateParameter(valid_21627893, JString, required = false,
                                   default = nil)
  if valid_21627893 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627893
  var valid_21627894 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627894 = validateParameter(valid_21627894, JString, required = false,
                                   default = nil)
  if valid_21627894 != nil:
    section.add "X-Amz-Algorithm", valid_21627894
  var valid_21627895 = header.getOrDefault("X-Amz-Signature")
  valid_21627895 = validateParameter(valid_21627895, JString, required = false,
                                   default = nil)
  if valid_21627895 != nil:
    section.add "X-Amz-Signature", valid_21627895
  var valid_21627896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627896 = validateParameter(valid_21627896, JString, required = false,
                                   default = nil)
  if valid_21627896 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627896
  var valid_21627897 = header.getOrDefault("X-Amz-Credential")
  valid_21627897 = validateParameter(valid_21627897, JString, required = false,
                                   default = nil)
  if valid_21627897 != nil:
    section.add "X-Amz-Credential", valid_21627897
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

proc call*(call_21627899: Call_UpdateTrigger_21627887; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a trigger definition.
  ## 
  let valid = call_21627899.validator(path, query, header, formData, body, _)
  let scheme = call_21627899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627899.makeUrl(scheme.get, call_21627899.host, call_21627899.base,
                               call_21627899.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627899, uri, valid, _)

proc call*(call_21627900: Call_UpdateTrigger_21627887; body: JsonNode): Recallable =
  ## updateTrigger
  ## Updates a trigger definition.
  ##   body: JObject (required)
  var body_21627901 = newJObject()
  if body != nil:
    body_21627901 = body
  result = call_21627900.call(nil, nil, nil, nil, body_21627901)

var updateTrigger* = Call_UpdateTrigger_21627887(name: "updateTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateTrigger",
    validator: validate_UpdateTrigger_21627888, base: "/",
    makeUrl: url_UpdateTrigger_21627889, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserDefinedFunction_21627902 = ref object of OpenApiRestCall_21625435
proc url_UpdateUserDefinedFunction_21627904(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserDefinedFunction_21627903(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an existing function definition in the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627905 = header.getOrDefault("X-Amz-Date")
  valid_21627905 = validateParameter(valid_21627905, JString, required = false,
                                   default = nil)
  if valid_21627905 != nil:
    section.add "X-Amz-Date", valid_21627905
  var valid_21627906 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627906 = validateParameter(valid_21627906, JString, required = false,
                                   default = nil)
  if valid_21627906 != nil:
    section.add "X-Amz-Security-Token", valid_21627906
  var valid_21627907 = header.getOrDefault("X-Amz-Target")
  valid_21627907 = validateParameter(valid_21627907, JString, required = true, default = newJString(
      "AWSGlue.UpdateUserDefinedFunction"))
  if valid_21627907 != nil:
    section.add "X-Amz-Target", valid_21627907
  var valid_21627908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627908 = validateParameter(valid_21627908, JString, required = false,
                                   default = nil)
  if valid_21627908 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627908
  var valid_21627909 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627909 = validateParameter(valid_21627909, JString, required = false,
                                   default = nil)
  if valid_21627909 != nil:
    section.add "X-Amz-Algorithm", valid_21627909
  var valid_21627910 = header.getOrDefault("X-Amz-Signature")
  valid_21627910 = validateParameter(valid_21627910, JString, required = false,
                                   default = nil)
  if valid_21627910 != nil:
    section.add "X-Amz-Signature", valid_21627910
  var valid_21627911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627911 = validateParameter(valid_21627911, JString, required = false,
                                   default = nil)
  if valid_21627911 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627911
  var valid_21627912 = header.getOrDefault("X-Amz-Credential")
  valid_21627912 = validateParameter(valid_21627912, JString, required = false,
                                   default = nil)
  if valid_21627912 != nil:
    section.add "X-Amz-Credential", valid_21627912
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

proc call*(call_21627914: Call_UpdateUserDefinedFunction_21627902;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing function definition in the Data Catalog.
  ## 
  let valid = call_21627914.validator(path, query, header, formData, body, _)
  let scheme = call_21627914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627914.makeUrl(scheme.get, call_21627914.host, call_21627914.base,
                               call_21627914.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627914, uri, valid, _)

proc call*(call_21627915: Call_UpdateUserDefinedFunction_21627902; body: JsonNode): Recallable =
  ## updateUserDefinedFunction
  ## Updates an existing function definition in the Data Catalog.
  ##   body: JObject (required)
  var body_21627916 = newJObject()
  if body != nil:
    body_21627916 = body
  result = call_21627915.call(nil, nil, nil, nil, body_21627916)

var updateUserDefinedFunction* = Call_UpdateUserDefinedFunction_21627902(
    name: "updateUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateUserDefinedFunction",
    validator: validate_UpdateUserDefinedFunction_21627903, base: "/",
    makeUrl: url_UpdateUserDefinedFunction_21627904,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkflow_21627917 = ref object of OpenApiRestCall_21625435
proc url_UpdateWorkflow_21627919(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateWorkflow_21627918(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627920 = header.getOrDefault("X-Amz-Date")
  valid_21627920 = validateParameter(valid_21627920, JString, required = false,
                                   default = nil)
  if valid_21627920 != nil:
    section.add "X-Amz-Date", valid_21627920
  var valid_21627921 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627921 = validateParameter(valid_21627921, JString, required = false,
                                   default = nil)
  if valid_21627921 != nil:
    section.add "X-Amz-Security-Token", valid_21627921
  var valid_21627922 = header.getOrDefault("X-Amz-Target")
  valid_21627922 = validateParameter(valid_21627922, JString, required = true, default = newJString(
      "AWSGlue.UpdateWorkflow"))
  if valid_21627922 != nil:
    section.add "X-Amz-Target", valid_21627922
  var valid_21627923 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627923 = validateParameter(valid_21627923, JString, required = false,
                                   default = nil)
  if valid_21627923 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627923
  var valid_21627924 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627924 = validateParameter(valid_21627924, JString, required = false,
                                   default = nil)
  if valid_21627924 != nil:
    section.add "X-Amz-Algorithm", valid_21627924
  var valid_21627925 = header.getOrDefault("X-Amz-Signature")
  valid_21627925 = validateParameter(valid_21627925, JString, required = false,
                                   default = nil)
  if valid_21627925 != nil:
    section.add "X-Amz-Signature", valid_21627925
  var valid_21627926 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627926 = validateParameter(valid_21627926, JString, required = false,
                                   default = nil)
  if valid_21627926 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627926
  var valid_21627927 = header.getOrDefault("X-Amz-Credential")
  valid_21627927 = validateParameter(valid_21627927, JString, required = false,
                                   default = nil)
  if valid_21627927 != nil:
    section.add "X-Amz-Credential", valid_21627927
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

proc call*(call_21627929: Call_UpdateWorkflow_21627917; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing workflow.
  ## 
  let valid = call_21627929.validator(path, query, header, formData, body, _)
  let scheme = call_21627929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627929.makeUrl(scheme.get, call_21627929.host, call_21627929.base,
                               call_21627929.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627929, uri, valid, _)

proc call*(call_21627930: Call_UpdateWorkflow_21627917; body: JsonNode): Recallable =
  ## updateWorkflow
  ## Updates an existing workflow.
  ##   body: JObject (required)
  var body_21627931 = newJObject()
  if body != nil:
    body_21627931 = body
  result = call_21627930.call(nil, nil, nil, nil, body_21627931)

var updateWorkflow* = Call_UpdateWorkflow_21627917(name: "updateWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateWorkflow",
    validator: validate_UpdateWorkflow_21627918, base: "/",
    makeUrl: url_UpdateWorkflow_21627919, schemes: {Scheme.Https, Scheme.Http})
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