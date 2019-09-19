
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateBroker_601025 = ref object of OpenApiRestCall_600426
proc url_CreateBroker_601027(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateBroker_601026(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601028 = header.getOrDefault("X-Amz-Date")
  valid_601028 = validateParameter(valid_601028, JString, required = false,
                                 default = nil)
  if valid_601028 != nil:
    section.add "X-Amz-Date", valid_601028
  var valid_601029 = header.getOrDefault("X-Amz-Security-Token")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-Security-Token", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-Content-Sha256", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-Algorithm")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-Algorithm", valid_601031
  var valid_601032 = header.getOrDefault("X-Amz-Signature")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-Signature", valid_601032
  var valid_601033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601033 = validateParameter(valid_601033, JString, required = false,
                                 default = nil)
  if valid_601033 != nil:
    section.add "X-Amz-SignedHeaders", valid_601033
  var valid_601034 = header.getOrDefault("X-Amz-Credential")
  valid_601034 = validateParameter(valid_601034, JString, required = false,
                                 default = nil)
  if valid_601034 != nil:
    section.add "X-Amz-Credential", valid_601034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601036: Call_CreateBroker_601025; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a broker. Note: This API is asynchronous.
  ## 
  let valid = call_601036.validator(path, query, header, formData, body)
  let scheme = call_601036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601036.url(scheme.get, call_601036.host, call_601036.base,
                         call_601036.route, valid.getOrDefault("path"))
  result = hook(call_601036, url, valid)

proc call*(call_601037: Call_CreateBroker_601025; body: JsonNode): Recallable =
  ## createBroker
  ## Creates a broker. Note: This API is asynchronous.
  ##   body: JObject (required)
  var body_601038 = newJObject()
  if body != nil:
    body_601038 = body
  result = call_601037.call(nil, nil, nil, nil, body_601038)

var createBroker* = Call_CreateBroker_601025(name: "createBroker",
    meth: HttpMethod.HttpPost, host: "mq.amazonaws.com", route: "/v1/brokers",
    validator: validate_CreateBroker_601026, base: "/", url: url_CreateBroker_601027,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBrokers_600768 = ref object of OpenApiRestCall_600426
proc url_ListBrokers_600770(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListBrokers_600769(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600882 = query.getOrDefault("maxResults")
  valid_600882 = validateParameter(valid_600882, JInt, required = false, default = nil)
  if valid_600882 != nil:
    section.add "maxResults", valid_600882
  var valid_600883 = query.getOrDefault("nextToken")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "nextToken", valid_600883
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
  var valid_600884 = header.getOrDefault("X-Amz-Date")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-Date", valid_600884
  var valid_600885 = header.getOrDefault("X-Amz-Security-Token")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-Security-Token", valid_600885
  var valid_600886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Content-Sha256", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-Algorithm")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-Algorithm", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Signature")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Signature", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-SignedHeaders", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Credential")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Credential", valid_600890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600913: Call_ListBrokers_600768; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all brokers.
  ## 
  let valid = call_600913.validator(path, query, header, formData, body)
  let scheme = call_600913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600913.url(scheme.get, call_600913.host, call_600913.base,
                         call_600913.route, valid.getOrDefault("path"))
  result = hook(call_600913, url, valid)

proc call*(call_600984: Call_ListBrokers_600768; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listBrokers
  ## Returns a list of all brokers.
  ##   maxResults: int
  ##             : The maximum number of brokers that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  var query_600985 = newJObject()
  add(query_600985, "maxResults", newJInt(maxResults))
  add(query_600985, "nextToken", newJString(nextToken))
  result = call_600984.call(nil, query_600985, nil, nil, nil)

var listBrokers* = Call_ListBrokers_600768(name: "listBrokers",
                                        meth: HttpMethod.HttpGet,
                                        host: "mq.amazonaws.com",
                                        route: "/v1/brokers",
                                        validator: validate_ListBrokers_600769,
                                        base: "/", url: url_ListBrokers_600770,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfiguration_601054 = ref object of OpenApiRestCall_600426
proc url_CreateConfiguration_601056(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateConfiguration_601055(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_601057 = header.getOrDefault("X-Amz-Date")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Date", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Security-Token")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Security-Token", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Content-Sha256", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Algorithm")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Algorithm", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Signature")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Signature", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-SignedHeaders", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-Credential")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Credential", valid_601063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601065: Call_CreateConfiguration_601054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new configuration for the specified configuration name. Amazon MQ uses the default configuration (the engine type and version).
  ## 
  let valid = call_601065.validator(path, query, header, formData, body)
  let scheme = call_601065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601065.url(scheme.get, call_601065.host, call_601065.base,
                         call_601065.route, valid.getOrDefault("path"))
  result = hook(call_601065, url, valid)

proc call*(call_601066: Call_CreateConfiguration_601054; body: JsonNode): Recallable =
  ## createConfiguration
  ## Creates a new configuration for the specified configuration name. Amazon MQ uses the default configuration (the engine type and version).
  ##   body: JObject (required)
  var body_601067 = newJObject()
  if body != nil:
    body_601067 = body
  result = call_601066.call(nil, nil, nil, nil, body_601067)

var createConfiguration* = Call_CreateConfiguration_601054(
    name: "createConfiguration", meth: HttpMethod.HttpPost,
    host: "mq.amazonaws.com", route: "/v1/configurations",
    validator: validate_CreateConfiguration_601055, base: "/",
    url: url_CreateConfiguration_601056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurations_601039 = ref object of OpenApiRestCall_600426
proc url_ListConfigurations_601041(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListConfigurations_601040(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_601042 = query.getOrDefault("maxResults")
  valid_601042 = validateParameter(valid_601042, JInt, required = false, default = nil)
  if valid_601042 != nil:
    section.add "maxResults", valid_601042
  var valid_601043 = query.getOrDefault("nextToken")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "nextToken", valid_601043
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
  var valid_601044 = header.getOrDefault("X-Amz-Date")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Date", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Security-Token")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Security-Token", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Content-Sha256", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Algorithm")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Algorithm", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Signature")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Signature", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-SignedHeaders", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Credential")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Credential", valid_601050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601051: Call_ListConfigurations_601039; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all configurations.
  ## 
  let valid = call_601051.validator(path, query, header, formData, body)
  let scheme = call_601051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601051.url(scheme.get, call_601051.host, call_601051.base,
                         call_601051.route, valid.getOrDefault("path"))
  result = hook(call_601051, url, valid)

proc call*(call_601052: Call_ListConfigurations_601039; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listConfigurations
  ## Returns a list of all configurations.
  ##   maxResults: int
  ##             : The maximum number of configurations that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  var query_601053 = newJObject()
  add(query_601053, "maxResults", newJInt(maxResults))
  add(query_601053, "nextToken", newJString(nextToken))
  result = call_601052.call(nil, query_601053, nil, nil, nil)

var listConfigurations* = Call_ListConfigurations_601039(
    name: "listConfigurations", meth: HttpMethod.HttpGet, host: "mq.amazonaws.com",
    route: "/v1/configurations", validator: validate_ListConfigurations_601040,
    base: "/", url: url_ListConfigurations_601041,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_601096 = ref object of OpenApiRestCall_600426
proc url_CreateTags_601098(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateTags_601097(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601099 = path.getOrDefault("resource-arn")
  valid_601099 = validateParameter(valid_601099, JString, required = true,
                                 default = nil)
  if valid_601099 != nil:
    section.add "resource-arn", valid_601099
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
  var valid_601100 = header.getOrDefault("X-Amz-Date")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Date", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Security-Token")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Security-Token", valid_601101
  var valid_601102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-Content-Sha256", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Algorithm")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Algorithm", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Signature")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Signature", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-SignedHeaders", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Credential")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Credential", valid_601106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601108: Call_CreateTags_601096; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a tag to a resource.
  ## 
  let valid = call_601108.validator(path, query, header, formData, body)
  let scheme = call_601108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601108.url(scheme.get, call_601108.host, call_601108.base,
                         call_601108.route, valid.getOrDefault("path"))
  result = hook(call_601108, url, valid)

proc call*(call_601109: Call_CreateTags_601096; resourceArn: string; body: JsonNode): Recallable =
  ## createTags
  ## Add a tag to a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource tag.
  ##   body: JObject (required)
  var path_601110 = newJObject()
  var body_601111 = newJObject()
  add(path_601110, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_601111 = body
  result = call_601109.call(path_601110, nil, nil, nil, body_601111)

var createTags* = Call_CreateTags_601096(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "mq.amazonaws.com",
                                      route: "/v1/tags/{resource-arn}",
                                      validator: validate_CreateTags_601097,
                                      base: "/", url: url_CreateTags_601098,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_601068 = ref object of OpenApiRestCall_600426
proc url_ListTags_601070(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListTags_601069(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601085 = path.getOrDefault("resource-arn")
  valid_601085 = validateParameter(valid_601085, JString, required = true,
                                 default = nil)
  if valid_601085 != nil:
    section.add "resource-arn", valid_601085
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
  var valid_601086 = header.getOrDefault("X-Amz-Date")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Date", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-Security-Token")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Security-Token", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Content-Sha256", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Algorithm")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Algorithm", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Signature")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Signature", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-SignedHeaders", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Credential")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Credential", valid_601092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601093: Call_ListTags_601068; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists tags for a resource.
  ## 
  let valid = call_601093.validator(path, query, header, formData, body)
  let scheme = call_601093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601093.url(scheme.get, call_601093.host, call_601093.base,
                         call_601093.route, valid.getOrDefault("path"))
  result = hook(call_601093, url, valid)

proc call*(call_601094: Call_ListTags_601068; resourceArn: string): Recallable =
  ## listTags
  ## Lists tags for a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource tag.
  var path_601095 = newJObject()
  add(path_601095, "resource-arn", newJString(resourceArn))
  result = call_601094.call(path_601095, nil, nil, nil, nil)

var listTags* = Call_ListTags_601068(name: "listTags", meth: HttpMethod.HttpGet,
                                  host: "mq.amazonaws.com",
                                  route: "/v1/tags/{resource-arn}",
                                  validator: validate_ListTags_601069, base: "/",
                                  url: url_ListTags_601070,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_601127 = ref object of OpenApiRestCall_600426
proc url_UpdateUser_601129(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateUser_601128(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601130 = path.getOrDefault("broker-id")
  valid_601130 = validateParameter(valid_601130, JString, required = true,
                                 default = nil)
  if valid_601130 != nil:
    section.add "broker-id", valid_601130
  var valid_601131 = path.getOrDefault("username")
  valid_601131 = validateParameter(valid_601131, JString, required = true,
                                 default = nil)
  if valid_601131 != nil:
    section.add "username", valid_601131
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
  var valid_601132 = header.getOrDefault("X-Amz-Date")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-Date", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Security-Token")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Security-Token", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Content-Sha256", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Algorithm")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Algorithm", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-Signature")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Signature", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-SignedHeaders", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-Credential")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-Credential", valid_601138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601140: Call_UpdateUser_601127; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the information for an ActiveMQ user.
  ## 
  let valid = call_601140.validator(path, query, header, formData, body)
  let scheme = call_601140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601140.url(scheme.get, call_601140.host, call_601140.base,
                         call_601140.route, valid.getOrDefault("path"))
  result = hook(call_601140, url, valid)

proc call*(call_601141: Call_UpdateUser_601127; brokerId: string; username: string;
          body: JsonNode): Recallable =
  ## updateUser
  ## Updates the information for an ActiveMQ user.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   username: string (required)
  ##           : Required. The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  ##   body: JObject (required)
  var path_601142 = newJObject()
  var body_601143 = newJObject()
  add(path_601142, "broker-id", newJString(brokerId))
  add(path_601142, "username", newJString(username))
  if body != nil:
    body_601143 = body
  result = call_601141.call(path_601142, nil, nil, nil, body_601143)

var updateUser* = Call_UpdateUser_601127(name: "updateUser",
                                      meth: HttpMethod.HttpPut,
                                      host: "mq.amazonaws.com", route: "/v1/brokers/{broker-id}/users/{username}",
                                      validator: validate_UpdateUser_601128,
                                      base: "/", url: url_UpdateUser_601129,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_601144 = ref object of OpenApiRestCall_600426
proc url_CreateUser_601146(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateUser_601145(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601147 = path.getOrDefault("broker-id")
  valid_601147 = validateParameter(valid_601147, JString, required = true,
                                 default = nil)
  if valid_601147 != nil:
    section.add "broker-id", valid_601147
  var valid_601148 = path.getOrDefault("username")
  valid_601148 = validateParameter(valid_601148, JString, required = true,
                                 default = nil)
  if valid_601148 != nil:
    section.add "username", valid_601148
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
  var valid_601149 = header.getOrDefault("X-Amz-Date")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Date", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Security-Token")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Security-Token", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Content-Sha256", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Algorithm")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Algorithm", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-Signature")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-Signature", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-SignedHeaders", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Credential")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Credential", valid_601155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601157: Call_CreateUser_601144; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an ActiveMQ user.
  ## 
  let valid = call_601157.validator(path, query, header, formData, body)
  let scheme = call_601157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601157.url(scheme.get, call_601157.host, call_601157.base,
                         call_601157.route, valid.getOrDefault("path"))
  result = hook(call_601157, url, valid)

proc call*(call_601158: Call_CreateUser_601144; brokerId: string; username: string;
          body: JsonNode): Recallable =
  ## createUser
  ## Creates an ActiveMQ user.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   username: string (required)
  ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  ##   body: JObject (required)
  var path_601159 = newJObject()
  var body_601160 = newJObject()
  add(path_601159, "broker-id", newJString(brokerId))
  add(path_601159, "username", newJString(username))
  if body != nil:
    body_601160 = body
  result = call_601158.call(path_601159, nil, nil, nil, body_601160)

var createUser* = Call_CreateUser_601144(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "mq.amazonaws.com", route: "/v1/brokers/{broker-id}/users/{username}",
                                      validator: validate_CreateUser_601145,
                                      base: "/", url: url_CreateUser_601146,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_601112 = ref object of OpenApiRestCall_600426
proc url_DescribeUser_601114(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeUser_601113(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601115 = path.getOrDefault("broker-id")
  valid_601115 = validateParameter(valid_601115, JString, required = true,
                                 default = nil)
  if valid_601115 != nil:
    section.add "broker-id", valid_601115
  var valid_601116 = path.getOrDefault("username")
  valid_601116 = validateParameter(valid_601116, JString, required = true,
                                 default = nil)
  if valid_601116 != nil:
    section.add "username", valid_601116
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
  var valid_601117 = header.getOrDefault("X-Amz-Date")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "X-Amz-Date", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Security-Token")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Security-Token", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Content-Sha256", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Algorithm")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Algorithm", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-Signature")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Signature", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-SignedHeaders", valid_601122
  var valid_601123 = header.getOrDefault("X-Amz-Credential")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-Credential", valid_601123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601124: Call_DescribeUser_601112; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about an ActiveMQ user.
  ## 
  let valid = call_601124.validator(path, query, header, formData, body)
  let scheme = call_601124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601124.url(scheme.get, call_601124.host, call_601124.base,
                         call_601124.route, valid.getOrDefault("path"))
  result = hook(call_601124, url, valid)

proc call*(call_601125: Call_DescribeUser_601112; brokerId: string; username: string): Recallable =
  ## describeUser
  ## Returns information about an ActiveMQ user.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   username: string (required)
  ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  var path_601126 = newJObject()
  add(path_601126, "broker-id", newJString(brokerId))
  add(path_601126, "username", newJString(username))
  result = call_601125.call(path_601126, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_601112(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}/users/{username}",
    validator: validate_DescribeUser_601113, base: "/", url: url_DescribeUser_601114,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_601161 = ref object of OpenApiRestCall_600426
proc url_DeleteUser_601163(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteUser_601162(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601164 = path.getOrDefault("broker-id")
  valid_601164 = validateParameter(valid_601164, JString, required = true,
                                 default = nil)
  if valid_601164 != nil:
    section.add "broker-id", valid_601164
  var valid_601165 = path.getOrDefault("username")
  valid_601165 = validateParameter(valid_601165, JString, required = true,
                                 default = nil)
  if valid_601165 != nil:
    section.add "username", valid_601165
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
  var valid_601166 = header.getOrDefault("X-Amz-Date")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Date", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Security-Token")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Security-Token", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Content-Sha256", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Algorithm")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Algorithm", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Signature")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Signature", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-SignedHeaders", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-Credential")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-Credential", valid_601172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601173: Call_DeleteUser_601161; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an ActiveMQ user.
  ## 
  let valid = call_601173.validator(path, query, header, formData, body)
  let scheme = call_601173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601173.url(scheme.get, call_601173.host, call_601173.base,
                         call_601173.route, valid.getOrDefault("path"))
  result = hook(call_601173, url, valid)

proc call*(call_601174: Call_DeleteUser_601161; brokerId: string; username: string): Recallable =
  ## deleteUser
  ## Deletes an ActiveMQ user.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   username: string (required)
  ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  var path_601175 = newJObject()
  add(path_601175, "broker-id", newJString(brokerId))
  add(path_601175, "username", newJString(username))
  result = call_601174.call(path_601175, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_601161(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "mq.amazonaws.com", route: "/v1/brokers/{broker-id}/users/{username}",
                                      validator: validate_DeleteUser_601162,
                                      base: "/", url: url_DeleteUser_601163,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBroker_601190 = ref object of OpenApiRestCall_600426
proc url_UpdateBroker_601192(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "broker-id" in path, "`broker-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/brokers/"),
               (kind: VariableSegment, value: "broker-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateBroker_601191(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds a pending configuration change to a broker.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   broker-id: JString (required)
  ##            : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `broker-id` field"
  var valid_601193 = path.getOrDefault("broker-id")
  valid_601193 = validateParameter(valid_601193, JString, required = true,
                                 default = nil)
  if valid_601193 != nil:
    section.add "broker-id", valid_601193
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
  var valid_601194 = header.getOrDefault("X-Amz-Date")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Date", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Security-Token")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Security-Token", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Content-Sha256", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Algorithm")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Algorithm", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-Signature")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-Signature", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-SignedHeaders", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Credential")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Credential", valid_601200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601202: Call_UpdateBroker_601190; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a pending configuration change to a broker.
  ## 
  let valid = call_601202.validator(path, query, header, formData, body)
  let scheme = call_601202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601202.url(scheme.get, call_601202.host, call_601202.base,
                         call_601202.route, valid.getOrDefault("path"))
  result = hook(call_601202, url, valid)

proc call*(call_601203: Call_UpdateBroker_601190; brokerId: string; body: JsonNode): Recallable =
  ## updateBroker
  ## Adds a pending configuration change to a broker.
  ##   brokerId: string (required)
  ##           : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  ##   body: JObject (required)
  var path_601204 = newJObject()
  var body_601205 = newJObject()
  add(path_601204, "broker-id", newJString(brokerId))
  if body != nil:
    body_601205 = body
  result = call_601203.call(path_601204, nil, nil, nil, body_601205)

var updateBroker* = Call_UpdateBroker_601190(name: "updateBroker",
    meth: HttpMethod.HttpPut, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}", validator: validate_UpdateBroker_601191,
    base: "/", url: url_UpdateBroker_601192, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBroker_601176 = ref object of OpenApiRestCall_600426
proc url_DescribeBroker_601178(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "broker-id" in path, "`broker-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/brokers/"),
               (kind: VariableSegment, value: "broker-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeBroker_601177(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns information about the specified broker.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   broker-id: JString (required)
  ##            : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `broker-id` field"
  var valid_601179 = path.getOrDefault("broker-id")
  valid_601179 = validateParameter(valid_601179, JString, required = true,
                                 default = nil)
  if valid_601179 != nil:
    section.add "broker-id", valid_601179
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
  var valid_601180 = header.getOrDefault("X-Amz-Date")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Date", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-Security-Token")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Security-Token", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Content-Sha256", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Algorithm")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Algorithm", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Signature")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Signature", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-SignedHeaders", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Credential")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Credential", valid_601186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601187: Call_DescribeBroker_601176; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified broker.
  ## 
  let valid = call_601187.validator(path, query, header, formData, body)
  let scheme = call_601187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601187.url(scheme.get, call_601187.host, call_601187.base,
                         call_601187.route, valid.getOrDefault("path"))
  result = hook(call_601187, url, valid)

proc call*(call_601188: Call_DescribeBroker_601176; brokerId: string): Recallable =
  ## describeBroker
  ## Returns information about the specified broker.
  ##   brokerId: string (required)
  ##           : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  var path_601189 = newJObject()
  add(path_601189, "broker-id", newJString(brokerId))
  result = call_601188.call(path_601189, nil, nil, nil, nil)

var describeBroker* = Call_DescribeBroker_601176(name: "describeBroker",
    meth: HttpMethod.HttpGet, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}", validator: validate_DescribeBroker_601177,
    base: "/", url: url_DescribeBroker_601178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBroker_601206 = ref object of OpenApiRestCall_600426
proc url_DeleteBroker_601208(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "broker-id" in path, "`broker-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/brokers/"),
               (kind: VariableSegment, value: "broker-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteBroker_601207(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a broker. Note: This API is asynchronous.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   broker-id: JString (required)
  ##            : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `broker-id` field"
  var valid_601209 = path.getOrDefault("broker-id")
  valid_601209 = validateParameter(valid_601209, JString, required = true,
                                 default = nil)
  if valid_601209 != nil:
    section.add "broker-id", valid_601209
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
  var valid_601210 = header.getOrDefault("X-Amz-Date")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Date", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-Security-Token")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-Security-Token", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Content-Sha256", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-Algorithm")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-Algorithm", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-Signature")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Signature", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-SignedHeaders", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Credential")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Credential", valid_601216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601217: Call_DeleteBroker_601206; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a broker. Note: This API is asynchronous.
  ## 
  let valid = call_601217.validator(path, query, header, formData, body)
  let scheme = call_601217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601217.url(scheme.get, call_601217.host, call_601217.base,
                         call_601217.route, valid.getOrDefault("path"))
  result = hook(call_601217, url, valid)

proc call*(call_601218: Call_DeleteBroker_601206; brokerId: string): Recallable =
  ## deleteBroker
  ## Deletes a broker. Note: This API is asynchronous.
  ##   brokerId: string (required)
  ##           : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  var path_601219 = newJObject()
  add(path_601219, "broker-id", newJString(brokerId))
  result = call_601218.call(path_601219, nil, nil, nil, nil)

var deleteBroker* = Call_DeleteBroker_601206(name: "deleteBroker",
    meth: HttpMethod.HttpDelete, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}", validator: validate_DeleteBroker_601207,
    base: "/", url: url_DeleteBroker_601208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_601220 = ref object of OpenApiRestCall_600426
proc url_DeleteTags_601222(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resource-arn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteTags_601221(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601223 = path.getOrDefault("resource-arn")
  valid_601223 = validateParameter(valid_601223, JString, required = true,
                                 default = nil)
  if valid_601223 != nil:
    section.add "resource-arn", valid_601223
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_601224 = query.getOrDefault("tagKeys")
  valid_601224 = validateParameter(valid_601224, JArray, required = true, default = nil)
  if valid_601224 != nil:
    section.add "tagKeys", valid_601224
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
  var valid_601225 = header.getOrDefault("X-Amz-Date")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-Date", valid_601225
  var valid_601226 = header.getOrDefault("X-Amz-Security-Token")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-Security-Token", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Content-Sha256", valid_601227
  var valid_601228 = header.getOrDefault("X-Amz-Algorithm")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "X-Amz-Algorithm", valid_601228
  var valid_601229 = header.getOrDefault("X-Amz-Signature")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-Signature", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-SignedHeaders", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Credential")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Credential", valid_601231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601232: Call_DeleteTags_601220; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from a resource.
  ## 
  let valid = call_601232.validator(path, query, header, formData, body)
  let scheme = call_601232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601232.url(scheme.get, call_601232.host, call_601232.base,
                         call_601232.route, valid.getOrDefault("path"))
  result = hook(call_601232, url, valid)

proc call*(call_601233: Call_DeleteTags_601220; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## deleteTags
  ## Removes a tag from a resource.
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource tag.
  var path_601234 = newJObject()
  var query_601235 = newJObject()
  if tagKeys != nil:
    query_601235.add "tagKeys", tagKeys
  add(path_601234, "resource-arn", newJString(resourceArn))
  result = call_601233.call(path_601234, query_601235, nil, nil, nil)

var deleteTags* = Call_DeleteTags_601220(name: "deleteTags",
                                      meth: HttpMethod.HttpDelete,
                                      host: "mq.amazonaws.com",
                                      route: "/v1/tags/{resource-arn}#tagKeys",
                                      validator: validate_DeleteTags_601221,
                                      base: "/", url: url_DeleteTags_601222,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBrokerEngineTypes_601236 = ref object of OpenApiRestCall_600426
proc url_DescribeBrokerEngineTypes_601238(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeBrokerEngineTypes_601237(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601239 = query.getOrDefault("maxResults")
  valid_601239 = validateParameter(valid_601239, JInt, required = false, default = nil)
  if valid_601239 != nil:
    section.add "maxResults", valid_601239
  var valid_601240 = query.getOrDefault("nextToken")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "nextToken", valid_601240
  var valid_601241 = query.getOrDefault("engineType")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "engineType", valid_601241
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
  var valid_601242 = header.getOrDefault("X-Amz-Date")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Date", valid_601242
  var valid_601243 = header.getOrDefault("X-Amz-Security-Token")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-Security-Token", valid_601243
  var valid_601244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-Content-Sha256", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Algorithm")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Algorithm", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-Signature")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Signature", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-SignedHeaders", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-Credential")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Credential", valid_601248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601249: Call_DescribeBrokerEngineTypes_601236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe available engine types and versions.
  ## 
  let valid = call_601249.validator(path, query, header, formData, body)
  let scheme = call_601249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601249.url(scheme.get, call_601249.host, call_601249.base,
                         call_601249.route, valid.getOrDefault("path"))
  result = hook(call_601249, url, valid)

proc call*(call_601250: Call_DescribeBrokerEngineTypes_601236; maxResults: int = 0;
          nextToken: string = ""; engineType: string = ""): Recallable =
  ## describeBrokerEngineTypes
  ## Describe available engine types and versions.
  ##   maxResults: int
  ##             : The maximum number of engine types that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   engineType: string
  ##             : Filter response by engine type.
  var query_601251 = newJObject()
  add(query_601251, "maxResults", newJInt(maxResults))
  add(query_601251, "nextToken", newJString(nextToken))
  add(query_601251, "engineType", newJString(engineType))
  result = call_601250.call(nil, query_601251, nil, nil, nil)

var describeBrokerEngineTypes* = Call_DescribeBrokerEngineTypes_601236(
    name: "describeBrokerEngineTypes", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/broker-engine-types",
    validator: validate_DescribeBrokerEngineTypes_601237, base: "/",
    url: url_DescribeBrokerEngineTypes_601238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBrokerInstanceOptions_601252 = ref object of OpenApiRestCall_600426
proc url_DescribeBrokerInstanceOptions_601254(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeBrokerInstanceOptions_601253(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describe available broker instance options.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of instance options that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: JString
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   hostInstanceType: JString
  ##                   : Filter response by host instance type.
  ##   engineType: JString
  ##             : Filter response by engine type.
  section = newJObject()
  var valid_601255 = query.getOrDefault("maxResults")
  valid_601255 = validateParameter(valid_601255, JInt, required = false, default = nil)
  if valid_601255 != nil:
    section.add "maxResults", valid_601255
  var valid_601256 = query.getOrDefault("nextToken")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "nextToken", valid_601256
  var valid_601257 = query.getOrDefault("hostInstanceType")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "hostInstanceType", valid_601257
  var valid_601258 = query.getOrDefault("engineType")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "engineType", valid_601258
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
  var valid_601259 = header.getOrDefault("X-Amz-Date")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-Date", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-Security-Token")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Security-Token", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Content-Sha256", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-Algorithm")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Algorithm", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-Signature")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Signature", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-SignedHeaders", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-Credential")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Credential", valid_601265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601266: Call_DescribeBrokerInstanceOptions_601252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe available broker instance options.
  ## 
  let valid = call_601266.validator(path, query, header, formData, body)
  let scheme = call_601266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601266.url(scheme.get, call_601266.host, call_601266.base,
                         call_601266.route, valid.getOrDefault("path"))
  result = hook(call_601266, url, valid)

proc call*(call_601267: Call_DescribeBrokerInstanceOptions_601252;
          maxResults: int = 0; nextToken: string = ""; hostInstanceType: string = "";
          engineType: string = ""): Recallable =
  ## describeBrokerInstanceOptions
  ## Describe available broker instance options.
  ##   maxResults: int
  ##             : The maximum number of instance options that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   hostInstanceType: string
  ##                   : Filter response by host instance type.
  ##   engineType: string
  ##             : Filter response by engine type.
  var query_601268 = newJObject()
  add(query_601268, "maxResults", newJInt(maxResults))
  add(query_601268, "nextToken", newJString(nextToken))
  add(query_601268, "hostInstanceType", newJString(hostInstanceType))
  add(query_601268, "engineType", newJString(engineType))
  result = call_601267.call(nil, query_601268, nil, nil, nil)

var describeBrokerInstanceOptions* = Call_DescribeBrokerInstanceOptions_601252(
    name: "describeBrokerInstanceOptions", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/broker-instance-options",
    validator: validate_DescribeBrokerInstanceOptions_601253, base: "/",
    url: url_DescribeBrokerInstanceOptions_601254,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfiguration_601283 = ref object of OpenApiRestCall_600426
proc url_UpdateConfiguration_601285(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "configuration-id" in path,
        "`configuration-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/configurations/"),
               (kind: VariableSegment, value: "configuration-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateConfiguration_601284(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_601286 = path.getOrDefault("configuration-id")
  valid_601286 = validateParameter(valid_601286, JString, required = true,
                                 default = nil)
  if valid_601286 != nil:
    section.add "configuration-id", valid_601286
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
  var valid_601287 = header.getOrDefault("X-Amz-Date")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Date", valid_601287
  var valid_601288 = header.getOrDefault("X-Amz-Security-Token")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Security-Token", valid_601288
  var valid_601289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-Content-Sha256", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Algorithm")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Algorithm", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Signature")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Signature", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-SignedHeaders", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-Credential")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Credential", valid_601293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601295: Call_UpdateConfiguration_601283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified configuration.
  ## 
  let valid = call_601295.validator(path, query, header, formData, body)
  let scheme = call_601295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601295.url(scheme.get, call_601295.host, call_601295.base,
                         call_601295.route, valid.getOrDefault("path"))
  result = hook(call_601295, url, valid)

proc call*(call_601296: Call_UpdateConfiguration_601283; body: JsonNode;
          configurationId: string): Recallable =
  ## updateConfiguration
  ## Updates the specified configuration.
  ##   body: JObject (required)
  ##   configurationId: string (required)
  ##                  : The unique ID that Amazon MQ generates for the configuration.
  var path_601297 = newJObject()
  var body_601298 = newJObject()
  if body != nil:
    body_601298 = body
  add(path_601297, "configuration-id", newJString(configurationId))
  result = call_601296.call(path_601297, nil, nil, nil, body_601298)

var updateConfiguration* = Call_UpdateConfiguration_601283(
    name: "updateConfiguration", meth: HttpMethod.HttpPut, host: "mq.amazonaws.com",
    route: "/v1/configurations/{configuration-id}",
    validator: validate_UpdateConfiguration_601284, base: "/",
    url: url_UpdateConfiguration_601285, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfiguration_601269 = ref object of OpenApiRestCall_600426
proc url_DescribeConfiguration_601271(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "configuration-id" in path,
        "`configuration-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/configurations/"),
               (kind: VariableSegment, value: "configuration-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeConfiguration_601270(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601272 = path.getOrDefault("configuration-id")
  valid_601272 = validateParameter(valid_601272, JString, required = true,
                                 default = nil)
  if valid_601272 != nil:
    section.add "configuration-id", valid_601272
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
  var valid_601273 = header.getOrDefault("X-Amz-Date")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Date", valid_601273
  var valid_601274 = header.getOrDefault("X-Amz-Security-Token")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "X-Amz-Security-Token", valid_601274
  var valid_601275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-Content-Sha256", valid_601275
  var valid_601276 = header.getOrDefault("X-Amz-Algorithm")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-Algorithm", valid_601276
  var valid_601277 = header.getOrDefault("X-Amz-Signature")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-Signature", valid_601277
  var valid_601278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-SignedHeaders", valid_601278
  var valid_601279 = header.getOrDefault("X-Amz-Credential")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-Credential", valid_601279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601280: Call_DescribeConfiguration_601269; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified configuration.
  ## 
  let valid = call_601280.validator(path, query, header, formData, body)
  let scheme = call_601280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601280.url(scheme.get, call_601280.host, call_601280.base,
                         call_601280.route, valid.getOrDefault("path"))
  result = hook(call_601280, url, valid)

proc call*(call_601281: Call_DescribeConfiguration_601269; configurationId: string): Recallable =
  ## describeConfiguration
  ## Returns information about the specified configuration.
  ##   configurationId: string (required)
  ##                  : The unique ID that Amazon MQ generates for the configuration.
  var path_601282 = newJObject()
  add(path_601282, "configuration-id", newJString(configurationId))
  result = call_601281.call(path_601282, nil, nil, nil, nil)

var describeConfiguration* = Call_DescribeConfiguration_601269(
    name: "describeConfiguration", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/configurations/{configuration-id}",
    validator: validate_DescribeConfiguration_601270, base: "/",
    url: url_DescribeConfiguration_601271, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationRevision_601299 = ref object of OpenApiRestCall_600426
proc url_DescribeConfigurationRevision_601301(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeConfigurationRevision_601300(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601302 = path.getOrDefault("configuration-revision")
  valid_601302 = validateParameter(valid_601302, JString, required = true,
                                 default = nil)
  if valid_601302 != nil:
    section.add "configuration-revision", valid_601302
  var valid_601303 = path.getOrDefault("configuration-id")
  valid_601303 = validateParameter(valid_601303, JString, required = true,
                                 default = nil)
  if valid_601303 != nil:
    section.add "configuration-id", valid_601303
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
  var valid_601304 = header.getOrDefault("X-Amz-Date")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "X-Amz-Date", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-Security-Token")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Security-Token", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Content-Sha256", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Algorithm")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Algorithm", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-Signature")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Signature", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-SignedHeaders", valid_601309
  var valid_601310 = header.getOrDefault("X-Amz-Credential")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Credential", valid_601310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601311: Call_DescribeConfigurationRevision_601299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the specified configuration revision for the specified configuration.
  ## 
  let valid = call_601311.validator(path, query, header, formData, body)
  let scheme = call_601311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601311.url(scheme.get, call_601311.host, call_601311.base,
                         call_601311.route, valid.getOrDefault("path"))
  result = hook(call_601311, url, valid)

proc call*(call_601312: Call_DescribeConfigurationRevision_601299;
          configurationRevision: string; configurationId: string): Recallable =
  ## describeConfigurationRevision
  ## Returns the specified configuration revision for the specified configuration.
  ##   configurationRevision: string (required)
  ##                        : The revision of the configuration.
  ##   configurationId: string (required)
  ##                  : The unique ID that Amazon MQ generates for the configuration.
  var path_601313 = newJObject()
  add(path_601313, "configuration-revision", newJString(configurationRevision))
  add(path_601313, "configuration-id", newJString(configurationId))
  result = call_601312.call(path_601313, nil, nil, nil, nil)

var describeConfigurationRevision* = Call_DescribeConfigurationRevision_601299(
    name: "describeConfigurationRevision", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/configurations/{configuration-id}/revisions/{configuration-revision}",
    validator: validate_DescribeConfigurationRevision_601300, base: "/",
    url: url_DescribeConfigurationRevision_601301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationRevisions_601314 = ref object of OpenApiRestCall_600426
proc url_ListConfigurationRevisions_601316(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListConfigurationRevisions_601315(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601317 = path.getOrDefault("configuration-id")
  valid_601317 = validateParameter(valid_601317, JString, required = true,
                                 default = nil)
  if valid_601317 != nil:
    section.add "configuration-id", valid_601317
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of configurations that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: JString
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  section = newJObject()
  var valid_601318 = query.getOrDefault("maxResults")
  valid_601318 = validateParameter(valid_601318, JInt, required = false, default = nil)
  if valid_601318 != nil:
    section.add "maxResults", valid_601318
  var valid_601319 = query.getOrDefault("nextToken")
  valid_601319 = validateParameter(valid_601319, JString, required = false,
                                 default = nil)
  if valid_601319 != nil:
    section.add "nextToken", valid_601319
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
  var valid_601320 = header.getOrDefault("X-Amz-Date")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "X-Amz-Date", valid_601320
  var valid_601321 = header.getOrDefault("X-Amz-Security-Token")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "X-Amz-Security-Token", valid_601321
  var valid_601322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "X-Amz-Content-Sha256", valid_601322
  var valid_601323 = header.getOrDefault("X-Amz-Algorithm")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "X-Amz-Algorithm", valid_601323
  var valid_601324 = header.getOrDefault("X-Amz-Signature")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-Signature", valid_601324
  var valid_601325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-SignedHeaders", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-Credential")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Credential", valid_601326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601327: Call_ListConfigurationRevisions_601314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all revisions for the specified configuration.
  ## 
  let valid = call_601327.validator(path, query, header, formData, body)
  let scheme = call_601327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601327.url(scheme.get, call_601327.host, call_601327.base,
                         call_601327.route, valid.getOrDefault("path"))
  result = hook(call_601327, url, valid)

proc call*(call_601328: Call_ListConfigurationRevisions_601314;
          configurationId: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listConfigurationRevisions
  ## Returns a list of all revisions for the specified configuration.
  ##   maxResults: int
  ##             : The maximum number of configurations that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   configurationId: string (required)
  ##                  : The unique ID that Amazon MQ generates for the configuration.
  var path_601329 = newJObject()
  var query_601330 = newJObject()
  add(query_601330, "maxResults", newJInt(maxResults))
  add(query_601330, "nextToken", newJString(nextToken))
  add(path_601329, "configuration-id", newJString(configurationId))
  result = call_601328.call(path_601329, query_601330, nil, nil, nil)

var listConfigurationRevisions* = Call_ListConfigurationRevisions_601314(
    name: "listConfigurationRevisions", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com",
    route: "/v1/configurations/{configuration-id}/revisions",
    validator: validate_ListConfigurationRevisions_601315, base: "/",
    url: url_ListConfigurationRevisions_601316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_601331 = ref object of OpenApiRestCall_600426
proc url_ListUsers_601333(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "broker-id" in path, "`broker-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/brokers/"),
               (kind: VariableSegment, value: "broker-id"),
               (kind: ConstantSegment, value: "/users")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListUsers_601332(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of all ActiveMQ users.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   broker-id: JString (required)
  ##            : The unique ID that Amazon MQ generates for the broker.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `broker-id` field"
  var valid_601334 = path.getOrDefault("broker-id")
  valid_601334 = validateParameter(valid_601334, JString, required = true,
                                 default = nil)
  if valid_601334 != nil:
    section.add "broker-id", valid_601334
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of ActiveMQ users that can be returned per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: JString
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  section = newJObject()
  var valid_601335 = query.getOrDefault("maxResults")
  valid_601335 = validateParameter(valid_601335, JInt, required = false, default = nil)
  if valid_601335 != nil:
    section.add "maxResults", valid_601335
  var valid_601336 = query.getOrDefault("nextToken")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "nextToken", valid_601336
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
  var valid_601337 = header.getOrDefault("X-Amz-Date")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-Date", valid_601337
  var valid_601338 = header.getOrDefault("X-Amz-Security-Token")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-Security-Token", valid_601338
  var valid_601339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "X-Amz-Content-Sha256", valid_601339
  var valid_601340 = header.getOrDefault("X-Amz-Algorithm")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-Algorithm", valid_601340
  var valid_601341 = header.getOrDefault("X-Amz-Signature")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-Signature", valid_601341
  var valid_601342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-SignedHeaders", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-Credential")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Credential", valid_601343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601344: Call_ListUsers_601331; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all ActiveMQ users.
  ## 
  let valid = call_601344.validator(path, query, header, formData, body)
  let scheme = call_601344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601344.url(scheme.get, call_601344.host, call_601344.base,
                         call_601344.route, valid.getOrDefault("path"))
  result = hook(call_601344, url, valid)

proc call*(call_601345: Call_ListUsers_601331; brokerId: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listUsers
  ## Returns a list of all ActiveMQ users.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   maxResults: int
  ##             : The maximum number of ActiveMQ users that can be returned per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  var path_601346 = newJObject()
  var query_601347 = newJObject()
  add(path_601346, "broker-id", newJString(brokerId))
  add(query_601347, "maxResults", newJInt(maxResults))
  add(query_601347, "nextToken", newJString(nextToken))
  result = call_601345.call(path_601346, query_601347, nil, nil, nil)

var listUsers* = Call_ListUsers_601331(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "mq.amazonaws.com",
                                    route: "/v1/brokers/{broker-id}/users",
                                    validator: validate_ListUsers_601332,
                                    base: "/", url: url_ListUsers_601333,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootBroker_601348 = ref object of OpenApiRestCall_600426
proc url_RebootBroker_601350(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "broker-id" in path, "`broker-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/brokers/"),
               (kind: VariableSegment, value: "broker-id"),
               (kind: ConstantSegment, value: "/reboot")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_RebootBroker_601349(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Reboots a broker. Note: This API is asynchronous.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   broker-id: JString (required)
  ##            : The unique ID that Amazon MQ generates for the broker.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `broker-id` field"
  var valid_601351 = path.getOrDefault("broker-id")
  valid_601351 = validateParameter(valid_601351, JString, required = true,
                                 default = nil)
  if valid_601351 != nil:
    section.add "broker-id", valid_601351
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
  var valid_601352 = header.getOrDefault("X-Amz-Date")
  valid_601352 = validateParameter(valid_601352, JString, required = false,
                                 default = nil)
  if valid_601352 != nil:
    section.add "X-Amz-Date", valid_601352
  var valid_601353 = header.getOrDefault("X-Amz-Security-Token")
  valid_601353 = validateParameter(valid_601353, JString, required = false,
                                 default = nil)
  if valid_601353 != nil:
    section.add "X-Amz-Security-Token", valid_601353
  var valid_601354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601354 = validateParameter(valid_601354, JString, required = false,
                                 default = nil)
  if valid_601354 != nil:
    section.add "X-Amz-Content-Sha256", valid_601354
  var valid_601355 = header.getOrDefault("X-Amz-Algorithm")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "X-Amz-Algorithm", valid_601355
  var valid_601356 = header.getOrDefault("X-Amz-Signature")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-Signature", valid_601356
  var valid_601357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-SignedHeaders", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-Credential")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Credential", valid_601358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601359: Call_RebootBroker_601348; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Reboots a broker. Note: This API is asynchronous.
  ## 
  let valid = call_601359.validator(path, query, header, formData, body)
  let scheme = call_601359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601359.url(scheme.get, call_601359.host, call_601359.base,
                         call_601359.route, valid.getOrDefault("path"))
  result = hook(call_601359, url, valid)

proc call*(call_601360: Call_RebootBroker_601348; brokerId: string): Recallable =
  ## rebootBroker
  ## Reboots a broker. Note: This API is asynchronous.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  var path_601361 = newJObject()
  add(path_601361, "broker-id", newJString(brokerId))
  result = call_601360.call(path_601361, nil, nil, nil, nil)

var rebootBroker* = Call_RebootBroker_601348(name: "rebootBroker",
    meth: HttpMethod.HttpPost, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}/reboot", validator: validate_RebootBroker_601349,
    base: "/", url: url_RebootBroker_601350, schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
