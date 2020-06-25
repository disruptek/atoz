
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: AmazonMQ
## version: 2017-11-27
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon MQ is a managed message broker service for Apache ActiveMQ that makes it easy to set up and operate message brokers in the cloud. A message broker allows software applications and components to communicate using various programming languages, operating systems, and formal messaging protocols.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/mq/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "mq.ap-northeast-1.amazonaws.com",
                           "ap-southeast-1": "mq.ap-southeast-1.amazonaws.com",
                           "us-west-2": "mq.us-west-2.amazonaws.com",
                           "eu-west-2": "mq.eu-west-2.amazonaws.com",
                           "ap-northeast-3": "mq.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "mq.eu-central-1.amazonaws.com",
                           "us-east-2": "mq.us-east-2.amazonaws.com",
                           "us-east-1": "mq.us-east-1.amazonaws.com", "cn-northwest-1": "mq.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "mq.ap-south-1.amazonaws.com",
                           "eu-north-1": "mq.eu-north-1.amazonaws.com",
                           "ap-northeast-2": "mq.ap-northeast-2.amazonaws.com",
                           "us-west-1": "mq.us-west-1.amazonaws.com",
                           "us-gov-east-1": "mq.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "mq.eu-west-3.amazonaws.com",
                           "cn-north-1": "mq.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "mq.sa-east-1.amazonaws.com",
                           "eu-west-1": "mq.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "mq.us-gov-west-1.amazonaws.com",
                           "ap-southeast-2": "mq.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "mq.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "mq.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "mq.ap-southeast-1.amazonaws.com",
      "us-west-2": "mq.us-west-2.amazonaws.com",
      "eu-west-2": "mq.eu-west-2.amazonaws.com",
      "ap-northeast-3": "mq.ap-northeast-3.amazonaws.com",
      "eu-central-1": "mq.eu-central-1.amazonaws.com",
      "us-east-2": "mq.us-east-2.amazonaws.com",
      "us-east-1": "mq.us-east-1.amazonaws.com",
      "cn-northwest-1": "mq.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "mq.ap-south-1.amazonaws.com",
      "eu-north-1": "mq.eu-north-1.amazonaws.com",
      "ap-northeast-2": "mq.ap-northeast-2.amazonaws.com",
      "us-west-1": "mq.us-west-1.amazonaws.com",
      "us-gov-east-1": "mq.us-gov-east-1.amazonaws.com",
      "eu-west-3": "mq.eu-west-3.amazonaws.com",
      "cn-north-1": "mq.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "mq.sa-east-1.amazonaws.com",
      "eu-west-1": "mq.eu-west-1.amazonaws.com",
      "us-gov-west-1": "mq.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "mq.ap-southeast-2.amazonaws.com",
      "ca-central-1": "mq.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "mq"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateBroker_21626019 = ref object of OpenApiRestCall_21625435
proc url_CreateBroker_21626021(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateBroker_21626020(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates a broker. Note: This API is asynchronous.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626022 = header.getOrDefault("X-Amz-Date")
  valid_21626022 = validateParameter(valid_21626022, JString, required = false,
                                   default = nil)
  if valid_21626022 != nil:
    section.add "X-Amz-Date", valid_21626022
  var valid_21626023 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626023 = validateParameter(valid_21626023, JString, required = false,
                                   default = nil)
  if valid_21626023 != nil:
    section.add "X-Amz-Security-Token", valid_21626023
  var valid_21626024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626024 = validateParameter(valid_21626024, JString, required = false,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626024
  var valid_21626025 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626025 = validateParameter(valid_21626025, JString, required = false,
                                   default = nil)
  if valid_21626025 != nil:
    section.add "X-Amz-Algorithm", valid_21626025
  var valid_21626026 = header.getOrDefault("X-Amz-Signature")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Signature", valid_21626026
  var valid_21626027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626027 = validateParameter(valid_21626027, JString, required = false,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626027
  var valid_21626028 = header.getOrDefault("X-Amz-Credential")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "X-Amz-Credential", valid_21626028
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

proc call*(call_21626030: Call_CreateBroker_21626019; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a broker. Note: This API is asynchronous.
  ## 
  let valid = call_21626030.validator(path, query, header, formData, body, _)
  let scheme = call_21626030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626030.makeUrl(scheme.get, call_21626030.host, call_21626030.base,
                               call_21626030.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626030, uri, valid, _)

proc call*(call_21626031: Call_CreateBroker_21626019; body: JsonNode): Recallable =
  ## createBroker
  ## Creates a broker. Note: This API is asynchronous.
  ##   body: JObject (required)
  var body_21626032 = newJObject()
  if body != nil:
    body_21626032 = body
  result = call_21626031.call(nil, nil, nil, nil, body_21626032)

var createBroker* = Call_CreateBroker_21626019(name: "createBroker",
    meth: HttpMethod.HttpPost, host: "mq.amazonaws.com", route: "/v1/brokers",
    validator: validate_CreateBroker_21626020, base: "/", makeUrl: url_CreateBroker_21626021,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBrokers_21625779 = ref object of OpenApiRestCall_21625435
proc url_ListBrokers_21625781(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBrokers_21625780(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of all brokers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of brokers that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: JString
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  section = newJObject()
  var valid_21625882 = query.getOrDefault("maxResults")
  valid_21625882 = validateParameter(valid_21625882, JInt, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "maxResults", valid_21625882
  var valid_21625883 = query.getOrDefault("nextToken")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "nextToken", valid_21625883
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625884 = header.getOrDefault("X-Amz-Date")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "X-Amz-Date", valid_21625884
  var valid_21625885 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "X-Amz-Security-Token", valid_21625885
  var valid_21625886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625886 = validateParameter(valid_21625886, JString, required = false,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625886
  var valid_21625887 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625887 = validateParameter(valid_21625887, JString, required = false,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "X-Amz-Algorithm", valid_21625887
  var valid_21625888 = header.getOrDefault("X-Amz-Signature")
  valid_21625888 = validateParameter(valid_21625888, JString, required = false,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "X-Amz-Signature", valid_21625888
  var valid_21625889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625889 = validateParameter(valid_21625889, JString, required = false,
                                   default = nil)
  if valid_21625889 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625889
  var valid_21625890 = header.getOrDefault("X-Amz-Credential")
  valid_21625890 = validateParameter(valid_21625890, JString, required = false,
                                   default = nil)
  if valid_21625890 != nil:
    section.add "X-Amz-Credential", valid_21625890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625915: Call_ListBrokers_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of all brokers.
  ## 
  let valid = call_21625915.validator(path, query, header, formData, body, _)
  let scheme = call_21625915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625915.makeUrl(scheme.get, call_21625915.host, call_21625915.base,
                               call_21625915.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625915, uri, valid, _)

proc call*(call_21625978: Call_ListBrokers_21625779; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listBrokers
  ## Returns a list of all brokers.
  ##   maxResults: int
  ##             : The maximum number of brokers that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  var query_21625980 = newJObject()
  add(query_21625980, "maxResults", newJInt(maxResults))
  add(query_21625980, "nextToken", newJString(nextToken))
  result = call_21625978.call(nil, query_21625980, nil, nil, nil)

var listBrokers* = Call_ListBrokers_21625779(name: "listBrokers",
    meth: HttpMethod.HttpGet, host: "mq.amazonaws.com", route: "/v1/brokers",
    validator: validate_ListBrokers_21625780, base: "/", makeUrl: url_ListBrokers_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfiguration_21626048 = ref object of OpenApiRestCall_21625435
proc url_CreateConfiguration_21626050(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConfiguration_21626049(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new configuration for the specified configuration name. Amazon MQ uses the default configuration (the engine type and version).
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626051 = header.getOrDefault("X-Amz-Date")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Date", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Security-Token", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Algorithm", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-Signature")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-Signature", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Credential")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Credential", valid_21626057
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

proc call*(call_21626059: Call_CreateConfiguration_21626048; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new configuration for the specified configuration name. Amazon MQ uses the default configuration (the engine type and version).
  ## 
  let valid = call_21626059.validator(path, query, header, formData, body, _)
  let scheme = call_21626059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626059.makeUrl(scheme.get, call_21626059.host, call_21626059.base,
                               call_21626059.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626059, uri, valid, _)

proc call*(call_21626060: Call_CreateConfiguration_21626048; body: JsonNode): Recallable =
  ## createConfiguration
  ## Creates a new configuration for the specified configuration name. Amazon MQ uses the default configuration (the engine type and version).
  ##   body: JObject (required)
  var body_21626061 = newJObject()
  if body != nil:
    body_21626061 = body
  result = call_21626060.call(nil, nil, nil, nil, body_21626061)

var createConfiguration* = Call_CreateConfiguration_21626048(
    name: "createConfiguration", meth: HttpMethod.HttpPost,
    host: "mq.amazonaws.com", route: "/v1/configurations",
    validator: validate_CreateConfiguration_21626049, base: "/",
    makeUrl: url_CreateConfiguration_21626050,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurations_21626033 = ref object of OpenApiRestCall_21625435
proc url_ListConfigurations_21626035(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConfigurations_21626034(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of all configurations.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of configurations that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: JString
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  section = newJObject()
  var valid_21626036 = query.getOrDefault("maxResults")
  valid_21626036 = validateParameter(valid_21626036, JInt, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "maxResults", valid_21626036
  var valid_21626037 = query.getOrDefault("nextToken")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "nextToken", valid_21626037
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626038 = header.getOrDefault("X-Amz-Date")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Date", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Security-Token", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Algorithm", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Signature")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Signature", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-Credential")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-Credential", valid_21626044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626045: Call_ListConfigurations_21626033; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of all configurations.
  ## 
  let valid = call_21626045.validator(path, query, header, formData, body, _)
  let scheme = call_21626045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626045.makeUrl(scheme.get, call_21626045.host, call_21626045.base,
                               call_21626045.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626045, uri, valid, _)

proc call*(call_21626046: Call_ListConfigurations_21626033; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listConfigurations
  ## Returns a list of all configurations.
  ##   maxResults: int
  ##             : The maximum number of configurations that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  var query_21626047 = newJObject()
  add(query_21626047, "maxResults", newJInt(maxResults))
  add(query_21626047, "nextToken", newJString(nextToken))
  result = call_21626046.call(nil, query_21626047, nil, nil, nil)

var listConfigurations* = Call_ListConfigurations_21626033(
    name: "listConfigurations", meth: HttpMethod.HttpGet, host: "mq.amazonaws.com",
    route: "/v1/configurations", validator: validate_ListConfigurations_21626034,
    base: "/", makeUrl: url_ListConfigurations_21626035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_21626089 = ref object of OpenApiRestCall_21625435
proc url_CreateTags_21626091(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateTags_21626090(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Add a tag to a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The Amazon Resource Name (ARN) of the resource tag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_21626092 = path.getOrDefault("resource-arn")
  valid_21626092 = validateParameter(valid_21626092, JString, required = true,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "resource-arn", valid_21626092
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626093 = header.getOrDefault("X-Amz-Date")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Date", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "X-Amz-Security-Token", valid_21626094
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

proc call*(call_21626101: Call_CreateTags_21626089; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Add a tag to a resource.
  ## 
  let valid = call_21626101.validator(path, query, header, formData, body, _)
  let scheme = call_21626101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626101.makeUrl(scheme.get, call_21626101.host, call_21626101.base,
                               call_21626101.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626101, uri, valid, _)

proc call*(call_21626102: Call_CreateTags_21626089; resourceArn: string;
          body: JsonNode): Recallable =
  ## createTags
  ## Add a tag to a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource tag.
  ##   body: JObject (required)
  var path_21626103 = newJObject()
  var body_21626104 = newJObject()
  add(path_21626103, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_21626104 = body
  result = call_21626102.call(path_21626103, nil, nil, nil, body_21626104)

var createTags* = Call_CreateTags_21626089(name: "createTags",
                                        meth: HttpMethod.HttpPost,
                                        host: "mq.amazonaws.com",
                                        route: "/v1/tags/{resource-arn}",
                                        validator: validate_CreateTags_21626090,
                                        base: "/", makeUrl: url_CreateTags_21626091,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_21626062 = ref object of OpenApiRestCall_21625435
proc url_ListTags_21626064(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTags_21626063(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists tags for a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The Amazon Resource Name (ARN) of the resource tag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_21626078 = path.getOrDefault("resource-arn")
  valid_21626078 = validateParameter(valid_21626078, JString, required = true,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "resource-arn", valid_21626078
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626079 = header.getOrDefault("X-Amz-Date")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-Date", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Security-Token", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Algorithm", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-Signature")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-Signature", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-Credential")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-Credential", valid_21626085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626086: Call_ListTags_21626062; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists tags for a resource.
  ## 
  let valid = call_21626086.validator(path, query, header, formData, body, _)
  let scheme = call_21626086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626086.makeUrl(scheme.get, call_21626086.host, call_21626086.base,
                               call_21626086.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626086, uri, valid, _)

proc call*(call_21626087: Call_ListTags_21626062; resourceArn: string): Recallable =
  ## listTags
  ## Lists tags for a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource tag.
  var path_21626088 = newJObject()
  add(path_21626088, "resource-arn", newJString(resourceArn))
  result = call_21626087.call(path_21626088, nil, nil, nil, nil)

var listTags* = Call_ListTags_21626062(name: "listTags", meth: HttpMethod.HttpGet,
                                    host: "mq.amazonaws.com",
                                    route: "/v1/tags/{resource-arn}",
                                    validator: validate_ListTags_21626063,
                                    base: "/", makeUrl: url_ListTags_21626064,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_21626120 = ref object of OpenApiRestCall_21625435
proc url_UpdateUser_21626122(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "broker-id" in path, "`broker-id` is a required path parameter"
  assert "username" in path, "`username` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/brokers/"),
               (kind: VariableSegment, value: "broker-id"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "username")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUser_21626121(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the information for an ActiveMQ user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   broker-id: JString (required)
  ##            : The unique ID that Amazon MQ generates for the broker.
  ##   username: JString (required)
  ##           : Required. The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `broker-id` field"
  var valid_21626123 = path.getOrDefault("broker-id")
  valid_21626123 = validateParameter(valid_21626123, JString, required = true,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "broker-id", valid_21626123
  var valid_21626124 = path.getOrDefault("username")
  valid_21626124 = validateParameter(valid_21626124, JString, required = true,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "username", valid_21626124
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626125 = header.getOrDefault("X-Amz-Date")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Date", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Security-Token", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-Algorithm", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Signature")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Signature", valid_21626129
  var valid_21626130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626130
  var valid_21626131 = header.getOrDefault("X-Amz-Credential")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "X-Amz-Credential", valid_21626131
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

proc call*(call_21626133: Call_UpdateUser_21626120; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the information for an ActiveMQ user.
  ## 
  let valid = call_21626133.validator(path, query, header, formData, body, _)
  let scheme = call_21626133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626133.makeUrl(scheme.get, call_21626133.host, call_21626133.base,
                               call_21626133.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626133, uri, valid, _)

proc call*(call_21626134: Call_UpdateUser_21626120; brokerId: string;
          username: string; body: JsonNode): Recallable =
  ## updateUser
  ## Updates the information for an ActiveMQ user.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   username: string (required)
  ##           : Required. The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  ##   body: JObject (required)
  var path_21626135 = newJObject()
  var body_21626136 = newJObject()
  add(path_21626135, "broker-id", newJString(brokerId))
  add(path_21626135, "username", newJString(username))
  if body != nil:
    body_21626136 = body
  result = call_21626134.call(path_21626135, nil, nil, nil, body_21626136)

var updateUser* = Call_UpdateUser_21626120(name: "updateUser",
                                        meth: HttpMethod.HttpPut,
                                        host: "mq.amazonaws.com", route: "/v1/brokers/{broker-id}/users/{username}",
                                        validator: validate_UpdateUser_21626121,
                                        base: "/", makeUrl: url_UpdateUser_21626122,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_21626137 = ref object of OpenApiRestCall_21625435
proc url_CreateUser_21626139(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "broker-id" in path, "`broker-id` is a required path parameter"
  assert "username" in path, "`username` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/brokers/"),
               (kind: VariableSegment, value: "broker-id"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "username")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateUser_21626138(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an ActiveMQ user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   broker-id: JString (required)
  ##            : The unique ID that Amazon MQ generates for the broker.
  ##   username: JString (required)
  ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `broker-id` field"
  var valid_21626140 = path.getOrDefault("broker-id")
  valid_21626140 = validateParameter(valid_21626140, JString, required = true,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "broker-id", valid_21626140
  var valid_21626141 = path.getOrDefault("username")
  valid_21626141 = validateParameter(valid_21626141, JString, required = true,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "username", valid_21626141
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626142 = header.getOrDefault("X-Amz-Date")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Date", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-Security-Token", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626144
  var valid_21626145 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-Algorithm", valid_21626145
  var valid_21626146 = header.getOrDefault("X-Amz-Signature")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-Signature", valid_21626146
  var valid_21626147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626147 = validateParameter(valid_21626147, JString, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626147
  var valid_21626148 = header.getOrDefault("X-Amz-Credential")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "X-Amz-Credential", valid_21626148
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

proc call*(call_21626150: Call_CreateUser_21626137; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an ActiveMQ user.
  ## 
  let valid = call_21626150.validator(path, query, header, formData, body, _)
  let scheme = call_21626150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626150.makeUrl(scheme.get, call_21626150.host, call_21626150.base,
                               call_21626150.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626150, uri, valid, _)

proc call*(call_21626151: Call_CreateUser_21626137; brokerId: string;
          username: string; body: JsonNode): Recallable =
  ## createUser
  ## Creates an ActiveMQ user.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   username: string (required)
  ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  ##   body: JObject (required)
  var path_21626152 = newJObject()
  var body_21626153 = newJObject()
  add(path_21626152, "broker-id", newJString(brokerId))
  add(path_21626152, "username", newJString(username))
  if body != nil:
    body_21626153 = body
  result = call_21626151.call(path_21626152, nil, nil, nil, body_21626153)

var createUser* = Call_CreateUser_21626137(name: "createUser",
                                        meth: HttpMethod.HttpPost,
                                        host: "mq.amazonaws.com", route: "/v1/brokers/{broker-id}/users/{username}",
                                        validator: validate_CreateUser_21626138,
                                        base: "/", makeUrl: url_CreateUser_21626139,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_21626105 = ref object of OpenApiRestCall_21625435
proc url_DescribeUser_21626107(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "broker-id" in path, "`broker-id` is a required path parameter"
  assert "username" in path, "`username` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/brokers/"),
               (kind: VariableSegment, value: "broker-id"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "username")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeUser_21626106(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Returns information about an ActiveMQ user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   broker-id: JString (required)
  ##            : The unique ID that Amazon MQ generates for the broker.
  ##   username: JString (required)
  ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `broker-id` field"
  var valid_21626108 = path.getOrDefault("broker-id")
  valid_21626108 = validateParameter(valid_21626108, JString, required = true,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "broker-id", valid_21626108
  var valid_21626109 = path.getOrDefault("username")
  valid_21626109 = validateParameter(valid_21626109, JString, required = true,
                                   default = nil)
  if valid_21626109 != nil:
    section.add "username", valid_21626109
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626110 = header.getOrDefault("X-Amz-Date")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Date", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Security-Token", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-Algorithm", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Signature")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Signature", valid_21626114
  var valid_21626115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-Credential")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-Credential", valid_21626116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626117: Call_DescribeUser_21626105; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about an ActiveMQ user.
  ## 
  let valid = call_21626117.validator(path, query, header, formData, body, _)
  let scheme = call_21626117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626117.makeUrl(scheme.get, call_21626117.host, call_21626117.base,
                               call_21626117.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626117, uri, valid, _)

proc call*(call_21626118: Call_DescribeUser_21626105; brokerId: string;
          username: string): Recallable =
  ## describeUser
  ## Returns information about an ActiveMQ user.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   username: string (required)
  ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  var path_21626119 = newJObject()
  add(path_21626119, "broker-id", newJString(brokerId))
  add(path_21626119, "username", newJString(username))
  result = call_21626118.call(path_21626119, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_21626105(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}/users/{username}",
    validator: validate_DescribeUser_21626106, base: "/", makeUrl: url_DescribeUser_21626107,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_21626154 = ref object of OpenApiRestCall_21625435
proc url_DeleteUser_21626156(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "broker-id" in path, "`broker-id` is a required path parameter"
  assert "username" in path, "`username` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/brokers/"),
               (kind: VariableSegment, value: "broker-id"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "username")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteUser_21626155(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an ActiveMQ user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   broker-id: JString (required)
  ##            : The unique ID that Amazon MQ generates for the broker.
  ##   username: JString (required)
  ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `broker-id` field"
  var valid_21626157 = path.getOrDefault("broker-id")
  valid_21626157 = validateParameter(valid_21626157, JString, required = true,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "broker-id", valid_21626157
  var valid_21626158 = path.getOrDefault("username")
  valid_21626158 = validateParameter(valid_21626158, JString, required = true,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "username", valid_21626158
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626159 = header.getOrDefault("X-Amz-Date")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Date", valid_21626159
  var valid_21626160 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "X-Amz-Security-Token", valid_21626160
  var valid_21626161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626161
  var valid_21626162 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "X-Amz-Algorithm", valid_21626162
  var valid_21626163 = header.getOrDefault("X-Amz-Signature")
  valid_21626163 = validateParameter(valid_21626163, JString, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "X-Amz-Signature", valid_21626163
  var valid_21626164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626164
  var valid_21626165 = header.getOrDefault("X-Amz-Credential")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "X-Amz-Credential", valid_21626165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626166: Call_DeleteUser_21626154; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an ActiveMQ user.
  ## 
  let valid = call_21626166.validator(path, query, header, formData, body, _)
  let scheme = call_21626166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626166.makeUrl(scheme.get, call_21626166.host, call_21626166.base,
                               call_21626166.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626166, uri, valid, _)

proc call*(call_21626167: Call_DeleteUser_21626154; brokerId: string;
          username: string): Recallable =
  ## deleteUser
  ## Deletes an ActiveMQ user.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   username: string (required)
  ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  var path_21626168 = newJObject()
  add(path_21626168, "broker-id", newJString(brokerId))
  add(path_21626168, "username", newJString(username))
  result = call_21626167.call(path_21626168, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_21626154(name: "deleteUser",
                                        meth: HttpMethod.HttpDelete,
                                        host: "mq.amazonaws.com", route: "/v1/brokers/{broker-id}/users/{username}",
                                        validator: validate_DeleteUser_21626155,
                                        base: "/", makeUrl: url_DeleteUser_21626156,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBroker_21626183 = ref object of OpenApiRestCall_21625435
proc url_UpdateBroker_21626185(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "broker-id" in path, "`broker-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/brokers/"),
               (kind: VariableSegment, value: "broker-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateBroker_21626184(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Adds a pending configuration change to a broker.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   broker-id: JString (required)
  ##            : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `broker-id` field"
  var valid_21626186 = path.getOrDefault("broker-id")
  valid_21626186 = validateParameter(valid_21626186, JString, required = true,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "broker-id", valid_21626186
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626187 = header.getOrDefault("X-Amz-Date")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Date", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-Security-Token", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626189
  var valid_21626190 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "X-Amz-Algorithm", valid_21626190
  var valid_21626191 = header.getOrDefault("X-Amz-Signature")
  valid_21626191 = validateParameter(valid_21626191, JString, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "X-Amz-Signature", valid_21626191
  var valid_21626192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626192
  var valid_21626193 = header.getOrDefault("X-Amz-Credential")
  valid_21626193 = validateParameter(valid_21626193, JString, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "X-Amz-Credential", valid_21626193
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

proc call*(call_21626195: Call_UpdateBroker_21626183; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a pending configuration change to a broker.
  ## 
  let valid = call_21626195.validator(path, query, header, formData, body, _)
  let scheme = call_21626195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626195.makeUrl(scheme.get, call_21626195.host, call_21626195.base,
                               call_21626195.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626195, uri, valid, _)

proc call*(call_21626196: Call_UpdateBroker_21626183; brokerId: string;
          body: JsonNode): Recallable =
  ## updateBroker
  ## Adds a pending configuration change to a broker.
  ##   brokerId: string (required)
  ##           : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  ##   body: JObject (required)
  var path_21626197 = newJObject()
  var body_21626198 = newJObject()
  add(path_21626197, "broker-id", newJString(brokerId))
  if body != nil:
    body_21626198 = body
  result = call_21626196.call(path_21626197, nil, nil, nil, body_21626198)

var updateBroker* = Call_UpdateBroker_21626183(name: "updateBroker",
    meth: HttpMethod.HttpPut, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}", validator: validate_UpdateBroker_21626184,
    base: "/", makeUrl: url_UpdateBroker_21626185,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBroker_21626169 = ref object of OpenApiRestCall_21625435
proc url_DescribeBroker_21626171(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "broker-id" in path, "`broker-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/brokers/"),
               (kind: VariableSegment, value: "broker-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeBroker_21626170(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about the specified broker.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   broker-id: JString (required)
  ##            : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `broker-id` field"
  var valid_21626172 = path.getOrDefault("broker-id")
  valid_21626172 = validateParameter(valid_21626172, JString, required = true,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "broker-id", valid_21626172
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626173 = header.getOrDefault("X-Amz-Date")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-Date", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Security-Token", valid_21626174
  var valid_21626175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626175 = validateParameter(valid_21626175, JString, required = false,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626175
  var valid_21626176 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626176 = validateParameter(valid_21626176, JString, required = false,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "X-Amz-Algorithm", valid_21626176
  var valid_21626177 = header.getOrDefault("X-Amz-Signature")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "X-Amz-Signature", valid_21626177
  var valid_21626178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626178
  var valid_21626179 = header.getOrDefault("X-Amz-Credential")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "X-Amz-Credential", valid_21626179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626180: Call_DescribeBroker_21626169; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the specified broker.
  ## 
  let valid = call_21626180.validator(path, query, header, formData, body, _)
  let scheme = call_21626180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626180.makeUrl(scheme.get, call_21626180.host, call_21626180.base,
                               call_21626180.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626180, uri, valid, _)

proc call*(call_21626181: Call_DescribeBroker_21626169; brokerId: string): Recallable =
  ## describeBroker
  ## Returns information about the specified broker.
  ##   brokerId: string (required)
  ##           : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  var path_21626182 = newJObject()
  add(path_21626182, "broker-id", newJString(brokerId))
  result = call_21626181.call(path_21626182, nil, nil, nil, nil)

var describeBroker* = Call_DescribeBroker_21626169(name: "describeBroker",
    meth: HttpMethod.HttpGet, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}", validator: validate_DescribeBroker_21626170,
    base: "/", makeUrl: url_DescribeBroker_21626171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBroker_21626199 = ref object of OpenApiRestCall_21625435
proc url_DeleteBroker_21626201(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "broker-id" in path, "`broker-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/brokers/"),
               (kind: VariableSegment, value: "broker-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBroker_21626200(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes a broker. Note: This API is asynchronous.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   broker-id: JString (required)
  ##            : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `broker-id` field"
  var valid_21626202 = path.getOrDefault("broker-id")
  valid_21626202 = validateParameter(valid_21626202, JString, required = true,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "broker-id", valid_21626202
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626203 = header.getOrDefault("X-Amz-Date")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-Date", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Security-Token", valid_21626204
  var valid_21626205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626205 = validateParameter(valid_21626205, JString, required = false,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626205
  var valid_21626206 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626206 = validateParameter(valid_21626206, JString, required = false,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "X-Amz-Algorithm", valid_21626206
  var valid_21626207 = header.getOrDefault("X-Amz-Signature")
  valid_21626207 = validateParameter(valid_21626207, JString, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "X-Amz-Signature", valid_21626207
  var valid_21626208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626208 = validateParameter(valid_21626208, JString, required = false,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626208
  var valid_21626209 = header.getOrDefault("X-Amz-Credential")
  valid_21626209 = validateParameter(valid_21626209, JString, required = false,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "X-Amz-Credential", valid_21626209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626210: Call_DeleteBroker_21626199; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a broker. Note: This API is asynchronous.
  ## 
  let valid = call_21626210.validator(path, query, header, formData, body, _)
  let scheme = call_21626210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626210.makeUrl(scheme.get, call_21626210.host, call_21626210.base,
                               call_21626210.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626210, uri, valid, _)

proc call*(call_21626211: Call_DeleteBroker_21626199; brokerId: string): Recallable =
  ## deleteBroker
  ## Deletes a broker. Note: This API is asynchronous.
  ##   brokerId: string (required)
  ##           : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  var path_21626212 = newJObject()
  add(path_21626212, "broker-id", newJString(brokerId))
  result = call_21626211.call(path_21626212, nil, nil, nil, nil)

var deleteBroker* = Call_DeleteBroker_21626199(name: "deleteBroker",
    meth: HttpMethod.HttpDelete, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}", validator: validate_DeleteBroker_21626200,
    base: "/", makeUrl: url_DeleteBroker_21626201,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_21626213 = ref object of OpenApiRestCall_21625435
proc url_DeleteTags_21626215(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resource-arn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteTags_21626214(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes a tag from a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The Amazon Resource Name (ARN) of the resource tag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_21626216 = path.getOrDefault("resource-arn")
  valid_21626216 = validateParameter(valid_21626216, JString, required = true,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "resource-arn", valid_21626216
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_21626217 = query.getOrDefault("tagKeys")
  valid_21626217 = validateParameter(valid_21626217, JArray, required = true,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "tagKeys", valid_21626217
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626218 = header.getOrDefault("X-Amz-Date")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-Date", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Security-Token", valid_21626219
  var valid_21626220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626220 = validateParameter(valid_21626220, JString, required = false,
                                   default = nil)
  if valid_21626220 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626220
  var valid_21626221 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626221 = validateParameter(valid_21626221, JString, required = false,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "X-Amz-Algorithm", valid_21626221
  var valid_21626222 = header.getOrDefault("X-Amz-Signature")
  valid_21626222 = validateParameter(valid_21626222, JString, required = false,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "X-Amz-Signature", valid_21626222
  var valid_21626223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626223 = validateParameter(valid_21626223, JString, required = false,
                                   default = nil)
  if valid_21626223 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626223
  var valid_21626224 = header.getOrDefault("X-Amz-Credential")
  valid_21626224 = validateParameter(valid_21626224, JString, required = false,
                                   default = nil)
  if valid_21626224 != nil:
    section.add "X-Amz-Credential", valid_21626224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626225: Call_DeleteTags_21626213; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a tag from a resource.
  ## 
  let valid = call_21626225.validator(path, query, header, formData, body, _)
  let scheme = call_21626225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626225.makeUrl(scheme.get, call_21626225.host, call_21626225.base,
                               call_21626225.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626225, uri, valid, _)

proc call*(call_21626226: Call_DeleteTags_21626213; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## deleteTags
  ## Removes a tag from a resource.
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource tag.
  var path_21626227 = newJObject()
  var query_21626228 = newJObject()
  if tagKeys != nil:
    query_21626228.add "tagKeys", tagKeys
  add(path_21626227, "resource-arn", newJString(resourceArn))
  result = call_21626226.call(path_21626227, query_21626228, nil, nil, nil)

var deleteTags* = Call_DeleteTags_21626213(name: "deleteTags",
                                        meth: HttpMethod.HttpDelete,
                                        host: "mq.amazonaws.com", route: "/v1/tags/{resource-arn}#tagKeys",
                                        validator: validate_DeleteTags_21626214,
                                        base: "/", makeUrl: url_DeleteTags_21626215,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBrokerEngineTypes_21626229 = ref object of OpenApiRestCall_21625435
proc url_DescribeBrokerEngineTypes_21626231(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeBrokerEngineTypes_21626230(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describe available engine types and versions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of engine types that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: JString
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   engineType: JString
  ##             : Filter response by engine type.
  section = newJObject()
  var valid_21626232 = query.getOrDefault("maxResults")
  valid_21626232 = validateParameter(valid_21626232, JInt, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "maxResults", valid_21626232
  var valid_21626233 = query.getOrDefault("nextToken")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "nextToken", valid_21626233
  var valid_21626234 = query.getOrDefault("engineType")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "engineType", valid_21626234
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626235 = header.getOrDefault("X-Amz-Date")
  valid_21626235 = validateParameter(valid_21626235, JString, required = false,
                                   default = nil)
  if valid_21626235 != nil:
    section.add "X-Amz-Date", valid_21626235
  var valid_21626236 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626236 = validateParameter(valid_21626236, JString, required = false,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "X-Amz-Security-Token", valid_21626236
  var valid_21626237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626237 = validateParameter(valid_21626237, JString, required = false,
                                   default = nil)
  if valid_21626237 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626237
  var valid_21626238 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626238 = validateParameter(valid_21626238, JString, required = false,
                                   default = nil)
  if valid_21626238 != nil:
    section.add "X-Amz-Algorithm", valid_21626238
  var valid_21626239 = header.getOrDefault("X-Amz-Signature")
  valid_21626239 = validateParameter(valid_21626239, JString, required = false,
                                   default = nil)
  if valid_21626239 != nil:
    section.add "X-Amz-Signature", valid_21626239
  var valid_21626240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626240 = validateParameter(valid_21626240, JString, required = false,
                                   default = nil)
  if valid_21626240 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626240
  var valid_21626241 = header.getOrDefault("X-Amz-Credential")
  valid_21626241 = validateParameter(valid_21626241, JString, required = false,
                                   default = nil)
  if valid_21626241 != nil:
    section.add "X-Amz-Credential", valid_21626241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626242: Call_DescribeBrokerEngineTypes_21626229;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describe available engine types and versions.
  ## 
  let valid = call_21626242.validator(path, query, header, formData, body, _)
  let scheme = call_21626242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626242.makeUrl(scheme.get, call_21626242.host, call_21626242.base,
                               call_21626242.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626242, uri, valid, _)

proc call*(call_21626243: Call_DescribeBrokerEngineTypes_21626229;
          maxResults: int = 0; nextToken: string = ""; engineType: string = ""): Recallable =
  ## describeBrokerEngineTypes
  ## Describe available engine types and versions.
  ##   maxResults: int
  ##             : The maximum number of engine types that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   engineType: string
  ##             : Filter response by engine type.
  var query_21626244 = newJObject()
  add(query_21626244, "maxResults", newJInt(maxResults))
  add(query_21626244, "nextToken", newJString(nextToken))
  add(query_21626244, "engineType", newJString(engineType))
  result = call_21626243.call(nil, query_21626244, nil, nil, nil)

var describeBrokerEngineTypes* = Call_DescribeBrokerEngineTypes_21626229(
    name: "describeBrokerEngineTypes", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/broker-engine-types",
    validator: validate_DescribeBrokerEngineTypes_21626230, base: "/",
    makeUrl: url_DescribeBrokerEngineTypes_21626231,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBrokerInstanceOptions_21626245 = ref object of OpenApiRestCall_21625435
proc url_DescribeBrokerInstanceOptions_21626247(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeBrokerInstanceOptions_21626246(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Describe available broker instance options.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   storageType: JString
  ##              : Filter response by storage type.
  ##   maxResults: JInt
  ##             : The maximum number of instance options that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: JString
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   hostInstanceType: JString
  ##                   : Filter response by host instance type.
  ##   engineType: JString
  ##             : Filter response by engine type.
  section = newJObject()
  var valid_21626248 = query.getOrDefault("storageType")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "storageType", valid_21626248
  var valid_21626249 = query.getOrDefault("maxResults")
  valid_21626249 = validateParameter(valid_21626249, JInt, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "maxResults", valid_21626249
  var valid_21626250 = query.getOrDefault("nextToken")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "nextToken", valid_21626250
  var valid_21626251 = query.getOrDefault("hostInstanceType")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "hostInstanceType", valid_21626251
  var valid_21626252 = query.getOrDefault("engineType")
  valid_21626252 = validateParameter(valid_21626252, JString, required = false,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "engineType", valid_21626252
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626253 = header.getOrDefault("X-Amz-Date")
  valid_21626253 = validateParameter(valid_21626253, JString, required = false,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "X-Amz-Date", valid_21626253
  var valid_21626254 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626254 = validateParameter(valid_21626254, JString, required = false,
                                   default = nil)
  if valid_21626254 != nil:
    section.add "X-Amz-Security-Token", valid_21626254
  var valid_21626255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626255 = validateParameter(valid_21626255, JString, required = false,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626255
  var valid_21626256 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626256 = validateParameter(valid_21626256, JString, required = false,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "X-Amz-Algorithm", valid_21626256
  var valid_21626257 = header.getOrDefault("X-Amz-Signature")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-Signature", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-Credential")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "X-Amz-Credential", valid_21626259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626260: Call_DescribeBrokerInstanceOptions_21626245;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describe available broker instance options.
  ## 
  let valid = call_21626260.validator(path, query, header, formData, body, _)
  let scheme = call_21626260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626260.makeUrl(scheme.get, call_21626260.host, call_21626260.base,
                               call_21626260.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626260, uri, valid, _)

proc call*(call_21626261: Call_DescribeBrokerInstanceOptions_21626245;
          storageType: string = ""; maxResults: int = 0; nextToken: string = "";
          hostInstanceType: string = ""; engineType: string = ""): Recallable =
  ## describeBrokerInstanceOptions
  ## Describe available broker instance options.
  ##   storageType: string
  ##              : Filter response by storage type.
  ##   maxResults: int
  ##             : The maximum number of instance options that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   hostInstanceType: string
  ##                   : Filter response by host instance type.
  ##   engineType: string
  ##             : Filter response by engine type.
  var query_21626262 = newJObject()
  add(query_21626262, "storageType", newJString(storageType))
  add(query_21626262, "maxResults", newJInt(maxResults))
  add(query_21626262, "nextToken", newJString(nextToken))
  add(query_21626262, "hostInstanceType", newJString(hostInstanceType))
  add(query_21626262, "engineType", newJString(engineType))
  result = call_21626261.call(nil, query_21626262, nil, nil, nil)

var describeBrokerInstanceOptions* = Call_DescribeBrokerInstanceOptions_21626245(
    name: "describeBrokerInstanceOptions", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/broker-instance-options",
    validator: validate_DescribeBrokerInstanceOptions_21626246, base: "/",
    makeUrl: url_DescribeBrokerInstanceOptions_21626247,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfiguration_21626277 = ref object of OpenApiRestCall_21625435
proc url_UpdateConfiguration_21626279(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "configuration-id" in path,
        "`configuration-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/configurations/"),
               (kind: VariableSegment, value: "configuration-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateConfiguration_21626278(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the specified configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   configuration-id: JString (required)
  ##                   : The unique ID that Amazon MQ generates for the configuration.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `configuration-id` field"
  var valid_21626280 = path.getOrDefault("configuration-id")
  valid_21626280 = validateParameter(valid_21626280, JString, required = true,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "configuration-id", valid_21626280
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626281 = header.getOrDefault("X-Amz-Date")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-Date", valid_21626281
  var valid_21626282 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "X-Amz-Security-Token", valid_21626282
  var valid_21626283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626283
  var valid_21626284 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "X-Amz-Algorithm", valid_21626284
  var valid_21626285 = header.getOrDefault("X-Amz-Signature")
  valid_21626285 = validateParameter(valid_21626285, JString, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "X-Amz-Signature", valid_21626285
  var valid_21626286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626286 = validateParameter(valid_21626286, JString, required = false,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626286
  var valid_21626287 = header.getOrDefault("X-Amz-Credential")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Credential", valid_21626287
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

proc call*(call_21626289: Call_UpdateConfiguration_21626277; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the specified configuration.
  ## 
  let valid = call_21626289.validator(path, query, header, formData, body, _)
  let scheme = call_21626289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626289.makeUrl(scheme.get, call_21626289.host, call_21626289.base,
                               call_21626289.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626289, uri, valid, _)

proc call*(call_21626290: Call_UpdateConfiguration_21626277; body: JsonNode;
          configurationId: string): Recallable =
  ## updateConfiguration
  ## Updates the specified configuration.
  ##   body: JObject (required)
  ##   configurationId: string (required)
  ##                  : The unique ID that Amazon MQ generates for the configuration.
  var path_21626291 = newJObject()
  var body_21626292 = newJObject()
  if body != nil:
    body_21626292 = body
  add(path_21626291, "configuration-id", newJString(configurationId))
  result = call_21626290.call(path_21626291, nil, nil, nil, body_21626292)

var updateConfiguration* = Call_UpdateConfiguration_21626277(
    name: "updateConfiguration", meth: HttpMethod.HttpPut, host: "mq.amazonaws.com",
    route: "/v1/configurations/{configuration-id}",
    validator: validate_UpdateConfiguration_21626278, base: "/",
    makeUrl: url_UpdateConfiguration_21626279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfiguration_21626263 = ref object of OpenApiRestCall_21625435
proc url_DescribeConfiguration_21626265(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "configuration-id" in path,
        "`configuration-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/configurations/"),
               (kind: VariableSegment, value: "configuration-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeConfiguration_21626264(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about the specified configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   configuration-id: JString (required)
  ##                   : The unique ID that Amazon MQ generates for the configuration.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `configuration-id` field"
  var valid_21626266 = path.getOrDefault("configuration-id")
  valid_21626266 = validateParameter(valid_21626266, JString, required = true,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "configuration-id", valid_21626266
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626267 = header.getOrDefault("X-Amz-Date")
  valid_21626267 = validateParameter(valid_21626267, JString, required = false,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "X-Amz-Date", valid_21626267
  var valid_21626268 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626268 = validateParameter(valid_21626268, JString, required = false,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "X-Amz-Security-Token", valid_21626268
  var valid_21626269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626269 = validateParameter(valid_21626269, JString, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626269
  var valid_21626270 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626270 = validateParameter(valid_21626270, JString, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "X-Amz-Algorithm", valid_21626270
  var valid_21626271 = header.getOrDefault("X-Amz-Signature")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "X-Amz-Signature", valid_21626271
  var valid_21626272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-Credential")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Credential", valid_21626273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626274: Call_DescribeConfiguration_21626263;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the specified configuration.
  ## 
  let valid = call_21626274.validator(path, query, header, formData, body, _)
  let scheme = call_21626274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626274.makeUrl(scheme.get, call_21626274.host, call_21626274.base,
                               call_21626274.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626274, uri, valid, _)

proc call*(call_21626275: Call_DescribeConfiguration_21626263;
          configurationId: string): Recallable =
  ## describeConfiguration
  ## Returns information about the specified configuration.
  ##   configurationId: string (required)
  ##                  : The unique ID that Amazon MQ generates for the configuration.
  var path_21626276 = newJObject()
  add(path_21626276, "configuration-id", newJString(configurationId))
  result = call_21626275.call(path_21626276, nil, nil, nil, nil)

var describeConfiguration* = Call_DescribeConfiguration_21626263(
    name: "describeConfiguration", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/configurations/{configuration-id}",
    validator: validate_DescribeConfiguration_21626264, base: "/",
    makeUrl: url_DescribeConfiguration_21626265,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationRevision_21626293 = ref object of OpenApiRestCall_21625435
proc url_DescribeConfigurationRevision_21626295(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "configuration-id" in path,
        "`configuration-id` is a required path parameter"
  assert "configuration-revision" in path,
        "`configuration-revision` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/configurations/"),
               (kind: VariableSegment, value: "configuration-id"),
               (kind: ConstantSegment, value: "/revisions/"),
               (kind: VariableSegment, value: "configuration-revision")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeConfigurationRevision_21626294(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns the specified configuration revision for the specified configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   configuration-revision: JString (required)
  ##                         : The revision of the configuration.
  ##   configuration-id: JString (required)
  ##                   : The unique ID that Amazon MQ generates for the configuration.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `configuration-revision` field"
  var valid_21626296 = path.getOrDefault("configuration-revision")
  valid_21626296 = validateParameter(valid_21626296, JString, required = true,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "configuration-revision", valid_21626296
  var valid_21626297 = path.getOrDefault("configuration-id")
  valid_21626297 = validateParameter(valid_21626297, JString, required = true,
                                   default = nil)
  if valid_21626297 != nil:
    section.add "configuration-id", valid_21626297
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626298 = header.getOrDefault("X-Amz-Date")
  valid_21626298 = validateParameter(valid_21626298, JString, required = false,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "X-Amz-Date", valid_21626298
  var valid_21626299 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626299 = validateParameter(valid_21626299, JString, required = false,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "X-Amz-Security-Token", valid_21626299
  var valid_21626300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626300 = validateParameter(valid_21626300, JString, required = false,
                                   default = nil)
  if valid_21626300 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626300
  var valid_21626301 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626301 = validateParameter(valid_21626301, JString, required = false,
                                   default = nil)
  if valid_21626301 != nil:
    section.add "X-Amz-Algorithm", valid_21626301
  var valid_21626302 = header.getOrDefault("X-Amz-Signature")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-Signature", valid_21626302
  var valid_21626303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Credential")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-Credential", valid_21626304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626305: Call_DescribeConfigurationRevision_21626293;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the specified configuration revision for the specified configuration.
  ## 
  let valid = call_21626305.validator(path, query, header, formData, body, _)
  let scheme = call_21626305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626305.makeUrl(scheme.get, call_21626305.host, call_21626305.base,
                               call_21626305.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626305, uri, valid, _)

proc call*(call_21626306: Call_DescribeConfigurationRevision_21626293;
          configurationRevision: string; configurationId: string): Recallable =
  ## describeConfigurationRevision
  ## Returns the specified configuration revision for the specified configuration.
  ##   configurationRevision: string (required)
  ##                        : The revision of the configuration.
  ##   configurationId: string (required)
  ##                  : The unique ID that Amazon MQ generates for the configuration.
  var path_21626307 = newJObject()
  add(path_21626307, "configuration-revision", newJString(configurationRevision))
  add(path_21626307, "configuration-id", newJString(configurationId))
  result = call_21626306.call(path_21626307, nil, nil, nil, nil)

var describeConfigurationRevision* = Call_DescribeConfigurationRevision_21626293(
    name: "describeConfigurationRevision", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/configurations/{configuration-id}/revisions/{configuration-revision}",
    validator: validate_DescribeConfigurationRevision_21626294, base: "/",
    makeUrl: url_DescribeConfigurationRevision_21626295,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationRevisions_21626308 = ref object of OpenApiRestCall_21625435
proc url_ListConfigurationRevisions_21626310(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "configuration-id" in path,
        "`configuration-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/configurations/"),
               (kind: VariableSegment, value: "configuration-id"),
               (kind: ConstantSegment, value: "/revisions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListConfigurationRevisions_21626309(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of all revisions for the specified configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   configuration-id: JString (required)
  ##                   : The unique ID that Amazon MQ generates for the configuration.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `configuration-id` field"
  var valid_21626311 = path.getOrDefault("configuration-id")
  valid_21626311 = validateParameter(valid_21626311, JString, required = true,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "configuration-id", valid_21626311
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of configurations that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: JString
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  section = newJObject()
  var valid_21626312 = query.getOrDefault("maxResults")
  valid_21626312 = validateParameter(valid_21626312, JInt, required = false,
                                   default = nil)
  if valid_21626312 != nil:
    section.add "maxResults", valid_21626312
  var valid_21626313 = query.getOrDefault("nextToken")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "nextToken", valid_21626313
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626314 = header.getOrDefault("X-Amz-Date")
  valid_21626314 = validateParameter(valid_21626314, JString, required = false,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "X-Amz-Date", valid_21626314
  var valid_21626315 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626315 = validateParameter(valid_21626315, JString, required = false,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "X-Amz-Security-Token", valid_21626315
  var valid_21626316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626316 = validateParameter(valid_21626316, JString, required = false,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626316
  var valid_21626317 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Algorithm", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-Signature")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-Signature", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-Credential")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Credential", valid_21626320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626321: Call_ListConfigurationRevisions_21626308;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of all revisions for the specified configuration.
  ## 
  let valid = call_21626321.validator(path, query, header, formData, body, _)
  let scheme = call_21626321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626321.makeUrl(scheme.get, call_21626321.host, call_21626321.base,
                               call_21626321.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626321, uri, valid, _)

proc call*(call_21626322: Call_ListConfigurationRevisions_21626308;
          configurationId: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listConfigurationRevisions
  ## Returns a list of all revisions for the specified configuration.
  ##   maxResults: int
  ##             : The maximum number of configurations that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   configurationId: string (required)
  ##                  : The unique ID that Amazon MQ generates for the configuration.
  var path_21626323 = newJObject()
  var query_21626324 = newJObject()
  add(query_21626324, "maxResults", newJInt(maxResults))
  add(query_21626324, "nextToken", newJString(nextToken))
  add(path_21626323, "configuration-id", newJString(configurationId))
  result = call_21626322.call(path_21626323, query_21626324, nil, nil, nil)

var listConfigurationRevisions* = Call_ListConfigurationRevisions_21626308(
    name: "listConfigurationRevisions", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com",
    route: "/v1/configurations/{configuration-id}/revisions",
    validator: validate_ListConfigurationRevisions_21626309, base: "/",
    makeUrl: url_ListConfigurationRevisions_21626310,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_21626325 = ref object of OpenApiRestCall_21625435
proc url_ListUsers_21626327(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "broker-id" in path, "`broker-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/brokers/"),
               (kind: VariableSegment, value: "broker-id"),
               (kind: ConstantSegment, value: "/users")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListUsers_21626326(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of all ActiveMQ users.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   broker-id: JString (required)
  ##            : The unique ID that Amazon MQ generates for the broker.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `broker-id` field"
  var valid_21626328 = path.getOrDefault("broker-id")
  valid_21626328 = validateParameter(valid_21626328, JString, required = true,
                                   default = nil)
  if valid_21626328 != nil:
    section.add "broker-id", valid_21626328
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of ActiveMQ users that can be returned per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: JString
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  section = newJObject()
  var valid_21626329 = query.getOrDefault("maxResults")
  valid_21626329 = validateParameter(valid_21626329, JInt, required = false,
                                   default = nil)
  if valid_21626329 != nil:
    section.add "maxResults", valid_21626329
  var valid_21626330 = query.getOrDefault("nextToken")
  valid_21626330 = validateParameter(valid_21626330, JString, required = false,
                                   default = nil)
  if valid_21626330 != nil:
    section.add "nextToken", valid_21626330
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626331 = header.getOrDefault("X-Amz-Date")
  valid_21626331 = validateParameter(valid_21626331, JString, required = false,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "X-Amz-Date", valid_21626331
  var valid_21626332 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Security-Token", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "X-Amz-Algorithm", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Signature")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Signature", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Credential")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Credential", valid_21626337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626338: Call_ListUsers_21626325; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of all ActiveMQ users.
  ## 
  let valid = call_21626338.validator(path, query, header, formData, body, _)
  let scheme = call_21626338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626338.makeUrl(scheme.get, call_21626338.host, call_21626338.base,
                               call_21626338.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626338, uri, valid, _)

proc call*(call_21626339: Call_ListUsers_21626325; brokerId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listUsers
  ## Returns a list of all ActiveMQ users.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   maxResults: int
  ##             : The maximum number of ActiveMQ users that can be returned per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  var path_21626340 = newJObject()
  var query_21626341 = newJObject()
  add(path_21626340, "broker-id", newJString(brokerId))
  add(query_21626341, "maxResults", newJInt(maxResults))
  add(query_21626341, "nextToken", newJString(nextToken))
  result = call_21626339.call(path_21626340, query_21626341, nil, nil, nil)

var listUsers* = Call_ListUsers_21626325(name: "listUsers", meth: HttpMethod.HttpGet,
                                      host: "mq.amazonaws.com",
                                      route: "/v1/brokers/{broker-id}/users",
                                      validator: validate_ListUsers_21626326,
                                      base: "/", makeUrl: url_ListUsers_21626327,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootBroker_21626342 = ref object of OpenApiRestCall_21625435
proc url_RebootBroker_21626344(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "broker-id" in path, "`broker-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/brokers/"),
               (kind: VariableSegment, value: "broker-id"),
               (kind: ConstantSegment, value: "/reboot")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RebootBroker_21626343(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Reboots a broker. Note: This API is asynchronous.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   broker-id: JString (required)
  ##            : The unique ID that Amazon MQ generates for the broker.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `broker-id` field"
  var valid_21626345 = path.getOrDefault("broker-id")
  valid_21626345 = validateParameter(valid_21626345, JString, required = true,
                                   default = nil)
  if valid_21626345 != nil:
    section.add "broker-id", valid_21626345
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626346 = header.getOrDefault("X-Amz-Date")
  valid_21626346 = validateParameter(valid_21626346, JString, required = false,
                                   default = nil)
  if valid_21626346 != nil:
    section.add "X-Amz-Date", valid_21626346
  var valid_21626347 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Security-Token", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Algorithm", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Signature")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Signature", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Credential")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Credential", valid_21626352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626353: Call_RebootBroker_21626342; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Reboots a broker. Note: This API is asynchronous.
  ## 
  let valid = call_21626353.validator(path, query, header, formData, body, _)
  let scheme = call_21626353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626353.makeUrl(scheme.get, call_21626353.host, call_21626353.base,
                               call_21626353.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626353, uri, valid, _)

proc call*(call_21626354: Call_RebootBroker_21626342; brokerId: string): Recallable =
  ## rebootBroker
  ## Reboots a broker. Note: This API is asynchronous.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  var path_21626355 = newJObject()
  add(path_21626355, "broker-id", newJString(brokerId))
  result = call_21626354.call(path_21626355, nil, nil, nil, nil)

var rebootBroker* = Call_RebootBroker_21626342(name: "rebootBroker",
    meth: HttpMethod.HttpPost, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}/reboot", validator: validate_RebootBroker_21626343,
    base: "/", makeUrl: url_RebootBroker_21626344,
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