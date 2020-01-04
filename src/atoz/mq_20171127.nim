
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_CreateBroker_601984 = ref object of OpenApiRestCall_601389
proc url_CreateBroker_601986(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBroker_601985(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601987 = header.getOrDefault("X-Amz-Signature")
  valid_601987 = validateParameter(valid_601987, JString, required = false,
                                 default = nil)
  if valid_601987 != nil:
    section.add "X-Amz-Signature", valid_601987
  var valid_601988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601988 = validateParameter(valid_601988, JString, required = false,
                                 default = nil)
  if valid_601988 != nil:
    section.add "X-Amz-Content-Sha256", valid_601988
  var valid_601989 = header.getOrDefault("X-Amz-Date")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "X-Amz-Date", valid_601989
  var valid_601990 = header.getOrDefault("X-Amz-Credential")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Credential", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-Security-Token")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Security-Token", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Algorithm")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Algorithm", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-SignedHeaders", valid_601993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601995: Call_CreateBroker_601984; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a broker. Note: This API is asynchronous.
  ## 
  let valid = call_601995.validator(path, query, header, formData, body)
  let scheme = call_601995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601995.url(scheme.get, call_601995.host, call_601995.base,
                         call_601995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601995, url, valid)

proc call*(call_601996: Call_CreateBroker_601984; body: JsonNode): Recallable =
  ## createBroker
  ## Creates a broker. Note: This API is asynchronous.
  ##   body: JObject (required)
  var body_601997 = newJObject()
  if body != nil:
    body_601997 = body
  result = call_601996.call(nil, nil, nil, nil, body_601997)

var createBroker* = Call_CreateBroker_601984(name: "createBroker",
    meth: HttpMethod.HttpPost, host: "mq.amazonaws.com", route: "/v1/brokers",
    validator: validate_CreateBroker_601985, base: "/", url: url_CreateBroker_601986,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBrokers_601727 = ref object of OpenApiRestCall_601389
proc url_ListBrokers_601729(protocol: Scheme; host: string; base: string;
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

proc validate_ListBrokers_601728(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of all brokers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   maxResults: JInt
  ##             : The maximum number of brokers that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  section = newJObject()
  var valid_601841 = query.getOrDefault("nextToken")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "nextToken", valid_601841
  var valid_601842 = query.getOrDefault("maxResults")
  valid_601842 = validateParameter(valid_601842, JInt, required = false, default = nil)
  if valid_601842 != nil:
    section.add "maxResults", valid_601842
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601843 = header.getOrDefault("X-Amz-Signature")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Signature", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-Content-Sha256", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Date")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Date", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Credential")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Credential", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Security-Token")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Security-Token", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-Algorithm")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-Algorithm", valid_601848
  var valid_601849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-SignedHeaders", valid_601849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601872: Call_ListBrokers_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all brokers.
  ## 
  let valid = call_601872.validator(path, query, header, formData, body)
  let scheme = call_601872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601872.url(scheme.get, call_601872.host, call_601872.base,
                         call_601872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601872, url, valid)

proc call*(call_601943: Call_ListBrokers_601727; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listBrokers
  ## Returns a list of all brokers.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   maxResults: int
  ##             : The maximum number of brokers that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  var query_601944 = newJObject()
  add(query_601944, "nextToken", newJString(nextToken))
  add(query_601944, "maxResults", newJInt(maxResults))
  result = call_601943.call(nil, query_601944, nil, nil, nil)

var listBrokers* = Call_ListBrokers_601727(name: "listBrokers",
                                        meth: HttpMethod.HttpGet,
                                        host: "mq.amazonaws.com",
                                        route: "/v1/brokers",
                                        validator: validate_ListBrokers_601728,
                                        base: "/", url: url_ListBrokers_601729,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfiguration_602013 = ref object of OpenApiRestCall_601389
proc url_CreateConfiguration_602015(protocol: Scheme; host: string; base: string;
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

proc validate_CreateConfiguration_602014(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602016 = header.getOrDefault("X-Amz-Signature")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Signature", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Content-Sha256", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Date")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Date", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Credential")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Credential", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Security-Token")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Security-Token", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Algorithm")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Algorithm", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-SignedHeaders", valid_602022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602024: Call_CreateConfiguration_602013; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new configuration for the specified configuration name. Amazon MQ uses the default configuration (the engine type and version).
  ## 
  let valid = call_602024.validator(path, query, header, formData, body)
  let scheme = call_602024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602024.url(scheme.get, call_602024.host, call_602024.base,
                         call_602024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602024, url, valid)

proc call*(call_602025: Call_CreateConfiguration_602013; body: JsonNode): Recallable =
  ## createConfiguration
  ## Creates a new configuration for the specified configuration name. Amazon MQ uses the default configuration (the engine type and version).
  ##   body: JObject (required)
  var body_602026 = newJObject()
  if body != nil:
    body_602026 = body
  result = call_602025.call(nil, nil, nil, nil, body_602026)

var createConfiguration* = Call_CreateConfiguration_602013(
    name: "createConfiguration", meth: HttpMethod.HttpPost,
    host: "mq.amazonaws.com", route: "/v1/configurations",
    validator: validate_CreateConfiguration_602014, base: "/",
    url: url_CreateConfiguration_602015, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurations_601998 = ref object of OpenApiRestCall_601389
proc url_ListConfigurations_602000(protocol: Scheme; host: string; base: string;
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

proc validate_ListConfigurations_601999(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns a list of all configurations.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   maxResults: JInt
  ##             : The maximum number of configurations that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  section = newJObject()
  var valid_602001 = query.getOrDefault("nextToken")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "nextToken", valid_602001
  var valid_602002 = query.getOrDefault("maxResults")
  valid_602002 = validateParameter(valid_602002, JInt, required = false, default = nil)
  if valid_602002 != nil:
    section.add "maxResults", valid_602002
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602003 = header.getOrDefault("X-Amz-Signature")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Signature", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Content-Sha256", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Date")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Date", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Credential")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Credential", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Security-Token")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Security-Token", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Algorithm")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Algorithm", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-SignedHeaders", valid_602009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602010: Call_ListConfigurations_601998; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all configurations.
  ## 
  let valid = call_602010.validator(path, query, header, formData, body)
  let scheme = call_602010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602010.url(scheme.get, call_602010.host, call_602010.base,
                         call_602010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602010, url, valid)

proc call*(call_602011: Call_ListConfigurations_601998; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listConfigurations
  ## Returns a list of all configurations.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   maxResults: int
  ##             : The maximum number of configurations that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  var query_602012 = newJObject()
  add(query_602012, "nextToken", newJString(nextToken))
  add(query_602012, "maxResults", newJInt(maxResults))
  result = call_602011.call(nil, query_602012, nil, nil, nil)

var listConfigurations* = Call_ListConfigurations_601998(
    name: "listConfigurations", meth: HttpMethod.HttpGet, host: "mq.amazonaws.com",
    route: "/v1/configurations", validator: validate_ListConfigurations_601999,
    base: "/", url: url_ListConfigurations_602000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_602055 = ref object of OpenApiRestCall_601389
proc url_CreateTags_602057(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateTags_602056(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602058 = path.getOrDefault("resource-arn")
  valid_602058 = validateParameter(valid_602058, JString, required = true,
                                 default = nil)
  if valid_602058 != nil:
    section.add "resource-arn", valid_602058
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602059 = header.getOrDefault("X-Amz-Signature")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "X-Amz-Signature", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Content-Sha256", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Date")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Date", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Credential")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Credential", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Security-Token")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Security-Token", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Algorithm")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Algorithm", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-SignedHeaders", valid_602065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602067: Call_CreateTags_602055; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a tag to a resource.
  ## 
  let valid = call_602067.validator(path, query, header, formData, body)
  let scheme = call_602067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602067.url(scheme.get, call_602067.host, call_602067.base,
                         call_602067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602067, url, valid)

proc call*(call_602068: Call_CreateTags_602055; resourceArn: string; body: JsonNode): Recallable =
  ## createTags
  ## Add a tag to a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource tag.
  ##   body: JObject (required)
  var path_602069 = newJObject()
  var body_602070 = newJObject()
  add(path_602069, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_602070 = body
  result = call_602068.call(path_602069, nil, nil, nil, body_602070)

var createTags* = Call_CreateTags_602055(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "mq.amazonaws.com",
                                      route: "/v1/tags/{resource-arn}",
                                      validator: validate_CreateTags_602056,
                                      base: "/", url: url_CreateTags_602057,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_602027 = ref object of OpenApiRestCall_601389
proc url_ListTags_602029(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTags_602028(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602044 = path.getOrDefault("resource-arn")
  valid_602044 = validateParameter(valid_602044, JString, required = true,
                                 default = nil)
  if valid_602044 != nil:
    section.add "resource-arn", valid_602044
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602045 = header.getOrDefault("X-Amz-Signature")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Signature", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Content-Sha256", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Date")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Date", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Credential")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Credential", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Security-Token")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Security-Token", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Algorithm")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Algorithm", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-SignedHeaders", valid_602051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602052: Call_ListTags_602027; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists tags for a resource.
  ## 
  let valid = call_602052.validator(path, query, header, formData, body)
  let scheme = call_602052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602052.url(scheme.get, call_602052.host, call_602052.base,
                         call_602052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602052, url, valid)

proc call*(call_602053: Call_ListTags_602027; resourceArn: string): Recallable =
  ## listTags
  ## Lists tags for a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource tag.
  var path_602054 = newJObject()
  add(path_602054, "resource-arn", newJString(resourceArn))
  result = call_602053.call(path_602054, nil, nil, nil, nil)

var listTags* = Call_ListTags_602027(name: "listTags", meth: HttpMethod.HttpGet,
                                  host: "mq.amazonaws.com",
                                  route: "/v1/tags/{resource-arn}",
                                  validator: validate_ListTags_602028, base: "/",
                                  url: url_ListTags_602029,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_602086 = ref object of OpenApiRestCall_601389
proc url_UpdateUser_602088(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateUser_602087(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602089 = path.getOrDefault("broker-id")
  valid_602089 = validateParameter(valid_602089, JString, required = true,
                                 default = nil)
  if valid_602089 != nil:
    section.add "broker-id", valid_602089
  var valid_602090 = path.getOrDefault("username")
  valid_602090 = validateParameter(valid_602090, JString, required = true,
                                 default = nil)
  if valid_602090 != nil:
    section.add "username", valid_602090
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602091 = header.getOrDefault("X-Amz-Signature")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Signature", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Content-Sha256", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Date")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Date", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Credential")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Credential", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Security-Token")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Security-Token", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-Algorithm")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Algorithm", valid_602096
  var valid_602097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-SignedHeaders", valid_602097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602099: Call_UpdateUser_602086; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the information for an ActiveMQ user.
  ## 
  let valid = call_602099.validator(path, query, header, formData, body)
  let scheme = call_602099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602099.url(scheme.get, call_602099.host, call_602099.base,
                         call_602099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602099, url, valid)

proc call*(call_602100: Call_UpdateUser_602086; brokerId: string; body: JsonNode;
          username: string): Recallable =
  ## updateUser
  ## Updates the information for an ActiveMQ user.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   body: JObject (required)
  ##   username: string (required)
  ##           : Required. The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  var path_602101 = newJObject()
  var body_602102 = newJObject()
  add(path_602101, "broker-id", newJString(brokerId))
  if body != nil:
    body_602102 = body
  add(path_602101, "username", newJString(username))
  result = call_602100.call(path_602101, nil, nil, nil, body_602102)

var updateUser* = Call_UpdateUser_602086(name: "updateUser",
                                      meth: HttpMethod.HttpPut,
                                      host: "mq.amazonaws.com", route: "/v1/brokers/{broker-id}/users/{username}",
                                      validator: validate_UpdateUser_602087,
                                      base: "/", url: url_UpdateUser_602088,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_602103 = ref object of OpenApiRestCall_601389
proc url_CreateUser_602105(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateUser_602104(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602106 = path.getOrDefault("broker-id")
  valid_602106 = validateParameter(valid_602106, JString, required = true,
                                 default = nil)
  if valid_602106 != nil:
    section.add "broker-id", valid_602106
  var valid_602107 = path.getOrDefault("username")
  valid_602107 = validateParameter(valid_602107, JString, required = true,
                                 default = nil)
  if valid_602107 != nil:
    section.add "username", valid_602107
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602108 = header.getOrDefault("X-Amz-Signature")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Signature", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Content-Sha256", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Date")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Date", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Credential")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Credential", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-Security-Token")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-Security-Token", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-Algorithm")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Algorithm", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-SignedHeaders", valid_602114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602116: Call_CreateUser_602103; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an ActiveMQ user.
  ## 
  let valid = call_602116.validator(path, query, header, formData, body)
  let scheme = call_602116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602116.url(scheme.get, call_602116.host, call_602116.base,
                         call_602116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602116, url, valid)

proc call*(call_602117: Call_CreateUser_602103; brokerId: string; body: JsonNode;
          username: string): Recallable =
  ## createUser
  ## Creates an ActiveMQ user.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   body: JObject (required)
  ##   username: string (required)
  ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  var path_602118 = newJObject()
  var body_602119 = newJObject()
  add(path_602118, "broker-id", newJString(brokerId))
  if body != nil:
    body_602119 = body
  add(path_602118, "username", newJString(username))
  result = call_602117.call(path_602118, nil, nil, nil, body_602119)

var createUser* = Call_CreateUser_602103(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "mq.amazonaws.com", route: "/v1/brokers/{broker-id}/users/{username}",
                                      validator: validate_CreateUser_602104,
                                      base: "/", url: url_CreateUser_602105,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_602071 = ref object of OpenApiRestCall_601389
proc url_DescribeUser_602073(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUser_602072(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602074 = path.getOrDefault("broker-id")
  valid_602074 = validateParameter(valid_602074, JString, required = true,
                                 default = nil)
  if valid_602074 != nil:
    section.add "broker-id", valid_602074
  var valid_602075 = path.getOrDefault("username")
  valid_602075 = validateParameter(valid_602075, JString, required = true,
                                 default = nil)
  if valid_602075 != nil:
    section.add "username", valid_602075
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602076 = header.getOrDefault("X-Amz-Signature")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Signature", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Content-Sha256", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Date")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Date", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Credential")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Credential", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Security-Token")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Security-Token", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-Algorithm")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Algorithm", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-SignedHeaders", valid_602082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602083: Call_DescribeUser_602071; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about an ActiveMQ user.
  ## 
  let valid = call_602083.validator(path, query, header, formData, body)
  let scheme = call_602083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602083.url(scheme.get, call_602083.host, call_602083.base,
                         call_602083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602083, url, valid)

proc call*(call_602084: Call_DescribeUser_602071; brokerId: string; username: string): Recallable =
  ## describeUser
  ## Returns information about an ActiveMQ user.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   username: string (required)
  ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  var path_602085 = newJObject()
  add(path_602085, "broker-id", newJString(brokerId))
  add(path_602085, "username", newJString(username))
  result = call_602084.call(path_602085, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_602071(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}/users/{username}",
    validator: validate_DescribeUser_602072, base: "/", url: url_DescribeUser_602073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_602120 = ref object of OpenApiRestCall_601389
proc url_DeleteUser_602122(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteUser_602121(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602123 = path.getOrDefault("broker-id")
  valid_602123 = validateParameter(valid_602123, JString, required = true,
                                 default = nil)
  if valid_602123 != nil:
    section.add "broker-id", valid_602123
  var valid_602124 = path.getOrDefault("username")
  valid_602124 = validateParameter(valid_602124, JString, required = true,
                                 default = nil)
  if valid_602124 != nil:
    section.add "username", valid_602124
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602125 = header.getOrDefault("X-Amz-Signature")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Signature", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Content-Sha256", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-Date")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Date", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Credential")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Credential", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-Security-Token")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-Security-Token", valid_602129
  var valid_602130 = header.getOrDefault("X-Amz-Algorithm")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "X-Amz-Algorithm", valid_602130
  var valid_602131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "X-Amz-SignedHeaders", valid_602131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602132: Call_DeleteUser_602120; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an ActiveMQ user.
  ## 
  let valid = call_602132.validator(path, query, header, formData, body)
  let scheme = call_602132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602132.url(scheme.get, call_602132.host, call_602132.base,
                         call_602132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602132, url, valid)

proc call*(call_602133: Call_DeleteUser_602120; brokerId: string; username: string): Recallable =
  ## deleteUser
  ## Deletes an ActiveMQ user.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   username: string (required)
  ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  var path_602134 = newJObject()
  add(path_602134, "broker-id", newJString(brokerId))
  add(path_602134, "username", newJString(username))
  result = call_602133.call(path_602134, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_602120(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "mq.amazonaws.com", route: "/v1/brokers/{broker-id}/users/{username}",
                                      validator: validate_DeleteUser_602121,
                                      base: "/", url: url_DeleteUser_602122,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBroker_602149 = ref object of OpenApiRestCall_601389
proc url_UpdateBroker_602151(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBroker_602150(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602152 = path.getOrDefault("broker-id")
  valid_602152 = validateParameter(valid_602152, JString, required = true,
                                 default = nil)
  if valid_602152 != nil:
    section.add "broker-id", valid_602152
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602153 = header.getOrDefault("X-Amz-Signature")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Signature", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Content-Sha256", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Date")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Date", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-Credential")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Credential", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Security-Token")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Security-Token", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-Algorithm")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Algorithm", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-SignedHeaders", valid_602159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602161: Call_UpdateBroker_602149; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a pending configuration change to a broker.
  ## 
  let valid = call_602161.validator(path, query, header, formData, body)
  let scheme = call_602161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602161.url(scheme.get, call_602161.host, call_602161.base,
                         call_602161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602161, url, valid)

proc call*(call_602162: Call_UpdateBroker_602149; brokerId: string; body: JsonNode): Recallable =
  ## updateBroker
  ## Adds a pending configuration change to a broker.
  ##   brokerId: string (required)
  ##           : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  ##   body: JObject (required)
  var path_602163 = newJObject()
  var body_602164 = newJObject()
  add(path_602163, "broker-id", newJString(brokerId))
  if body != nil:
    body_602164 = body
  result = call_602162.call(path_602163, nil, nil, nil, body_602164)

var updateBroker* = Call_UpdateBroker_602149(name: "updateBroker",
    meth: HttpMethod.HttpPut, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}", validator: validate_UpdateBroker_602150,
    base: "/", url: url_UpdateBroker_602151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBroker_602135 = ref object of OpenApiRestCall_601389
proc url_DescribeBroker_602137(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeBroker_602136(path: JsonNode; query: JsonNode;
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
  var valid_602138 = path.getOrDefault("broker-id")
  valid_602138 = validateParameter(valid_602138, JString, required = true,
                                 default = nil)
  if valid_602138 != nil:
    section.add "broker-id", valid_602138
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602139 = header.getOrDefault("X-Amz-Signature")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Signature", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Content-Sha256", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Date")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Date", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Credential")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Credential", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Security-Token")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Security-Token", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Algorithm")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Algorithm", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-SignedHeaders", valid_602145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602146: Call_DescribeBroker_602135; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified broker.
  ## 
  let valid = call_602146.validator(path, query, header, formData, body)
  let scheme = call_602146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602146.url(scheme.get, call_602146.host, call_602146.base,
                         call_602146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602146, url, valid)

proc call*(call_602147: Call_DescribeBroker_602135; brokerId: string): Recallable =
  ## describeBroker
  ## Returns information about the specified broker.
  ##   brokerId: string (required)
  ##           : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  var path_602148 = newJObject()
  add(path_602148, "broker-id", newJString(brokerId))
  result = call_602147.call(path_602148, nil, nil, nil, nil)

var describeBroker* = Call_DescribeBroker_602135(name: "describeBroker",
    meth: HttpMethod.HttpGet, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}", validator: validate_DescribeBroker_602136,
    base: "/", url: url_DescribeBroker_602137, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBroker_602165 = ref object of OpenApiRestCall_601389
proc url_DeleteBroker_602167(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBroker_602166(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602168 = path.getOrDefault("broker-id")
  valid_602168 = validateParameter(valid_602168, JString, required = true,
                                 default = nil)
  if valid_602168 != nil:
    section.add "broker-id", valid_602168
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602169 = header.getOrDefault("X-Amz-Signature")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Signature", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Content-Sha256", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-Date")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-Date", valid_602171
  var valid_602172 = header.getOrDefault("X-Amz-Credential")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "X-Amz-Credential", valid_602172
  var valid_602173 = header.getOrDefault("X-Amz-Security-Token")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "X-Amz-Security-Token", valid_602173
  var valid_602174 = header.getOrDefault("X-Amz-Algorithm")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Algorithm", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-SignedHeaders", valid_602175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602176: Call_DeleteBroker_602165; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a broker. Note: This API is asynchronous.
  ## 
  let valid = call_602176.validator(path, query, header, formData, body)
  let scheme = call_602176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602176.url(scheme.get, call_602176.host, call_602176.base,
                         call_602176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602176, url, valid)

proc call*(call_602177: Call_DeleteBroker_602165; brokerId: string): Recallable =
  ## deleteBroker
  ## Deletes a broker. Note: This API is asynchronous.
  ##   brokerId: string (required)
  ##           : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  var path_602178 = newJObject()
  add(path_602178, "broker-id", newJString(brokerId))
  result = call_602177.call(path_602178, nil, nil, nil, nil)

var deleteBroker* = Call_DeleteBroker_602165(name: "deleteBroker",
    meth: HttpMethod.HttpDelete, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}", validator: validate_DeleteBroker_602166,
    base: "/", url: url_DeleteBroker_602167, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_602179 = ref object of OpenApiRestCall_601389
proc url_DeleteTags_602181(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteTags_602180(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602182 = path.getOrDefault("resource-arn")
  valid_602182 = validateParameter(valid_602182, JString, required = true,
                                 default = nil)
  if valid_602182 != nil:
    section.add "resource-arn", valid_602182
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_602183 = query.getOrDefault("tagKeys")
  valid_602183 = validateParameter(valid_602183, JArray, required = true, default = nil)
  if valid_602183 != nil:
    section.add "tagKeys", valid_602183
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602184 = header.getOrDefault("X-Amz-Signature")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Signature", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-Content-Sha256", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-Date")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-Date", valid_602186
  var valid_602187 = header.getOrDefault("X-Amz-Credential")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "X-Amz-Credential", valid_602187
  var valid_602188 = header.getOrDefault("X-Amz-Security-Token")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "X-Amz-Security-Token", valid_602188
  var valid_602189 = header.getOrDefault("X-Amz-Algorithm")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-Algorithm", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-SignedHeaders", valid_602190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602191: Call_DeleteTags_602179; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from a resource.
  ## 
  let valid = call_602191.validator(path, query, header, formData, body)
  let scheme = call_602191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602191.url(scheme.get, call_602191.host, call_602191.base,
                         call_602191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602191, url, valid)

proc call*(call_602192: Call_DeleteTags_602179; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## deleteTags
  ## Removes a tag from a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource tag.
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  var path_602193 = newJObject()
  var query_602194 = newJObject()
  add(path_602193, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_602194.add "tagKeys", tagKeys
  result = call_602192.call(path_602193, query_602194, nil, nil, nil)

var deleteTags* = Call_DeleteTags_602179(name: "deleteTags",
                                      meth: HttpMethod.HttpDelete,
                                      host: "mq.amazonaws.com",
                                      route: "/v1/tags/{resource-arn}#tagKeys",
                                      validator: validate_DeleteTags_602180,
                                      base: "/", url: url_DeleteTags_602181,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBrokerEngineTypes_602195 = ref object of OpenApiRestCall_601389
proc url_DescribeBrokerEngineTypes_602197(protocol: Scheme; host: string;
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

proc validate_DescribeBrokerEngineTypes_602196(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describe available engine types and versions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   engineType: JString
  ##             : Filter response by engine type.
  ##   maxResults: JInt
  ##             : The maximum number of engine types that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  section = newJObject()
  var valid_602198 = query.getOrDefault("nextToken")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "nextToken", valid_602198
  var valid_602199 = query.getOrDefault("engineType")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "engineType", valid_602199
  var valid_602200 = query.getOrDefault("maxResults")
  valid_602200 = validateParameter(valid_602200, JInt, required = false, default = nil)
  if valid_602200 != nil:
    section.add "maxResults", valid_602200
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602201 = header.getOrDefault("X-Amz-Signature")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-Signature", valid_602201
  var valid_602202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "X-Amz-Content-Sha256", valid_602202
  var valid_602203 = header.getOrDefault("X-Amz-Date")
  valid_602203 = validateParameter(valid_602203, JString, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "X-Amz-Date", valid_602203
  var valid_602204 = header.getOrDefault("X-Amz-Credential")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "X-Amz-Credential", valid_602204
  var valid_602205 = header.getOrDefault("X-Amz-Security-Token")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "X-Amz-Security-Token", valid_602205
  var valid_602206 = header.getOrDefault("X-Amz-Algorithm")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "X-Amz-Algorithm", valid_602206
  var valid_602207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "X-Amz-SignedHeaders", valid_602207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602208: Call_DescribeBrokerEngineTypes_602195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe available engine types and versions.
  ## 
  let valid = call_602208.validator(path, query, header, formData, body)
  let scheme = call_602208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602208.url(scheme.get, call_602208.host, call_602208.base,
                         call_602208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602208, url, valid)

proc call*(call_602209: Call_DescribeBrokerEngineTypes_602195;
          nextToken: string = ""; engineType: string = ""; maxResults: int = 0): Recallable =
  ## describeBrokerEngineTypes
  ## Describe available engine types and versions.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   engineType: string
  ##             : Filter response by engine type.
  ##   maxResults: int
  ##             : The maximum number of engine types that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  var query_602210 = newJObject()
  add(query_602210, "nextToken", newJString(nextToken))
  add(query_602210, "engineType", newJString(engineType))
  add(query_602210, "maxResults", newJInt(maxResults))
  result = call_602209.call(nil, query_602210, nil, nil, nil)

var describeBrokerEngineTypes* = Call_DescribeBrokerEngineTypes_602195(
    name: "describeBrokerEngineTypes", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/broker-engine-types",
    validator: validate_DescribeBrokerEngineTypes_602196, base: "/",
    url: url_DescribeBrokerEngineTypes_602197,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBrokerInstanceOptions_602211 = ref object of OpenApiRestCall_601389
proc url_DescribeBrokerInstanceOptions_602213(protocol: Scheme; host: string;
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

proc validate_DescribeBrokerInstanceOptions_602212(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describe available broker instance options.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   storageType: JString
  ##              : Filter response by storage type.
  ##   engineType: JString
  ##             : Filter response by engine type.
  ##   hostInstanceType: JString
  ##                   : Filter response by host instance type.
  ##   maxResults: JInt
  ##             : The maximum number of instance options that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  section = newJObject()
  var valid_602214 = query.getOrDefault("nextToken")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "nextToken", valid_602214
  var valid_602215 = query.getOrDefault("storageType")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "storageType", valid_602215
  var valid_602216 = query.getOrDefault("engineType")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "engineType", valid_602216
  var valid_602217 = query.getOrDefault("hostInstanceType")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "hostInstanceType", valid_602217
  var valid_602218 = query.getOrDefault("maxResults")
  valid_602218 = validateParameter(valid_602218, JInt, required = false, default = nil)
  if valid_602218 != nil:
    section.add "maxResults", valid_602218
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602219 = header.getOrDefault("X-Amz-Signature")
  valid_602219 = validateParameter(valid_602219, JString, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "X-Amz-Signature", valid_602219
  var valid_602220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "X-Amz-Content-Sha256", valid_602220
  var valid_602221 = header.getOrDefault("X-Amz-Date")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-Date", valid_602221
  var valid_602222 = header.getOrDefault("X-Amz-Credential")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "X-Amz-Credential", valid_602222
  var valid_602223 = header.getOrDefault("X-Amz-Security-Token")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "X-Amz-Security-Token", valid_602223
  var valid_602224 = header.getOrDefault("X-Amz-Algorithm")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-Algorithm", valid_602224
  var valid_602225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-SignedHeaders", valid_602225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602226: Call_DescribeBrokerInstanceOptions_602211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe available broker instance options.
  ## 
  let valid = call_602226.validator(path, query, header, formData, body)
  let scheme = call_602226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602226.url(scheme.get, call_602226.host, call_602226.base,
                         call_602226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602226, url, valid)

proc call*(call_602227: Call_DescribeBrokerInstanceOptions_602211;
          nextToken: string = ""; storageType: string = ""; engineType: string = "";
          hostInstanceType: string = ""; maxResults: int = 0): Recallable =
  ## describeBrokerInstanceOptions
  ## Describe available broker instance options.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   storageType: string
  ##              : Filter response by storage type.
  ##   engineType: string
  ##             : Filter response by engine type.
  ##   hostInstanceType: string
  ##                   : Filter response by host instance type.
  ##   maxResults: int
  ##             : The maximum number of instance options that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  var query_602228 = newJObject()
  add(query_602228, "nextToken", newJString(nextToken))
  add(query_602228, "storageType", newJString(storageType))
  add(query_602228, "engineType", newJString(engineType))
  add(query_602228, "hostInstanceType", newJString(hostInstanceType))
  add(query_602228, "maxResults", newJInt(maxResults))
  result = call_602227.call(nil, query_602228, nil, nil, nil)

var describeBrokerInstanceOptions* = Call_DescribeBrokerInstanceOptions_602211(
    name: "describeBrokerInstanceOptions", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/broker-instance-options",
    validator: validate_DescribeBrokerInstanceOptions_602212, base: "/",
    url: url_DescribeBrokerInstanceOptions_602213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfiguration_602243 = ref object of OpenApiRestCall_601389
proc url_UpdateConfiguration_602245(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateConfiguration_602244(path: JsonNode; query: JsonNode;
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
  var valid_602246 = path.getOrDefault("configuration-id")
  valid_602246 = validateParameter(valid_602246, JString, required = true,
                                 default = nil)
  if valid_602246 != nil:
    section.add "configuration-id", valid_602246
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602247 = header.getOrDefault("X-Amz-Signature")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-Signature", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Content-Sha256", valid_602248
  var valid_602249 = header.getOrDefault("X-Amz-Date")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-Date", valid_602249
  var valid_602250 = header.getOrDefault("X-Amz-Credential")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-Credential", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-Security-Token")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Security-Token", valid_602251
  var valid_602252 = header.getOrDefault("X-Amz-Algorithm")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "X-Amz-Algorithm", valid_602252
  var valid_602253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-SignedHeaders", valid_602253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602255: Call_UpdateConfiguration_602243; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified configuration.
  ## 
  let valid = call_602255.validator(path, query, header, formData, body)
  let scheme = call_602255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602255.url(scheme.get, call_602255.host, call_602255.base,
                         call_602255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602255, url, valid)

proc call*(call_602256: Call_UpdateConfiguration_602243; body: JsonNode;
          configurationId: string): Recallable =
  ## updateConfiguration
  ## Updates the specified configuration.
  ##   body: JObject (required)
  ##   configurationId: string (required)
  ##                  : The unique ID that Amazon MQ generates for the configuration.
  var path_602257 = newJObject()
  var body_602258 = newJObject()
  if body != nil:
    body_602258 = body
  add(path_602257, "configuration-id", newJString(configurationId))
  result = call_602256.call(path_602257, nil, nil, nil, body_602258)

var updateConfiguration* = Call_UpdateConfiguration_602243(
    name: "updateConfiguration", meth: HttpMethod.HttpPut, host: "mq.amazonaws.com",
    route: "/v1/configurations/{configuration-id}",
    validator: validate_UpdateConfiguration_602244, base: "/",
    url: url_UpdateConfiguration_602245, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfiguration_602229 = ref object of OpenApiRestCall_601389
proc url_DescribeConfiguration_602231(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeConfiguration_602230(path: JsonNode; query: JsonNode;
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
  var valid_602232 = path.getOrDefault("configuration-id")
  valid_602232 = validateParameter(valid_602232, JString, required = true,
                                 default = nil)
  if valid_602232 != nil:
    section.add "configuration-id", valid_602232
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602233 = header.getOrDefault("X-Amz-Signature")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Signature", valid_602233
  var valid_602234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Content-Sha256", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-Date")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-Date", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Credential")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Credential", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-Security-Token")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-Security-Token", valid_602237
  var valid_602238 = header.getOrDefault("X-Amz-Algorithm")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-Algorithm", valid_602238
  var valid_602239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-SignedHeaders", valid_602239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602240: Call_DescribeConfiguration_602229; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified configuration.
  ## 
  let valid = call_602240.validator(path, query, header, formData, body)
  let scheme = call_602240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602240.url(scheme.get, call_602240.host, call_602240.base,
                         call_602240.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602240, url, valid)

proc call*(call_602241: Call_DescribeConfiguration_602229; configurationId: string): Recallable =
  ## describeConfiguration
  ## Returns information about the specified configuration.
  ##   configurationId: string (required)
  ##                  : The unique ID that Amazon MQ generates for the configuration.
  var path_602242 = newJObject()
  add(path_602242, "configuration-id", newJString(configurationId))
  result = call_602241.call(path_602242, nil, nil, nil, nil)

var describeConfiguration* = Call_DescribeConfiguration_602229(
    name: "describeConfiguration", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/configurations/{configuration-id}",
    validator: validate_DescribeConfiguration_602230, base: "/",
    url: url_DescribeConfiguration_602231, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationRevision_602259 = ref object of OpenApiRestCall_601389
proc url_DescribeConfigurationRevision_602261(protocol: Scheme; host: string;
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

proc validate_DescribeConfigurationRevision_602260(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the specified configuration revision for the specified configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   configuration-id: JString (required)
  ##                   : The unique ID that Amazon MQ generates for the configuration.
  ##   configuration-revision: JString (required)
  ##                         : The revision of the configuration.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `configuration-id` field"
  var valid_602262 = path.getOrDefault("configuration-id")
  valid_602262 = validateParameter(valid_602262, JString, required = true,
                                 default = nil)
  if valid_602262 != nil:
    section.add "configuration-id", valid_602262
  var valid_602263 = path.getOrDefault("configuration-revision")
  valid_602263 = validateParameter(valid_602263, JString, required = true,
                                 default = nil)
  if valid_602263 != nil:
    section.add "configuration-revision", valid_602263
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602264 = header.getOrDefault("X-Amz-Signature")
  valid_602264 = validateParameter(valid_602264, JString, required = false,
                                 default = nil)
  if valid_602264 != nil:
    section.add "X-Amz-Signature", valid_602264
  var valid_602265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "X-Amz-Content-Sha256", valid_602265
  var valid_602266 = header.getOrDefault("X-Amz-Date")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "X-Amz-Date", valid_602266
  var valid_602267 = header.getOrDefault("X-Amz-Credential")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "X-Amz-Credential", valid_602267
  var valid_602268 = header.getOrDefault("X-Amz-Security-Token")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "X-Amz-Security-Token", valid_602268
  var valid_602269 = header.getOrDefault("X-Amz-Algorithm")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-Algorithm", valid_602269
  var valid_602270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-SignedHeaders", valid_602270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602271: Call_DescribeConfigurationRevision_602259; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the specified configuration revision for the specified configuration.
  ## 
  let valid = call_602271.validator(path, query, header, formData, body)
  let scheme = call_602271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602271.url(scheme.get, call_602271.host, call_602271.base,
                         call_602271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602271, url, valid)

proc call*(call_602272: Call_DescribeConfigurationRevision_602259;
          configurationId: string; configurationRevision: string): Recallable =
  ## describeConfigurationRevision
  ## Returns the specified configuration revision for the specified configuration.
  ##   configurationId: string (required)
  ##                  : The unique ID that Amazon MQ generates for the configuration.
  ##   configurationRevision: string (required)
  ##                        : The revision of the configuration.
  var path_602273 = newJObject()
  add(path_602273, "configuration-id", newJString(configurationId))
  add(path_602273, "configuration-revision", newJString(configurationRevision))
  result = call_602272.call(path_602273, nil, nil, nil, nil)

var describeConfigurationRevision* = Call_DescribeConfigurationRevision_602259(
    name: "describeConfigurationRevision", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/configurations/{configuration-id}/revisions/{configuration-revision}",
    validator: validate_DescribeConfigurationRevision_602260, base: "/",
    url: url_DescribeConfigurationRevision_602261,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationRevisions_602274 = ref object of OpenApiRestCall_601389
proc url_ListConfigurationRevisions_602276(protocol: Scheme; host: string;
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

proc validate_ListConfigurationRevisions_602275(path: JsonNode; query: JsonNode;
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
  var valid_602277 = path.getOrDefault("configuration-id")
  valid_602277 = validateParameter(valid_602277, JString, required = true,
                                 default = nil)
  if valid_602277 != nil:
    section.add "configuration-id", valid_602277
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   maxResults: JInt
  ##             : The maximum number of configurations that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  section = newJObject()
  var valid_602278 = query.getOrDefault("nextToken")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "nextToken", valid_602278
  var valid_602279 = query.getOrDefault("maxResults")
  valid_602279 = validateParameter(valid_602279, JInt, required = false, default = nil)
  if valid_602279 != nil:
    section.add "maxResults", valid_602279
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602280 = header.getOrDefault("X-Amz-Signature")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-Signature", valid_602280
  var valid_602281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-Content-Sha256", valid_602281
  var valid_602282 = header.getOrDefault("X-Amz-Date")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-Date", valid_602282
  var valid_602283 = header.getOrDefault("X-Amz-Credential")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-Credential", valid_602283
  var valid_602284 = header.getOrDefault("X-Amz-Security-Token")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Security-Token", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-Algorithm")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Algorithm", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-SignedHeaders", valid_602286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602287: Call_ListConfigurationRevisions_602274; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all revisions for the specified configuration.
  ## 
  let valid = call_602287.validator(path, query, header, formData, body)
  let scheme = call_602287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602287.url(scheme.get, call_602287.host, call_602287.base,
                         call_602287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602287, url, valid)

proc call*(call_602288: Call_ListConfigurationRevisions_602274;
          configurationId: string; nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listConfigurationRevisions
  ## Returns a list of all revisions for the specified configuration.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   configurationId: string (required)
  ##                  : The unique ID that Amazon MQ generates for the configuration.
  ##   maxResults: int
  ##             : The maximum number of configurations that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  var path_602289 = newJObject()
  var query_602290 = newJObject()
  add(query_602290, "nextToken", newJString(nextToken))
  add(path_602289, "configuration-id", newJString(configurationId))
  add(query_602290, "maxResults", newJInt(maxResults))
  result = call_602288.call(path_602289, query_602290, nil, nil, nil)

var listConfigurationRevisions* = Call_ListConfigurationRevisions_602274(
    name: "listConfigurationRevisions", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com",
    route: "/v1/configurations/{configuration-id}/revisions",
    validator: validate_ListConfigurationRevisions_602275, base: "/",
    url: url_ListConfigurationRevisions_602276,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_602291 = ref object of OpenApiRestCall_601389
proc url_ListUsers_602293(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListUsers_602292(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602294 = path.getOrDefault("broker-id")
  valid_602294 = validateParameter(valid_602294, JString, required = true,
                                 default = nil)
  if valid_602294 != nil:
    section.add "broker-id", valid_602294
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   maxResults: JInt
  ##             : The maximum number of ActiveMQ users that can be returned per page (20 by default). This value must be an integer from 5 to 100.
  section = newJObject()
  var valid_602295 = query.getOrDefault("nextToken")
  valid_602295 = validateParameter(valid_602295, JString, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "nextToken", valid_602295
  var valid_602296 = query.getOrDefault("maxResults")
  valid_602296 = validateParameter(valid_602296, JInt, required = false, default = nil)
  if valid_602296 != nil:
    section.add "maxResults", valid_602296
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602297 = header.getOrDefault("X-Amz-Signature")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "X-Amz-Signature", valid_602297
  var valid_602298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-Content-Sha256", valid_602298
  var valid_602299 = header.getOrDefault("X-Amz-Date")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "X-Amz-Date", valid_602299
  var valid_602300 = header.getOrDefault("X-Amz-Credential")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Credential", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Security-Token")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Security-Token", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-Algorithm")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-Algorithm", valid_602302
  var valid_602303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "X-Amz-SignedHeaders", valid_602303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602304: Call_ListUsers_602291; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all ActiveMQ users.
  ## 
  let valid = call_602304.validator(path, query, header, formData, body)
  let scheme = call_602304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602304.url(scheme.get, call_602304.host, call_602304.base,
                         call_602304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602304, url, valid)

proc call*(call_602305: Call_ListUsers_602291; brokerId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listUsers
  ## Returns a list of all ActiveMQ users.
  ##   nextToken: string
  ##            : The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  ##   maxResults: int
  ##             : The maximum number of ActiveMQ users that can be returned per page (20 by default). This value must be an integer from 5 to 100.
  var path_602306 = newJObject()
  var query_602307 = newJObject()
  add(query_602307, "nextToken", newJString(nextToken))
  add(path_602306, "broker-id", newJString(brokerId))
  add(query_602307, "maxResults", newJInt(maxResults))
  result = call_602305.call(path_602306, query_602307, nil, nil, nil)

var listUsers* = Call_ListUsers_602291(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "mq.amazonaws.com",
                                    route: "/v1/brokers/{broker-id}/users",
                                    validator: validate_ListUsers_602292,
                                    base: "/", url: url_ListUsers_602293,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootBroker_602308 = ref object of OpenApiRestCall_601389
proc url_RebootBroker_602310(protocol: Scheme; host: string; base: string;
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

proc validate_RebootBroker_602309(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602311 = path.getOrDefault("broker-id")
  valid_602311 = validateParameter(valid_602311, JString, required = true,
                                 default = nil)
  if valid_602311 != nil:
    section.add "broker-id", valid_602311
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602312 = header.getOrDefault("X-Amz-Signature")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-Signature", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-Content-Sha256", valid_602313
  var valid_602314 = header.getOrDefault("X-Amz-Date")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Date", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Credential")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Credential", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Security-Token")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Security-Token", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Algorithm")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Algorithm", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-SignedHeaders", valid_602318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602319: Call_RebootBroker_602308; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Reboots a broker. Note: This API is asynchronous.
  ## 
  let valid = call_602319.validator(path, query, header, formData, body)
  let scheme = call_602319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602319.url(scheme.get, call_602319.host, call_602319.base,
                         call_602319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602319, url, valid)

proc call*(call_602320: Call_RebootBroker_602308; brokerId: string): Recallable =
  ## rebootBroker
  ## Reboots a broker. Note: This API is asynchronous.
  ##   brokerId: string (required)
  ##           : The unique ID that Amazon MQ generates for the broker.
  var path_602321 = newJObject()
  add(path_602321, "broker-id", newJString(brokerId))
  result = call_602320.call(path_602321, nil, nil, nil, nil)

var rebootBroker* = Call_RebootBroker_602308(name: "rebootBroker",
    meth: HttpMethod.HttpPost, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}/reboot", validator: validate_RebootBroker_602309,
    base: "/", url: url_RebootBroker_602310, schemes: {Scheme.Https, Scheme.Http})
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
