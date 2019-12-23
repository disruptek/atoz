
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateBroker_599962 = ref object of OpenApiRestCall_599368
proc url_CreateBroker_599964(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateBroker_599963(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599965 = header.getOrDefault("X-Amz-Date")
  valid_599965 = validateParameter(valid_599965, JString, required = false,
                                 default = nil)
  if valid_599965 != nil:
    section.add "X-Amz-Date", valid_599965
  var valid_599966 = header.getOrDefault("X-Amz-Security-Token")
  valid_599966 = validateParameter(valid_599966, JString, required = false,
                                 default = nil)
  if valid_599966 != nil:
    section.add "X-Amz-Security-Token", valid_599966
  var valid_599967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599967 = validateParameter(valid_599967, JString, required = false,
                                 default = nil)
  if valid_599967 != nil:
    section.add "X-Amz-Content-Sha256", valid_599967
  var valid_599968 = header.getOrDefault("X-Amz-Algorithm")
  valid_599968 = validateParameter(valid_599968, JString, required = false,
                                 default = nil)
  if valid_599968 != nil:
    section.add "X-Amz-Algorithm", valid_599968
  var valid_599969 = header.getOrDefault("X-Amz-Signature")
  valid_599969 = validateParameter(valid_599969, JString, required = false,
                                 default = nil)
  if valid_599969 != nil:
    section.add "X-Amz-Signature", valid_599969
  var valid_599970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599970 = validateParameter(valid_599970, JString, required = false,
                                 default = nil)
  if valid_599970 != nil:
    section.add "X-Amz-SignedHeaders", valid_599970
  var valid_599971 = header.getOrDefault("X-Amz-Credential")
  valid_599971 = validateParameter(valid_599971, JString, required = false,
                                 default = nil)
  if valid_599971 != nil:
    section.add "X-Amz-Credential", valid_599971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599973: Call_CreateBroker_599962; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a broker. Note: This API is asynchronous.
  ## 
  let valid = call_599973.validator(path, query, header, formData, body)
  let scheme = call_599973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599973.url(scheme.get, call_599973.host, call_599973.base,
                         call_599973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599973, url, valid)

proc call*(call_599974: Call_CreateBroker_599962; body: JsonNode): Recallable =
  ## createBroker
  ## Creates a broker. Note: This API is asynchronous.
  ##   body: JObject (required)
  var body_599975 = newJObject()
  if body != nil:
    body_599975 = body
  result = call_599974.call(nil, nil, nil, nil, body_599975)

var createBroker* = Call_CreateBroker_599962(name: "createBroker",
    meth: HttpMethod.HttpPost, host: "mq.amazonaws.com", route: "/v1/brokers",
    validator: validate_CreateBroker_599963, base: "/", url: url_CreateBroker_599964,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBrokers_599705 = ref object of OpenApiRestCall_599368
proc url_ListBrokers_599707(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBrokers_599706(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599819 = query.getOrDefault("maxResults")
  valid_599819 = validateParameter(valid_599819, JInt, required = false, default = nil)
  if valid_599819 != nil:
    section.add "maxResults", valid_599819
  var valid_599820 = query.getOrDefault("nextToken")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "nextToken", valid_599820
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
  var valid_599821 = header.getOrDefault("X-Amz-Date")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "X-Amz-Date", valid_599821
  var valid_599822 = header.getOrDefault("X-Amz-Security-Token")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "X-Amz-Security-Token", valid_599822
  var valid_599823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "X-Amz-Content-Sha256", valid_599823
  var valid_599824 = header.getOrDefault("X-Amz-Algorithm")
  valid_599824 = validateParameter(valid_599824, JString, required = false,
                                 default = nil)
  if valid_599824 != nil:
    section.add "X-Amz-Algorithm", valid_599824
  var valid_599825 = header.getOrDefault("X-Amz-Signature")
  valid_599825 = validateParameter(valid_599825, JString, required = false,
                                 default = nil)
  if valid_599825 != nil:
    section.add "X-Amz-Signature", valid_599825
  var valid_599826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599826 = validateParameter(valid_599826, JString, required = false,
                                 default = nil)
  if valid_599826 != nil:
    section.add "X-Amz-SignedHeaders", valid_599826
  var valid_599827 = header.getOrDefault("X-Amz-Credential")
  valid_599827 = validateParameter(valid_599827, JString, required = false,
                                 default = nil)
  if valid_599827 != nil:
    section.add "X-Amz-Credential", valid_599827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599850: Call_ListBrokers_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all brokers.
  ## 
  let valid = call_599850.validator(path, query, header, formData, body)
  let scheme = call_599850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599850.url(scheme.get, call_599850.host, call_599850.base,
                         call_599850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599850, url, valid)

proc call*(call_599921: Call_ListBrokers_599705; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listBrokers
  ## Returns a list of all brokers.
  ##   maxResults: int
  ##             : The maximum number of brokers that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  var query_599922 = newJObject()
  add(query_599922, "maxResults", newJInt(maxResults))
  add(query_599922, "nextToken", newJString(nextToken))
  result = call_599921.call(nil, query_599922, nil, nil, nil)

var listBrokers* = Call_ListBrokers_599705(name: "listBrokers",
                                        meth: HttpMethod.HttpGet,
                                        host: "mq.amazonaws.com",
                                        route: "/v1/brokers",
                                        validator: validate_ListBrokers_599706,
                                        base: "/", url: url_ListBrokers_599707,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfiguration_599991 = ref object of OpenApiRestCall_599368
proc url_CreateConfiguration_599993(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConfiguration_599992(path: JsonNode; query: JsonNode;
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
  var valid_599994 = header.getOrDefault("X-Amz-Date")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "X-Amz-Date", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Security-Token")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Security-Token", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Content-Sha256", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Algorithm")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Algorithm", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-Signature")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Signature", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-SignedHeaders", valid_599999
  var valid_600000 = header.getOrDefault("X-Amz-Credential")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-Credential", valid_600000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600002: Call_CreateConfiguration_599991; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new configuration for the specified configuration name. Amazon MQ uses the default configuration (the engine type and version).
  ## 
  let valid = call_600002.validator(path, query, header, formData, body)
  let scheme = call_600002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600002.url(scheme.get, call_600002.host, call_600002.base,
                         call_600002.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600002, url, valid)

proc call*(call_600003: Call_CreateConfiguration_599991; body: JsonNode): Recallable =
  ## createConfiguration
  ## Creates a new configuration for the specified configuration name. Amazon MQ uses the default configuration (the engine type and version).
  ##   body: JObject (required)
  var body_600004 = newJObject()
  if body != nil:
    body_600004 = body
  result = call_600003.call(nil, nil, nil, nil, body_600004)

var createConfiguration* = Call_CreateConfiguration_599991(
    name: "createConfiguration", meth: HttpMethod.HttpPost,
    host: "mq.amazonaws.com", route: "/v1/configurations",
    validator: validate_CreateConfiguration_599992, base: "/",
    url: url_CreateConfiguration_599993, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurations_599976 = ref object of OpenApiRestCall_599368
proc url_ListConfigurations_599978(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConfigurations_599977(path: JsonNode; query: JsonNode;
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
  var valid_599979 = query.getOrDefault("maxResults")
  valid_599979 = validateParameter(valid_599979, JInt, required = false, default = nil)
  if valid_599979 != nil:
    section.add "maxResults", valid_599979
  var valid_599980 = query.getOrDefault("nextToken")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "nextToken", valid_599980
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
  var valid_599981 = header.getOrDefault("X-Amz-Date")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Date", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Security-Token")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Security-Token", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Content-Sha256", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Algorithm")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Algorithm", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Signature")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Signature", valid_599985
  var valid_599986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-SignedHeaders", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-Credential")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Credential", valid_599987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599988: Call_ListConfigurations_599976; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all configurations.
  ## 
  let valid = call_599988.validator(path, query, header, formData, body)
  let scheme = call_599988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599988.url(scheme.get, call_599988.host, call_599988.base,
                         call_599988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599988, url, valid)

proc call*(call_599989: Call_ListConfigurations_599976; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listConfigurations
  ## Returns a list of all configurations.
  ##   maxResults: int
  ##             : The maximum number of configurations that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  var query_599990 = newJObject()
  add(query_599990, "maxResults", newJInt(maxResults))
  add(query_599990, "nextToken", newJString(nextToken))
  result = call_599989.call(nil, query_599990, nil, nil, nil)

var listConfigurations* = Call_ListConfigurations_599976(
    name: "listConfigurations", meth: HttpMethod.HttpGet, host: "mq.amazonaws.com",
    route: "/v1/configurations", validator: validate_ListConfigurations_599977,
    base: "/", url: url_ListConfigurations_599978,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_600033 = ref object of OpenApiRestCall_599368
proc url_CreateTags_600035(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateTags_600034(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600036 = path.getOrDefault("resource-arn")
  valid_600036 = validateParameter(valid_600036, JString, required = true,
                                 default = nil)
  if valid_600036 != nil:
    section.add "resource-arn", valid_600036
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
  var valid_600037 = header.getOrDefault("X-Amz-Date")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Date", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Security-Token")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Security-Token", valid_600038
  var valid_600039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Content-Sha256", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Algorithm")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Algorithm", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Signature")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Signature", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-SignedHeaders", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Credential")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Credential", valid_600043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600045: Call_CreateTags_600033; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a tag to a resource.
  ## 
  let valid = call_600045.validator(path, query, header, formData, body)
  let scheme = call_600045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600045.url(scheme.get, call_600045.host, call_600045.base,
                         call_600045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600045, url, valid)

proc call*(call_600046: Call_CreateTags_600033; resourceArn: string; body: JsonNode): Recallable =
  ## createTags
  ## Add a tag to a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource tag.
  ##   body: JObject (required)
  var path_600047 = newJObject()
  var body_600048 = newJObject()
  add(path_600047, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_600048 = body
  result = call_600046.call(path_600047, nil, nil, nil, body_600048)

var createTags* = Call_CreateTags_600033(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "mq.amazonaws.com",
                                      route: "/v1/tags/{resource-arn}",
                                      validator: validate_CreateTags_600034,
                                      base: "/", url: url_CreateTags_600035,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_600005 = ref object of OpenApiRestCall_599368
proc url_ListTags_600007(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTags_600006(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600022 = path.getOrDefault("resource-arn")
  valid_600022 = validateParameter(valid_600022, JString, required = true,
                                 default = nil)
  if valid_600022 != nil:
    section.add "resource-arn", valid_600022
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
  var valid_600023 = header.getOrDefault("X-Amz-Date")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Date", valid_600023
  var valid_600024 = header.getOrDefault("X-Amz-Security-Token")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-Security-Token", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Content-Sha256", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Algorithm")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Algorithm", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Signature")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Signature", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-SignedHeaders", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Credential")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Credential", valid_600029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600030: Call_ListTags_600005; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists tags for a resource.
  ## 
  let valid = call_600030.validator(path, query, header, formData, body)
  let scheme = call_600030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600030.url(scheme.get, call_600030.host, call_600030.base,
                         call_600030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600030, url, valid)

proc call*(call_600031: Call_ListTags_600005; resourceArn: string): Recallable =
  ## listTags
  ## Lists tags for a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource tag.
  var path_600032 = newJObject()
  add(path_600032, "resource-arn", newJString(resourceArn))
  result = call_600031.call(path_600032, nil, nil, nil, nil)

var listTags* = Call_ListTags_600005(name: "listTags", meth: HttpMethod.HttpGet,
                                  host: "mq.amazonaws.com",
                                  route: "/v1/tags/{resource-arn}",
                                  validator: validate_ListTags_600006, base: "/",
                                  url: url_ListTags_600007,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_600064 = ref object of OpenApiRestCall_599368
proc url_UpdateUser_600066(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUser_600065(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600067 = path.getOrDefault("broker-id")
  valid_600067 = validateParameter(valid_600067, JString, required = true,
                                 default = nil)
  if valid_600067 != nil:
    section.add "broker-id", valid_600067
  var valid_600068 = path.getOrDefault("username")
  valid_600068 = validateParameter(valid_600068, JString, required = true,
                                 default = nil)
  if valid_600068 != nil:
    section.add "username", valid_600068
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
  var valid_600069 = header.getOrDefault("X-Amz-Date")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "X-Amz-Date", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Security-Token")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Security-Token", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Content-Sha256", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Algorithm")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Algorithm", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-Signature")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-Signature", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-SignedHeaders", valid_600074
  var valid_600075 = header.getOrDefault("X-Amz-Credential")
  valid_600075 = validateParameter(valid_600075, JString, required = false,
                                 default = nil)
  if valid_600075 != nil:
    section.add "X-Amz-Credential", valid_600075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600077: Call_UpdateUser_600064; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the information for an ActiveMQ user.
  ## 
  let valid = call_600077.validator(path, query, header, formData, body)
  let scheme = call_600077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600077.url(scheme.get, call_600077.host, call_600077.base,
                         call_600077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600077, url, valid)

proc call*(call_600078: Call_UpdateUser_600064; brokerId: string; username: string;
          body: JsonNode): Recallable =
  ## updateUser
  ## Updates the information for an ActiveMQ user.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   username: string (required)
  ##           : Required. The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  ##   body: JObject (required)
  var path_600079 = newJObject()
  var body_600080 = newJObject()
  add(path_600079, "broker-id", newJString(brokerId))
  add(path_600079, "username", newJString(username))
  if body != nil:
    body_600080 = body
  result = call_600078.call(path_600079, nil, nil, nil, body_600080)

var updateUser* = Call_UpdateUser_600064(name: "updateUser",
                                      meth: HttpMethod.HttpPut,
                                      host: "mq.amazonaws.com", route: "/v1/brokers/{broker-id}/users/{username}",
                                      validator: validate_UpdateUser_600065,
                                      base: "/", url: url_UpdateUser_600066,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_600081 = ref object of OpenApiRestCall_599368
proc url_CreateUser_600083(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateUser_600082(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600084 = path.getOrDefault("broker-id")
  valid_600084 = validateParameter(valid_600084, JString, required = true,
                                 default = nil)
  if valid_600084 != nil:
    section.add "broker-id", valid_600084
  var valid_600085 = path.getOrDefault("username")
  valid_600085 = validateParameter(valid_600085, JString, required = true,
                                 default = nil)
  if valid_600085 != nil:
    section.add "username", valid_600085
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
  var valid_600086 = header.getOrDefault("X-Amz-Date")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Date", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Security-Token")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Security-Token", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-Content-Sha256", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Algorithm")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Algorithm", valid_600089
  var valid_600090 = header.getOrDefault("X-Amz-Signature")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "X-Amz-Signature", valid_600090
  var valid_600091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600091 = validateParameter(valid_600091, JString, required = false,
                                 default = nil)
  if valid_600091 != nil:
    section.add "X-Amz-SignedHeaders", valid_600091
  var valid_600092 = header.getOrDefault("X-Amz-Credential")
  valid_600092 = validateParameter(valid_600092, JString, required = false,
                                 default = nil)
  if valid_600092 != nil:
    section.add "X-Amz-Credential", valid_600092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600094: Call_CreateUser_600081; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an ActiveMQ user.
  ## 
  let valid = call_600094.validator(path, query, header, formData, body)
  let scheme = call_600094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600094.url(scheme.get, call_600094.host, call_600094.base,
                         call_600094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600094, url, valid)

proc call*(call_600095: Call_CreateUser_600081; brokerId: string; username: string;
          body: JsonNode): Recallable =
  ## createUser
  ## Creates an ActiveMQ user.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   username: string (required)
  ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  ##   body: JObject (required)
  var path_600096 = newJObject()
  var body_600097 = newJObject()
  add(path_600096, "broker-id", newJString(brokerId))
  add(path_600096, "username", newJString(username))
  if body != nil:
    body_600097 = body
  result = call_600095.call(path_600096, nil, nil, nil, body_600097)

var createUser* = Call_CreateUser_600081(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "mq.amazonaws.com", route: "/v1/brokers/{broker-id}/users/{username}",
                                      validator: validate_CreateUser_600082,
                                      base: "/", url: url_CreateUser_600083,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_600049 = ref object of OpenApiRestCall_599368
proc url_DescribeUser_600051(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeUser_600050(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600052 = path.getOrDefault("broker-id")
  valid_600052 = validateParameter(valid_600052, JString, required = true,
                                 default = nil)
  if valid_600052 != nil:
    section.add "broker-id", valid_600052
  var valid_600053 = path.getOrDefault("username")
  valid_600053 = validateParameter(valid_600053, JString, required = true,
                                 default = nil)
  if valid_600053 != nil:
    section.add "username", valid_600053
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
  var valid_600054 = header.getOrDefault("X-Amz-Date")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "X-Amz-Date", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Security-Token")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Security-Token", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Content-Sha256", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Algorithm")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Algorithm", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-Signature")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-Signature", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-SignedHeaders", valid_600059
  var valid_600060 = header.getOrDefault("X-Amz-Credential")
  valid_600060 = validateParameter(valid_600060, JString, required = false,
                                 default = nil)
  if valid_600060 != nil:
    section.add "X-Amz-Credential", valid_600060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600061: Call_DescribeUser_600049; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about an ActiveMQ user.
  ## 
  let valid = call_600061.validator(path, query, header, formData, body)
  let scheme = call_600061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600061.url(scheme.get, call_600061.host, call_600061.base,
                         call_600061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600061, url, valid)

proc call*(call_600062: Call_DescribeUser_600049; brokerId: string; username: string): Recallable =
  ## describeUser
  ## Returns information about an ActiveMQ user.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   username: string (required)
  ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  var path_600063 = newJObject()
  add(path_600063, "broker-id", newJString(brokerId))
  add(path_600063, "username", newJString(username))
  result = call_600062.call(path_600063, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_600049(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}/users/{username}",
    validator: validate_DescribeUser_600050, base: "/", url: url_DescribeUser_600051,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_600098 = ref object of OpenApiRestCall_599368
proc url_DeleteUser_600100(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteUser_600099(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600101 = path.getOrDefault("broker-id")
  valid_600101 = validateParameter(valid_600101, JString, required = true,
                                 default = nil)
  if valid_600101 != nil:
    section.add "broker-id", valid_600101
  var valid_600102 = path.getOrDefault("username")
  valid_600102 = validateParameter(valid_600102, JString, required = true,
                                 default = nil)
  if valid_600102 != nil:
    section.add "username", valid_600102
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
  var valid_600103 = header.getOrDefault("X-Amz-Date")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-Date", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Security-Token")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Security-Token", valid_600104
  var valid_600105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Content-Sha256", valid_600105
  var valid_600106 = header.getOrDefault("X-Amz-Algorithm")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "X-Amz-Algorithm", valid_600106
  var valid_600107 = header.getOrDefault("X-Amz-Signature")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "X-Amz-Signature", valid_600107
  var valid_600108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "X-Amz-SignedHeaders", valid_600108
  var valid_600109 = header.getOrDefault("X-Amz-Credential")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "X-Amz-Credential", valid_600109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600110: Call_DeleteUser_600098; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an ActiveMQ user.
  ## 
  let valid = call_600110.validator(path, query, header, formData, body)
  let scheme = call_600110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600110.url(scheme.get, call_600110.host, call_600110.base,
                         call_600110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600110, url, valid)

proc call*(call_600111: Call_DeleteUser_600098; brokerId: string; username: string): Recallable =
  ## deleteUser
  ## Deletes an ActiveMQ user.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   username: string (required)
  ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  var path_600112 = newJObject()
  add(path_600112, "broker-id", newJString(brokerId))
  add(path_600112, "username", newJString(username))
  result = call_600111.call(path_600112, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_600098(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "mq.amazonaws.com", route: "/v1/brokers/{broker-id}/users/{username}",
                                      validator: validate_DeleteUser_600099,
                                      base: "/", url: url_DeleteUser_600100,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBroker_600127 = ref object of OpenApiRestCall_599368
proc url_UpdateBroker_600129(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateBroker_600128(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600130 = path.getOrDefault("broker-id")
  valid_600130 = validateParameter(valid_600130, JString, required = true,
                                 default = nil)
  if valid_600130 != nil:
    section.add "broker-id", valid_600130
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
  var valid_600131 = header.getOrDefault("X-Amz-Date")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Date", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Security-Token")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Security-Token", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-Content-Sha256", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Algorithm")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Algorithm", valid_600134
  var valid_600135 = header.getOrDefault("X-Amz-Signature")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "X-Amz-Signature", valid_600135
  var valid_600136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "X-Amz-SignedHeaders", valid_600136
  var valid_600137 = header.getOrDefault("X-Amz-Credential")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "X-Amz-Credential", valid_600137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600139: Call_UpdateBroker_600127; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a pending configuration change to a broker.
  ## 
  let valid = call_600139.validator(path, query, header, formData, body)
  let scheme = call_600139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600139.url(scheme.get, call_600139.host, call_600139.base,
                         call_600139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600139, url, valid)

proc call*(call_600140: Call_UpdateBroker_600127; brokerId: string; body: JsonNode): Recallable =
  ## updateBroker
  ## Adds a pending configuration change to a broker.
  ##   brokerId: string (required)
  ##           : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  ##   body: JObject (required)
  var path_600141 = newJObject()
  var body_600142 = newJObject()
  add(path_600141, "broker-id", newJString(brokerId))
  if body != nil:
    body_600142 = body
  result = call_600140.call(path_600141, nil, nil, nil, body_600142)

var updateBroker* = Call_UpdateBroker_600127(name: "updateBroker",
    meth: HttpMethod.HttpPut, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}", validator: validate_UpdateBroker_600128,
    base: "/", url: url_UpdateBroker_600129, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBroker_600113 = ref object of OpenApiRestCall_599368
proc url_DescribeBroker_600115(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeBroker_600114(path: JsonNode; query: JsonNode;
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
  var valid_600116 = path.getOrDefault("broker-id")
  valid_600116 = validateParameter(valid_600116, JString, required = true,
                                 default = nil)
  if valid_600116 != nil:
    section.add "broker-id", valid_600116
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
  var valid_600117 = header.getOrDefault("X-Amz-Date")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Date", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-Security-Token")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Security-Token", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Content-Sha256", valid_600119
  var valid_600120 = header.getOrDefault("X-Amz-Algorithm")
  valid_600120 = validateParameter(valid_600120, JString, required = false,
                                 default = nil)
  if valid_600120 != nil:
    section.add "X-Amz-Algorithm", valid_600120
  var valid_600121 = header.getOrDefault("X-Amz-Signature")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "X-Amz-Signature", valid_600121
  var valid_600122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-SignedHeaders", valid_600122
  var valid_600123 = header.getOrDefault("X-Amz-Credential")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Credential", valid_600123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600124: Call_DescribeBroker_600113; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified broker.
  ## 
  let valid = call_600124.validator(path, query, header, formData, body)
  let scheme = call_600124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600124.url(scheme.get, call_600124.host, call_600124.base,
                         call_600124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600124, url, valid)

proc call*(call_600125: Call_DescribeBroker_600113; brokerId: string): Recallable =
  ## describeBroker
  ## Returns information about the specified broker.
  ##   brokerId: string (required)
  ##           : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  var path_600126 = newJObject()
  add(path_600126, "broker-id", newJString(brokerId))
  result = call_600125.call(path_600126, nil, nil, nil, nil)

var describeBroker* = Call_DescribeBroker_600113(name: "describeBroker",
    meth: HttpMethod.HttpGet, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}", validator: validate_DescribeBroker_600114,
    base: "/", url: url_DescribeBroker_600115, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBroker_600143 = ref object of OpenApiRestCall_599368
proc url_DeleteBroker_600145(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBroker_600144(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600146 = path.getOrDefault("broker-id")
  valid_600146 = validateParameter(valid_600146, JString, required = true,
                                 default = nil)
  if valid_600146 != nil:
    section.add "broker-id", valid_600146
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
  var valid_600147 = header.getOrDefault("X-Amz-Date")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Date", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-Security-Token")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-Security-Token", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Content-Sha256", valid_600149
  var valid_600150 = header.getOrDefault("X-Amz-Algorithm")
  valid_600150 = validateParameter(valid_600150, JString, required = false,
                                 default = nil)
  if valid_600150 != nil:
    section.add "X-Amz-Algorithm", valid_600150
  var valid_600151 = header.getOrDefault("X-Amz-Signature")
  valid_600151 = validateParameter(valid_600151, JString, required = false,
                                 default = nil)
  if valid_600151 != nil:
    section.add "X-Amz-Signature", valid_600151
  var valid_600152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600152 = validateParameter(valid_600152, JString, required = false,
                                 default = nil)
  if valid_600152 != nil:
    section.add "X-Amz-SignedHeaders", valid_600152
  var valid_600153 = header.getOrDefault("X-Amz-Credential")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "X-Amz-Credential", valid_600153
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600154: Call_DeleteBroker_600143; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a broker. Note: This API is asynchronous.
  ## 
  let valid = call_600154.validator(path, query, header, formData, body)
  let scheme = call_600154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600154.url(scheme.get, call_600154.host, call_600154.base,
                         call_600154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600154, url, valid)

proc call*(call_600155: Call_DeleteBroker_600143; brokerId: string): Recallable =
  ## deleteBroker
  ## Deletes a broker. Note: This API is asynchronous.
  ##   brokerId: string (required)
  ##           : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  var path_600156 = newJObject()
  add(path_600156, "broker-id", newJString(brokerId))
  result = call_600155.call(path_600156, nil, nil, nil, nil)

var deleteBroker* = Call_DeleteBroker_600143(name: "deleteBroker",
    meth: HttpMethod.HttpDelete, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}", validator: validate_DeleteBroker_600144,
    base: "/", url: url_DeleteBroker_600145, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_600157 = ref object of OpenApiRestCall_599368
proc url_DeleteTags_600159(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteTags_600158(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600160 = path.getOrDefault("resource-arn")
  valid_600160 = validateParameter(valid_600160, JString, required = true,
                                 default = nil)
  if valid_600160 != nil:
    section.add "resource-arn", valid_600160
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_600161 = query.getOrDefault("tagKeys")
  valid_600161 = validateParameter(valid_600161, JArray, required = true, default = nil)
  if valid_600161 != nil:
    section.add "tagKeys", valid_600161
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
  var valid_600162 = header.getOrDefault("X-Amz-Date")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-Date", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-Security-Token")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-Security-Token", valid_600163
  var valid_600164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-Content-Sha256", valid_600164
  var valid_600165 = header.getOrDefault("X-Amz-Algorithm")
  valid_600165 = validateParameter(valid_600165, JString, required = false,
                                 default = nil)
  if valid_600165 != nil:
    section.add "X-Amz-Algorithm", valid_600165
  var valid_600166 = header.getOrDefault("X-Amz-Signature")
  valid_600166 = validateParameter(valid_600166, JString, required = false,
                                 default = nil)
  if valid_600166 != nil:
    section.add "X-Amz-Signature", valid_600166
  var valid_600167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600167 = validateParameter(valid_600167, JString, required = false,
                                 default = nil)
  if valid_600167 != nil:
    section.add "X-Amz-SignedHeaders", valid_600167
  var valid_600168 = header.getOrDefault("X-Amz-Credential")
  valid_600168 = validateParameter(valid_600168, JString, required = false,
                                 default = nil)
  if valid_600168 != nil:
    section.add "X-Amz-Credential", valid_600168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600169: Call_DeleteTags_600157; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from a resource.
  ## 
  let valid = call_600169.validator(path, query, header, formData, body)
  let scheme = call_600169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600169.url(scheme.get, call_600169.host, call_600169.base,
                         call_600169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600169, url, valid)

proc call*(call_600170: Call_DeleteTags_600157; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## deleteTags
  ## Removes a tag from a resource.
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource tag.
  var path_600171 = newJObject()
  var query_600172 = newJObject()
  if tagKeys != nil:
    query_600172.add "tagKeys", tagKeys
  add(path_600171, "resource-arn", newJString(resourceArn))
  result = call_600170.call(path_600171, query_600172, nil, nil, nil)

var deleteTags* = Call_DeleteTags_600157(name: "deleteTags",
                                      meth: HttpMethod.HttpDelete,
                                      host: "mq.amazonaws.com",
                                      route: "/v1/tags/{resource-arn}#tagKeys",
                                      validator: validate_DeleteTags_600158,
                                      base: "/", url: url_DeleteTags_600159,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBrokerEngineTypes_600173 = ref object of OpenApiRestCall_599368
proc url_DescribeBrokerEngineTypes_600175(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeBrokerEngineTypes_600174(path: JsonNode; query: JsonNode;
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
  var valid_600176 = query.getOrDefault("maxResults")
  valid_600176 = validateParameter(valid_600176, JInt, required = false, default = nil)
  if valid_600176 != nil:
    section.add "maxResults", valid_600176
  var valid_600177 = query.getOrDefault("nextToken")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "nextToken", valid_600177
  var valid_600178 = query.getOrDefault("engineType")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "engineType", valid_600178
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
  var valid_600179 = header.getOrDefault("X-Amz-Date")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-Date", valid_600179
  var valid_600180 = header.getOrDefault("X-Amz-Security-Token")
  valid_600180 = validateParameter(valid_600180, JString, required = false,
                                 default = nil)
  if valid_600180 != nil:
    section.add "X-Amz-Security-Token", valid_600180
  var valid_600181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600181 = validateParameter(valid_600181, JString, required = false,
                                 default = nil)
  if valid_600181 != nil:
    section.add "X-Amz-Content-Sha256", valid_600181
  var valid_600182 = header.getOrDefault("X-Amz-Algorithm")
  valid_600182 = validateParameter(valid_600182, JString, required = false,
                                 default = nil)
  if valid_600182 != nil:
    section.add "X-Amz-Algorithm", valid_600182
  var valid_600183 = header.getOrDefault("X-Amz-Signature")
  valid_600183 = validateParameter(valid_600183, JString, required = false,
                                 default = nil)
  if valid_600183 != nil:
    section.add "X-Amz-Signature", valid_600183
  var valid_600184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600184 = validateParameter(valid_600184, JString, required = false,
                                 default = nil)
  if valid_600184 != nil:
    section.add "X-Amz-SignedHeaders", valid_600184
  var valid_600185 = header.getOrDefault("X-Amz-Credential")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-Credential", valid_600185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600186: Call_DescribeBrokerEngineTypes_600173; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe available engine types and versions.
  ## 
  let valid = call_600186.validator(path, query, header, formData, body)
  let scheme = call_600186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600186.url(scheme.get, call_600186.host, call_600186.base,
                         call_600186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600186, url, valid)

proc call*(call_600187: Call_DescribeBrokerEngineTypes_600173; maxResults: int = 0;
          nextToken: string = ""; engineType: string = ""): Recallable =
  ## describeBrokerEngineTypes
  ## Describe available engine types and versions.
  ##   maxResults: int
  ##             : The maximum number of engine types that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   engineType: string
  ##             : Filter response by engine type.
  var query_600188 = newJObject()
  add(query_600188, "maxResults", newJInt(maxResults))
  add(query_600188, "nextToken", newJString(nextToken))
  add(query_600188, "engineType", newJString(engineType))
  result = call_600187.call(nil, query_600188, nil, nil, nil)

var describeBrokerEngineTypes* = Call_DescribeBrokerEngineTypes_600173(
    name: "describeBrokerEngineTypes", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/broker-engine-types",
    validator: validate_DescribeBrokerEngineTypes_600174, base: "/",
    url: url_DescribeBrokerEngineTypes_600175,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBrokerInstanceOptions_600189 = ref object of OpenApiRestCall_599368
proc url_DescribeBrokerInstanceOptions_600191(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeBrokerInstanceOptions_600190(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600192 = query.getOrDefault("storageType")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "storageType", valid_600192
  var valid_600193 = query.getOrDefault("maxResults")
  valid_600193 = validateParameter(valid_600193, JInt, required = false, default = nil)
  if valid_600193 != nil:
    section.add "maxResults", valid_600193
  var valid_600194 = query.getOrDefault("nextToken")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "nextToken", valid_600194
  var valid_600195 = query.getOrDefault("hostInstanceType")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "hostInstanceType", valid_600195
  var valid_600196 = query.getOrDefault("engineType")
  valid_600196 = validateParameter(valid_600196, JString, required = false,
                                 default = nil)
  if valid_600196 != nil:
    section.add "engineType", valid_600196
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
  var valid_600197 = header.getOrDefault("X-Amz-Date")
  valid_600197 = validateParameter(valid_600197, JString, required = false,
                                 default = nil)
  if valid_600197 != nil:
    section.add "X-Amz-Date", valid_600197
  var valid_600198 = header.getOrDefault("X-Amz-Security-Token")
  valid_600198 = validateParameter(valid_600198, JString, required = false,
                                 default = nil)
  if valid_600198 != nil:
    section.add "X-Amz-Security-Token", valid_600198
  var valid_600199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600199 = validateParameter(valid_600199, JString, required = false,
                                 default = nil)
  if valid_600199 != nil:
    section.add "X-Amz-Content-Sha256", valid_600199
  var valid_600200 = header.getOrDefault("X-Amz-Algorithm")
  valid_600200 = validateParameter(valid_600200, JString, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "X-Amz-Algorithm", valid_600200
  var valid_600201 = header.getOrDefault("X-Amz-Signature")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "X-Amz-Signature", valid_600201
  var valid_600202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-SignedHeaders", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-Credential")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Credential", valid_600203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600204: Call_DescribeBrokerInstanceOptions_600189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe available broker instance options.
  ## 
  let valid = call_600204.validator(path, query, header, formData, body)
  let scheme = call_600204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600204.url(scheme.get, call_600204.host, call_600204.base,
                         call_600204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600204, url, valid)

proc call*(call_600205: Call_DescribeBrokerInstanceOptions_600189;
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
  var query_600206 = newJObject()
  add(query_600206, "storageType", newJString(storageType))
  add(query_600206, "maxResults", newJInt(maxResults))
  add(query_600206, "nextToken", newJString(nextToken))
  add(query_600206, "hostInstanceType", newJString(hostInstanceType))
  add(query_600206, "engineType", newJString(engineType))
  result = call_600205.call(nil, query_600206, nil, nil, nil)

var describeBrokerInstanceOptions* = Call_DescribeBrokerInstanceOptions_600189(
    name: "describeBrokerInstanceOptions", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/broker-instance-options",
    validator: validate_DescribeBrokerInstanceOptions_600190, base: "/",
    url: url_DescribeBrokerInstanceOptions_600191,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfiguration_600221 = ref object of OpenApiRestCall_599368
proc url_UpdateConfiguration_600223(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateConfiguration_600222(path: JsonNode; query: JsonNode;
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
  var valid_600224 = path.getOrDefault("configuration-id")
  valid_600224 = validateParameter(valid_600224, JString, required = true,
                                 default = nil)
  if valid_600224 != nil:
    section.add "configuration-id", valid_600224
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
  var valid_600225 = header.getOrDefault("X-Amz-Date")
  valid_600225 = validateParameter(valid_600225, JString, required = false,
                                 default = nil)
  if valid_600225 != nil:
    section.add "X-Amz-Date", valid_600225
  var valid_600226 = header.getOrDefault("X-Amz-Security-Token")
  valid_600226 = validateParameter(valid_600226, JString, required = false,
                                 default = nil)
  if valid_600226 != nil:
    section.add "X-Amz-Security-Token", valid_600226
  var valid_600227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600227 = validateParameter(valid_600227, JString, required = false,
                                 default = nil)
  if valid_600227 != nil:
    section.add "X-Amz-Content-Sha256", valid_600227
  var valid_600228 = header.getOrDefault("X-Amz-Algorithm")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-Algorithm", valid_600228
  var valid_600229 = header.getOrDefault("X-Amz-Signature")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-Signature", valid_600229
  var valid_600230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-SignedHeaders", valid_600230
  var valid_600231 = header.getOrDefault("X-Amz-Credential")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "X-Amz-Credential", valid_600231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600233: Call_UpdateConfiguration_600221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified configuration.
  ## 
  let valid = call_600233.validator(path, query, header, formData, body)
  let scheme = call_600233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600233.url(scheme.get, call_600233.host, call_600233.base,
                         call_600233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600233, url, valid)

proc call*(call_600234: Call_UpdateConfiguration_600221; body: JsonNode;
          configurationId: string): Recallable =
  ## updateConfiguration
  ## Updates the specified configuration.
  ##   body: JObject (required)
  ##   configurationId: string (required)
  ##                  : The unique ID that Amazon MQ generates for the configuration.
  var path_600235 = newJObject()
  var body_600236 = newJObject()
  if body != nil:
    body_600236 = body
  add(path_600235, "configuration-id", newJString(configurationId))
  result = call_600234.call(path_600235, nil, nil, nil, body_600236)

var updateConfiguration* = Call_UpdateConfiguration_600221(
    name: "updateConfiguration", meth: HttpMethod.HttpPut, host: "mq.amazonaws.com",
    route: "/v1/configurations/{configuration-id}",
    validator: validate_UpdateConfiguration_600222, base: "/",
    url: url_UpdateConfiguration_600223, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfiguration_600207 = ref object of OpenApiRestCall_599368
proc url_DescribeConfiguration_600209(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeConfiguration_600208(path: JsonNode; query: JsonNode;
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
  var valid_600210 = path.getOrDefault("configuration-id")
  valid_600210 = validateParameter(valid_600210, JString, required = true,
                                 default = nil)
  if valid_600210 != nil:
    section.add "configuration-id", valid_600210
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
  var valid_600211 = header.getOrDefault("X-Amz-Date")
  valid_600211 = validateParameter(valid_600211, JString, required = false,
                                 default = nil)
  if valid_600211 != nil:
    section.add "X-Amz-Date", valid_600211
  var valid_600212 = header.getOrDefault("X-Amz-Security-Token")
  valid_600212 = validateParameter(valid_600212, JString, required = false,
                                 default = nil)
  if valid_600212 != nil:
    section.add "X-Amz-Security-Token", valid_600212
  var valid_600213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "X-Amz-Content-Sha256", valid_600213
  var valid_600214 = header.getOrDefault("X-Amz-Algorithm")
  valid_600214 = validateParameter(valid_600214, JString, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "X-Amz-Algorithm", valid_600214
  var valid_600215 = header.getOrDefault("X-Amz-Signature")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-Signature", valid_600215
  var valid_600216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "X-Amz-SignedHeaders", valid_600216
  var valid_600217 = header.getOrDefault("X-Amz-Credential")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Credential", valid_600217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600218: Call_DescribeConfiguration_600207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified configuration.
  ## 
  let valid = call_600218.validator(path, query, header, formData, body)
  let scheme = call_600218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600218.url(scheme.get, call_600218.host, call_600218.base,
                         call_600218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600218, url, valid)

proc call*(call_600219: Call_DescribeConfiguration_600207; configurationId: string): Recallable =
  ## describeConfiguration
  ## Returns information about the specified configuration.
  ##   configurationId: string (required)
  ##                  : The unique ID that Amazon MQ generates for the configuration.
  var path_600220 = newJObject()
  add(path_600220, "configuration-id", newJString(configurationId))
  result = call_600219.call(path_600220, nil, nil, nil, nil)

var describeConfiguration* = Call_DescribeConfiguration_600207(
    name: "describeConfiguration", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/configurations/{configuration-id}",
    validator: validate_DescribeConfiguration_600208, base: "/",
    url: url_DescribeConfiguration_600209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationRevision_600237 = ref object of OpenApiRestCall_599368
proc url_DescribeConfigurationRevision_600239(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeConfigurationRevision_600238(path: JsonNode; query: JsonNode;
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
  var valid_600240 = path.getOrDefault("configuration-revision")
  valid_600240 = validateParameter(valid_600240, JString, required = true,
                                 default = nil)
  if valid_600240 != nil:
    section.add "configuration-revision", valid_600240
  var valid_600241 = path.getOrDefault("configuration-id")
  valid_600241 = validateParameter(valid_600241, JString, required = true,
                                 default = nil)
  if valid_600241 != nil:
    section.add "configuration-id", valid_600241
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
  var valid_600242 = header.getOrDefault("X-Amz-Date")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "X-Amz-Date", valid_600242
  var valid_600243 = header.getOrDefault("X-Amz-Security-Token")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "X-Amz-Security-Token", valid_600243
  var valid_600244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600244 = validateParameter(valid_600244, JString, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "X-Amz-Content-Sha256", valid_600244
  var valid_600245 = header.getOrDefault("X-Amz-Algorithm")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-Algorithm", valid_600245
  var valid_600246 = header.getOrDefault("X-Amz-Signature")
  valid_600246 = validateParameter(valid_600246, JString, required = false,
                                 default = nil)
  if valid_600246 != nil:
    section.add "X-Amz-Signature", valid_600246
  var valid_600247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-SignedHeaders", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-Credential")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Credential", valid_600248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600249: Call_DescribeConfigurationRevision_600237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the specified configuration revision for the specified configuration.
  ## 
  let valid = call_600249.validator(path, query, header, formData, body)
  let scheme = call_600249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600249.url(scheme.get, call_600249.host, call_600249.base,
                         call_600249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600249, url, valid)

proc call*(call_600250: Call_DescribeConfigurationRevision_600237;
          configurationRevision: string; configurationId: string): Recallable =
  ## describeConfigurationRevision
  ## Returns the specified configuration revision for the specified configuration.
  ##   configurationRevision: string (required)
  ##                        : The revision of the configuration.
  ##   configurationId: string (required)
  ##                  : The unique ID that Amazon MQ generates for the configuration.
  var path_600251 = newJObject()
  add(path_600251, "configuration-revision", newJString(configurationRevision))
  add(path_600251, "configuration-id", newJString(configurationId))
  result = call_600250.call(path_600251, nil, nil, nil, nil)

var describeConfigurationRevision* = Call_DescribeConfigurationRevision_600237(
    name: "describeConfigurationRevision", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/configurations/{configuration-id}/revisions/{configuration-revision}",
    validator: validate_DescribeConfigurationRevision_600238, base: "/",
    url: url_DescribeConfigurationRevision_600239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationRevisions_600252 = ref object of OpenApiRestCall_599368
proc url_ListConfigurationRevisions_600254(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListConfigurationRevisions_600253(path: JsonNode; query: JsonNode;
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
  var valid_600255 = path.getOrDefault("configuration-id")
  valid_600255 = validateParameter(valid_600255, JString, required = true,
                                 default = nil)
  if valid_600255 != nil:
    section.add "configuration-id", valid_600255
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of configurations that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: JString
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  section = newJObject()
  var valid_600256 = query.getOrDefault("maxResults")
  valid_600256 = validateParameter(valid_600256, JInt, required = false, default = nil)
  if valid_600256 != nil:
    section.add "maxResults", valid_600256
  var valid_600257 = query.getOrDefault("nextToken")
  valid_600257 = validateParameter(valid_600257, JString, required = false,
                                 default = nil)
  if valid_600257 != nil:
    section.add "nextToken", valid_600257
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
  var valid_600258 = header.getOrDefault("X-Amz-Date")
  valid_600258 = validateParameter(valid_600258, JString, required = false,
                                 default = nil)
  if valid_600258 != nil:
    section.add "X-Amz-Date", valid_600258
  var valid_600259 = header.getOrDefault("X-Amz-Security-Token")
  valid_600259 = validateParameter(valid_600259, JString, required = false,
                                 default = nil)
  if valid_600259 != nil:
    section.add "X-Amz-Security-Token", valid_600259
  var valid_600260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600260 = validateParameter(valid_600260, JString, required = false,
                                 default = nil)
  if valid_600260 != nil:
    section.add "X-Amz-Content-Sha256", valid_600260
  var valid_600261 = header.getOrDefault("X-Amz-Algorithm")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "X-Amz-Algorithm", valid_600261
  var valid_600262 = header.getOrDefault("X-Amz-Signature")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-Signature", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-SignedHeaders", valid_600263
  var valid_600264 = header.getOrDefault("X-Amz-Credential")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "X-Amz-Credential", valid_600264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600265: Call_ListConfigurationRevisions_600252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all revisions for the specified configuration.
  ## 
  let valid = call_600265.validator(path, query, header, formData, body)
  let scheme = call_600265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600265.url(scheme.get, call_600265.host, call_600265.base,
                         call_600265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600265, url, valid)

proc call*(call_600266: Call_ListConfigurationRevisions_600252;
          configurationId: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listConfigurationRevisions
  ## Returns a list of all revisions for the specified configuration.
  ##   maxResults: int
  ##             : The maximum number of configurations that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   configurationId: string (required)
  ##                  : The unique ID that Amazon MQ generates for the configuration.
  var path_600267 = newJObject()
  var query_600268 = newJObject()
  add(query_600268, "maxResults", newJInt(maxResults))
  add(query_600268, "nextToken", newJString(nextToken))
  add(path_600267, "configuration-id", newJString(configurationId))
  result = call_600266.call(path_600267, query_600268, nil, nil, nil)

var listConfigurationRevisions* = Call_ListConfigurationRevisions_600252(
    name: "listConfigurationRevisions", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com",
    route: "/v1/configurations/{configuration-id}/revisions",
    validator: validate_ListConfigurationRevisions_600253, base: "/",
    url: url_ListConfigurationRevisions_600254,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_600269 = ref object of OpenApiRestCall_599368
proc url_ListUsers_600271(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListUsers_600270(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600272 = path.getOrDefault("broker-id")
  valid_600272 = validateParameter(valid_600272, JString, required = true,
                                 default = nil)
  if valid_600272 != nil:
    section.add "broker-id", valid_600272
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of ActiveMQ users that can be returned per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: JString
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  section = newJObject()
  var valid_600273 = query.getOrDefault("maxResults")
  valid_600273 = validateParameter(valid_600273, JInt, required = false, default = nil)
  if valid_600273 != nil:
    section.add "maxResults", valid_600273
  var valid_600274 = query.getOrDefault("nextToken")
  valid_600274 = validateParameter(valid_600274, JString, required = false,
                                 default = nil)
  if valid_600274 != nil:
    section.add "nextToken", valid_600274
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
  var valid_600275 = header.getOrDefault("X-Amz-Date")
  valid_600275 = validateParameter(valid_600275, JString, required = false,
                                 default = nil)
  if valid_600275 != nil:
    section.add "X-Amz-Date", valid_600275
  var valid_600276 = header.getOrDefault("X-Amz-Security-Token")
  valid_600276 = validateParameter(valid_600276, JString, required = false,
                                 default = nil)
  if valid_600276 != nil:
    section.add "X-Amz-Security-Token", valid_600276
  var valid_600277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-Content-Sha256", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-Algorithm")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Algorithm", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-Signature")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-Signature", valid_600279
  var valid_600280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-SignedHeaders", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Credential")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Credential", valid_600281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600282: Call_ListUsers_600269; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all ActiveMQ users.
  ## 
  let valid = call_600282.validator(path, query, header, formData, body)
  let scheme = call_600282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600282.url(scheme.get, call_600282.host, call_600282.base,
                         call_600282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600282, url, valid)

proc call*(call_600283: Call_ListUsers_600269; brokerId: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listUsers
  ## Returns a list of all ActiveMQ users.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   maxResults: int
  ##             : The maximum number of ActiveMQ users that can be returned per page (20 by default). This value must be an integer from 5 to 100.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  var path_600284 = newJObject()
  var query_600285 = newJObject()
  add(path_600284, "broker-id", newJString(brokerId))
  add(query_600285, "maxResults", newJInt(maxResults))
  add(query_600285, "nextToken", newJString(nextToken))
  result = call_600283.call(path_600284, query_600285, nil, nil, nil)

var listUsers* = Call_ListUsers_600269(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "mq.amazonaws.com",
                                    route: "/v1/brokers/{broker-id}/users",
                                    validator: validate_ListUsers_600270,
                                    base: "/", url: url_ListUsers_600271,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootBroker_600286 = ref object of OpenApiRestCall_599368
proc url_RebootBroker_600288(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RebootBroker_600287(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600289 = path.getOrDefault("broker-id")
  valid_600289 = validateParameter(valid_600289, JString, required = true,
                                 default = nil)
  if valid_600289 != nil:
    section.add "broker-id", valid_600289
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
  var valid_600290 = header.getOrDefault("X-Amz-Date")
  valid_600290 = validateParameter(valid_600290, JString, required = false,
                                 default = nil)
  if valid_600290 != nil:
    section.add "X-Amz-Date", valid_600290
  var valid_600291 = header.getOrDefault("X-Amz-Security-Token")
  valid_600291 = validateParameter(valid_600291, JString, required = false,
                                 default = nil)
  if valid_600291 != nil:
    section.add "X-Amz-Security-Token", valid_600291
  var valid_600292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-Content-Sha256", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-Algorithm")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Algorithm", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-Signature")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Signature", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-SignedHeaders", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Credential")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Credential", valid_600296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600297: Call_RebootBroker_600286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Reboots a broker. Note: This API is asynchronous.
  ## 
  let valid = call_600297.validator(path, query, header, formData, body)
  let scheme = call_600297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600297.url(scheme.get, call_600297.host, call_600297.base,
                         call_600297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600297, url, valid)

proc call*(call_600298: Call_RebootBroker_600286; brokerId: string): Recallable =
  ## rebootBroker
  ## Reboots a broker. Note: This API is asynchronous.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  var path_600299 = newJObject()
  add(path_600299, "broker-id", newJString(brokerId))
  result = call_600298.call(path_600299, nil, nil, nil, nil)

var rebootBroker* = Call_RebootBroker_600286(name: "rebootBroker",
    meth: HttpMethod.HttpPost, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}/reboot", validator: validate_RebootBroker_600287,
    base: "/", url: url_RebootBroker_600288, schemes: {Scheme.Https, Scheme.Http})
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
