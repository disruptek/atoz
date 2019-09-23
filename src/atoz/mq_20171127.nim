
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_600437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600437): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateBroker_601031 = ref object of OpenApiRestCall_600437
proc url_CreateBroker_601033(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateBroker_601032(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601034 = header.getOrDefault("X-Amz-Date")
  valid_601034 = validateParameter(valid_601034, JString, required = false,
                                 default = nil)
  if valid_601034 != nil:
    section.add "X-Amz-Date", valid_601034
  var valid_601035 = header.getOrDefault("X-Amz-Security-Token")
  valid_601035 = validateParameter(valid_601035, JString, required = false,
                                 default = nil)
  if valid_601035 != nil:
    section.add "X-Amz-Security-Token", valid_601035
  var valid_601036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601036 = validateParameter(valid_601036, JString, required = false,
                                 default = nil)
  if valid_601036 != nil:
    section.add "X-Amz-Content-Sha256", valid_601036
  var valid_601037 = header.getOrDefault("X-Amz-Algorithm")
  valid_601037 = validateParameter(valid_601037, JString, required = false,
                                 default = nil)
  if valid_601037 != nil:
    section.add "X-Amz-Algorithm", valid_601037
  var valid_601038 = header.getOrDefault("X-Amz-Signature")
  valid_601038 = validateParameter(valid_601038, JString, required = false,
                                 default = nil)
  if valid_601038 != nil:
    section.add "X-Amz-Signature", valid_601038
  var valid_601039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601039 = validateParameter(valid_601039, JString, required = false,
                                 default = nil)
  if valid_601039 != nil:
    section.add "X-Amz-SignedHeaders", valid_601039
  var valid_601040 = header.getOrDefault("X-Amz-Credential")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Credential", valid_601040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601042: Call_CreateBroker_601031; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a broker. Note: This API is asynchronous.
  ## 
  let valid = call_601042.validator(path, query, header, formData, body)
  let scheme = call_601042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601042.url(scheme.get, call_601042.host, call_601042.base,
                         call_601042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601042, url, valid)

proc call*(call_601043: Call_CreateBroker_601031; body: JsonNode): Recallable =
  ## createBroker
  ## Creates a broker. Note: This API is asynchronous.
  ##   body: JObject (required)
  var body_601044 = newJObject()
  if body != nil:
    body_601044 = body
  result = call_601043.call(nil, nil, nil, nil, body_601044)

var createBroker* = Call_CreateBroker_601031(name: "createBroker",
    meth: HttpMethod.HttpPost, host: "mq.amazonaws.com", route: "/v1/brokers",
    validator: validate_CreateBroker_601032, base: "/", url: url_CreateBroker_601033,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBrokers_600774 = ref object of OpenApiRestCall_600437
proc url_ListBrokers_600776(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBrokers_600775(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600888 = query.getOrDefault("maxResults")
  valid_600888 = validateParameter(valid_600888, JInt, required = false, default = nil)
  if valid_600888 != nil:
    section.add "maxResults", valid_600888
  var valid_600889 = query.getOrDefault("nextToken")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "nextToken", valid_600889
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
  var valid_600890 = header.getOrDefault("X-Amz-Date")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Date", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-Security-Token")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-Security-Token", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-Content-Sha256", valid_600892
  var valid_600893 = header.getOrDefault("X-Amz-Algorithm")
  valid_600893 = validateParameter(valid_600893, JString, required = false,
                                 default = nil)
  if valid_600893 != nil:
    section.add "X-Amz-Algorithm", valid_600893
  var valid_600894 = header.getOrDefault("X-Amz-Signature")
  valid_600894 = validateParameter(valid_600894, JString, required = false,
                                 default = nil)
  if valid_600894 != nil:
    section.add "X-Amz-Signature", valid_600894
  var valid_600895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600895 = validateParameter(valid_600895, JString, required = false,
                                 default = nil)
  if valid_600895 != nil:
    section.add "X-Amz-SignedHeaders", valid_600895
  var valid_600896 = header.getOrDefault("X-Amz-Credential")
  valid_600896 = validateParameter(valid_600896, JString, required = false,
                                 default = nil)
  if valid_600896 != nil:
    section.add "X-Amz-Credential", valid_600896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600919: Call_ListBrokers_600774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all brokers.
  ## 
  let valid = call_600919.validator(path, query, header, formData, body)
  let scheme = call_600919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600919.url(scheme.get, call_600919.host, call_600919.base,
                         call_600919.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600919, url, valid)

proc call*(call_600990: Call_ListBrokers_600774; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listBrokers
  ## Returns a list of all brokers.
  ##   maxResults: int
  ##             : The maximum number of brokers that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  var query_600991 = newJObject()
  add(query_600991, "maxResults", newJInt(maxResults))
  add(query_600991, "nextToken", newJString(nextToken))
  result = call_600990.call(nil, query_600991, nil, nil, nil)

var listBrokers* = Call_ListBrokers_600774(name: "listBrokers",
                                        meth: HttpMethod.HttpGet,
                                        host: "mq.amazonaws.com",
                                        route: "/v1/brokers",
                                        validator: validate_ListBrokers_600775,
                                        base: "/", url: url_ListBrokers_600776,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfiguration_601060 = ref object of OpenApiRestCall_600437
proc url_CreateConfiguration_601062(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateConfiguration_601061(path: JsonNode; query: JsonNode;
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
  var valid_601063 = header.getOrDefault("X-Amz-Date")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Date", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-Security-Token")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Security-Token", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Content-Sha256", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-Algorithm")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Algorithm", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-Signature")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Signature", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-SignedHeaders", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-Credential")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Credential", valid_601069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601071: Call_CreateConfiguration_601060; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new configuration for the specified configuration name. Amazon MQ uses the default configuration (the engine type and version).
  ## 
  let valid = call_601071.validator(path, query, header, formData, body)
  let scheme = call_601071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601071.url(scheme.get, call_601071.host, call_601071.base,
                         call_601071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601071, url, valid)

proc call*(call_601072: Call_CreateConfiguration_601060; body: JsonNode): Recallable =
  ## createConfiguration
  ## Creates a new configuration for the specified configuration name. Amazon MQ uses the default configuration (the engine type and version).
  ##   body: JObject (required)
  var body_601073 = newJObject()
  if body != nil:
    body_601073 = body
  result = call_601072.call(nil, nil, nil, nil, body_601073)

var createConfiguration* = Call_CreateConfiguration_601060(
    name: "createConfiguration", meth: HttpMethod.HttpPost,
    host: "mq.amazonaws.com", route: "/v1/configurations",
    validator: validate_CreateConfiguration_601061, base: "/",
    url: url_CreateConfiguration_601062, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurations_601045 = ref object of OpenApiRestCall_600437
proc url_ListConfigurations_601047(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListConfigurations_601046(path: JsonNode; query: JsonNode;
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
  var valid_601048 = query.getOrDefault("maxResults")
  valid_601048 = validateParameter(valid_601048, JInt, required = false, default = nil)
  if valid_601048 != nil:
    section.add "maxResults", valid_601048
  var valid_601049 = query.getOrDefault("nextToken")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "nextToken", valid_601049
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
  var valid_601050 = header.getOrDefault("X-Amz-Date")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Date", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-Security-Token")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Security-Token", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Content-Sha256", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-Algorithm")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Algorithm", valid_601053
  var valid_601054 = header.getOrDefault("X-Amz-Signature")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Signature", valid_601054
  var valid_601055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-SignedHeaders", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Credential")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Credential", valid_601056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601057: Call_ListConfigurations_601045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all configurations.
  ## 
  let valid = call_601057.validator(path, query, header, formData, body)
  let scheme = call_601057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601057.url(scheme.get, call_601057.host, call_601057.base,
                         call_601057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601057, url, valid)

proc call*(call_601058: Call_ListConfigurations_601045; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listConfigurations
  ## Returns a list of all configurations.
  ##   maxResults: int
  ##             : The maximum number of configurations that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  var query_601059 = newJObject()
  add(query_601059, "maxResults", newJInt(maxResults))
  add(query_601059, "nextToken", newJString(nextToken))
  result = call_601058.call(nil, query_601059, nil, nil, nil)

var listConfigurations* = Call_ListConfigurations_601045(
    name: "listConfigurations", meth: HttpMethod.HttpGet, host: "mq.amazonaws.com",
    route: "/v1/configurations", validator: validate_ListConfigurations_601046,
    base: "/", url: url_ListConfigurations_601047,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_601102 = ref object of OpenApiRestCall_600437
proc url_CreateTags_601104(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_CreateTags_601103(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601105 = path.getOrDefault("resource-arn")
  valid_601105 = validateParameter(valid_601105, JString, required = true,
                                 default = nil)
  if valid_601105 != nil:
    section.add "resource-arn", valid_601105
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
  var valid_601106 = header.getOrDefault("X-Amz-Date")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Date", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Security-Token")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Security-Token", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Content-Sha256", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Algorithm")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Algorithm", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Signature")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Signature", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-SignedHeaders", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-Credential")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-Credential", valid_601112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601114: Call_CreateTags_601102; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a tag to a resource.
  ## 
  let valid = call_601114.validator(path, query, header, formData, body)
  let scheme = call_601114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601114.url(scheme.get, call_601114.host, call_601114.base,
                         call_601114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601114, url, valid)

proc call*(call_601115: Call_CreateTags_601102; resourceArn: string; body: JsonNode): Recallable =
  ## createTags
  ## Add a tag to a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource tag.
  ##   body: JObject (required)
  var path_601116 = newJObject()
  var body_601117 = newJObject()
  add(path_601116, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_601117 = body
  result = call_601115.call(path_601116, nil, nil, nil, body_601117)

var createTags* = Call_CreateTags_601102(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "mq.amazonaws.com",
                                      route: "/v1/tags/{resource-arn}",
                                      validator: validate_CreateTags_601103,
                                      base: "/", url: url_CreateTags_601104,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_601074 = ref object of OpenApiRestCall_600437
proc url_ListTags_601076(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_ListTags_601075(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601091 = path.getOrDefault("resource-arn")
  valid_601091 = validateParameter(valid_601091, JString, required = true,
                                 default = nil)
  if valid_601091 != nil:
    section.add "resource-arn", valid_601091
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
  var valid_601092 = header.getOrDefault("X-Amz-Date")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Date", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-Security-Token")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Security-Token", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Content-Sha256", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Algorithm")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Algorithm", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Signature")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Signature", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-SignedHeaders", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-Credential")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-Credential", valid_601098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601099: Call_ListTags_601074; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists tags for a resource.
  ## 
  let valid = call_601099.validator(path, query, header, formData, body)
  let scheme = call_601099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601099.url(scheme.get, call_601099.host, call_601099.base,
                         call_601099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601099, url, valid)

proc call*(call_601100: Call_ListTags_601074; resourceArn: string): Recallable =
  ## listTags
  ## Lists tags for a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource tag.
  var path_601101 = newJObject()
  add(path_601101, "resource-arn", newJString(resourceArn))
  result = call_601100.call(path_601101, nil, nil, nil, nil)

var listTags* = Call_ListTags_601074(name: "listTags", meth: HttpMethod.HttpGet,
                                  host: "mq.amazonaws.com",
                                  route: "/v1/tags/{resource-arn}",
                                  validator: validate_ListTags_601075, base: "/",
                                  url: url_ListTags_601076,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_601133 = ref object of OpenApiRestCall_600437
proc url_UpdateUser_601135(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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
  result.path = base & hydrated.get

proc validate_UpdateUser_601134(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601136 = path.getOrDefault("broker-id")
  valid_601136 = validateParameter(valid_601136, JString, required = true,
                                 default = nil)
  if valid_601136 != nil:
    section.add "broker-id", valid_601136
  var valid_601137 = path.getOrDefault("username")
  valid_601137 = validateParameter(valid_601137, JString, required = true,
                                 default = nil)
  if valid_601137 != nil:
    section.add "username", valid_601137
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
  var valid_601138 = header.getOrDefault("X-Amz-Date")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-Date", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Security-Token")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Security-Token", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Content-Sha256", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Algorithm")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Algorithm", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-Signature")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-Signature", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-SignedHeaders", valid_601143
  var valid_601144 = header.getOrDefault("X-Amz-Credential")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-Credential", valid_601144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601146: Call_UpdateUser_601133; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the information for an ActiveMQ user.
  ## 
  let valid = call_601146.validator(path, query, header, formData, body)
  let scheme = call_601146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601146.url(scheme.get, call_601146.host, call_601146.base,
                         call_601146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601146, url, valid)

proc call*(call_601147: Call_UpdateUser_601133; brokerId: string; username: string;
          body: JsonNode): Recallable =
  ## updateUser
  ## Updates the information for an ActiveMQ user.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   username: string (required)
  ##           : Required. The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  ##   body: JObject (required)
  var path_601148 = newJObject()
  var body_601149 = newJObject()
  add(path_601148, "broker-id", newJString(brokerId))
  add(path_601148, "username", newJString(username))
  if body != nil:
    body_601149 = body
  result = call_601147.call(path_601148, nil, nil, nil, body_601149)

var updateUser* = Call_UpdateUser_601133(name: "updateUser",
                                      meth: HttpMethod.HttpPut,
                                      host: "mq.amazonaws.com", route: "/v1/brokers/{broker-id}/users/{username}",
                                      validator: validate_UpdateUser_601134,
                                      base: "/", url: url_UpdateUser_601135,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_601150 = ref object of OpenApiRestCall_600437
proc url_CreateUser_601152(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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
  result.path = base & hydrated.get

proc validate_CreateUser_601151(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601153 = path.getOrDefault("broker-id")
  valid_601153 = validateParameter(valid_601153, JString, required = true,
                                 default = nil)
  if valid_601153 != nil:
    section.add "broker-id", valid_601153
  var valid_601154 = path.getOrDefault("username")
  valid_601154 = validateParameter(valid_601154, JString, required = true,
                                 default = nil)
  if valid_601154 != nil:
    section.add "username", valid_601154
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
  var valid_601155 = header.getOrDefault("X-Amz-Date")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Date", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-Security-Token")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Security-Token", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-Content-Sha256", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-Algorithm")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-Algorithm", valid_601158
  var valid_601159 = header.getOrDefault("X-Amz-Signature")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "X-Amz-Signature", valid_601159
  var valid_601160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-SignedHeaders", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Credential")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Credential", valid_601161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601163: Call_CreateUser_601150; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an ActiveMQ user.
  ## 
  let valid = call_601163.validator(path, query, header, formData, body)
  let scheme = call_601163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601163.url(scheme.get, call_601163.host, call_601163.base,
                         call_601163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601163, url, valid)

proc call*(call_601164: Call_CreateUser_601150; brokerId: string; username: string;
          body: JsonNode): Recallable =
  ## createUser
  ## Creates an ActiveMQ user.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   username: string (required)
  ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  ##   body: JObject (required)
  var path_601165 = newJObject()
  var body_601166 = newJObject()
  add(path_601165, "broker-id", newJString(brokerId))
  add(path_601165, "username", newJString(username))
  if body != nil:
    body_601166 = body
  result = call_601164.call(path_601165, nil, nil, nil, body_601166)

var createUser* = Call_CreateUser_601150(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "mq.amazonaws.com", route: "/v1/brokers/{broker-id}/users/{username}",
                                      validator: validate_CreateUser_601151,
                                      base: "/", url: url_CreateUser_601152,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_601118 = ref object of OpenApiRestCall_600437
proc url_DescribeUser_601120(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeUser_601119(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601121 = path.getOrDefault("broker-id")
  valid_601121 = validateParameter(valid_601121, JString, required = true,
                                 default = nil)
  if valid_601121 != nil:
    section.add "broker-id", valid_601121
  var valid_601122 = path.getOrDefault("username")
  valid_601122 = validateParameter(valid_601122, JString, required = true,
                                 default = nil)
  if valid_601122 != nil:
    section.add "username", valid_601122
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
  var valid_601123 = header.getOrDefault("X-Amz-Date")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-Date", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-Security-Token")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Security-Token", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Content-Sha256", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Algorithm")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Algorithm", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-Signature")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Signature", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-SignedHeaders", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-Credential")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Credential", valid_601129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601130: Call_DescribeUser_601118; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about an ActiveMQ user.
  ## 
  let valid = call_601130.validator(path, query, header, formData, body)
  let scheme = call_601130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601130.url(scheme.get, call_601130.host, call_601130.base,
                         call_601130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601130, url, valid)

proc call*(call_601131: Call_DescribeUser_601118; brokerId: string; username: string): Recallable =
  ## describeUser
  ## Returns information about an ActiveMQ user.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   username: string (required)
  ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  var path_601132 = newJObject()
  add(path_601132, "broker-id", newJString(brokerId))
  add(path_601132, "username", newJString(username))
  result = call_601131.call(path_601132, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_601118(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}/users/{username}",
    validator: validate_DescribeUser_601119, base: "/", url: url_DescribeUser_601120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_601167 = ref object of OpenApiRestCall_600437
proc url_DeleteUser_601169(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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
  result.path = base & hydrated.get

proc validate_DeleteUser_601168(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601170 = path.getOrDefault("broker-id")
  valid_601170 = validateParameter(valid_601170, JString, required = true,
                                 default = nil)
  if valid_601170 != nil:
    section.add "broker-id", valid_601170
  var valid_601171 = path.getOrDefault("username")
  valid_601171 = validateParameter(valid_601171, JString, required = true,
                                 default = nil)
  if valid_601171 != nil:
    section.add "username", valid_601171
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
  var valid_601172 = header.getOrDefault("X-Amz-Date")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-Date", valid_601172
  var valid_601173 = header.getOrDefault("X-Amz-Security-Token")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-Security-Token", valid_601173
  var valid_601174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601174 = validateParameter(valid_601174, JString, required = false,
                                 default = nil)
  if valid_601174 != nil:
    section.add "X-Amz-Content-Sha256", valid_601174
  var valid_601175 = header.getOrDefault("X-Amz-Algorithm")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "X-Amz-Algorithm", valid_601175
  var valid_601176 = header.getOrDefault("X-Amz-Signature")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "X-Amz-Signature", valid_601176
  var valid_601177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601177 = validateParameter(valid_601177, JString, required = false,
                                 default = nil)
  if valid_601177 != nil:
    section.add "X-Amz-SignedHeaders", valid_601177
  var valid_601178 = header.getOrDefault("X-Amz-Credential")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "X-Amz-Credential", valid_601178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601179: Call_DeleteUser_601167; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an ActiveMQ user.
  ## 
  let valid = call_601179.validator(path, query, header, formData, body)
  let scheme = call_601179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601179.url(scheme.get, call_601179.host, call_601179.base,
                         call_601179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601179, url, valid)

proc call*(call_601180: Call_DeleteUser_601167; brokerId: string; username: string): Recallable =
  ## deleteUser
  ## Deletes an ActiveMQ user.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   username: string (required)
  ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  var path_601181 = newJObject()
  add(path_601181, "broker-id", newJString(brokerId))
  add(path_601181, "username", newJString(username))
  result = call_601180.call(path_601181, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_601167(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "mq.amazonaws.com", route: "/v1/brokers/{broker-id}/users/{username}",
                                      validator: validate_DeleteUser_601168,
                                      base: "/", url: url_DeleteUser_601169,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBroker_601196 = ref object of OpenApiRestCall_600437
proc url_UpdateBroker_601198(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateBroker_601197(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601199 = path.getOrDefault("broker-id")
  valid_601199 = validateParameter(valid_601199, JString, required = true,
                                 default = nil)
  if valid_601199 != nil:
    section.add "broker-id", valid_601199
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
  var valid_601200 = header.getOrDefault("X-Amz-Date")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Date", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Security-Token")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Security-Token", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-Content-Sha256", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Algorithm")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Algorithm", valid_601203
  var valid_601204 = header.getOrDefault("X-Amz-Signature")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-Signature", valid_601204
  var valid_601205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-SignedHeaders", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Credential")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Credential", valid_601206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601208: Call_UpdateBroker_601196; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a pending configuration change to a broker.
  ## 
  let valid = call_601208.validator(path, query, header, formData, body)
  let scheme = call_601208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601208.url(scheme.get, call_601208.host, call_601208.base,
                         call_601208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601208, url, valid)

proc call*(call_601209: Call_UpdateBroker_601196; brokerId: string; body: JsonNode): Recallable =
  ## updateBroker
  ## Adds a pending configuration change to a broker.
  ##   brokerId: string (required)
  ##           : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  ##   body: JObject (required)
  var path_601210 = newJObject()
  var body_601211 = newJObject()
  add(path_601210, "broker-id", newJString(brokerId))
  if body != nil:
    body_601211 = body
  result = call_601209.call(path_601210, nil, nil, nil, body_601211)

var updateBroker* = Call_UpdateBroker_601196(name: "updateBroker",
    meth: HttpMethod.HttpPut, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}", validator: validate_UpdateBroker_601197,
    base: "/", url: url_UpdateBroker_601198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBroker_601182 = ref object of OpenApiRestCall_600437
proc url_DescribeBroker_601184(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeBroker_601183(path: JsonNode; query: JsonNode;
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
  var valid_601185 = path.getOrDefault("broker-id")
  valid_601185 = validateParameter(valid_601185, JString, required = true,
                                 default = nil)
  if valid_601185 != nil:
    section.add "broker-id", valid_601185
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
  var valid_601186 = header.getOrDefault("X-Amz-Date")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Date", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-Security-Token")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-Security-Token", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Content-Sha256", valid_601188
  var valid_601189 = header.getOrDefault("X-Amz-Algorithm")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "X-Amz-Algorithm", valid_601189
  var valid_601190 = header.getOrDefault("X-Amz-Signature")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Signature", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-SignedHeaders", valid_601191
  var valid_601192 = header.getOrDefault("X-Amz-Credential")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = nil)
  if valid_601192 != nil:
    section.add "X-Amz-Credential", valid_601192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601193: Call_DescribeBroker_601182; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified broker.
  ## 
  let valid = call_601193.validator(path, query, header, formData, body)
  let scheme = call_601193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601193.url(scheme.get, call_601193.host, call_601193.base,
                         call_601193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601193, url, valid)

proc call*(call_601194: Call_DescribeBroker_601182; brokerId: string): Recallable =
  ## describeBroker
  ## Returns information about the specified broker.
  ##   brokerId: string (required)
  ##           : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  var path_601195 = newJObject()
  add(path_601195, "broker-id", newJString(brokerId))
  result = call_601194.call(path_601195, nil, nil, nil, nil)

var describeBroker* = Call_DescribeBroker_601182(name: "describeBroker",
    meth: HttpMethod.HttpGet, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}", validator: validate_DescribeBroker_601183,
    base: "/", url: url_DescribeBroker_601184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBroker_601212 = ref object of OpenApiRestCall_600437
proc url_DeleteBroker_601214(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteBroker_601213(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601215 = path.getOrDefault("broker-id")
  valid_601215 = validateParameter(valid_601215, JString, required = true,
                                 default = nil)
  if valid_601215 != nil:
    section.add "broker-id", valid_601215
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
  var valid_601216 = header.getOrDefault("X-Amz-Date")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Date", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-Security-Token")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Security-Token", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Content-Sha256", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-Algorithm")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Algorithm", valid_601219
  var valid_601220 = header.getOrDefault("X-Amz-Signature")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Signature", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-SignedHeaders", valid_601221
  var valid_601222 = header.getOrDefault("X-Amz-Credential")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "X-Amz-Credential", valid_601222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601223: Call_DeleteBroker_601212; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a broker. Note: This API is asynchronous.
  ## 
  let valid = call_601223.validator(path, query, header, formData, body)
  let scheme = call_601223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601223.url(scheme.get, call_601223.host, call_601223.base,
                         call_601223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601223, url, valid)

proc call*(call_601224: Call_DeleteBroker_601212; brokerId: string): Recallable =
  ## deleteBroker
  ## Deletes a broker. Note: This API is asynchronous.
  ##   brokerId: string (required)
  ##           : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  var path_601225 = newJObject()
  add(path_601225, "broker-id", newJString(brokerId))
  result = call_601224.call(path_601225, nil, nil, nil, nil)

var deleteBroker* = Call_DeleteBroker_601212(name: "deleteBroker",
    meth: HttpMethod.HttpDelete, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}", validator: validate_DeleteBroker_601213,
    base: "/", url: url_DeleteBroker_601214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_601226 = ref object of OpenApiRestCall_600437
proc url_DeleteTags_601228(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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
  result.path = base & hydrated.get

proc validate_DeleteTags_601227(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601229 = path.getOrDefault("resource-arn")
  valid_601229 = validateParameter(valid_601229, JString, required = true,
                                 default = nil)
  if valid_601229 != nil:
    section.add "resource-arn", valid_601229
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_601230 = query.getOrDefault("tagKeys")
  valid_601230 = validateParameter(valid_601230, JArray, required = true, default = nil)
  if valid_601230 != nil:
    section.add "tagKeys", valid_601230
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
  var valid_601231 = header.getOrDefault("X-Amz-Date")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Date", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-Security-Token")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Security-Token", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Content-Sha256", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-Algorithm")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Algorithm", valid_601234
  var valid_601235 = header.getOrDefault("X-Amz-Signature")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Signature", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-SignedHeaders", valid_601236
  var valid_601237 = header.getOrDefault("X-Amz-Credential")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "X-Amz-Credential", valid_601237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601238: Call_DeleteTags_601226; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from a resource.
  ## 
  let valid = call_601238.validator(path, query, header, formData, body)
  let scheme = call_601238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601238.url(scheme.get, call_601238.host, call_601238.base,
                         call_601238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601238, url, valid)

proc call*(call_601239: Call_DeleteTags_601226; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## deleteTags
  ## Removes a tag from a resource.
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource tag.
  var path_601240 = newJObject()
  var query_601241 = newJObject()
  if tagKeys != nil:
    query_601241.add "tagKeys", tagKeys
  add(path_601240, "resource-arn", newJString(resourceArn))
  result = call_601239.call(path_601240, query_601241, nil, nil, nil)

var deleteTags* = Call_DeleteTags_601226(name: "deleteTags",
                                      meth: HttpMethod.HttpDelete,
                                      host: "mq.amazonaws.com",
                                      route: "/v1/tags/{resource-arn}#tagKeys",
                                      validator: validate_DeleteTags_601227,
                                      base: "/", url: url_DeleteTags_601228,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBrokerEngineTypes_601242 = ref object of OpenApiRestCall_600437
proc url_DescribeBrokerEngineTypes_601244(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeBrokerEngineTypes_601243(path: JsonNode; query: JsonNode;
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
  var valid_601245 = query.getOrDefault("maxResults")
  valid_601245 = validateParameter(valid_601245, JInt, required = false, default = nil)
  if valid_601245 != nil:
    section.add "maxResults", valid_601245
  var valid_601246 = query.getOrDefault("nextToken")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "nextToken", valid_601246
  var valid_601247 = query.getOrDefault("engineType")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "engineType", valid_601247
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
  var valid_601248 = header.getOrDefault("X-Amz-Date")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Date", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Security-Token")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Security-Token", valid_601249
  var valid_601250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Content-Sha256", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-Algorithm")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Algorithm", valid_601251
  var valid_601252 = header.getOrDefault("X-Amz-Signature")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-Signature", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-SignedHeaders", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Credential")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Credential", valid_601254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601255: Call_DescribeBrokerEngineTypes_601242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe available engine types and versions.
  ## 
  let valid = call_601255.validator(path, query, header, formData, body)
  let scheme = call_601255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601255.url(scheme.get, call_601255.host, call_601255.base,
                         call_601255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601255, url, valid)

proc call*(call_601256: Call_DescribeBrokerEngineTypes_601242; maxResults: int = 0;
          nextToken: string = ""; engineType: string = ""): Recallable =
  ## describeBrokerEngineTypes
  ## Describe available engine types and versions.
  ##   maxResults: int
  ##             : The maximum number of engine types that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   engineType: string
  ##             : Filter response by engine type.
  var query_601257 = newJObject()
  add(query_601257, "maxResults", newJInt(maxResults))
  add(query_601257, "nextToken", newJString(nextToken))
  add(query_601257, "engineType", newJString(engineType))
  result = call_601256.call(nil, query_601257, nil, nil, nil)

var describeBrokerEngineTypes* = Call_DescribeBrokerEngineTypes_601242(
    name: "describeBrokerEngineTypes", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/broker-engine-types",
    validator: validate_DescribeBrokerEngineTypes_601243, base: "/",
    url: url_DescribeBrokerEngineTypes_601244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBrokerInstanceOptions_601258 = ref object of OpenApiRestCall_600437
proc url_DescribeBrokerInstanceOptions_601260(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeBrokerInstanceOptions_601259(path: JsonNode; query: JsonNode;
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
  var valid_601261 = query.getOrDefault("maxResults")
  valid_601261 = validateParameter(valid_601261, JInt, required = false, default = nil)
  if valid_601261 != nil:
    section.add "maxResults", valid_601261
  var valid_601262 = query.getOrDefault("nextToken")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "nextToken", valid_601262
  var valid_601263 = query.getOrDefault("hostInstanceType")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "hostInstanceType", valid_601263
  var valid_601264 = query.getOrDefault("engineType")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "engineType", valid_601264
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
  var valid_601265 = header.getOrDefault("X-Amz-Date")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Date", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Security-Token")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Security-Token", valid_601266
  var valid_601267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-Content-Sha256", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-Algorithm")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Algorithm", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-Signature")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Signature", valid_601269
  var valid_601270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-SignedHeaders", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-Credential")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-Credential", valid_601271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601272: Call_DescribeBrokerInstanceOptions_601258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe available broker instance options.
  ## 
  let valid = call_601272.validator(path, query, header, formData, body)
  let scheme = call_601272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601272.url(scheme.get, call_601272.host, call_601272.base,
                         call_601272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601272, url, valid)

proc call*(call_601273: Call_DescribeBrokerInstanceOptions_601258;
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
  var query_601274 = newJObject()
  add(query_601274, "maxResults", newJInt(maxResults))
  add(query_601274, "nextToken", newJString(nextToken))
  add(query_601274, "hostInstanceType", newJString(hostInstanceType))
  add(query_601274, "engineType", newJString(engineType))
  result = call_601273.call(nil, query_601274, nil, nil, nil)

var describeBrokerInstanceOptions* = Call_DescribeBrokerInstanceOptions_601258(
    name: "describeBrokerInstanceOptions", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/broker-instance-options",
    validator: validate_DescribeBrokerInstanceOptions_601259, base: "/",
    url: url_DescribeBrokerInstanceOptions_601260,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfiguration_601289 = ref object of OpenApiRestCall_600437
proc url_UpdateConfiguration_601291(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateConfiguration_601290(path: JsonNode; query: JsonNode;
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
  var valid_601292 = path.getOrDefault("configuration-id")
  valid_601292 = validateParameter(valid_601292, JString, required = true,
                                 default = nil)
  if valid_601292 != nil:
    section.add "configuration-id", valid_601292
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
  var valid_601293 = header.getOrDefault("X-Amz-Date")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Date", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-Security-Token")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-Security-Token", valid_601294
  var valid_601295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Content-Sha256", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-Algorithm")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Algorithm", valid_601296
  var valid_601297 = header.getOrDefault("X-Amz-Signature")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "X-Amz-Signature", valid_601297
  var valid_601298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-SignedHeaders", valid_601298
  var valid_601299 = header.getOrDefault("X-Amz-Credential")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-Credential", valid_601299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601301: Call_UpdateConfiguration_601289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified configuration.
  ## 
  let valid = call_601301.validator(path, query, header, formData, body)
  let scheme = call_601301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601301.url(scheme.get, call_601301.host, call_601301.base,
                         call_601301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601301, url, valid)

proc call*(call_601302: Call_UpdateConfiguration_601289; body: JsonNode;
          configurationId: string): Recallable =
  ## updateConfiguration
  ## Updates the specified configuration.
  ##   body: JObject (required)
  ##   configurationId: string (required)
  ##                  : The unique ID that Amazon MQ generates for the configuration.
  var path_601303 = newJObject()
  var body_601304 = newJObject()
  if body != nil:
    body_601304 = body
  add(path_601303, "configuration-id", newJString(configurationId))
  result = call_601302.call(path_601303, nil, nil, nil, body_601304)

var updateConfiguration* = Call_UpdateConfiguration_601289(
    name: "updateConfiguration", meth: HttpMethod.HttpPut, host: "mq.amazonaws.com",
    route: "/v1/configurations/{configuration-id}",
    validator: validate_UpdateConfiguration_601290, base: "/",
    url: url_UpdateConfiguration_601291, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfiguration_601275 = ref object of OpenApiRestCall_600437
proc url_DescribeConfiguration_601277(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeConfiguration_601276(path: JsonNode; query: JsonNode;
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
  var valid_601278 = path.getOrDefault("configuration-id")
  valid_601278 = validateParameter(valid_601278, JString, required = true,
                                 default = nil)
  if valid_601278 != nil:
    section.add "configuration-id", valid_601278
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
  var valid_601279 = header.getOrDefault("X-Amz-Date")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-Date", valid_601279
  var valid_601280 = header.getOrDefault("X-Amz-Security-Token")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Security-Token", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Content-Sha256", valid_601281
  var valid_601282 = header.getOrDefault("X-Amz-Algorithm")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "X-Amz-Algorithm", valid_601282
  var valid_601283 = header.getOrDefault("X-Amz-Signature")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-Signature", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-SignedHeaders", valid_601284
  var valid_601285 = header.getOrDefault("X-Amz-Credential")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-Credential", valid_601285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601286: Call_DescribeConfiguration_601275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified configuration.
  ## 
  let valid = call_601286.validator(path, query, header, formData, body)
  let scheme = call_601286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601286.url(scheme.get, call_601286.host, call_601286.base,
                         call_601286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601286, url, valid)

proc call*(call_601287: Call_DescribeConfiguration_601275; configurationId: string): Recallable =
  ## describeConfiguration
  ## Returns information about the specified configuration.
  ##   configurationId: string (required)
  ##                  : The unique ID that Amazon MQ generates for the configuration.
  var path_601288 = newJObject()
  add(path_601288, "configuration-id", newJString(configurationId))
  result = call_601287.call(path_601288, nil, nil, nil, nil)

var describeConfiguration* = Call_DescribeConfiguration_601275(
    name: "describeConfiguration", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/configurations/{configuration-id}",
    validator: validate_DescribeConfiguration_601276, base: "/",
    url: url_DescribeConfiguration_601277, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationRevision_601305 = ref object of OpenApiRestCall_600437
proc url_DescribeConfigurationRevision_601307(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DescribeConfigurationRevision_601306(path: JsonNode; query: JsonNode;
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
  var valid_601308 = path.getOrDefault("configuration-revision")
  valid_601308 = validateParameter(valid_601308, JString, required = true,
                                 default = nil)
  if valid_601308 != nil:
    section.add "configuration-revision", valid_601308
  var valid_601309 = path.getOrDefault("configuration-id")
  valid_601309 = validateParameter(valid_601309, JString, required = true,
                                 default = nil)
  if valid_601309 != nil:
    section.add "configuration-id", valid_601309
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
  var valid_601310 = header.getOrDefault("X-Amz-Date")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Date", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-Security-Token")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-Security-Token", valid_601311
  var valid_601312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Content-Sha256", valid_601312
  var valid_601313 = header.getOrDefault("X-Amz-Algorithm")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-Algorithm", valid_601313
  var valid_601314 = header.getOrDefault("X-Amz-Signature")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-Signature", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-SignedHeaders", valid_601315
  var valid_601316 = header.getOrDefault("X-Amz-Credential")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-Credential", valid_601316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601317: Call_DescribeConfigurationRevision_601305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the specified configuration revision for the specified configuration.
  ## 
  let valid = call_601317.validator(path, query, header, formData, body)
  let scheme = call_601317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601317.url(scheme.get, call_601317.host, call_601317.base,
                         call_601317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601317, url, valid)

proc call*(call_601318: Call_DescribeConfigurationRevision_601305;
          configurationRevision: string; configurationId: string): Recallable =
  ## describeConfigurationRevision
  ## Returns the specified configuration revision for the specified configuration.
  ##   configurationRevision: string (required)
  ##                        : The revision of the configuration.
  ##   configurationId: string (required)
  ##                  : The unique ID that Amazon MQ generates for the configuration.
  var path_601319 = newJObject()
  add(path_601319, "configuration-revision", newJString(configurationRevision))
  add(path_601319, "configuration-id", newJString(configurationId))
  result = call_601318.call(path_601319, nil, nil, nil, nil)

var describeConfigurationRevision* = Call_DescribeConfigurationRevision_601305(
    name: "describeConfigurationRevision", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/configurations/{configuration-id}/revisions/{configuration-revision}",
    validator: validate_DescribeConfigurationRevision_601306, base: "/",
    url: url_DescribeConfigurationRevision_601307,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationRevisions_601320 = ref object of OpenApiRestCall_600437
proc url_ListConfigurationRevisions_601322(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_ListConfigurationRevisions_601321(path: JsonNode; query: JsonNode;
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
  var valid_601323 = path.getOrDefault("configuration-id")
  valid_601323 = validateParameter(valid_601323, JString, required = true,
                                 default = nil)
  if valid_601323 != nil:
    section.add "configuration-id", valid_601323
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of configurations that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: JString
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  section = newJObject()
  var valid_601324 = query.getOrDefault("maxResults")
  valid_601324 = validateParameter(valid_601324, JInt, required = false, default = nil)
  if valid_601324 != nil:
    section.add "maxResults", valid_601324
  var valid_601325 = query.getOrDefault("nextToken")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "nextToken", valid_601325
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
  var valid_601326 = header.getOrDefault("X-Amz-Date")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Date", valid_601326
  var valid_601327 = header.getOrDefault("X-Amz-Security-Token")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "X-Amz-Security-Token", valid_601327
  var valid_601328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-Content-Sha256", valid_601328
  var valid_601329 = header.getOrDefault("X-Amz-Algorithm")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-Algorithm", valid_601329
  var valid_601330 = header.getOrDefault("X-Amz-Signature")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-Signature", valid_601330
  var valid_601331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-SignedHeaders", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-Credential")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Credential", valid_601332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601333: Call_ListConfigurationRevisions_601320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all revisions for the specified configuration.
  ## 
  let valid = call_601333.validator(path, query, header, formData, body)
  let scheme = call_601333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601333.url(scheme.get, call_601333.host, call_601333.base,
                         call_601333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601333, url, valid)

proc call*(call_601334: Call_ListConfigurationRevisions_601320;
          configurationId: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listConfigurationRevisions
  ## Returns a list of all revisions for the specified configuration.
  ##   maxResults: int
  ##             : The maximum number of configurations that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   configurationId: string (required)
  ##                  : The unique ID that Amazon MQ generates for the configuration.
  var path_601335 = newJObject()
  var query_601336 = newJObject()
  add(query_601336, "maxResults", newJInt(maxResults))
  add(query_601336, "nextToken", newJString(nextToken))
  add(path_601335, "configuration-id", newJString(configurationId))
  result = call_601334.call(path_601335, query_601336, nil, nil, nil)

var listConfigurationRevisions* = Call_ListConfigurationRevisions_601320(
    name: "listConfigurationRevisions", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com",
    route: "/v1/configurations/{configuration-id}/revisions",
    validator: validate_ListConfigurationRevisions_601321, base: "/",
    url: url_ListConfigurationRevisions_601322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_601337 = ref object of OpenApiRestCall_600437
proc url_ListUsers_601339(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
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
  result.path = base & hydrated.get

proc validate_ListUsers_601338(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601340 = path.getOrDefault("broker-id")
  valid_601340 = validateParameter(valid_601340, JString, required = true,
                                 default = nil)
  if valid_601340 != nil:
    section.add "broker-id", valid_601340
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of ActiveMQ users that can be returned per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: JString
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  section = newJObject()
  var valid_601341 = query.getOrDefault("maxResults")
  valid_601341 = validateParameter(valid_601341, JInt, required = false, default = nil)
  if valid_601341 != nil:
    section.add "maxResults", valid_601341
  var valid_601342 = query.getOrDefault("nextToken")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "nextToken", valid_601342
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
  var valid_601343 = header.getOrDefault("X-Amz-Date")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Date", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Security-Token")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Security-Token", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Content-Sha256", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-Algorithm")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-Algorithm", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-Signature")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Signature", valid_601347
  var valid_601348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "X-Amz-SignedHeaders", valid_601348
  var valid_601349 = header.getOrDefault("X-Amz-Credential")
  valid_601349 = validateParameter(valid_601349, JString, required = false,
                                 default = nil)
  if valid_601349 != nil:
    section.add "X-Amz-Credential", valid_601349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601350: Call_ListUsers_601337; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all ActiveMQ users.
  ## 
  let valid = call_601350.validator(path, query, header, formData, body)
  let scheme = call_601350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601350.url(scheme.get, call_601350.host, call_601350.base,
                         call_601350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601350, url, valid)

proc call*(call_601351: Call_ListUsers_601337; brokerId: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listUsers
  ## Returns a list of all ActiveMQ users.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   maxResults: int
  ##             : The maximum number of ActiveMQ users that can be returned per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  var path_601352 = newJObject()
  var query_601353 = newJObject()
  add(path_601352, "broker-id", newJString(brokerId))
  add(query_601353, "maxResults", newJInt(maxResults))
  add(query_601353, "nextToken", newJString(nextToken))
  result = call_601351.call(path_601352, query_601353, nil, nil, nil)

var listUsers* = Call_ListUsers_601337(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "mq.amazonaws.com",
                                    route: "/v1/brokers/{broker-id}/users",
                                    validator: validate_ListUsers_601338,
                                    base: "/", url: url_ListUsers_601339,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootBroker_601354 = ref object of OpenApiRestCall_600437
proc url_RebootBroker_601356(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_RebootBroker_601355(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601357 = path.getOrDefault("broker-id")
  valid_601357 = validateParameter(valid_601357, JString, required = true,
                                 default = nil)
  if valid_601357 != nil:
    section.add "broker-id", valid_601357
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
  var valid_601358 = header.getOrDefault("X-Amz-Date")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Date", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Security-Token")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Security-Token", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-Content-Sha256", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-Algorithm")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-Algorithm", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-Signature")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-Signature", valid_601362
  var valid_601363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-SignedHeaders", valid_601363
  var valid_601364 = header.getOrDefault("X-Amz-Credential")
  valid_601364 = validateParameter(valid_601364, JString, required = false,
                                 default = nil)
  if valid_601364 != nil:
    section.add "X-Amz-Credential", valid_601364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601365: Call_RebootBroker_601354; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Reboots a broker. Note: This API is asynchronous.
  ## 
  let valid = call_601365.validator(path, query, header, formData, body)
  let scheme = call_601365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601365.url(scheme.get, call_601365.host, call_601365.base,
                         call_601365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601365, url, valid)

proc call*(call_601366: Call_RebootBroker_601354; brokerId: string): Recallable =
  ## rebootBroker
  ## Reboots a broker. Note: This API is asynchronous.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  var path_601367 = newJObject()
  add(path_601367, "broker-id", newJString(brokerId))
  result = call_601366.call(path_601367, nil, nil, nil, nil)

var rebootBroker* = Call_RebootBroker_601354(name: "rebootBroker",
    meth: HttpMethod.HttpPost, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}/reboot", validator: validate_RebootBroker_601355,
    base: "/", url: url_RebootBroker_601356, schemes: {Scheme.Https, Scheme.Http})
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
