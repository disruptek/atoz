
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AmazonApiGatewayV2
## version: 2018-11-29
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon API Gateway V2
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/apigateway/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "apigateway.ap-northeast-1.amazonaws.com", "ap-southeast-1": "apigateway.ap-southeast-1.amazonaws.com",
                           "us-west-2": "apigateway.us-west-2.amazonaws.com",
                           "eu-west-2": "apigateway.eu-west-2.amazonaws.com", "ap-northeast-3": "apigateway.ap-northeast-3.amazonaws.com", "eu-central-1": "apigateway.eu-central-1.amazonaws.com",
                           "us-east-2": "apigateway.us-east-2.amazonaws.com",
                           "us-east-1": "apigateway.us-east-1.amazonaws.com", "cn-northwest-1": "apigateway.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "apigateway.ap-south-1.amazonaws.com",
                           "eu-north-1": "apigateway.eu-north-1.amazonaws.com", "ap-northeast-2": "apigateway.ap-northeast-2.amazonaws.com",
                           "us-west-1": "apigateway.us-west-1.amazonaws.com", "us-gov-east-1": "apigateway.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "apigateway.eu-west-3.amazonaws.com", "cn-north-1": "apigateway.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "apigateway.sa-east-1.amazonaws.com",
                           "eu-west-1": "apigateway.eu-west-1.amazonaws.com", "us-gov-west-1": "apigateway.us-gov-west-1.amazonaws.com", "ap-southeast-2": "apigateway.ap-southeast-2.amazonaws.com", "ca-central-1": "apigateway.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "apigateway.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "apigateway.ap-southeast-1.amazonaws.com",
      "us-west-2": "apigateway.us-west-2.amazonaws.com",
      "eu-west-2": "apigateway.eu-west-2.amazonaws.com",
      "ap-northeast-3": "apigateway.ap-northeast-3.amazonaws.com",
      "eu-central-1": "apigateway.eu-central-1.amazonaws.com",
      "us-east-2": "apigateway.us-east-2.amazonaws.com",
      "us-east-1": "apigateway.us-east-1.amazonaws.com",
      "cn-northwest-1": "apigateway.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "apigateway.ap-south-1.amazonaws.com",
      "eu-north-1": "apigateway.eu-north-1.amazonaws.com",
      "ap-northeast-2": "apigateway.ap-northeast-2.amazonaws.com",
      "us-west-1": "apigateway.us-west-1.amazonaws.com",
      "us-gov-east-1": "apigateway.us-gov-east-1.amazonaws.com",
      "eu-west-3": "apigateway.eu-west-3.amazonaws.com",
      "cn-north-1": "apigateway.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "apigateway.sa-east-1.amazonaws.com",
      "eu-west-1": "apigateway.eu-west-1.amazonaws.com",
      "us-gov-west-1": "apigateway.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "apigateway.ap-southeast-2.amazonaws.com",
      "ca-central-1": "apigateway.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "apigatewayv2"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_ImportApi_601984 = ref object of OpenApiRestCall_601389
proc url_ImportApi_601986(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportApi_601985(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Imports an API.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   failOnWarnings: JBool
  ##                 : Specifies whether to rollback the API creation (true) or not (false) when a warning is encountered. The default value is false.
  ##   basepath: JString
  ##           : Represents the base path of the imported API. Supported only for HTTP APIs.
  section = newJObject()
  var valid_601987 = query.getOrDefault("failOnWarnings")
  valid_601987 = validateParameter(valid_601987, JBool, required = false, default = nil)
  if valid_601987 != nil:
    section.add "failOnWarnings", valid_601987
  var valid_601988 = query.getOrDefault("basepath")
  valid_601988 = validateParameter(valid_601988, JString, required = false,
                                 default = nil)
  if valid_601988 != nil:
    section.add "basepath", valid_601988
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
  var valid_601989 = header.getOrDefault("X-Amz-Signature")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "X-Amz-Signature", valid_601989
  var valid_601990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Content-Sha256", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-Date")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Date", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Credential")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Credential", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-Security-Token")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-Security-Token", valid_601993
  var valid_601994 = header.getOrDefault("X-Amz-Algorithm")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-Algorithm", valid_601994
  var valid_601995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "X-Amz-SignedHeaders", valid_601995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601997: Call_ImportApi_601984; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports an API.
  ## 
  let valid = call_601997.validator(path, query, header, formData, body)
  let scheme = call_601997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601997.url(scheme.get, call_601997.host, call_601997.base,
                         call_601997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601997, url, valid)

proc call*(call_601998: Call_ImportApi_601984; body: JsonNode;
          failOnWarnings: bool = false; basepath: string = ""): Recallable =
  ## importApi
  ## Imports an API.
  ##   failOnWarnings: bool
  ##                 : Specifies whether to rollback the API creation (true) or not (false) when a warning is encountered. The default value is false.
  ##   body: JObject (required)
  ##   basepath: string
  ##           : Represents the base path of the imported API. Supported only for HTTP APIs.
  var query_601999 = newJObject()
  var body_602000 = newJObject()
  add(query_601999, "failOnWarnings", newJBool(failOnWarnings))
  if body != nil:
    body_602000 = body
  add(query_601999, "basepath", newJString(basepath))
  result = call_601998.call(nil, query_601999, nil, nil, body_602000)

var importApi* = Call_ImportApi_601984(name: "importApi", meth: HttpMethod.HttpPut,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis",
                                    validator: validate_ImportApi_601985,
                                    base: "/", url: url_ImportApi_601986,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApi_602001 = ref object of OpenApiRestCall_601389
proc url_CreateApi_602003(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApi_602002(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an Api resource.
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
  var valid_602004 = header.getOrDefault("X-Amz-Signature")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Signature", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Content-Sha256", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Date")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Date", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Credential")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Credential", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Security-Token")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Security-Token", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Algorithm")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Algorithm", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-SignedHeaders", valid_602010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602012: Call_CreateApi_602001; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Api resource.
  ## 
  let valid = call_602012.validator(path, query, header, formData, body)
  let scheme = call_602012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602012.url(scheme.get, call_602012.host, call_602012.base,
                         call_602012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602012, url, valid)

proc call*(call_602013: Call_CreateApi_602001; body: JsonNode): Recallable =
  ## createApi
  ## Creates an Api resource.
  ##   body: JObject (required)
  var body_602014 = newJObject()
  if body != nil:
    body_602014 = body
  result = call_602013.call(nil, nil, nil, nil, body_602014)

var createApi* = Call_CreateApi_602001(name: "createApi", meth: HttpMethod.HttpPost,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis",
                                    validator: validate_CreateApi_602002,
                                    base: "/", url: url_CreateApi_602003,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApis_601727 = ref object of OpenApiRestCall_601389
proc url_GetApis_601729(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApis_601728(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a collection of Api resources.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_601841 = query.getOrDefault("nextToken")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "nextToken", valid_601841
  var valid_601842 = query.getOrDefault("maxResults")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
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

proc call*(call_601872: Call_GetApis_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of Api resources.
  ## 
  let valid = call_601872.validator(path, query, header, formData, body)
  let scheme = call_601872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601872.url(scheme.get, call_601872.host, call_601872.base,
                         call_601872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601872, url, valid)

proc call*(call_601943: Call_GetApis_601727; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getApis
  ## Gets a collection of Api resources.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var query_601944 = newJObject()
  add(query_601944, "nextToken", newJString(nextToken))
  add(query_601944, "maxResults", newJString(maxResults))
  result = call_601943.call(nil, query_601944, nil, nil, nil)

var getApis* = Call_GetApis_601727(name: "getApis", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/v2/apis", validator: validate_GetApis_601728,
                                base: "/", url: url_GetApis_601729,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApiMapping_602046 = ref object of OpenApiRestCall_601389
proc url_CreateApiMapping_602048(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName"),
               (kind: ConstantSegment, value: "/apimappings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateApiMapping_602047(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates an API mapping.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
  ##             : The domain name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domainName` field"
  var valid_602049 = path.getOrDefault("domainName")
  valid_602049 = validateParameter(valid_602049, JString, required = true,
                                 default = nil)
  if valid_602049 != nil:
    section.add "domainName", valid_602049
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
  var valid_602050 = header.getOrDefault("X-Amz-Signature")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Signature", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Content-Sha256", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Date")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Date", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-Credential")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Credential", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-Security-Token")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-Security-Token", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-Algorithm")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-Algorithm", valid_602055
  var valid_602056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-SignedHeaders", valid_602056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602058: Call_CreateApiMapping_602046; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an API mapping.
  ## 
  let valid = call_602058.validator(path, query, header, formData, body)
  let scheme = call_602058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602058.url(scheme.get, call_602058.host, call_602058.base,
                         call_602058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602058, url, valid)

proc call*(call_602059: Call_CreateApiMapping_602046; body: JsonNode;
          domainName: string): Recallable =
  ## createApiMapping
  ## Creates an API mapping.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : The domain name.
  var path_602060 = newJObject()
  var body_602061 = newJObject()
  if body != nil:
    body_602061 = body
  add(path_602060, "domainName", newJString(domainName))
  result = call_602059.call(path_602060, nil, nil, nil, body_602061)

var createApiMapping* = Call_CreateApiMapping_602046(name: "createApiMapping",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings",
    validator: validate_CreateApiMapping_602047, base: "/",
    url: url_CreateApiMapping_602048, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiMappings_602015 = ref object of OpenApiRestCall_601389
proc url_GetApiMappings_602017(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName"),
               (kind: ConstantSegment, value: "/apimappings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApiMappings_602016(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets API mappings.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
  ##             : The domain name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domainName` field"
  var valid_602032 = path.getOrDefault("domainName")
  valid_602032 = validateParameter(valid_602032, JString, required = true,
                                 default = nil)
  if valid_602032 != nil:
    section.add "domainName", valid_602032
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_602033 = query.getOrDefault("nextToken")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "nextToken", valid_602033
  var valid_602034 = query.getOrDefault("maxResults")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "maxResults", valid_602034
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
  var valid_602035 = header.getOrDefault("X-Amz-Signature")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Signature", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Content-Sha256", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-Date")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Date", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-Credential")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Credential", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-Security-Token")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Security-Token", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Algorithm")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Algorithm", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-SignedHeaders", valid_602041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602042: Call_GetApiMappings_602015; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets API mappings.
  ## 
  let valid = call_602042.validator(path, query, header, formData, body)
  let scheme = call_602042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602042.url(scheme.get, call_602042.host, call_602042.base,
                         call_602042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602042, url, valid)

proc call*(call_602043: Call_GetApiMappings_602015; domainName: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getApiMappings
  ## Gets API mappings.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_602044 = newJObject()
  var query_602045 = newJObject()
  add(query_602045, "nextToken", newJString(nextToken))
  add(path_602044, "domainName", newJString(domainName))
  add(query_602045, "maxResults", newJString(maxResults))
  result = call_602043.call(path_602044, query_602045, nil, nil, nil)

var getApiMappings* = Call_GetApiMappings_602015(name: "getApiMappings",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings",
    validator: validate_GetApiMappings_602016, base: "/", url: url_GetApiMappings_602017,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAuthorizer_602079 = ref object of OpenApiRestCall_601389
proc url_CreateAuthorizer_602081(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/authorizers")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateAuthorizer_602080(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates an Authorizer for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602082 = path.getOrDefault("apiId")
  valid_602082 = validateParameter(valid_602082, JString, required = true,
                                 default = nil)
  if valid_602082 != nil:
    section.add "apiId", valid_602082
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
  var valid_602083 = header.getOrDefault("X-Amz-Signature")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Signature", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-Content-Sha256", valid_602084
  var valid_602085 = header.getOrDefault("X-Amz-Date")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Date", valid_602085
  var valid_602086 = header.getOrDefault("X-Amz-Credential")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-Credential", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Security-Token")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Security-Token", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-Algorithm")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Algorithm", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-SignedHeaders", valid_602089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602091: Call_CreateAuthorizer_602079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Authorizer for an API.
  ## 
  let valid = call_602091.validator(path, query, header, formData, body)
  let scheme = call_602091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602091.url(scheme.get, call_602091.host, call_602091.base,
                         call_602091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602091, url, valid)

proc call*(call_602092: Call_CreateAuthorizer_602079; apiId: string; body: JsonNode): Recallable =
  ## createAuthorizer
  ## Creates an Authorizer for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_602093 = newJObject()
  var body_602094 = newJObject()
  add(path_602093, "apiId", newJString(apiId))
  if body != nil:
    body_602094 = body
  result = call_602092.call(path_602093, nil, nil, nil, body_602094)

var createAuthorizer* = Call_CreateAuthorizer_602079(name: "createAuthorizer",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers", validator: validate_CreateAuthorizer_602080,
    base: "/", url: url_CreateAuthorizer_602081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizers_602062 = ref object of OpenApiRestCall_601389
proc url_GetAuthorizers_602064(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/authorizers")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAuthorizers_602063(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets the Authorizers for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602065 = path.getOrDefault("apiId")
  valid_602065 = validateParameter(valid_602065, JString, required = true,
                                 default = nil)
  if valid_602065 != nil:
    section.add "apiId", valid_602065
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_602066 = query.getOrDefault("nextToken")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "nextToken", valid_602066
  var valid_602067 = query.getOrDefault("maxResults")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "maxResults", valid_602067
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
  var valid_602068 = header.getOrDefault("X-Amz-Signature")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Signature", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-Content-Sha256", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-Date")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Date", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-Credential")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Credential", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-Security-Token")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Security-Token", valid_602072
  var valid_602073 = header.getOrDefault("X-Amz-Algorithm")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Algorithm", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-SignedHeaders", valid_602074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602075: Call_GetAuthorizers_602062; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Authorizers for an API.
  ## 
  let valid = call_602075.validator(path, query, header, formData, body)
  let scheme = call_602075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602075.url(scheme.get, call_602075.host, call_602075.base,
                         call_602075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602075, url, valid)

proc call*(call_602076: Call_GetAuthorizers_602062; apiId: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getAuthorizers
  ## Gets the Authorizers for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_602077 = newJObject()
  var query_602078 = newJObject()
  add(query_602078, "nextToken", newJString(nextToken))
  add(path_602077, "apiId", newJString(apiId))
  add(query_602078, "maxResults", newJString(maxResults))
  result = call_602076.call(path_602077, query_602078, nil, nil, nil)

var getAuthorizers* = Call_GetAuthorizers_602062(name: "getAuthorizers",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers", validator: validate_GetAuthorizers_602063,
    base: "/", url: url_GetAuthorizers_602064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_602112 = ref object of OpenApiRestCall_601389
proc url_CreateDeployment_602114(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/deployments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDeployment_602113(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a Deployment for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602115 = path.getOrDefault("apiId")
  valid_602115 = validateParameter(valid_602115, JString, required = true,
                                 default = nil)
  if valid_602115 != nil:
    section.add "apiId", valid_602115
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
  var valid_602116 = header.getOrDefault("X-Amz-Signature")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "X-Amz-Signature", valid_602116
  var valid_602117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "X-Amz-Content-Sha256", valid_602117
  var valid_602118 = header.getOrDefault("X-Amz-Date")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-Date", valid_602118
  var valid_602119 = header.getOrDefault("X-Amz-Credential")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Credential", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Security-Token")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Security-Token", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Algorithm")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Algorithm", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-SignedHeaders", valid_602122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602124: Call_CreateDeployment_602112; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Deployment for an API.
  ## 
  let valid = call_602124.validator(path, query, header, formData, body)
  let scheme = call_602124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602124.url(scheme.get, call_602124.host, call_602124.base,
                         call_602124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602124, url, valid)

proc call*(call_602125: Call_CreateDeployment_602112; apiId: string; body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a Deployment for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_602126 = newJObject()
  var body_602127 = newJObject()
  add(path_602126, "apiId", newJString(apiId))
  if body != nil:
    body_602127 = body
  result = call_602125.call(path_602126, nil, nil, nil, body_602127)

var createDeployment* = Call_CreateDeployment_602112(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments", validator: validate_CreateDeployment_602113,
    base: "/", url: url_CreateDeployment_602114,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployments_602095 = ref object of OpenApiRestCall_601389
proc url_GetDeployments_602097(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/deployments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeployments_602096(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets the Deployments for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602098 = path.getOrDefault("apiId")
  valid_602098 = validateParameter(valid_602098, JString, required = true,
                                 default = nil)
  if valid_602098 != nil:
    section.add "apiId", valid_602098
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_602099 = query.getOrDefault("nextToken")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "nextToken", valid_602099
  var valid_602100 = query.getOrDefault("maxResults")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "maxResults", valid_602100
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
  var valid_602101 = header.getOrDefault("X-Amz-Signature")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-Signature", valid_602101
  var valid_602102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-Content-Sha256", valid_602102
  var valid_602103 = header.getOrDefault("X-Amz-Date")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Date", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-Credential")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-Credential", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Security-Token")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Security-Token", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Algorithm")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Algorithm", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-SignedHeaders", valid_602107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602108: Call_GetDeployments_602095; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Deployments for an API.
  ## 
  let valid = call_602108.validator(path, query, header, formData, body)
  let scheme = call_602108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602108.url(scheme.get, call_602108.host, call_602108.base,
                         call_602108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602108, url, valid)

proc call*(call_602109: Call_GetDeployments_602095; apiId: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getDeployments
  ## Gets the Deployments for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_602110 = newJObject()
  var query_602111 = newJObject()
  add(query_602111, "nextToken", newJString(nextToken))
  add(path_602110, "apiId", newJString(apiId))
  add(query_602111, "maxResults", newJString(maxResults))
  result = call_602109.call(path_602110, query_602111, nil, nil, nil)

var getDeployments* = Call_GetDeployments_602095(name: "getDeployments",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments", validator: validate_GetDeployments_602096,
    base: "/", url: url_GetDeployments_602097, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainName_602143 = ref object of OpenApiRestCall_601389
proc url_CreateDomainName_602145(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDomainName_602144(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a domain name.
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
  var valid_602146 = header.getOrDefault("X-Amz-Signature")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Signature", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Content-Sha256", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-Date")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-Date", valid_602148
  var valid_602149 = header.getOrDefault("X-Amz-Credential")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "X-Amz-Credential", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-Security-Token")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Security-Token", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Algorithm")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Algorithm", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-SignedHeaders", valid_602152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602154: Call_CreateDomainName_602143; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a domain name.
  ## 
  let valid = call_602154.validator(path, query, header, formData, body)
  let scheme = call_602154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602154.url(scheme.get, call_602154.host, call_602154.base,
                         call_602154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602154, url, valid)

proc call*(call_602155: Call_CreateDomainName_602143; body: JsonNode): Recallable =
  ## createDomainName
  ## Creates a domain name.
  ##   body: JObject (required)
  var body_602156 = newJObject()
  if body != nil:
    body_602156 = body
  result = call_602155.call(nil, nil, nil, nil, body_602156)

var createDomainName* = Call_CreateDomainName_602143(name: "createDomainName",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames", validator: validate_CreateDomainName_602144,
    base: "/", url: url_CreateDomainName_602145,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainNames_602128 = ref object of OpenApiRestCall_601389
proc url_GetDomainNames_602130(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainNames_602129(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets the domain names for an AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_602131 = query.getOrDefault("nextToken")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "nextToken", valid_602131
  var valid_602132 = query.getOrDefault("maxResults")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "maxResults", valid_602132
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
  var valid_602133 = header.getOrDefault("X-Amz-Signature")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "X-Amz-Signature", valid_602133
  var valid_602134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "X-Amz-Content-Sha256", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Date")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Date", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Credential")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Credential", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Security-Token")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Security-Token", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Algorithm")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Algorithm", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-SignedHeaders", valid_602139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602140: Call_GetDomainNames_602128; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the domain names for an AWS account.
  ## 
  let valid = call_602140.validator(path, query, header, formData, body)
  let scheme = call_602140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602140.url(scheme.get, call_602140.host, call_602140.base,
                         call_602140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602140, url, valid)

proc call*(call_602141: Call_GetDomainNames_602128; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getDomainNames
  ## Gets the domain names for an AWS account.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var query_602142 = newJObject()
  add(query_602142, "nextToken", newJString(nextToken))
  add(query_602142, "maxResults", newJString(maxResults))
  result = call_602141.call(nil, query_602142, nil, nil, nil)

var getDomainNames* = Call_GetDomainNames_602128(name: "getDomainNames",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames", validator: validate_GetDomainNames_602129, base: "/",
    url: url_GetDomainNames_602130, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntegration_602174 = ref object of OpenApiRestCall_601389
proc url_CreateIntegration_602176(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateIntegration_602175(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates an Integration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602177 = path.getOrDefault("apiId")
  valid_602177 = validateParameter(valid_602177, JString, required = true,
                                 default = nil)
  if valid_602177 != nil:
    section.add "apiId", valid_602177
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
  var valid_602178 = header.getOrDefault("X-Amz-Signature")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Signature", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Content-Sha256", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Date")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Date", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Credential")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Credential", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Security-Token")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Security-Token", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Algorithm")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Algorithm", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-SignedHeaders", valid_602184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602186: Call_CreateIntegration_602174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Integration.
  ## 
  let valid = call_602186.validator(path, query, header, formData, body)
  let scheme = call_602186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602186.url(scheme.get, call_602186.host, call_602186.base,
                         call_602186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602186, url, valid)

proc call*(call_602187: Call_CreateIntegration_602174; apiId: string; body: JsonNode): Recallable =
  ## createIntegration
  ## Creates an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_602188 = newJObject()
  var body_602189 = newJObject()
  add(path_602188, "apiId", newJString(apiId))
  if body != nil:
    body_602189 = body
  result = call_602187.call(path_602188, nil, nil, nil, body_602189)

var createIntegration* = Call_CreateIntegration_602174(name: "createIntegration",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations", validator: validate_CreateIntegration_602175,
    base: "/", url: url_CreateIntegration_602176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrations_602157 = ref object of OpenApiRestCall_601389
proc url_GetIntegrations_602159(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntegrations_602158(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Gets the Integrations for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602160 = path.getOrDefault("apiId")
  valid_602160 = validateParameter(valid_602160, JString, required = true,
                                 default = nil)
  if valid_602160 != nil:
    section.add "apiId", valid_602160
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_602161 = query.getOrDefault("nextToken")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "nextToken", valid_602161
  var valid_602162 = query.getOrDefault("maxResults")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "maxResults", valid_602162
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
  var valid_602163 = header.getOrDefault("X-Amz-Signature")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Signature", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Content-Sha256", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Date")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Date", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Credential")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Credential", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Security-Token")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Security-Token", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Algorithm")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Algorithm", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-SignedHeaders", valid_602169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602170: Call_GetIntegrations_602157; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Integrations for an API.
  ## 
  let valid = call_602170.validator(path, query, header, formData, body)
  let scheme = call_602170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602170.url(scheme.get, call_602170.host, call_602170.base,
                         call_602170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602170, url, valid)

proc call*(call_602171: Call_GetIntegrations_602157; apiId: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getIntegrations
  ## Gets the Integrations for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_602172 = newJObject()
  var query_602173 = newJObject()
  add(query_602173, "nextToken", newJString(nextToken))
  add(path_602172, "apiId", newJString(apiId))
  add(query_602173, "maxResults", newJString(maxResults))
  result = call_602171.call(path_602172, query_602173, nil, nil, nil)

var getIntegrations* = Call_GetIntegrations_602157(name: "getIntegrations",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations", validator: validate_GetIntegrations_602158,
    base: "/", url: url_GetIntegrations_602159, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntegrationResponse_602208 = ref object of OpenApiRestCall_601389
proc url_CreateIntegrationResponse_602210(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId"),
               (kind: ConstantSegment, value: "/integrationresponses")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateIntegrationResponse_602209(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an IntegrationResponses.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602211 = path.getOrDefault("apiId")
  valid_602211 = validateParameter(valid_602211, JString, required = true,
                                 default = nil)
  if valid_602211 != nil:
    section.add "apiId", valid_602211
  var valid_602212 = path.getOrDefault("integrationId")
  valid_602212 = validateParameter(valid_602212, JString, required = true,
                                 default = nil)
  if valid_602212 != nil:
    section.add "integrationId", valid_602212
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
  var valid_602213 = header.getOrDefault("X-Amz-Signature")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Signature", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Content-Sha256", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Date")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Date", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-Credential")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-Credential", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-Security-Token")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-Security-Token", valid_602217
  var valid_602218 = header.getOrDefault("X-Amz-Algorithm")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "X-Amz-Algorithm", valid_602218
  var valid_602219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602219 = validateParameter(valid_602219, JString, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "X-Amz-SignedHeaders", valid_602219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602221: Call_CreateIntegrationResponse_602208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an IntegrationResponses.
  ## 
  let valid = call_602221.validator(path, query, header, formData, body)
  let scheme = call_602221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602221.url(scheme.get, call_602221.host, call_602221.base,
                         call_602221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602221, url, valid)

proc call*(call_602222: Call_CreateIntegrationResponse_602208; apiId: string;
          integrationId: string; body: JsonNode): Recallable =
  ## createIntegrationResponse
  ## Creates an IntegrationResponses.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  ##   body: JObject (required)
  var path_602223 = newJObject()
  var body_602224 = newJObject()
  add(path_602223, "apiId", newJString(apiId))
  add(path_602223, "integrationId", newJString(integrationId))
  if body != nil:
    body_602224 = body
  result = call_602222.call(path_602223, nil, nil, nil, body_602224)

var createIntegrationResponse* = Call_CreateIntegrationResponse_602208(
    name: "createIntegrationResponse", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses",
    validator: validate_CreateIntegrationResponse_602209, base: "/",
    url: url_CreateIntegrationResponse_602210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponses_602190 = ref object of OpenApiRestCall_601389
proc url_GetIntegrationResponses_602192(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId"),
               (kind: ConstantSegment, value: "/integrationresponses")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntegrationResponses_602191(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the IntegrationResponses for an Integration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602193 = path.getOrDefault("apiId")
  valid_602193 = validateParameter(valid_602193, JString, required = true,
                                 default = nil)
  if valid_602193 != nil:
    section.add "apiId", valid_602193
  var valid_602194 = path.getOrDefault("integrationId")
  valid_602194 = validateParameter(valid_602194, JString, required = true,
                                 default = nil)
  if valid_602194 != nil:
    section.add "integrationId", valid_602194
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_602195 = query.getOrDefault("nextToken")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "nextToken", valid_602195
  var valid_602196 = query.getOrDefault("maxResults")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "maxResults", valid_602196
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
  var valid_602197 = header.getOrDefault("X-Amz-Signature")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Signature", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Content-Sha256", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Date")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Date", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-Credential")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Credential", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-Security-Token")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-Security-Token", valid_602201
  var valid_602202 = header.getOrDefault("X-Amz-Algorithm")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "X-Amz-Algorithm", valid_602202
  var valid_602203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602203 = validateParameter(valid_602203, JString, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "X-Amz-SignedHeaders", valid_602203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602204: Call_GetIntegrationResponses_602190; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the IntegrationResponses for an Integration.
  ## 
  let valid = call_602204.validator(path, query, header, formData, body)
  let scheme = call_602204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602204.url(scheme.get, call_602204.host, call_602204.base,
                         call_602204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602204, url, valid)

proc call*(call_602205: Call_GetIntegrationResponses_602190; apiId: string;
          integrationId: string; nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getIntegrationResponses
  ## Gets the IntegrationResponses for an Integration.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_602206 = newJObject()
  var query_602207 = newJObject()
  add(query_602207, "nextToken", newJString(nextToken))
  add(path_602206, "apiId", newJString(apiId))
  add(path_602206, "integrationId", newJString(integrationId))
  add(query_602207, "maxResults", newJString(maxResults))
  result = call_602205.call(path_602206, query_602207, nil, nil, nil)

var getIntegrationResponses* = Call_GetIntegrationResponses_602190(
    name: "getIntegrationResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses",
    validator: validate_GetIntegrationResponses_602191, base: "/",
    url: url_GetIntegrationResponses_602192, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_602242 = ref object of OpenApiRestCall_601389
proc url_CreateModel_602244(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/models")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateModel_602243(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a Model for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602245 = path.getOrDefault("apiId")
  valid_602245 = validateParameter(valid_602245, JString, required = true,
                                 default = nil)
  if valid_602245 != nil:
    section.add "apiId", valid_602245
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
  var valid_602246 = header.getOrDefault("X-Amz-Signature")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-Signature", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-Content-Sha256", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-Date")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Date", valid_602248
  var valid_602249 = header.getOrDefault("X-Amz-Credential")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-Credential", valid_602249
  var valid_602250 = header.getOrDefault("X-Amz-Security-Token")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-Security-Token", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-Algorithm")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Algorithm", valid_602251
  var valid_602252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "X-Amz-SignedHeaders", valid_602252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602254: Call_CreateModel_602242; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Model for an API.
  ## 
  let valid = call_602254.validator(path, query, header, formData, body)
  let scheme = call_602254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602254.url(scheme.get, call_602254.host, call_602254.base,
                         call_602254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602254, url, valid)

proc call*(call_602255: Call_CreateModel_602242; apiId: string; body: JsonNode): Recallable =
  ## createModel
  ## Creates a Model for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_602256 = newJObject()
  var body_602257 = newJObject()
  add(path_602256, "apiId", newJString(apiId))
  if body != nil:
    body_602257 = body
  result = call_602255.call(path_602256, nil, nil, nil, body_602257)

var createModel* = Call_CreateModel_602242(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/models",
                                        validator: validate_CreateModel_602243,
                                        base: "/", url: url_CreateModel_602244,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_602225 = ref object of OpenApiRestCall_601389
proc url_GetModels_602227(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/models")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetModels_602226(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the Models for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602228 = path.getOrDefault("apiId")
  valid_602228 = validateParameter(valid_602228, JString, required = true,
                                 default = nil)
  if valid_602228 != nil:
    section.add "apiId", valid_602228
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_602229 = query.getOrDefault("nextToken")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "nextToken", valid_602229
  var valid_602230 = query.getOrDefault("maxResults")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "maxResults", valid_602230
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
  var valid_602231 = header.getOrDefault("X-Amz-Signature")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Signature", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-Content-Sha256", valid_602232
  var valid_602233 = header.getOrDefault("X-Amz-Date")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Date", valid_602233
  var valid_602234 = header.getOrDefault("X-Amz-Credential")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Credential", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-Security-Token")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-Security-Token", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Algorithm")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Algorithm", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-SignedHeaders", valid_602237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602238: Call_GetModels_602225; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Models for an API.
  ## 
  let valid = call_602238.validator(path, query, header, formData, body)
  let scheme = call_602238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602238.url(scheme.get, call_602238.host, call_602238.base,
                         call_602238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602238, url, valid)

proc call*(call_602239: Call_GetModels_602225; apiId: string; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getModels
  ## Gets the Models for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_602240 = newJObject()
  var query_602241 = newJObject()
  add(query_602241, "nextToken", newJString(nextToken))
  add(path_602240, "apiId", newJString(apiId))
  add(query_602241, "maxResults", newJString(maxResults))
  result = call_602239.call(path_602240, query_602241, nil, nil, nil)

var getModels* = Call_GetModels_602225(name: "getModels", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/models",
                                    validator: validate_GetModels_602226,
                                    base: "/", url: url_GetModels_602227,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoute_602275 = ref object of OpenApiRestCall_601389
proc url_CreateRoute_602277(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRoute_602276(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a Route for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602278 = path.getOrDefault("apiId")
  valid_602278 = validateParameter(valid_602278, JString, required = true,
                                 default = nil)
  if valid_602278 != nil:
    section.add "apiId", valid_602278
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
  var valid_602279 = header.getOrDefault("X-Amz-Signature")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-Signature", valid_602279
  var valid_602280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-Content-Sha256", valid_602280
  var valid_602281 = header.getOrDefault("X-Amz-Date")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-Date", valid_602281
  var valid_602282 = header.getOrDefault("X-Amz-Credential")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-Credential", valid_602282
  var valid_602283 = header.getOrDefault("X-Amz-Security-Token")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-Security-Token", valid_602283
  var valid_602284 = header.getOrDefault("X-Amz-Algorithm")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Algorithm", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-SignedHeaders", valid_602285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602287: Call_CreateRoute_602275; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Route for an API.
  ## 
  let valid = call_602287.validator(path, query, header, formData, body)
  let scheme = call_602287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602287.url(scheme.get, call_602287.host, call_602287.base,
                         call_602287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602287, url, valid)

proc call*(call_602288: Call_CreateRoute_602275; apiId: string; body: JsonNode): Recallable =
  ## createRoute
  ## Creates a Route for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_602289 = newJObject()
  var body_602290 = newJObject()
  add(path_602289, "apiId", newJString(apiId))
  if body != nil:
    body_602290 = body
  result = call_602288.call(path_602289, nil, nil, nil, body_602290)

var createRoute* = Call_CreateRoute_602275(name: "createRoute",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/routes",
                                        validator: validate_CreateRoute_602276,
                                        base: "/", url: url_CreateRoute_602277,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoutes_602258 = ref object of OpenApiRestCall_601389
proc url_GetRoutes_602260(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRoutes_602259(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the Routes for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602261 = path.getOrDefault("apiId")
  valid_602261 = validateParameter(valid_602261, JString, required = true,
                                 default = nil)
  if valid_602261 != nil:
    section.add "apiId", valid_602261
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_602262 = query.getOrDefault("nextToken")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "nextToken", valid_602262
  var valid_602263 = query.getOrDefault("maxResults")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "maxResults", valid_602263
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

proc call*(call_602271: Call_GetRoutes_602258; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Routes for an API.
  ## 
  let valid = call_602271.validator(path, query, header, formData, body)
  let scheme = call_602271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602271.url(scheme.get, call_602271.host, call_602271.base,
                         call_602271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602271, url, valid)

proc call*(call_602272: Call_GetRoutes_602258; apiId: string; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getRoutes
  ## Gets the Routes for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_602273 = newJObject()
  var query_602274 = newJObject()
  add(query_602274, "nextToken", newJString(nextToken))
  add(path_602273, "apiId", newJString(apiId))
  add(query_602274, "maxResults", newJString(maxResults))
  result = call_602272.call(path_602273, query_602274, nil, nil, nil)

var getRoutes* = Call_GetRoutes_602258(name: "getRoutes", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/routes",
                                    validator: validate_GetRoutes_602259,
                                    base: "/", url: url_GetRoutes_602260,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRouteResponse_602309 = ref object of OpenApiRestCall_601389
proc url_CreateRouteResponse_602311(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId"),
               (kind: ConstantSegment, value: "/routeresponses")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRouteResponse_602310(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a RouteResponse for a Route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602312 = path.getOrDefault("apiId")
  valid_602312 = validateParameter(valid_602312, JString, required = true,
                                 default = nil)
  if valid_602312 != nil:
    section.add "apiId", valid_602312
  var valid_602313 = path.getOrDefault("routeId")
  valid_602313 = validateParameter(valid_602313, JString, required = true,
                                 default = nil)
  if valid_602313 != nil:
    section.add "routeId", valid_602313
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
  var valid_602314 = header.getOrDefault("X-Amz-Signature")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Signature", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Content-Sha256", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Date")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Date", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Credential")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Credential", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-Security-Token")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-Security-Token", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-Algorithm")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-Algorithm", valid_602319
  var valid_602320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602320 = validateParameter(valid_602320, JString, required = false,
                                 default = nil)
  if valid_602320 != nil:
    section.add "X-Amz-SignedHeaders", valid_602320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602322: Call_CreateRouteResponse_602309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a RouteResponse for a Route.
  ## 
  let valid = call_602322.validator(path, query, header, formData, body)
  let scheme = call_602322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602322.url(scheme.get, call_602322.host, call_602322.base,
                         call_602322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602322, url, valid)

proc call*(call_602323: Call_CreateRouteResponse_602309; apiId: string;
          body: JsonNode; routeId: string): Recallable =
  ## createRouteResponse
  ## Creates a RouteResponse for a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   routeId: string (required)
  ##          : The route ID.
  var path_602324 = newJObject()
  var body_602325 = newJObject()
  add(path_602324, "apiId", newJString(apiId))
  if body != nil:
    body_602325 = body
  add(path_602324, "routeId", newJString(routeId))
  result = call_602323.call(path_602324, nil, nil, nil, body_602325)

var createRouteResponse* = Call_CreateRouteResponse_602309(
    name: "createRouteResponse", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses",
    validator: validate_CreateRouteResponse_602310, base: "/",
    url: url_CreateRouteResponse_602311, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRouteResponses_602291 = ref object of OpenApiRestCall_601389
proc url_GetRouteResponses_602293(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId"),
               (kind: ConstantSegment, value: "/routeresponses")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRouteResponses_602292(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Gets the RouteResponses for a Route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602294 = path.getOrDefault("apiId")
  valid_602294 = validateParameter(valid_602294, JString, required = true,
                                 default = nil)
  if valid_602294 != nil:
    section.add "apiId", valid_602294
  var valid_602295 = path.getOrDefault("routeId")
  valid_602295 = validateParameter(valid_602295, JString, required = true,
                                 default = nil)
  if valid_602295 != nil:
    section.add "routeId", valid_602295
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_602296 = query.getOrDefault("nextToken")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "nextToken", valid_602296
  var valid_602297 = query.getOrDefault("maxResults")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "maxResults", valid_602297
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
  var valid_602298 = header.getOrDefault("X-Amz-Signature")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-Signature", valid_602298
  var valid_602299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "X-Amz-Content-Sha256", valid_602299
  var valid_602300 = header.getOrDefault("X-Amz-Date")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Date", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Credential")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Credential", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-Security-Token")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-Security-Token", valid_602302
  var valid_602303 = header.getOrDefault("X-Amz-Algorithm")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "X-Amz-Algorithm", valid_602303
  var valid_602304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-SignedHeaders", valid_602304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602305: Call_GetRouteResponses_602291; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the RouteResponses for a Route.
  ## 
  let valid = call_602305.validator(path, query, header, formData, body)
  let scheme = call_602305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602305.url(scheme.get, call_602305.host, call_602305.base,
                         call_602305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602305, url, valid)

proc call*(call_602306: Call_GetRouteResponses_602291; apiId: string;
          routeId: string; nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getRouteResponses
  ## Gets the RouteResponses for a Route.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeId: string (required)
  ##          : The route ID.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_602307 = newJObject()
  var query_602308 = newJObject()
  add(query_602308, "nextToken", newJString(nextToken))
  add(path_602307, "apiId", newJString(apiId))
  add(path_602307, "routeId", newJString(routeId))
  add(query_602308, "maxResults", newJString(maxResults))
  result = call_602306.call(path_602307, query_602308, nil, nil, nil)

var getRouteResponses* = Call_GetRouteResponses_602291(name: "getRouteResponses",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses",
    validator: validate_GetRouteResponses_602292, base: "/",
    url: url_GetRouteResponses_602293, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStage_602343 = ref object of OpenApiRestCall_601389
proc url_CreateStage_602345(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/stages")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateStage_602344(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a Stage for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602346 = path.getOrDefault("apiId")
  valid_602346 = validateParameter(valid_602346, JString, required = true,
                                 default = nil)
  if valid_602346 != nil:
    section.add "apiId", valid_602346
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
  var valid_602347 = header.getOrDefault("X-Amz-Signature")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Signature", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-Content-Sha256", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-Date")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-Date", valid_602349
  var valid_602350 = header.getOrDefault("X-Amz-Credential")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-Credential", valid_602350
  var valid_602351 = header.getOrDefault("X-Amz-Security-Token")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-Security-Token", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-Algorithm")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-Algorithm", valid_602352
  var valid_602353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-SignedHeaders", valid_602353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602355: Call_CreateStage_602343; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Stage for an API.
  ## 
  let valid = call_602355.validator(path, query, header, formData, body)
  let scheme = call_602355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602355.url(scheme.get, call_602355.host, call_602355.base,
                         call_602355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602355, url, valid)

proc call*(call_602356: Call_CreateStage_602343; apiId: string; body: JsonNode): Recallable =
  ## createStage
  ## Creates a Stage for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_602357 = newJObject()
  var body_602358 = newJObject()
  add(path_602357, "apiId", newJString(apiId))
  if body != nil:
    body_602358 = body
  result = call_602356.call(path_602357, nil, nil, nil, body_602358)

var createStage* = Call_CreateStage_602343(name: "createStage",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/stages",
                                        validator: validate_CreateStage_602344,
                                        base: "/", url: url_CreateStage_602345,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStages_602326 = ref object of OpenApiRestCall_601389
proc url_GetStages_602328(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/stages")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStages_602327(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the Stages for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602329 = path.getOrDefault("apiId")
  valid_602329 = validateParameter(valid_602329, JString, required = true,
                                 default = nil)
  if valid_602329 != nil:
    section.add "apiId", valid_602329
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_602330 = query.getOrDefault("nextToken")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "nextToken", valid_602330
  var valid_602331 = query.getOrDefault("maxResults")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "maxResults", valid_602331
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
  var valid_602332 = header.getOrDefault("X-Amz-Signature")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Signature", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Content-Sha256", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-Date")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-Date", valid_602334
  var valid_602335 = header.getOrDefault("X-Amz-Credential")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "X-Amz-Credential", valid_602335
  var valid_602336 = header.getOrDefault("X-Amz-Security-Token")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-Security-Token", valid_602336
  var valid_602337 = header.getOrDefault("X-Amz-Algorithm")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "X-Amz-Algorithm", valid_602337
  var valid_602338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "X-Amz-SignedHeaders", valid_602338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602339: Call_GetStages_602326; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Stages for an API.
  ## 
  let valid = call_602339.validator(path, query, header, formData, body)
  let scheme = call_602339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602339.url(scheme.get, call_602339.host, call_602339.base,
                         call_602339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602339, url, valid)

proc call*(call_602340: Call_GetStages_602326; apiId: string; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getStages
  ## Gets the Stages for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_602341 = newJObject()
  var query_602342 = newJObject()
  add(query_602342, "nextToken", newJString(nextToken))
  add(path_602341, "apiId", newJString(apiId))
  add(query_602342, "maxResults", newJString(maxResults))
  result = call_602340.call(path_602341, query_602342, nil, nil, nil)

var getStages* = Call_GetStages_602326(name: "getStages", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/stages",
                                    validator: validate_GetStages_602327,
                                    base: "/", url: url_GetStages_602328,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReimportApi_602373 = ref object of OpenApiRestCall_601389
proc url_ReimportApi_602375(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ReimportApi_602374(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Puts an Api resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602376 = path.getOrDefault("apiId")
  valid_602376 = validateParameter(valid_602376, JString, required = true,
                                 default = nil)
  if valid_602376 != nil:
    section.add "apiId", valid_602376
  result.add "path", section
  ## parameters in `query` object:
  ##   failOnWarnings: JBool
  ##                 : Specifies whether to rollback the API creation (true) or not (false) when a warning is encountered. The default value is false.
  ##   basepath: JString
  ##           : Represents the base path of the imported API. Supported only for HTTP APIs.
  section = newJObject()
  var valid_602377 = query.getOrDefault("failOnWarnings")
  valid_602377 = validateParameter(valid_602377, JBool, required = false, default = nil)
  if valid_602377 != nil:
    section.add "failOnWarnings", valid_602377
  var valid_602378 = query.getOrDefault("basepath")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "basepath", valid_602378
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
  var valid_602379 = header.getOrDefault("X-Amz-Signature")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "X-Amz-Signature", valid_602379
  var valid_602380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "X-Amz-Content-Sha256", valid_602380
  var valid_602381 = header.getOrDefault("X-Amz-Date")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "X-Amz-Date", valid_602381
  var valid_602382 = header.getOrDefault("X-Amz-Credential")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-Credential", valid_602382
  var valid_602383 = header.getOrDefault("X-Amz-Security-Token")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "X-Amz-Security-Token", valid_602383
  var valid_602384 = header.getOrDefault("X-Amz-Algorithm")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "X-Amz-Algorithm", valid_602384
  var valid_602385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-SignedHeaders", valid_602385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602387: Call_ReimportApi_602373; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Puts an Api resource.
  ## 
  let valid = call_602387.validator(path, query, header, formData, body)
  let scheme = call_602387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602387.url(scheme.get, call_602387.host, call_602387.base,
                         call_602387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602387, url, valid)

proc call*(call_602388: Call_ReimportApi_602373; apiId: string; body: JsonNode;
          failOnWarnings: bool = false; basepath: string = ""): Recallable =
  ## reimportApi
  ## Puts an Api resource.
  ##   failOnWarnings: bool
  ##                 : Specifies whether to rollback the API creation (true) or not (false) when a warning is encountered. The default value is false.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   basepath: string
  ##           : Represents the base path of the imported API. Supported only for HTTP APIs.
  var path_602389 = newJObject()
  var query_602390 = newJObject()
  var body_602391 = newJObject()
  add(query_602390, "failOnWarnings", newJBool(failOnWarnings))
  add(path_602389, "apiId", newJString(apiId))
  if body != nil:
    body_602391 = body
  add(query_602390, "basepath", newJString(basepath))
  result = call_602388.call(path_602389, query_602390, nil, nil, body_602391)

var reimportApi* = Call_ReimportApi_602373(name: "reimportApi",
                                        meth: HttpMethod.HttpPut,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}",
                                        validator: validate_ReimportApi_602374,
                                        base: "/", url: url_ReimportApi_602375,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApi_602359 = ref object of OpenApiRestCall_601389
proc url_GetApi_602361(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApi_602360(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets an Api resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602362 = path.getOrDefault("apiId")
  valid_602362 = validateParameter(valid_602362, JString, required = true,
                                 default = nil)
  if valid_602362 != nil:
    section.add "apiId", valid_602362
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
  var valid_602363 = header.getOrDefault("X-Amz-Signature")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-Signature", valid_602363
  var valid_602364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-Content-Sha256", valid_602364
  var valid_602365 = header.getOrDefault("X-Amz-Date")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Date", valid_602365
  var valid_602366 = header.getOrDefault("X-Amz-Credential")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-Credential", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-Security-Token")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Security-Token", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Algorithm")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Algorithm", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-SignedHeaders", valid_602369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602370: Call_GetApi_602359; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Api resource.
  ## 
  let valid = call_602370.validator(path, query, header, formData, body)
  let scheme = call_602370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602370.url(scheme.get, call_602370.host, call_602370.base,
                         call_602370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602370, url, valid)

proc call*(call_602371: Call_GetApi_602359; apiId: string): Recallable =
  ## getApi
  ## Gets an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_602372 = newJObject()
  add(path_602372, "apiId", newJString(apiId))
  result = call_602371.call(path_602372, nil, nil, nil, nil)

var getApi* = Call_GetApi_602359(name: "getApi", meth: HttpMethod.HttpGet,
                              host: "apigateway.amazonaws.com",
                              route: "/v2/apis/{apiId}",
                              validator: validate_GetApi_602360, base: "/",
                              url: url_GetApi_602361,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApi_602406 = ref object of OpenApiRestCall_601389
proc url_UpdateApi_602408(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApi_602407(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an Api resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602409 = path.getOrDefault("apiId")
  valid_602409 = validateParameter(valid_602409, JString, required = true,
                                 default = nil)
  if valid_602409 != nil:
    section.add "apiId", valid_602409
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
  var valid_602410 = header.getOrDefault("X-Amz-Signature")
  valid_602410 = validateParameter(valid_602410, JString, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "X-Amz-Signature", valid_602410
  var valid_602411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-Content-Sha256", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-Date")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-Date", valid_602412
  var valid_602413 = header.getOrDefault("X-Amz-Credential")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-Credential", valid_602413
  var valid_602414 = header.getOrDefault("X-Amz-Security-Token")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Security-Token", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-Algorithm")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-Algorithm", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-SignedHeaders", valid_602416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602418: Call_UpdateApi_602406; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Api resource.
  ## 
  let valid = call_602418.validator(path, query, header, formData, body)
  let scheme = call_602418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602418.url(scheme.get, call_602418.host, call_602418.base,
                         call_602418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602418, url, valid)

proc call*(call_602419: Call_UpdateApi_602406; apiId: string; body: JsonNode): Recallable =
  ## updateApi
  ## Updates an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_602420 = newJObject()
  var body_602421 = newJObject()
  add(path_602420, "apiId", newJString(apiId))
  if body != nil:
    body_602421 = body
  result = call_602419.call(path_602420, nil, nil, nil, body_602421)

var updateApi* = Call_UpdateApi_602406(name: "updateApi", meth: HttpMethod.HttpPatch,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}",
                                    validator: validate_UpdateApi_602407,
                                    base: "/", url: url_UpdateApi_602408,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApi_602392 = ref object of OpenApiRestCall_601389
proc url_DeleteApi_602394(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApi_602393(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an Api resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602395 = path.getOrDefault("apiId")
  valid_602395 = validateParameter(valid_602395, JString, required = true,
                                 default = nil)
  if valid_602395 != nil:
    section.add "apiId", valid_602395
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
  var valid_602396 = header.getOrDefault("X-Amz-Signature")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "X-Amz-Signature", valid_602396
  var valid_602397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-Content-Sha256", valid_602397
  var valid_602398 = header.getOrDefault("X-Amz-Date")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Date", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-Credential")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Credential", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-Security-Token")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-Security-Token", valid_602400
  var valid_602401 = header.getOrDefault("X-Amz-Algorithm")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-Algorithm", valid_602401
  var valid_602402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-SignedHeaders", valid_602402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602403: Call_DeleteApi_602392; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Api resource.
  ## 
  let valid = call_602403.validator(path, query, header, formData, body)
  let scheme = call_602403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602403.url(scheme.get, call_602403.host, call_602403.base,
                         call_602403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602403, url, valid)

proc call*(call_602404: Call_DeleteApi_602392; apiId: string): Recallable =
  ## deleteApi
  ## Deletes an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_602405 = newJObject()
  add(path_602405, "apiId", newJString(apiId))
  result = call_602404.call(path_602405, nil, nil, nil, nil)

var deleteApi* = Call_DeleteApi_602392(name: "deleteApi",
                                    meth: HttpMethod.HttpDelete,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}",
                                    validator: validate_DeleteApi_602393,
                                    base: "/", url: url_DeleteApi_602394,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiMapping_602422 = ref object of OpenApiRestCall_601389
proc url_GetApiMapping_602424(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  assert "apiMappingId" in path, "`apiMappingId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName"),
               (kind: ConstantSegment, value: "/apimappings/"),
               (kind: VariableSegment, value: "apiMappingId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApiMapping_602423(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets an API mapping.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiMappingId: JString (required)
  ##               : The API mapping identifier.
  ##   domainName: JString (required)
  ##             : The domain name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `apiMappingId` field"
  var valid_602425 = path.getOrDefault("apiMappingId")
  valid_602425 = validateParameter(valid_602425, JString, required = true,
                                 default = nil)
  if valid_602425 != nil:
    section.add "apiMappingId", valid_602425
  var valid_602426 = path.getOrDefault("domainName")
  valid_602426 = validateParameter(valid_602426, JString, required = true,
                                 default = nil)
  if valid_602426 != nil:
    section.add "domainName", valid_602426
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
  var valid_602427 = header.getOrDefault("X-Amz-Signature")
  valid_602427 = validateParameter(valid_602427, JString, required = false,
                                 default = nil)
  if valid_602427 != nil:
    section.add "X-Amz-Signature", valid_602427
  var valid_602428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "X-Amz-Content-Sha256", valid_602428
  var valid_602429 = header.getOrDefault("X-Amz-Date")
  valid_602429 = validateParameter(valid_602429, JString, required = false,
                                 default = nil)
  if valid_602429 != nil:
    section.add "X-Amz-Date", valid_602429
  var valid_602430 = header.getOrDefault("X-Amz-Credential")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "X-Amz-Credential", valid_602430
  var valid_602431 = header.getOrDefault("X-Amz-Security-Token")
  valid_602431 = validateParameter(valid_602431, JString, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "X-Amz-Security-Token", valid_602431
  var valid_602432 = header.getOrDefault("X-Amz-Algorithm")
  valid_602432 = validateParameter(valid_602432, JString, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "X-Amz-Algorithm", valid_602432
  var valid_602433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "X-Amz-SignedHeaders", valid_602433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602434: Call_GetApiMapping_602422; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an API mapping.
  ## 
  let valid = call_602434.validator(path, query, header, formData, body)
  let scheme = call_602434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602434.url(scheme.get, call_602434.host, call_602434.base,
                         call_602434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602434, url, valid)

proc call*(call_602435: Call_GetApiMapping_602422; apiMappingId: string;
          domainName: string): Recallable =
  ## getApiMapping
  ## Gets an API mapping.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_602436 = newJObject()
  add(path_602436, "apiMappingId", newJString(apiMappingId))
  add(path_602436, "domainName", newJString(domainName))
  result = call_602435.call(path_602436, nil, nil, nil, nil)

var getApiMapping* = Call_GetApiMapping_602422(name: "getApiMapping",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_GetApiMapping_602423, base: "/", url: url_GetApiMapping_602424,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiMapping_602452 = ref object of OpenApiRestCall_601389
proc url_UpdateApiMapping_602454(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  assert "apiMappingId" in path, "`apiMappingId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName"),
               (kind: ConstantSegment, value: "/apimappings/"),
               (kind: VariableSegment, value: "apiMappingId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApiMapping_602453(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## The API mapping.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiMappingId: JString (required)
  ##               : The API mapping identifier.
  ##   domainName: JString (required)
  ##             : The domain name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `apiMappingId` field"
  var valid_602455 = path.getOrDefault("apiMappingId")
  valid_602455 = validateParameter(valid_602455, JString, required = true,
                                 default = nil)
  if valid_602455 != nil:
    section.add "apiMappingId", valid_602455
  var valid_602456 = path.getOrDefault("domainName")
  valid_602456 = validateParameter(valid_602456, JString, required = true,
                                 default = nil)
  if valid_602456 != nil:
    section.add "domainName", valid_602456
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
  var valid_602457 = header.getOrDefault("X-Amz-Signature")
  valid_602457 = validateParameter(valid_602457, JString, required = false,
                                 default = nil)
  if valid_602457 != nil:
    section.add "X-Amz-Signature", valid_602457
  var valid_602458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602458 = validateParameter(valid_602458, JString, required = false,
                                 default = nil)
  if valid_602458 != nil:
    section.add "X-Amz-Content-Sha256", valid_602458
  var valid_602459 = header.getOrDefault("X-Amz-Date")
  valid_602459 = validateParameter(valid_602459, JString, required = false,
                                 default = nil)
  if valid_602459 != nil:
    section.add "X-Amz-Date", valid_602459
  var valid_602460 = header.getOrDefault("X-Amz-Credential")
  valid_602460 = validateParameter(valid_602460, JString, required = false,
                                 default = nil)
  if valid_602460 != nil:
    section.add "X-Amz-Credential", valid_602460
  var valid_602461 = header.getOrDefault("X-Amz-Security-Token")
  valid_602461 = validateParameter(valid_602461, JString, required = false,
                                 default = nil)
  if valid_602461 != nil:
    section.add "X-Amz-Security-Token", valid_602461
  var valid_602462 = header.getOrDefault("X-Amz-Algorithm")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "X-Amz-Algorithm", valid_602462
  var valid_602463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602463 = validateParameter(valid_602463, JString, required = false,
                                 default = nil)
  if valid_602463 != nil:
    section.add "X-Amz-SignedHeaders", valid_602463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602465: Call_UpdateApiMapping_602452; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The API mapping.
  ## 
  let valid = call_602465.validator(path, query, header, formData, body)
  let scheme = call_602465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602465.url(scheme.get, call_602465.host, call_602465.base,
                         call_602465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602465, url, valid)

proc call*(call_602466: Call_UpdateApiMapping_602452; apiMappingId: string;
          body: JsonNode; domainName: string): Recallable =
  ## updateApiMapping
  ## The API mapping.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : The domain name.
  var path_602467 = newJObject()
  var body_602468 = newJObject()
  add(path_602467, "apiMappingId", newJString(apiMappingId))
  if body != nil:
    body_602468 = body
  add(path_602467, "domainName", newJString(domainName))
  result = call_602466.call(path_602467, nil, nil, nil, body_602468)

var updateApiMapping* = Call_UpdateApiMapping_602452(name: "updateApiMapping",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_UpdateApiMapping_602453, base: "/",
    url: url_UpdateApiMapping_602454, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiMapping_602437 = ref object of OpenApiRestCall_601389
proc url_DeleteApiMapping_602439(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  assert "apiMappingId" in path, "`apiMappingId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName"),
               (kind: ConstantSegment, value: "/apimappings/"),
               (kind: VariableSegment, value: "apiMappingId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApiMapping_602438(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes an API mapping.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiMappingId: JString (required)
  ##               : The API mapping identifier.
  ##   domainName: JString (required)
  ##             : The domain name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `apiMappingId` field"
  var valid_602440 = path.getOrDefault("apiMappingId")
  valid_602440 = validateParameter(valid_602440, JString, required = true,
                                 default = nil)
  if valid_602440 != nil:
    section.add "apiMappingId", valid_602440
  var valid_602441 = path.getOrDefault("domainName")
  valid_602441 = validateParameter(valid_602441, JString, required = true,
                                 default = nil)
  if valid_602441 != nil:
    section.add "domainName", valid_602441
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
  var valid_602442 = header.getOrDefault("X-Amz-Signature")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-Signature", valid_602442
  var valid_602443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-Content-Sha256", valid_602443
  var valid_602444 = header.getOrDefault("X-Amz-Date")
  valid_602444 = validateParameter(valid_602444, JString, required = false,
                                 default = nil)
  if valid_602444 != nil:
    section.add "X-Amz-Date", valid_602444
  var valid_602445 = header.getOrDefault("X-Amz-Credential")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "X-Amz-Credential", valid_602445
  var valid_602446 = header.getOrDefault("X-Amz-Security-Token")
  valid_602446 = validateParameter(valid_602446, JString, required = false,
                                 default = nil)
  if valid_602446 != nil:
    section.add "X-Amz-Security-Token", valid_602446
  var valid_602447 = header.getOrDefault("X-Amz-Algorithm")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "X-Amz-Algorithm", valid_602447
  var valid_602448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "X-Amz-SignedHeaders", valid_602448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602449: Call_DeleteApiMapping_602437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an API mapping.
  ## 
  let valid = call_602449.validator(path, query, header, formData, body)
  let scheme = call_602449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602449.url(scheme.get, call_602449.host, call_602449.base,
                         call_602449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602449, url, valid)

proc call*(call_602450: Call_DeleteApiMapping_602437; apiMappingId: string;
          domainName: string): Recallable =
  ## deleteApiMapping
  ## Deletes an API mapping.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_602451 = newJObject()
  add(path_602451, "apiMappingId", newJString(apiMappingId))
  add(path_602451, "domainName", newJString(domainName))
  result = call_602450.call(path_602451, nil, nil, nil, nil)

var deleteApiMapping* = Call_DeleteApiMapping_602437(name: "deleteApiMapping",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_DeleteApiMapping_602438, base: "/",
    url: url_DeleteApiMapping_602439, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizer_602469 = ref object of OpenApiRestCall_601389
proc url_GetAuthorizer_602471(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "authorizerId" in path, "`authorizerId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/authorizers/"),
               (kind: VariableSegment, value: "authorizerId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAuthorizer_602470(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets an Authorizer.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   authorizerId: JString (required)
  ##               : The authorizer identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602472 = path.getOrDefault("apiId")
  valid_602472 = validateParameter(valid_602472, JString, required = true,
                                 default = nil)
  if valid_602472 != nil:
    section.add "apiId", valid_602472
  var valid_602473 = path.getOrDefault("authorizerId")
  valid_602473 = validateParameter(valid_602473, JString, required = true,
                                 default = nil)
  if valid_602473 != nil:
    section.add "authorizerId", valid_602473
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
  var valid_602474 = header.getOrDefault("X-Amz-Signature")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "X-Amz-Signature", valid_602474
  var valid_602475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602475 = validateParameter(valid_602475, JString, required = false,
                                 default = nil)
  if valid_602475 != nil:
    section.add "X-Amz-Content-Sha256", valid_602475
  var valid_602476 = header.getOrDefault("X-Amz-Date")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "X-Amz-Date", valid_602476
  var valid_602477 = header.getOrDefault("X-Amz-Credential")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-Credential", valid_602477
  var valid_602478 = header.getOrDefault("X-Amz-Security-Token")
  valid_602478 = validateParameter(valid_602478, JString, required = false,
                                 default = nil)
  if valid_602478 != nil:
    section.add "X-Amz-Security-Token", valid_602478
  var valid_602479 = header.getOrDefault("X-Amz-Algorithm")
  valid_602479 = validateParameter(valid_602479, JString, required = false,
                                 default = nil)
  if valid_602479 != nil:
    section.add "X-Amz-Algorithm", valid_602479
  var valid_602480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602480 = validateParameter(valid_602480, JString, required = false,
                                 default = nil)
  if valid_602480 != nil:
    section.add "X-Amz-SignedHeaders", valid_602480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602481: Call_GetAuthorizer_602469; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Authorizer.
  ## 
  let valid = call_602481.validator(path, query, header, formData, body)
  let scheme = call_602481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602481.url(scheme.get, call_602481.host, call_602481.base,
                         call_602481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602481, url, valid)

proc call*(call_602482: Call_GetAuthorizer_602469; apiId: string;
          authorizerId: string): Recallable =
  ## getAuthorizer
  ## Gets an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  var path_602483 = newJObject()
  add(path_602483, "apiId", newJString(apiId))
  add(path_602483, "authorizerId", newJString(authorizerId))
  result = call_602482.call(path_602483, nil, nil, nil, nil)

var getAuthorizer* = Call_GetAuthorizer_602469(name: "getAuthorizer",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_GetAuthorizer_602470, base: "/", url: url_GetAuthorizer_602471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthorizer_602499 = ref object of OpenApiRestCall_601389
proc url_UpdateAuthorizer_602501(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "authorizerId" in path, "`authorizerId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/authorizers/"),
               (kind: VariableSegment, value: "authorizerId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateAuthorizer_602500(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates an Authorizer.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   authorizerId: JString (required)
  ##               : The authorizer identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602502 = path.getOrDefault("apiId")
  valid_602502 = validateParameter(valid_602502, JString, required = true,
                                 default = nil)
  if valid_602502 != nil:
    section.add "apiId", valid_602502
  var valid_602503 = path.getOrDefault("authorizerId")
  valid_602503 = validateParameter(valid_602503, JString, required = true,
                                 default = nil)
  if valid_602503 != nil:
    section.add "authorizerId", valid_602503
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
  var valid_602504 = header.getOrDefault("X-Amz-Signature")
  valid_602504 = validateParameter(valid_602504, JString, required = false,
                                 default = nil)
  if valid_602504 != nil:
    section.add "X-Amz-Signature", valid_602504
  var valid_602505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602505 = validateParameter(valid_602505, JString, required = false,
                                 default = nil)
  if valid_602505 != nil:
    section.add "X-Amz-Content-Sha256", valid_602505
  var valid_602506 = header.getOrDefault("X-Amz-Date")
  valid_602506 = validateParameter(valid_602506, JString, required = false,
                                 default = nil)
  if valid_602506 != nil:
    section.add "X-Amz-Date", valid_602506
  var valid_602507 = header.getOrDefault("X-Amz-Credential")
  valid_602507 = validateParameter(valid_602507, JString, required = false,
                                 default = nil)
  if valid_602507 != nil:
    section.add "X-Amz-Credential", valid_602507
  var valid_602508 = header.getOrDefault("X-Amz-Security-Token")
  valid_602508 = validateParameter(valid_602508, JString, required = false,
                                 default = nil)
  if valid_602508 != nil:
    section.add "X-Amz-Security-Token", valid_602508
  var valid_602509 = header.getOrDefault("X-Amz-Algorithm")
  valid_602509 = validateParameter(valid_602509, JString, required = false,
                                 default = nil)
  if valid_602509 != nil:
    section.add "X-Amz-Algorithm", valid_602509
  var valid_602510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "X-Amz-SignedHeaders", valid_602510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602512: Call_UpdateAuthorizer_602499; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Authorizer.
  ## 
  let valid = call_602512.validator(path, query, header, formData, body)
  let scheme = call_602512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602512.url(scheme.get, call_602512.host, call_602512.base,
                         call_602512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602512, url, valid)

proc call*(call_602513: Call_UpdateAuthorizer_602499; apiId: string;
          authorizerId: string; body: JsonNode): Recallable =
  ## updateAuthorizer
  ## Updates an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  ##   body: JObject (required)
  var path_602514 = newJObject()
  var body_602515 = newJObject()
  add(path_602514, "apiId", newJString(apiId))
  add(path_602514, "authorizerId", newJString(authorizerId))
  if body != nil:
    body_602515 = body
  result = call_602513.call(path_602514, nil, nil, nil, body_602515)

var updateAuthorizer* = Call_UpdateAuthorizer_602499(name: "updateAuthorizer",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_UpdateAuthorizer_602500, base: "/",
    url: url_UpdateAuthorizer_602501, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAuthorizer_602484 = ref object of OpenApiRestCall_601389
proc url_DeleteAuthorizer_602486(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "authorizerId" in path, "`authorizerId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/authorizers/"),
               (kind: VariableSegment, value: "authorizerId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAuthorizer_602485(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes an Authorizer.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   authorizerId: JString (required)
  ##               : The authorizer identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602487 = path.getOrDefault("apiId")
  valid_602487 = validateParameter(valid_602487, JString, required = true,
                                 default = nil)
  if valid_602487 != nil:
    section.add "apiId", valid_602487
  var valid_602488 = path.getOrDefault("authorizerId")
  valid_602488 = validateParameter(valid_602488, JString, required = true,
                                 default = nil)
  if valid_602488 != nil:
    section.add "authorizerId", valid_602488
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
  var valid_602489 = header.getOrDefault("X-Amz-Signature")
  valid_602489 = validateParameter(valid_602489, JString, required = false,
                                 default = nil)
  if valid_602489 != nil:
    section.add "X-Amz-Signature", valid_602489
  var valid_602490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602490 = validateParameter(valid_602490, JString, required = false,
                                 default = nil)
  if valid_602490 != nil:
    section.add "X-Amz-Content-Sha256", valid_602490
  var valid_602491 = header.getOrDefault("X-Amz-Date")
  valid_602491 = validateParameter(valid_602491, JString, required = false,
                                 default = nil)
  if valid_602491 != nil:
    section.add "X-Amz-Date", valid_602491
  var valid_602492 = header.getOrDefault("X-Amz-Credential")
  valid_602492 = validateParameter(valid_602492, JString, required = false,
                                 default = nil)
  if valid_602492 != nil:
    section.add "X-Amz-Credential", valid_602492
  var valid_602493 = header.getOrDefault("X-Amz-Security-Token")
  valid_602493 = validateParameter(valid_602493, JString, required = false,
                                 default = nil)
  if valid_602493 != nil:
    section.add "X-Amz-Security-Token", valid_602493
  var valid_602494 = header.getOrDefault("X-Amz-Algorithm")
  valid_602494 = validateParameter(valid_602494, JString, required = false,
                                 default = nil)
  if valid_602494 != nil:
    section.add "X-Amz-Algorithm", valid_602494
  var valid_602495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602495 = validateParameter(valid_602495, JString, required = false,
                                 default = nil)
  if valid_602495 != nil:
    section.add "X-Amz-SignedHeaders", valid_602495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602496: Call_DeleteAuthorizer_602484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Authorizer.
  ## 
  let valid = call_602496.validator(path, query, header, formData, body)
  let scheme = call_602496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602496.url(scheme.get, call_602496.host, call_602496.base,
                         call_602496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602496, url, valid)

proc call*(call_602497: Call_DeleteAuthorizer_602484; apiId: string;
          authorizerId: string): Recallable =
  ## deleteAuthorizer
  ## Deletes an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  var path_602498 = newJObject()
  add(path_602498, "apiId", newJString(apiId))
  add(path_602498, "authorizerId", newJString(authorizerId))
  result = call_602497.call(path_602498, nil, nil, nil, nil)

var deleteAuthorizer* = Call_DeleteAuthorizer_602484(name: "deleteAuthorizer",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_DeleteAuthorizer_602485, base: "/",
    url: url_DeleteAuthorizer_602486, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCorsConfiguration_602516 = ref object of OpenApiRestCall_601389
proc url_DeleteCorsConfiguration_602518(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/cors")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteCorsConfiguration_602517(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a CORS configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602519 = path.getOrDefault("apiId")
  valid_602519 = validateParameter(valid_602519, JString, required = true,
                                 default = nil)
  if valid_602519 != nil:
    section.add "apiId", valid_602519
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
  var valid_602520 = header.getOrDefault("X-Amz-Signature")
  valid_602520 = validateParameter(valid_602520, JString, required = false,
                                 default = nil)
  if valid_602520 != nil:
    section.add "X-Amz-Signature", valid_602520
  var valid_602521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602521 = validateParameter(valid_602521, JString, required = false,
                                 default = nil)
  if valid_602521 != nil:
    section.add "X-Amz-Content-Sha256", valid_602521
  var valid_602522 = header.getOrDefault("X-Amz-Date")
  valid_602522 = validateParameter(valid_602522, JString, required = false,
                                 default = nil)
  if valid_602522 != nil:
    section.add "X-Amz-Date", valid_602522
  var valid_602523 = header.getOrDefault("X-Amz-Credential")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "X-Amz-Credential", valid_602523
  var valid_602524 = header.getOrDefault("X-Amz-Security-Token")
  valid_602524 = validateParameter(valid_602524, JString, required = false,
                                 default = nil)
  if valid_602524 != nil:
    section.add "X-Amz-Security-Token", valid_602524
  var valid_602525 = header.getOrDefault("X-Amz-Algorithm")
  valid_602525 = validateParameter(valid_602525, JString, required = false,
                                 default = nil)
  if valid_602525 != nil:
    section.add "X-Amz-Algorithm", valid_602525
  var valid_602526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602526 = validateParameter(valid_602526, JString, required = false,
                                 default = nil)
  if valid_602526 != nil:
    section.add "X-Amz-SignedHeaders", valid_602526
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602527: Call_DeleteCorsConfiguration_602516; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a CORS configuration.
  ## 
  let valid = call_602527.validator(path, query, header, formData, body)
  let scheme = call_602527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602527.url(scheme.get, call_602527.host, call_602527.base,
                         call_602527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602527, url, valid)

proc call*(call_602528: Call_DeleteCorsConfiguration_602516; apiId: string): Recallable =
  ## deleteCorsConfiguration
  ## Deletes a CORS configuration.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_602529 = newJObject()
  add(path_602529, "apiId", newJString(apiId))
  result = call_602528.call(path_602529, nil, nil, nil, nil)

var deleteCorsConfiguration* = Call_DeleteCorsConfiguration_602516(
    name: "deleteCorsConfiguration", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/cors",
    validator: validate_DeleteCorsConfiguration_602517, base: "/",
    url: url_DeleteCorsConfiguration_602518, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_602530 = ref object of OpenApiRestCall_601389
proc url_GetDeployment_602532(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "deploymentId" in path, "`deploymentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/deployments/"),
               (kind: VariableSegment, value: "deploymentId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeployment_602531(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a Deployment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   deploymentId: JString (required)
  ##               : The deployment ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602533 = path.getOrDefault("apiId")
  valid_602533 = validateParameter(valid_602533, JString, required = true,
                                 default = nil)
  if valid_602533 != nil:
    section.add "apiId", valid_602533
  var valid_602534 = path.getOrDefault("deploymentId")
  valid_602534 = validateParameter(valid_602534, JString, required = true,
                                 default = nil)
  if valid_602534 != nil:
    section.add "deploymentId", valid_602534
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
  var valid_602535 = header.getOrDefault("X-Amz-Signature")
  valid_602535 = validateParameter(valid_602535, JString, required = false,
                                 default = nil)
  if valid_602535 != nil:
    section.add "X-Amz-Signature", valid_602535
  var valid_602536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602536 = validateParameter(valid_602536, JString, required = false,
                                 default = nil)
  if valid_602536 != nil:
    section.add "X-Amz-Content-Sha256", valid_602536
  var valid_602537 = header.getOrDefault("X-Amz-Date")
  valid_602537 = validateParameter(valid_602537, JString, required = false,
                                 default = nil)
  if valid_602537 != nil:
    section.add "X-Amz-Date", valid_602537
  var valid_602538 = header.getOrDefault("X-Amz-Credential")
  valid_602538 = validateParameter(valid_602538, JString, required = false,
                                 default = nil)
  if valid_602538 != nil:
    section.add "X-Amz-Credential", valid_602538
  var valid_602539 = header.getOrDefault("X-Amz-Security-Token")
  valid_602539 = validateParameter(valid_602539, JString, required = false,
                                 default = nil)
  if valid_602539 != nil:
    section.add "X-Amz-Security-Token", valid_602539
  var valid_602540 = header.getOrDefault("X-Amz-Algorithm")
  valid_602540 = validateParameter(valid_602540, JString, required = false,
                                 default = nil)
  if valid_602540 != nil:
    section.add "X-Amz-Algorithm", valid_602540
  var valid_602541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602541 = validateParameter(valid_602541, JString, required = false,
                                 default = nil)
  if valid_602541 != nil:
    section.add "X-Amz-SignedHeaders", valid_602541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602542: Call_GetDeployment_602530; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Deployment.
  ## 
  let valid = call_602542.validator(path, query, header, formData, body)
  let scheme = call_602542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602542.url(scheme.get, call_602542.host, call_602542.base,
                         call_602542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602542, url, valid)

proc call*(call_602543: Call_GetDeployment_602530; apiId: string;
          deploymentId: string): Recallable =
  ## getDeployment
  ## Gets a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_602544 = newJObject()
  add(path_602544, "apiId", newJString(apiId))
  add(path_602544, "deploymentId", newJString(deploymentId))
  result = call_602543.call(path_602544, nil, nil, nil, nil)

var getDeployment* = Call_GetDeployment_602530(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_GetDeployment_602531, base: "/", url: url_GetDeployment_602532,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeployment_602560 = ref object of OpenApiRestCall_601389
proc url_UpdateDeployment_602562(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "deploymentId" in path, "`deploymentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/deployments/"),
               (kind: VariableSegment, value: "deploymentId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDeployment_602561(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates a Deployment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   deploymentId: JString (required)
  ##               : The deployment ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602563 = path.getOrDefault("apiId")
  valid_602563 = validateParameter(valid_602563, JString, required = true,
                                 default = nil)
  if valid_602563 != nil:
    section.add "apiId", valid_602563
  var valid_602564 = path.getOrDefault("deploymentId")
  valid_602564 = validateParameter(valid_602564, JString, required = true,
                                 default = nil)
  if valid_602564 != nil:
    section.add "deploymentId", valid_602564
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
  var valid_602565 = header.getOrDefault("X-Amz-Signature")
  valid_602565 = validateParameter(valid_602565, JString, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "X-Amz-Signature", valid_602565
  var valid_602566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602566 = validateParameter(valid_602566, JString, required = false,
                                 default = nil)
  if valid_602566 != nil:
    section.add "X-Amz-Content-Sha256", valid_602566
  var valid_602567 = header.getOrDefault("X-Amz-Date")
  valid_602567 = validateParameter(valid_602567, JString, required = false,
                                 default = nil)
  if valid_602567 != nil:
    section.add "X-Amz-Date", valid_602567
  var valid_602568 = header.getOrDefault("X-Amz-Credential")
  valid_602568 = validateParameter(valid_602568, JString, required = false,
                                 default = nil)
  if valid_602568 != nil:
    section.add "X-Amz-Credential", valid_602568
  var valid_602569 = header.getOrDefault("X-Amz-Security-Token")
  valid_602569 = validateParameter(valid_602569, JString, required = false,
                                 default = nil)
  if valid_602569 != nil:
    section.add "X-Amz-Security-Token", valid_602569
  var valid_602570 = header.getOrDefault("X-Amz-Algorithm")
  valid_602570 = validateParameter(valid_602570, JString, required = false,
                                 default = nil)
  if valid_602570 != nil:
    section.add "X-Amz-Algorithm", valid_602570
  var valid_602571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602571 = validateParameter(valid_602571, JString, required = false,
                                 default = nil)
  if valid_602571 != nil:
    section.add "X-Amz-SignedHeaders", valid_602571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602573: Call_UpdateDeployment_602560; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Deployment.
  ## 
  let valid = call_602573.validator(path, query, header, formData, body)
  let scheme = call_602573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602573.url(scheme.get, call_602573.host, call_602573.base,
                         call_602573.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602573, url, valid)

proc call*(call_602574: Call_UpdateDeployment_602560; apiId: string; body: JsonNode;
          deploymentId: string): Recallable =
  ## updateDeployment
  ## Updates a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_602575 = newJObject()
  var body_602576 = newJObject()
  add(path_602575, "apiId", newJString(apiId))
  if body != nil:
    body_602576 = body
  add(path_602575, "deploymentId", newJString(deploymentId))
  result = call_602574.call(path_602575, nil, nil, nil, body_602576)

var updateDeployment* = Call_UpdateDeployment_602560(name: "updateDeployment",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_UpdateDeployment_602561, base: "/",
    url: url_UpdateDeployment_602562, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeployment_602545 = ref object of OpenApiRestCall_601389
proc url_DeleteDeployment_602547(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "deploymentId" in path, "`deploymentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/deployments/"),
               (kind: VariableSegment, value: "deploymentId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDeployment_602546(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes a Deployment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   deploymentId: JString (required)
  ##               : The deployment ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602548 = path.getOrDefault("apiId")
  valid_602548 = validateParameter(valid_602548, JString, required = true,
                                 default = nil)
  if valid_602548 != nil:
    section.add "apiId", valid_602548
  var valid_602549 = path.getOrDefault("deploymentId")
  valid_602549 = validateParameter(valid_602549, JString, required = true,
                                 default = nil)
  if valid_602549 != nil:
    section.add "deploymentId", valid_602549
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
  var valid_602550 = header.getOrDefault("X-Amz-Signature")
  valid_602550 = validateParameter(valid_602550, JString, required = false,
                                 default = nil)
  if valid_602550 != nil:
    section.add "X-Amz-Signature", valid_602550
  var valid_602551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602551 = validateParameter(valid_602551, JString, required = false,
                                 default = nil)
  if valid_602551 != nil:
    section.add "X-Amz-Content-Sha256", valid_602551
  var valid_602552 = header.getOrDefault("X-Amz-Date")
  valid_602552 = validateParameter(valid_602552, JString, required = false,
                                 default = nil)
  if valid_602552 != nil:
    section.add "X-Amz-Date", valid_602552
  var valid_602553 = header.getOrDefault("X-Amz-Credential")
  valid_602553 = validateParameter(valid_602553, JString, required = false,
                                 default = nil)
  if valid_602553 != nil:
    section.add "X-Amz-Credential", valid_602553
  var valid_602554 = header.getOrDefault("X-Amz-Security-Token")
  valid_602554 = validateParameter(valid_602554, JString, required = false,
                                 default = nil)
  if valid_602554 != nil:
    section.add "X-Amz-Security-Token", valid_602554
  var valid_602555 = header.getOrDefault("X-Amz-Algorithm")
  valid_602555 = validateParameter(valid_602555, JString, required = false,
                                 default = nil)
  if valid_602555 != nil:
    section.add "X-Amz-Algorithm", valid_602555
  var valid_602556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602556 = validateParameter(valid_602556, JString, required = false,
                                 default = nil)
  if valid_602556 != nil:
    section.add "X-Amz-SignedHeaders", valid_602556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602557: Call_DeleteDeployment_602545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Deployment.
  ## 
  let valid = call_602557.validator(path, query, header, formData, body)
  let scheme = call_602557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602557.url(scheme.get, call_602557.host, call_602557.base,
                         call_602557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602557, url, valid)

proc call*(call_602558: Call_DeleteDeployment_602545; apiId: string;
          deploymentId: string): Recallable =
  ## deleteDeployment
  ## Deletes a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_602559 = newJObject()
  add(path_602559, "apiId", newJString(apiId))
  add(path_602559, "deploymentId", newJString(deploymentId))
  result = call_602558.call(path_602559, nil, nil, nil, nil)

var deleteDeployment* = Call_DeleteDeployment_602545(name: "deleteDeployment",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_DeleteDeployment_602546, base: "/",
    url: url_DeleteDeployment_602547, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainName_602577 = ref object of OpenApiRestCall_601389
proc url_GetDomainName_602579(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDomainName_602578(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a domain name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
  ##             : The domain name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domainName` field"
  var valid_602580 = path.getOrDefault("domainName")
  valid_602580 = validateParameter(valid_602580, JString, required = true,
                                 default = nil)
  if valid_602580 != nil:
    section.add "domainName", valid_602580
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
  var valid_602581 = header.getOrDefault("X-Amz-Signature")
  valid_602581 = validateParameter(valid_602581, JString, required = false,
                                 default = nil)
  if valid_602581 != nil:
    section.add "X-Amz-Signature", valid_602581
  var valid_602582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602582 = validateParameter(valid_602582, JString, required = false,
                                 default = nil)
  if valid_602582 != nil:
    section.add "X-Amz-Content-Sha256", valid_602582
  var valid_602583 = header.getOrDefault("X-Amz-Date")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = nil)
  if valid_602583 != nil:
    section.add "X-Amz-Date", valid_602583
  var valid_602584 = header.getOrDefault("X-Amz-Credential")
  valid_602584 = validateParameter(valid_602584, JString, required = false,
                                 default = nil)
  if valid_602584 != nil:
    section.add "X-Amz-Credential", valid_602584
  var valid_602585 = header.getOrDefault("X-Amz-Security-Token")
  valid_602585 = validateParameter(valid_602585, JString, required = false,
                                 default = nil)
  if valid_602585 != nil:
    section.add "X-Amz-Security-Token", valid_602585
  var valid_602586 = header.getOrDefault("X-Amz-Algorithm")
  valid_602586 = validateParameter(valid_602586, JString, required = false,
                                 default = nil)
  if valid_602586 != nil:
    section.add "X-Amz-Algorithm", valid_602586
  var valid_602587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602587 = validateParameter(valid_602587, JString, required = false,
                                 default = nil)
  if valid_602587 != nil:
    section.add "X-Amz-SignedHeaders", valid_602587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602588: Call_GetDomainName_602577; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a domain name.
  ## 
  let valid = call_602588.validator(path, query, header, formData, body)
  let scheme = call_602588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602588.url(scheme.get, call_602588.host, call_602588.base,
                         call_602588.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602588, url, valid)

proc call*(call_602589: Call_GetDomainName_602577; domainName: string): Recallable =
  ## getDomainName
  ## Gets a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_602590 = newJObject()
  add(path_602590, "domainName", newJString(domainName))
  result = call_602589.call(path_602590, nil, nil, nil, nil)

var getDomainName* = Call_GetDomainName_602577(name: "getDomainName",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_GetDomainName_602578,
    base: "/", url: url_GetDomainName_602579, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainName_602605 = ref object of OpenApiRestCall_601389
proc url_UpdateDomainName_602607(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDomainName_602606(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates a domain name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
  ##             : The domain name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domainName` field"
  var valid_602608 = path.getOrDefault("domainName")
  valid_602608 = validateParameter(valid_602608, JString, required = true,
                                 default = nil)
  if valid_602608 != nil:
    section.add "domainName", valid_602608
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
  var valid_602609 = header.getOrDefault("X-Amz-Signature")
  valid_602609 = validateParameter(valid_602609, JString, required = false,
                                 default = nil)
  if valid_602609 != nil:
    section.add "X-Amz-Signature", valid_602609
  var valid_602610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602610 = validateParameter(valid_602610, JString, required = false,
                                 default = nil)
  if valid_602610 != nil:
    section.add "X-Amz-Content-Sha256", valid_602610
  var valid_602611 = header.getOrDefault("X-Amz-Date")
  valid_602611 = validateParameter(valid_602611, JString, required = false,
                                 default = nil)
  if valid_602611 != nil:
    section.add "X-Amz-Date", valid_602611
  var valid_602612 = header.getOrDefault("X-Amz-Credential")
  valid_602612 = validateParameter(valid_602612, JString, required = false,
                                 default = nil)
  if valid_602612 != nil:
    section.add "X-Amz-Credential", valid_602612
  var valid_602613 = header.getOrDefault("X-Amz-Security-Token")
  valid_602613 = validateParameter(valid_602613, JString, required = false,
                                 default = nil)
  if valid_602613 != nil:
    section.add "X-Amz-Security-Token", valid_602613
  var valid_602614 = header.getOrDefault("X-Amz-Algorithm")
  valid_602614 = validateParameter(valid_602614, JString, required = false,
                                 default = nil)
  if valid_602614 != nil:
    section.add "X-Amz-Algorithm", valid_602614
  var valid_602615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602615 = validateParameter(valid_602615, JString, required = false,
                                 default = nil)
  if valid_602615 != nil:
    section.add "X-Amz-SignedHeaders", valid_602615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602617: Call_UpdateDomainName_602605; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a domain name.
  ## 
  let valid = call_602617.validator(path, query, header, formData, body)
  let scheme = call_602617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602617.url(scheme.get, call_602617.host, call_602617.base,
                         call_602617.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602617, url, valid)

proc call*(call_602618: Call_UpdateDomainName_602605; body: JsonNode;
          domainName: string): Recallable =
  ## updateDomainName
  ## Updates a domain name.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : The domain name.
  var path_602619 = newJObject()
  var body_602620 = newJObject()
  if body != nil:
    body_602620 = body
  add(path_602619, "domainName", newJString(domainName))
  result = call_602618.call(path_602619, nil, nil, nil, body_602620)

var updateDomainName* = Call_UpdateDomainName_602605(name: "updateDomainName",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_UpdateDomainName_602606,
    base: "/", url: url_UpdateDomainName_602607,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainName_602591 = ref object of OpenApiRestCall_601389
proc url_DeleteDomainName_602593(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDomainName_602592(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes a domain name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
  ##             : The domain name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domainName` field"
  var valid_602594 = path.getOrDefault("domainName")
  valid_602594 = validateParameter(valid_602594, JString, required = true,
                                 default = nil)
  if valid_602594 != nil:
    section.add "domainName", valid_602594
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
  var valid_602595 = header.getOrDefault("X-Amz-Signature")
  valid_602595 = validateParameter(valid_602595, JString, required = false,
                                 default = nil)
  if valid_602595 != nil:
    section.add "X-Amz-Signature", valid_602595
  var valid_602596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602596 = validateParameter(valid_602596, JString, required = false,
                                 default = nil)
  if valid_602596 != nil:
    section.add "X-Amz-Content-Sha256", valid_602596
  var valid_602597 = header.getOrDefault("X-Amz-Date")
  valid_602597 = validateParameter(valid_602597, JString, required = false,
                                 default = nil)
  if valid_602597 != nil:
    section.add "X-Amz-Date", valid_602597
  var valid_602598 = header.getOrDefault("X-Amz-Credential")
  valid_602598 = validateParameter(valid_602598, JString, required = false,
                                 default = nil)
  if valid_602598 != nil:
    section.add "X-Amz-Credential", valid_602598
  var valid_602599 = header.getOrDefault("X-Amz-Security-Token")
  valid_602599 = validateParameter(valid_602599, JString, required = false,
                                 default = nil)
  if valid_602599 != nil:
    section.add "X-Amz-Security-Token", valid_602599
  var valid_602600 = header.getOrDefault("X-Amz-Algorithm")
  valid_602600 = validateParameter(valid_602600, JString, required = false,
                                 default = nil)
  if valid_602600 != nil:
    section.add "X-Amz-Algorithm", valid_602600
  var valid_602601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602601 = validateParameter(valid_602601, JString, required = false,
                                 default = nil)
  if valid_602601 != nil:
    section.add "X-Amz-SignedHeaders", valid_602601
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602602: Call_DeleteDomainName_602591; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a domain name.
  ## 
  let valid = call_602602.validator(path, query, header, formData, body)
  let scheme = call_602602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602602.url(scheme.get, call_602602.host, call_602602.base,
                         call_602602.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602602, url, valid)

proc call*(call_602603: Call_DeleteDomainName_602591; domainName: string): Recallable =
  ## deleteDomainName
  ## Deletes a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_602604 = newJObject()
  add(path_602604, "domainName", newJString(domainName))
  result = call_602603.call(path_602604, nil, nil, nil, nil)

var deleteDomainName* = Call_DeleteDomainName_602591(name: "deleteDomainName",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_DeleteDomainName_602592,
    base: "/", url: url_DeleteDomainName_602593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegration_602621 = ref object of OpenApiRestCall_601389
proc url_GetIntegration_602623(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntegration_602622(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets an Integration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602624 = path.getOrDefault("apiId")
  valid_602624 = validateParameter(valid_602624, JString, required = true,
                                 default = nil)
  if valid_602624 != nil:
    section.add "apiId", valid_602624
  var valid_602625 = path.getOrDefault("integrationId")
  valid_602625 = validateParameter(valid_602625, JString, required = true,
                                 default = nil)
  if valid_602625 != nil:
    section.add "integrationId", valid_602625
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
  var valid_602626 = header.getOrDefault("X-Amz-Signature")
  valid_602626 = validateParameter(valid_602626, JString, required = false,
                                 default = nil)
  if valid_602626 != nil:
    section.add "X-Amz-Signature", valid_602626
  var valid_602627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602627 = validateParameter(valid_602627, JString, required = false,
                                 default = nil)
  if valid_602627 != nil:
    section.add "X-Amz-Content-Sha256", valid_602627
  var valid_602628 = header.getOrDefault("X-Amz-Date")
  valid_602628 = validateParameter(valid_602628, JString, required = false,
                                 default = nil)
  if valid_602628 != nil:
    section.add "X-Amz-Date", valid_602628
  var valid_602629 = header.getOrDefault("X-Amz-Credential")
  valid_602629 = validateParameter(valid_602629, JString, required = false,
                                 default = nil)
  if valid_602629 != nil:
    section.add "X-Amz-Credential", valid_602629
  var valid_602630 = header.getOrDefault("X-Amz-Security-Token")
  valid_602630 = validateParameter(valid_602630, JString, required = false,
                                 default = nil)
  if valid_602630 != nil:
    section.add "X-Amz-Security-Token", valid_602630
  var valid_602631 = header.getOrDefault("X-Amz-Algorithm")
  valid_602631 = validateParameter(valid_602631, JString, required = false,
                                 default = nil)
  if valid_602631 != nil:
    section.add "X-Amz-Algorithm", valid_602631
  var valid_602632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602632 = validateParameter(valid_602632, JString, required = false,
                                 default = nil)
  if valid_602632 != nil:
    section.add "X-Amz-SignedHeaders", valid_602632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602633: Call_GetIntegration_602621; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Integration.
  ## 
  let valid = call_602633.validator(path, query, header, formData, body)
  let scheme = call_602633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602633.url(scheme.get, call_602633.host, call_602633.base,
                         call_602633.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602633, url, valid)

proc call*(call_602634: Call_GetIntegration_602621; apiId: string;
          integrationId: string): Recallable =
  ## getIntegration
  ## Gets an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_602635 = newJObject()
  add(path_602635, "apiId", newJString(apiId))
  add(path_602635, "integrationId", newJString(integrationId))
  result = call_602634.call(path_602635, nil, nil, nil, nil)

var getIntegration* = Call_GetIntegration_602621(name: "getIntegration",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_GetIntegration_602622, base: "/", url: url_GetIntegration_602623,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegration_602651 = ref object of OpenApiRestCall_601389
proc url_UpdateIntegration_602653(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateIntegration_602652(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates an Integration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602654 = path.getOrDefault("apiId")
  valid_602654 = validateParameter(valid_602654, JString, required = true,
                                 default = nil)
  if valid_602654 != nil:
    section.add "apiId", valid_602654
  var valid_602655 = path.getOrDefault("integrationId")
  valid_602655 = validateParameter(valid_602655, JString, required = true,
                                 default = nil)
  if valid_602655 != nil:
    section.add "integrationId", valid_602655
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
  var valid_602656 = header.getOrDefault("X-Amz-Signature")
  valid_602656 = validateParameter(valid_602656, JString, required = false,
                                 default = nil)
  if valid_602656 != nil:
    section.add "X-Amz-Signature", valid_602656
  var valid_602657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602657 = validateParameter(valid_602657, JString, required = false,
                                 default = nil)
  if valid_602657 != nil:
    section.add "X-Amz-Content-Sha256", valid_602657
  var valid_602658 = header.getOrDefault("X-Amz-Date")
  valid_602658 = validateParameter(valid_602658, JString, required = false,
                                 default = nil)
  if valid_602658 != nil:
    section.add "X-Amz-Date", valid_602658
  var valid_602659 = header.getOrDefault("X-Amz-Credential")
  valid_602659 = validateParameter(valid_602659, JString, required = false,
                                 default = nil)
  if valid_602659 != nil:
    section.add "X-Amz-Credential", valid_602659
  var valid_602660 = header.getOrDefault("X-Amz-Security-Token")
  valid_602660 = validateParameter(valid_602660, JString, required = false,
                                 default = nil)
  if valid_602660 != nil:
    section.add "X-Amz-Security-Token", valid_602660
  var valid_602661 = header.getOrDefault("X-Amz-Algorithm")
  valid_602661 = validateParameter(valid_602661, JString, required = false,
                                 default = nil)
  if valid_602661 != nil:
    section.add "X-Amz-Algorithm", valid_602661
  var valid_602662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602662 = validateParameter(valid_602662, JString, required = false,
                                 default = nil)
  if valid_602662 != nil:
    section.add "X-Amz-SignedHeaders", valid_602662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602664: Call_UpdateIntegration_602651; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Integration.
  ## 
  let valid = call_602664.validator(path, query, header, formData, body)
  let scheme = call_602664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602664.url(scheme.get, call_602664.host, call_602664.base,
                         call_602664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602664, url, valid)

proc call*(call_602665: Call_UpdateIntegration_602651; apiId: string;
          integrationId: string; body: JsonNode): Recallable =
  ## updateIntegration
  ## Updates an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  ##   body: JObject (required)
  var path_602666 = newJObject()
  var body_602667 = newJObject()
  add(path_602666, "apiId", newJString(apiId))
  add(path_602666, "integrationId", newJString(integrationId))
  if body != nil:
    body_602667 = body
  result = call_602665.call(path_602666, nil, nil, nil, body_602667)

var updateIntegration* = Call_UpdateIntegration_602651(name: "updateIntegration",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_UpdateIntegration_602652, base: "/",
    url: url_UpdateIntegration_602653, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegration_602636 = ref object of OpenApiRestCall_601389
proc url_DeleteIntegration_602638(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteIntegration_602637(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes an Integration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602639 = path.getOrDefault("apiId")
  valid_602639 = validateParameter(valid_602639, JString, required = true,
                                 default = nil)
  if valid_602639 != nil:
    section.add "apiId", valid_602639
  var valid_602640 = path.getOrDefault("integrationId")
  valid_602640 = validateParameter(valid_602640, JString, required = true,
                                 default = nil)
  if valid_602640 != nil:
    section.add "integrationId", valid_602640
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
  var valid_602641 = header.getOrDefault("X-Amz-Signature")
  valid_602641 = validateParameter(valid_602641, JString, required = false,
                                 default = nil)
  if valid_602641 != nil:
    section.add "X-Amz-Signature", valid_602641
  var valid_602642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602642 = validateParameter(valid_602642, JString, required = false,
                                 default = nil)
  if valid_602642 != nil:
    section.add "X-Amz-Content-Sha256", valid_602642
  var valid_602643 = header.getOrDefault("X-Amz-Date")
  valid_602643 = validateParameter(valid_602643, JString, required = false,
                                 default = nil)
  if valid_602643 != nil:
    section.add "X-Amz-Date", valid_602643
  var valid_602644 = header.getOrDefault("X-Amz-Credential")
  valid_602644 = validateParameter(valid_602644, JString, required = false,
                                 default = nil)
  if valid_602644 != nil:
    section.add "X-Amz-Credential", valid_602644
  var valid_602645 = header.getOrDefault("X-Amz-Security-Token")
  valid_602645 = validateParameter(valid_602645, JString, required = false,
                                 default = nil)
  if valid_602645 != nil:
    section.add "X-Amz-Security-Token", valid_602645
  var valid_602646 = header.getOrDefault("X-Amz-Algorithm")
  valid_602646 = validateParameter(valid_602646, JString, required = false,
                                 default = nil)
  if valid_602646 != nil:
    section.add "X-Amz-Algorithm", valid_602646
  var valid_602647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602647 = validateParameter(valid_602647, JString, required = false,
                                 default = nil)
  if valid_602647 != nil:
    section.add "X-Amz-SignedHeaders", valid_602647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602648: Call_DeleteIntegration_602636; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Integration.
  ## 
  let valid = call_602648.validator(path, query, header, formData, body)
  let scheme = call_602648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602648.url(scheme.get, call_602648.host, call_602648.base,
                         call_602648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602648, url, valid)

proc call*(call_602649: Call_DeleteIntegration_602636; apiId: string;
          integrationId: string): Recallable =
  ## deleteIntegration
  ## Deletes an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_602650 = newJObject()
  add(path_602650, "apiId", newJString(apiId))
  add(path_602650, "integrationId", newJString(integrationId))
  result = call_602649.call(path_602650, nil, nil, nil, nil)

var deleteIntegration* = Call_DeleteIntegration_602636(name: "deleteIntegration",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_DeleteIntegration_602637, base: "/",
    url: url_DeleteIntegration_602638, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponse_602668 = ref object of OpenApiRestCall_601389
proc url_GetIntegrationResponse_602670(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  assert "integrationResponseId" in path,
        "`integrationResponseId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId"),
               (kind: ConstantSegment, value: "/integrationresponses/"),
               (kind: VariableSegment, value: "integrationResponseId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntegrationResponse_602669(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets an IntegrationResponses.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   integrationResponseId: JString (required)
  ##                        : The integration response ID.
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `integrationResponseId` field"
  var valid_602671 = path.getOrDefault("integrationResponseId")
  valid_602671 = validateParameter(valid_602671, JString, required = true,
                                 default = nil)
  if valid_602671 != nil:
    section.add "integrationResponseId", valid_602671
  var valid_602672 = path.getOrDefault("apiId")
  valid_602672 = validateParameter(valid_602672, JString, required = true,
                                 default = nil)
  if valid_602672 != nil:
    section.add "apiId", valid_602672
  var valid_602673 = path.getOrDefault("integrationId")
  valid_602673 = validateParameter(valid_602673, JString, required = true,
                                 default = nil)
  if valid_602673 != nil:
    section.add "integrationId", valid_602673
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
  var valid_602674 = header.getOrDefault("X-Amz-Signature")
  valid_602674 = validateParameter(valid_602674, JString, required = false,
                                 default = nil)
  if valid_602674 != nil:
    section.add "X-Amz-Signature", valid_602674
  var valid_602675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602675 = validateParameter(valid_602675, JString, required = false,
                                 default = nil)
  if valid_602675 != nil:
    section.add "X-Amz-Content-Sha256", valid_602675
  var valid_602676 = header.getOrDefault("X-Amz-Date")
  valid_602676 = validateParameter(valid_602676, JString, required = false,
                                 default = nil)
  if valid_602676 != nil:
    section.add "X-Amz-Date", valid_602676
  var valid_602677 = header.getOrDefault("X-Amz-Credential")
  valid_602677 = validateParameter(valid_602677, JString, required = false,
                                 default = nil)
  if valid_602677 != nil:
    section.add "X-Amz-Credential", valid_602677
  var valid_602678 = header.getOrDefault("X-Amz-Security-Token")
  valid_602678 = validateParameter(valid_602678, JString, required = false,
                                 default = nil)
  if valid_602678 != nil:
    section.add "X-Amz-Security-Token", valid_602678
  var valid_602679 = header.getOrDefault("X-Amz-Algorithm")
  valid_602679 = validateParameter(valid_602679, JString, required = false,
                                 default = nil)
  if valid_602679 != nil:
    section.add "X-Amz-Algorithm", valid_602679
  var valid_602680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602680 = validateParameter(valid_602680, JString, required = false,
                                 default = nil)
  if valid_602680 != nil:
    section.add "X-Amz-SignedHeaders", valid_602680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602681: Call_GetIntegrationResponse_602668; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an IntegrationResponses.
  ## 
  let valid = call_602681.validator(path, query, header, formData, body)
  let scheme = call_602681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602681.url(scheme.get, call_602681.host, call_602681.base,
                         call_602681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602681, url, valid)

proc call*(call_602682: Call_GetIntegrationResponse_602668;
          integrationResponseId: string; apiId: string; integrationId: string): Recallable =
  ## getIntegrationResponse
  ## Gets an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_602683 = newJObject()
  add(path_602683, "integrationResponseId", newJString(integrationResponseId))
  add(path_602683, "apiId", newJString(apiId))
  add(path_602683, "integrationId", newJString(integrationId))
  result = call_602682.call(path_602683, nil, nil, nil, nil)

var getIntegrationResponse* = Call_GetIntegrationResponse_602668(
    name: "getIntegrationResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_GetIntegrationResponse_602669, base: "/",
    url: url_GetIntegrationResponse_602670, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegrationResponse_602700 = ref object of OpenApiRestCall_601389
proc url_UpdateIntegrationResponse_602702(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  assert "integrationResponseId" in path,
        "`integrationResponseId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId"),
               (kind: ConstantSegment, value: "/integrationresponses/"),
               (kind: VariableSegment, value: "integrationResponseId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateIntegrationResponse_602701(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an IntegrationResponses.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   integrationResponseId: JString (required)
  ##                        : The integration response ID.
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `integrationResponseId` field"
  var valid_602703 = path.getOrDefault("integrationResponseId")
  valid_602703 = validateParameter(valid_602703, JString, required = true,
                                 default = nil)
  if valid_602703 != nil:
    section.add "integrationResponseId", valid_602703
  var valid_602704 = path.getOrDefault("apiId")
  valid_602704 = validateParameter(valid_602704, JString, required = true,
                                 default = nil)
  if valid_602704 != nil:
    section.add "apiId", valid_602704
  var valid_602705 = path.getOrDefault("integrationId")
  valid_602705 = validateParameter(valid_602705, JString, required = true,
                                 default = nil)
  if valid_602705 != nil:
    section.add "integrationId", valid_602705
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
  var valid_602706 = header.getOrDefault("X-Amz-Signature")
  valid_602706 = validateParameter(valid_602706, JString, required = false,
                                 default = nil)
  if valid_602706 != nil:
    section.add "X-Amz-Signature", valid_602706
  var valid_602707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602707 = validateParameter(valid_602707, JString, required = false,
                                 default = nil)
  if valid_602707 != nil:
    section.add "X-Amz-Content-Sha256", valid_602707
  var valid_602708 = header.getOrDefault("X-Amz-Date")
  valid_602708 = validateParameter(valid_602708, JString, required = false,
                                 default = nil)
  if valid_602708 != nil:
    section.add "X-Amz-Date", valid_602708
  var valid_602709 = header.getOrDefault("X-Amz-Credential")
  valid_602709 = validateParameter(valid_602709, JString, required = false,
                                 default = nil)
  if valid_602709 != nil:
    section.add "X-Amz-Credential", valid_602709
  var valid_602710 = header.getOrDefault("X-Amz-Security-Token")
  valid_602710 = validateParameter(valid_602710, JString, required = false,
                                 default = nil)
  if valid_602710 != nil:
    section.add "X-Amz-Security-Token", valid_602710
  var valid_602711 = header.getOrDefault("X-Amz-Algorithm")
  valid_602711 = validateParameter(valid_602711, JString, required = false,
                                 default = nil)
  if valid_602711 != nil:
    section.add "X-Amz-Algorithm", valid_602711
  var valid_602712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602712 = validateParameter(valid_602712, JString, required = false,
                                 default = nil)
  if valid_602712 != nil:
    section.add "X-Amz-SignedHeaders", valid_602712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602714: Call_UpdateIntegrationResponse_602700; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an IntegrationResponses.
  ## 
  let valid = call_602714.validator(path, query, header, formData, body)
  let scheme = call_602714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602714.url(scheme.get, call_602714.host, call_602714.base,
                         call_602714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602714, url, valid)

proc call*(call_602715: Call_UpdateIntegrationResponse_602700;
          integrationResponseId: string; apiId: string; integrationId: string;
          body: JsonNode): Recallable =
  ## updateIntegrationResponse
  ## Updates an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  ##   body: JObject (required)
  var path_602716 = newJObject()
  var body_602717 = newJObject()
  add(path_602716, "integrationResponseId", newJString(integrationResponseId))
  add(path_602716, "apiId", newJString(apiId))
  add(path_602716, "integrationId", newJString(integrationId))
  if body != nil:
    body_602717 = body
  result = call_602715.call(path_602716, nil, nil, nil, body_602717)

var updateIntegrationResponse* = Call_UpdateIntegrationResponse_602700(
    name: "updateIntegrationResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_UpdateIntegrationResponse_602701, base: "/",
    url: url_UpdateIntegrationResponse_602702,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegrationResponse_602684 = ref object of OpenApiRestCall_601389
proc url_DeleteIntegrationResponse_602686(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  assert "integrationResponseId" in path,
        "`integrationResponseId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId"),
               (kind: ConstantSegment, value: "/integrationresponses/"),
               (kind: VariableSegment, value: "integrationResponseId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteIntegrationResponse_602685(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an IntegrationResponses.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   integrationResponseId: JString (required)
  ##                        : The integration response ID.
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `integrationResponseId` field"
  var valid_602687 = path.getOrDefault("integrationResponseId")
  valid_602687 = validateParameter(valid_602687, JString, required = true,
                                 default = nil)
  if valid_602687 != nil:
    section.add "integrationResponseId", valid_602687
  var valid_602688 = path.getOrDefault("apiId")
  valid_602688 = validateParameter(valid_602688, JString, required = true,
                                 default = nil)
  if valid_602688 != nil:
    section.add "apiId", valid_602688
  var valid_602689 = path.getOrDefault("integrationId")
  valid_602689 = validateParameter(valid_602689, JString, required = true,
                                 default = nil)
  if valid_602689 != nil:
    section.add "integrationId", valid_602689
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
  var valid_602690 = header.getOrDefault("X-Amz-Signature")
  valid_602690 = validateParameter(valid_602690, JString, required = false,
                                 default = nil)
  if valid_602690 != nil:
    section.add "X-Amz-Signature", valid_602690
  var valid_602691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602691 = validateParameter(valid_602691, JString, required = false,
                                 default = nil)
  if valid_602691 != nil:
    section.add "X-Amz-Content-Sha256", valid_602691
  var valid_602692 = header.getOrDefault("X-Amz-Date")
  valid_602692 = validateParameter(valid_602692, JString, required = false,
                                 default = nil)
  if valid_602692 != nil:
    section.add "X-Amz-Date", valid_602692
  var valid_602693 = header.getOrDefault("X-Amz-Credential")
  valid_602693 = validateParameter(valid_602693, JString, required = false,
                                 default = nil)
  if valid_602693 != nil:
    section.add "X-Amz-Credential", valid_602693
  var valid_602694 = header.getOrDefault("X-Amz-Security-Token")
  valid_602694 = validateParameter(valid_602694, JString, required = false,
                                 default = nil)
  if valid_602694 != nil:
    section.add "X-Amz-Security-Token", valid_602694
  var valid_602695 = header.getOrDefault("X-Amz-Algorithm")
  valid_602695 = validateParameter(valid_602695, JString, required = false,
                                 default = nil)
  if valid_602695 != nil:
    section.add "X-Amz-Algorithm", valid_602695
  var valid_602696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602696 = validateParameter(valid_602696, JString, required = false,
                                 default = nil)
  if valid_602696 != nil:
    section.add "X-Amz-SignedHeaders", valid_602696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602697: Call_DeleteIntegrationResponse_602684; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an IntegrationResponses.
  ## 
  let valid = call_602697.validator(path, query, header, formData, body)
  let scheme = call_602697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602697.url(scheme.get, call_602697.host, call_602697.base,
                         call_602697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602697, url, valid)

proc call*(call_602698: Call_DeleteIntegrationResponse_602684;
          integrationResponseId: string; apiId: string; integrationId: string): Recallable =
  ## deleteIntegrationResponse
  ## Deletes an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_602699 = newJObject()
  add(path_602699, "integrationResponseId", newJString(integrationResponseId))
  add(path_602699, "apiId", newJString(apiId))
  add(path_602699, "integrationId", newJString(integrationId))
  result = call_602698.call(path_602699, nil, nil, nil, nil)

var deleteIntegrationResponse* = Call_DeleteIntegrationResponse_602684(
    name: "deleteIntegrationResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_DeleteIntegrationResponse_602685, base: "/",
    url: url_DeleteIntegrationResponse_602686,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModel_602718 = ref object of OpenApiRestCall_601389
proc url_GetModel_602720(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "modelId" in path, "`modelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/models/"),
               (kind: VariableSegment, value: "modelId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetModel_602719(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a Model.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   modelId: JString (required)
  ##          : The model ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602721 = path.getOrDefault("apiId")
  valid_602721 = validateParameter(valid_602721, JString, required = true,
                                 default = nil)
  if valid_602721 != nil:
    section.add "apiId", valid_602721
  var valid_602722 = path.getOrDefault("modelId")
  valid_602722 = validateParameter(valid_602722, JString, required = true,
                                 default = nil)
  if valid_602722 != nil:
    section.add "modelId", valid_602722
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
  var valid_602723 = header.getOrDefault("X-Amz-Signature")
  valid_602723 = validateParameter(valid_602723, JString, required = false,
                                 default = nil)
  if valid_602723 != nil:
    section.add "X-Amz-Signature", valid_602723
  var valid_602724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602724 = validateParameter(valid_602724, JString, required = false,
                                 default = nil)
  if valid_602724 != nil:
    section.add "X-Amz-Content-Sha256", valid_602724
  var valid_602725 = header.getOrDefault("X-Amz-Date")
  valid_602725 = validateParameter(valid_602725, JString, required = false,
                                 default = nil)
  if valid_602725 != nil:
    section.add "X-Amz-Date", valid_602725
  var valid_602726 = header.getOrDefault("X-Amz-Credential")
  valid_602726 = validateParameter(valid_602726, JString, required = false,
                                 default = nil)
  if valid_602726 != nil:
    section.add "X-Amz-Credential", valid_602726
  var valid_602727 = header.getOrDefault("X-Amz-Security-Token")
  valid_602727 = validateParameter(valid_602727, JString, required = false,
                                 default = nil)
  if valid_602727 != nil:
    section.add "X-Amz-Security-Token", valid_602727
  var valid_602728 = header.getOrDefault("X-Amz-Algorithm")
  valid_602728 = validateParameter(valid_602728, JString, required = false,
                                 default = nil)
  if valid_602728 != nil:
    section.add "X-Amz-Algorithm", valid_602728
  var valid_602729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602729 = validateParameter(valid_602729, JString, required = false,
                                 default = nil)
  if valid_602729 != nil:
    section.add "X-Amz-SignedHeaders", valid_602729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602730: Call_GetModel_602718; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Model.
  ## 
  let valid = call_602730.validator(path, query, header, formData, body)
  let scheme = call_602730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602730.url(scheme.get, call_602730.host, call_602730.base,
                         call_602730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602730, url, valid)

proc call*(call_602731: Call_GetModel_602718; apiId: string; modelId: string): Recallable =
  ## getModel
  ## Gets a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_602732 = newJObject()
  add(path_602732, "apiId", newJString(apiId))
  add(path_602732, "modelId", newJString(modelId))
  result = call_602731.call(path_602732, nil, nil, nil, nil)

var getModel* = Call_GetModel_602718(name: "getModel", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/models/{modelId}",
                                  validator: validate_GetModel_602719, base: "/",
                                  url: url_GetModel_602720,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModel_602748 = ref object of OpenApiRestCall_601389
proc url_UpdateModel_602750(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "modelId" in path, "`modelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/models/"),
               (kind: VariableSegment, value: "modelId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateModel_602749(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a Model.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   modelId: JString (required)
  ##          : The model ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602751 = path.getOrDefault("apiId")
  valid_602751 = validateParameter(valid_602751, JString, required = true,
                                 default = nil)
  if valid_602751 != nil:
    section.add "apiId", valid_602751
  var valid_602752 = path.getOrDefault("modelId")
  valid_602752 = validateParameter(valid_602752, JString, required = true,
                                 default = nil)
  if valid_602752 != nil:
    section.add "modelId", valid_602752
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
  var valid_602753 = header.getOrDefault("X-Amz-Signature")
  valid_602753 = validateParameter(valid_602753, JString, required = false,
                                 default = nil)
  if valid_602753 != nil:
    section.add "X-Amz-Signature", valid_602753
  var valid_602754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602754 = validateParameter(valid_602754, JString, required = false,
                                 default = nil)
  if valid_602754 != nil:
    section.add "X-Amz-Content-Sha256", valid_602754
  var valid_602755 = header.getOrDefault("X-Amz-Date")
  valid_602755 = validateParameter(valid_602755, JString, required = false,
                                 default = nil)
  if valid_602755 != nil:
    section.add "X-Amz-Date", valid_602755
  var valid_602756 = header.getOrDefault("X-Amz-Credential")
  valid_602756 = validateParameter(valid_602756, JString, required = false,
                                 default = nil)
  if valid_602756 != nil:
    section.add "X-Amz-Credential", valid_602756
  var valid_602757 = header.getOrDefault("X-Amz-Security-Token")
  valid_602757 = validateParameter(valid_602757, JString, required = false,
                                 default = nil)
  if valid_602757 != nil:
    section.add "X-Amz-Security-Token", valid_602757
  var valid_602758 = header.getOrDefault("X-Amz-Algorithm")
  valid_602758 = validateParameter(valid_602758, JString, required = false,
                                 default = nil)
  if valid_602758 != nil:
    section.add "X-Amz-Algorithm", valid_602758
  var valid_602759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602759 = validateParameter(valid_602759, JString, required = false,
                                 default = nil)
  if valid_602759 != nil:
    section.add "X-Amz-SignedHeaders", valid_602759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602761: Call_UpdateModel_602748; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Model.
  ## 
  let valid = call_602761.validator(path, query, header, formData, body)
  let scheme = call_602761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602761.url(scheme.get, call_602761.host, call_602761.base,
                         call_602761.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602761, url, valid)

proc call*(call_602762: Call_UpdateModel_602748; apiId: string; body: JsonNode;
          modelId: string): Recallable =
  ## updateModel
  ## Updates a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   modelId: string (required)
  ##          : The model ID.
  var path_602763 = newJObject()
  var body_602764 = newJObject()
  add(path_602763, "apiId", newJString(apiId))
  if body != nil:
    body_602764 = body
  add(path_602763, "modelId", newJString(modelId))
  result = call_602762.call(path_602763, nil, nil, nil, body_602764)

var updateModel* = Call_UpdateModel_602748(name: "updateModel",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/models/{modelId}",
                                        validator: validate_UpdateModel_602749,
                                        base: "/", url: url_UpdateModel_602750,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_602733 = ref object of OpenApiRestCall_601389
proc url_DeleteModel_602735(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "modelId" in path, "`modelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/models/"),
               (kind: VariableSegment, value: "modelId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteModel_602734(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a Model.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   modelId: JString (required)
  ##          : The model ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602736 = path.getOrDefault("apiId")
  valid_602736 = validateParameter(valid_602736, JString, required = true,
                                 default = nil)
  if valid_602736 != nil:
    section.add "apiId", valid_602736
  var valid_602737 = path.getOrDefault("modelId")
  valid_602737 = validateParameter(valid_602737, JString, required = true,
                                 default = nil)
  if valid_602737 != nil:
    section.add "modelId", valid_602737
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
  var valid_602738 = header.getOrDefault("X-Amz-Signature")
  valid_602738 = validateParameter(valid_602738, JString, required = false,
                                 default = nil)
  if valid_602738 != nil:
    section.add "X-Amz-Signature", valid_602738
  var valid_602739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602739 = validateParameter(valid_602739, JString, required = false,
                                 default = nil)
  if valid_602739 != nil:
    section.add "X-Amz-Content-Sha256", valid_602739
  var valid_602740 = header.getOrDefault("X-Amz-Date")
  valid_602740 = validateParameter(valid_602740, JString, required = false,
                                 default = nil)
  if valid_602740 != nil:
    section.add "X-Amz-Date", valid_602740
  var valid_602741 = header.getOrDefault("X-Amz-Credential")
  valid_602741 = validateParameter(valid_602741, JString, required = false,
                                 default = nil)
  if valid_602741 != nil:
    section.add "X-Amz-Credential", valid_602741
  var valid_602742 = header.getOrDefault("X-Amz-Security-Token")
  valid_602742 = validateParameter(valid_602742, JString, required = false,
                                 default = nil)
  if valid_602742 != nil:
    section.add "X-Amz-Security-Token", valid_602742
  var valid_602743 = header.getOrDefault("X-Amz-Algorithm")
  valid_602743 = validateParameter(valid_602743, JString, required = false,
                                 default = nil)
  if valid_602743 != nil:
    section.add "X-Amz-Algorithm", valid_602743
  var valid_602744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602744 = validateParameter(valid_602744, JString, required = false,
                                 default = nil)
  if valid_602744 != nil:
    section.add "X-Amz-SignedHeaders", valid_602744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602745: Call_DeleteModel_602733; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Model.
  ## 
  let valid = call_602745.validator(path, query, header, formData, body)
  let scheme = call_602745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602745.url(scheme.get, call_602745.host, call_602745.base,
                         call_602745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602745, url, valid)

proc call*(call_602746: Call_DeleteModel_602733; apiId: string; modelId: string): Recallable =
  ## deleteModel
  ## Deletes a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_602747 = newJObject()
  add(path_602747, "apiId", newJString(apiId))
  add(path_602747, "modelId", newJString(modelId))
  result = call_602746.call(path_602747, nil, nil, nil, nil)

var deleteModel* = Call_DeleteModel_602733(name: "deleteModel",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/models/{modelId}",
                                        validator: validate_DeleteModel_602734,
                                        base: "/", url: url_DeleteModel_602735,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoute_602765 = ref object of OpenApiRestCall_601389
proc url_GetRoute_602767(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRoute_602766(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a Route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602768 = path.getOrDefault("apiId")
  valid_602768 = validateParameter(valid_602768, JString, required = true,
                                 default = nil)
  if valid_602768 != nil:
    section.add "apiId", valid_602768
  var valid_602769 = path.getOrDefault("routeId")
  valid_602769 = validateParameter(valid_602769, JString, required = true,
                                 default = nil)
  if valid_602769 != nil:
    section.add "routeId", valid_602769
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
  var valid_602770 = header.getOrDefault("X-Amz-Signature")
  valid_602770 = validateParameter(valid_602770, JString, required = false,
                                 default = nil)
  if valid_602770 != nil:
    section.add "X-Amz-Signature", valid_602770
  var valid_602771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602771 = validateParameter(valid_602771, JString, required = false,
                                 default = nil)
  if valid_602771 != nil:
    section.add "X-Amz-Content-Sha256", valid_602771
  var valid_602772 = header.getOrDefault("X-Amz-Date")
  valid_602772 = validateParameter(valid_602772, JString, required = false,
                                 default = nil)
  if valid_602772 != nil:
    section.add "X-Amz-Date", valid_602772
  var valid_602773 = header.getOrDefault("X-Amz-Credential")
  valid_602773 = validateParameter(valid_602773, JString, required = false,
                                 default = nil)
  if valid_602773 != nil:
    section.add "X-Amz-Credential", valid_602773
  var valid_602774 = header.getOrDefault("X-Amz-Security-Token")
  valid_602774 = validateParameter(valid_602774, JString, required = false,
                                 default = nil)
  if valid_602774 != nil:
    section.add "X-Amz-Security-Token", valid_602774
  var valid_602775 = header.getOrDefault("X-Amz-Algorithm")
  valid_602775 = validateParameter(valid_602775, JString, required = false,
                                 default = nil)
  if valid_602775 != nil:
    section.add "X-Amz-Algorithm", valid_602775
  var valid_602776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602776 = validateParameter(valid_602776, JString, required = false,
                                 default = nil)
  if valid_602776 != nil:
    section.add "X-Amz-SignedHeaders", valid_602776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602777: Call_GetRoute_602765; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Route.
  ## 
  let valid = call_602777.validator(path, query, header, formData, body)
  let scheme = call_602777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602777.url(scheme.get, call_602777.host, call_602777.base,
                         call_602777.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602777, url, valid)

proc call*(call_602778: Call_GetRoute_602765; apiId: string; routeId: string): Recallable =
  ## getRoute
  ## Gets a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_602779 = newJObject()
  add(path_602779, "apiId", newJString(apiId))
  add(path_602779, "routeId", newJString(routeId))
  result = call_602778.call(path_602779, nil, nil, nil, nil)

var getRoute* = Call_GetRoute_602765(name: "getRoute", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/routes/{routeId}",
                                  validator: validate_GetRoute_602766, base: "/",
                                  url: url_GetRoute_602767,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoute_602795 = ref object of OpenApiRestCall_601389
proc url_UpdateRoute_602797(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRoute_602796(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a Route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602798 = path.getOrDefault("apiId")
  valid_602798 = validateParameter(valid_602798, JString, required = true,
                                 default = nil)
  if valid_602798 != nil:
    section.add "apiId", valid_602798
  var valid_602799 = path.getOrDefault("routeId")
  valid_602799 = validateParameter(valid_602799, JString, required = true,
                                 default = nil)
  if valid_602799 != nil:
    section.add "routeId", valid_602799
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
  var valid_602800 = header.getOrDefault("X-Amz-Signature")
  valid_602800 = validateParameter(valid_602800, JString, required = false,
                                 default = nil)
  if valid_602800 != nil:
    section.add "X-Amz-Signature", valid_602800
  var valid_602801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602801 = validateParameter(valid_602801, JString, required = false,
                                 default = nil)
  if valid_602801 != nil:
    section.add "X-Amz-Content-Sha256", valid_602801
  var valid_602802 = header.getOrDefault("X-Amz-Date")
  valid_602802 = validateParameter(valid_602802, JString, required = false,
                                 default = nil)
  if valid_602802 != nil:
    section.add "X-Amz-Date", valid_602802
  var valid_602803 = header.getOrDefault("X-Amz-Credential")
  valid_602803 = validateParameter(valid_602803, JString, required = false,
                                 default = nil)
  if valid_602803 != nil:
    section.add "X-Amz-Credential", valid_602803
  var valid_602804 = header.getOrDefault("X-Amz-Security-Token")
  valid_602804 = validateParameter(valid_602804, JString, required = false,
                                 default = nil)
  if valid_602804 != nil:
    section.add "X-Amz-Security-Token", valid_602804
  var valid_602805 = header.getOrDefault("X-Amz-Algorithm")
  valid_602805 = validateParameter(valid_602805, JString, required = false,
                                 default = nil)
  if valid_602805 != nil:
    section.add "X-Amz-Algorithm", valid_602805
  var valid_602806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602806 = validateParameter(valid_602806, JString, required = false,
                                 default = nil)
  if valid_602806 != nil:
    section.add "X-Amz-SignedHeaders", valid_602806
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602808: Call_UpdateRoute_602795; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Route.
  ## 
  let valid = call_602808.validator(path, query, header, formData, body)
  let scheme = call_602808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602808.url(scheme.get, call_602808.host, call_602808.base,
                         call_602808.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602808, url, valid)

proc call*(call_602809: Call_UpdateRoute_602795; apiId: string; body: JsonNode;
          routeId: string): Recallable =
  ## updateRoute
  ## Updates a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   routeId: string (required)
  ##          : The route ID.
  var path_602810 = newJObject()
  var body_602811 = newJObject()
  add(path_602810, "apiId", newJString(apiId))
  if body != nil:
    body_602811 = body
  add(path_602810, "routeId", newJString(routeId))
  result = call_602809.call(path_602810, nil, nil, nil, body_602811)

var updateRoute* = Call_UpdateRoute_602795(name: "updateRoute",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}",
                                        validator: validate_UpdateRoute_602796,
                                        base: "/", url: url_UpdateRoute_602797,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoute_602780 = ref object of OpenApiRestCall_601389
proc url_DeleteRoute_602782(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRoute_602781(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a Route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602783 = path.getOrDefault("apiId")
  valid_602783 = validateParameter(valid_602783, JString, required = true,
                                 default = nil)
  if valid_602783 != nil:
    section.add "apiId", valid_602783
  var valid_602784 = path.getOrDefault("routeId")
  valid_602784 = validateParameter(valid_602784, JString, required = true,
                                 default = nil)
  if valid_602784 != nil:
    section.add "routeId", valid_602784
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
  var valid_602785 = header.getOrDefault("X-Amz-Signature")
  valid_602785 = validateParameter(valid_602785, JString, required = false,
                                 default = nil)
  if valid_602785 != nil:
    section.add "X-Amz-Signature", valid_602785
  var valid_602786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602786 = validateParameter(valid_602786, JString, required = false,
                                 default = nil)
  if valid_602786 != nil:
    section.add "X-Amz-Content-Sha256", valid_602786
  var valid_602787 = header.getOrDefault("X-Amz-Date")
  valid_602787 = validateParameter(valid_602787, JString, required = false,
                                 default = nil)
  if valid_602787 != nil:
    section.add "X-Amz-Date", valid_602787
  var valid_602788 = header.getOrDefault("X-Amz-Credential")
  valid_602788 = validateParameter(valid_602788, JString, required = false,
                                 default = nil)
  if valid_602788 != nil:
    section.add "X-Amz-Credential", valid_602788
  var valid_602789 = header.getOrDefault("X-Amz-Security-Token")
  valid_602789 = validateParameter(valid_602789, JString, required = false,
                                 default = nil)
  if valid_602789 != nil:
    section.add "X-Amz-Security-Token", valid_602789
  var valid_602790 = header.getOrDefault("X-Amz-Algorithm")
  valid_602790 = validateParameter(valid_602790, JString, required = false,
                                 default = nil)
  if valid_602790 != nil:
    section.add "X-Amz-Algorithm", valid_602790
  var valid_602791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602791 = validateParameter(valid_602791, JString, required = false,
                                 default = nil)
  if valid_602791 != nil:
    section.add "X-Amz-SignedHeaders", valid_602791
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602792: Call_DeleteRoute_602780; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Route.
  ## 
  let valid = call_602792.validator(path, query, header, formData, body)
  let scheme = call_602792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602792.url(scheme.get, call_602792.host, call_602792.base,
                         call_602792.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602792, url, valid)

proc call*(call_602793: Call_DeleteRoute_602780; apiId: string; routeId: string): Recallable =
  ## deleteRoute
  ## Deletes a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_602794 = newJObject()
  add(path_602794, "apiId", newJString(apiId))
  add(path_602794, "routeId", newJString(routeId))
  result = call_602793.call(path_602794, nil, nil, nil, nil)

var deleteRoute* = Call_DeleteRoute_602780(name: "deleteRoute",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}",
                                        validator: validate_DeleteRoute_602781,
                                        base: "/", url: url_DeleteRoute_602782,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRouteResponse_602812 = ref object of OpenApiRestCall_601389
proc url_GetRouteResponse_602814(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  assert "routeResponseId" in path, "`routeResponseId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId"),
               (kind: ConstantSegment, value: "/routeresponses/"),
               (kind: VariableSegment, value: "routeResponseId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRouteResponse_602813(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Gets a RouteResponse.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeResponseId: JString (required)
  ##                  : The route response ID.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602815 = path.getOrDefault("apiId")
  valid_602815 = validateParameter(valid_602815, JString, required = true,
                                 default = nil)
  if valid_602815 != nil:
    section.add "apiId", valid_602815
  var valid_602816 = path.getOrDefault("routeResponseId")
  valid_602816 = validateParameter(valid_602816, JString, required = true,
                                 default = nil)
  if valid_602816 != nil:
    section.add "routeResponseId", valid_602816
  var valid_602817 = path.getOrDefault("routeId")
  valid_602817 = validateParameter(valid_602817, JString, required = true,
                                 default = nil)
  if valid_602817 != nil:
    section.add "routeId", valid_602817
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
  var valid_602818 = header.getOrDefault("X-Amz-Signature")
  valid_602818 = validateParameter(valid_602818, JString, required = false,
                                 default = nil)
  if valid_602818 != nil:
    section.add "X-Amz-Signature", valid_602818
  var valid_602819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602819 = validateParameter(valid_602819, JString, required = false,
                                 default = nil)
  if valid_602819 != nil:
    section.add "X-Amz-Content-Sha256", valid_602819
  var valid_602820 = header.getOrDefault("X-Amz-Date")
  valid_602820 = validateParameter(valid_602820, JString, required = false,
                                 default = nil)
  if valid_602820 != nil:
    section.add "X-Amz-Date", valid_602820
  var valid_602821 = header.getOrDefault("X-Amz-Credential")
  valid_602821 = validateParameter(valid_602821, JString, required = false,
                                 default = nil)
  if valid_602821 != nil:
    section.add "X-Amz-Credential", valid_602821
  var valid_602822 = header.getOrDefault("X-Amz-Security-Token")
  valid_602822 = validateParameter(valid_602822, JString, required = false,
                                 default = nil)
  if valid_602822 != nil:
    section.add "X-Amz-Security-Token", valid_602822
  var valid_602823 = header.getOrDefault("X-Amz-Algorithm")
  valid_602823 = validateParameter(valid_602823, JString, required = false,
                                 default = nil)
  if valid_602823 != nil:
    section.add "X-Amz-Algorithm", valid_602823
  var valid_602824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602824 = validateParameter(valid_602824, JString, required = false,
                                 default = nil)
  if valid_602824 != nil:
    section.add "X-Amz-SignedHeaders", valid_602824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602825: Call_GetRouteResponse_602812; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a RouteResponse.
  ## 
  let valid = call_602825.validator(path, query, header, formData, body)
  let scheme = call_602825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602825.url(scheme.get, call_602825.host, call_602825.base,
                         call_602825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602825, url, valid)

proc call*(call_602826: Call_GetRouteResponse_602812; apiId: string;
          routeResponseId: string; routeId: string): Recallable =
  ## getRouteResponse
  ## Gets a RouteResponse.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeResponseId: string (required)
  ##                  : The route response ID.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_602827 = newJObject()
  add(path_602827, "apiId", newJString(apiId))
  add(path_602827, "routeResponseId", newJString(routeResponseId))
  add(path_602827, "routeId", newJString(routeId))
  result = call_602826.call(path_602827, nil, nil, nil, nil)

var getRouteResponse* = Call_GetRouteResponse_602812(name: "getRouteResponse",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_GetRouteResponse_602813, base: "/",
    url: url_GetRouteResponse_602814, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRouteResponse_602844 = ref object of OpenApiRestCall_601389
proc url_UpdateRouteResponse_602846(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  assert "routeResponseId" in path, "`routeResponseId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId"),
               (kind: ConstantSegment, value: "/routeresponses/"),
               (kind: VariableSegment, value: "routeResponseId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRouteResponse_602845(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Updates a RouteResponse.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeResponseId: JString (required)
  ##                  : The route response ID.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602847 = path.getOrDefault("apiId")
  valid_602847 = validateParameter(valid_602847, JString, required = true,
                                 default = nil)
  if valid_602847 != nil:
    section.add "apiId", valid_602847
  var valid_602848 = path.getOrDefault("routeResponseId")
  valid_602848 = validateParameter(valid_602848, JString, required = true,
                                 default = nil)
  if valid_602848 != nil:
    section.add "routeResponseId", valid_602848
  var valid_602849 = path.getOrDefault("routeId")
  valid_602849 = validateParameter(valid_602849, JString, required = true,
                                 default = nil)
  if valid_602849 != nil:
    section.add "routeId", valid_602849
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
  var valid_602850 = header.getOrDefault("X-Amz-Signature")
  valid_602850 = validateParameter(valid_602850, JString, required = false,
                                 default = nil)
  if valid_602850 != nil:
    section.add "X-Amz-Signature", valid_602850
  var valid_602851 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602851 = validateParameter(valid_602851, JString, required = false,
                                 default = nil)
  if valid_602851 != nil:
    section.add "X-Amz-Content-Sha256", valid_602851
  var valid_602852 = header.getOrDefault("X-Amz-Date")
  valid_602852 = validateParameter(valid_602852, JString, required = false,
                                 default = nil)
  if valid_602852 != nil:
    section.add "X-Amz-Date", valid_602852
  var valid_602853 = header.getOrDefault("X-Amz-Credential")
  valid_602853 = validateParameter(valid_602853, JString, required = false,
                                 default = nil)
  if valid_602853 != nil:
    section.add "X-Amz-Credential", valid_602853
  var valid_602854 = header.getOrDefault("X-Amz-Security-Token")
  valid_602854 = validateParameter(valid_602854, JString, required = false,
                                 default = nil)
  if valid_602854 != nil:
    section.add "X-Amz-Security-Token", valid_602854
  var valid_602855 = header.getOrDefault("X-Amz-Algorithm")
  valid_602855 = validateParameter(valid_602855, JString, required = false,
                                 default = nil)
  if valid_602855 != nil:
    section.add "X-Amz-Algorithm", valid_602855
  var valid_602856 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602856 = validateParameter(valid_602856, JString, required = false,
                                 default = nil)
  if valid_602856 != nil:
    section.add "X-Amz-SignedHeaders", valid_602856
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602858: Call_UpdateRouteResponse_602844; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a RouteResponse.
  ## 
  let valid = call_602858.validator(path, query, header, formData, body)
  let scheme = call_602858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602858.url(scheme.get, call_602858.host, call_602858.base,
                         call_602858.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602858, url, valid)

proc call*(call_602859: Call_UpdateRouteResponse_602844; apiId: string;
          routeResponseId: string; body: JsonNode; routeId: string): Recallable =
  ## updateRouteResponse
  ## Updates a RouteResponse.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeResponseId: string (required)
  ##                  : The route response ID.
  ##   body: JObject (required)
  ##   routeId: string (required)
  ##          : The route ID.
  var path_602860 = newJObject()
  var body_602861 = newJObject()
  add(path_602860, "apiId", newJString(apiId))
  add(path_602860, "routeResponseId", newJString(routeResponseId))
  if body != nil:
    body_602861 = body
  add(path_602860, "routeId", newJString(routeId))
  result = call_602859.call(path_602860, nil, nil, nil, body_602861)

var updateRouteResponse* = Call_UpdateRouteResponse_602844(
    name: "updateRouteResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_UpdateRouteResponse_602845, base: "/",
    url: url_UpdateRouteResponse_602846, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRouteResponse_602828 = ref object of OpenApiRestCall_601389
proc url_DeleteRouteResponse_602830(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  assert "routeResponseId" in path, "`routeResponseId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId"),
               (kind: ConstantSegment, value: "/routeresponses/"),
               (kind: VariableSegment, value: "routeResponseId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRouteResponse_602829(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes a RouteResponse.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeResponseId: JString (required)
  ##                  : The route response ID.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602831 = path.getOrDefault("apiId")
  valid_602831 = validateParameter(valid_602831, JString, required = true,
                                 default = nil)
  if valid_602831 != nil:
    section.add "apiId", valid_602831
  var valid_602832 = path.getOrDefault("routeResponseId")
  valid_602832 = validateParameter(valid_602832, JString, required = true,
                                 default = nil)
  if valid_602832 != nil:
    section.add "routeResponseId", valid_602832
  var valid_602833 = path.getOrDefault("routeId")
  valid_602833 = validateParameter(valid_602833, JString, required = true,
                                 default = nil)
  if valid_602833 != nil:
    section.add "routeId", valid_602833
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
  var valid_602834 = header.getOrDefault("X-Amz-Signature")
  valid_602834 = validateParameter(valid_602834, JString, required = false,
                                 default = nil)
  if valid_602834 != nil:
    section.add "X-Amz-Signature", valid_602834
  var valid_602835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602835 = validateParameter(valid_602835, JString, required = false,
                                 default = nil)
  if valid_602835 != nil:
    section.add "X-Amz-Content-Sha256", valid_602835
  var valid_602836 = header.getOrDefault("X-Amz-Date")
  valid_602836 = validateParameter(valid_602836, JString, required = false,
                                 default = nil)
  if valid_602836 != nil:
    section.add "X-Amz-Date", valid_602836
  var valid_602837 = header.getOrDefault("X-Amz-Credential")
  valid_602837 = validateParameter(valid_602837, JString, required = false,
                                 default = nil)
  if valid_602837 != nil:
    section.add "X-Amz-Credential", valid_602837
  var valid_602838 = header.getOrDefault("X-Amz-Security-Token")
  valid_602838 = validateParameter(valid_602838, JString, required = false,
                                 default = nil)
  if valid_602838 != nil:
    section.add "X-Amz-Security-Token", valid_602838
  var valid_602839 = header.getOrDefault("X-Amz-Algorithm")
  valid_602839 = validateParameter(valid_602839, JString, required = false,
                                 default = nil)
  if valid_602839 != nil:
    section.add "X-Amz-Algorithm", valid_602839
  var valid_602840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602840 = validateParameter(valid_602840, JString, required = false,
                                 default = nil)
  if valid_602840 != nil:
    section.add "X-Amz-SignedHeaders", valid_602840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602841: Call_DeleteRouteResponse_602828; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a RouteResponse.
  ## 
  let valid = call_602841.validator(path, query, header, formData, body)
  let scheme = call_602841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602841.url(scheme.get, call_602841.host, call_602841.base,
                         call_602841.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602841, url, valid)

proc call*(call_602842: Call_DeleteRouteResponse_602828; apiId: string;
          routeResponseId: string; routeId: string): Recallable =
  ## deleteRouteResponse
  ## Deletes a RouteResponse.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeResponseId: string (required)
  ##                  : The route response ID.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_602843 = newJObject()
  add(path_602843, "apiId", newJString(apiId))
  add(path_602843, "routeResponseId", newJString(routeResponseId))
  add(path_602843, "routeId", newJString(routeId))
  result = call_602842.call(path_602843, nil, nil, nil, nil)

var deleteRouteResponse* = Call_DeleteRouteResponse_602828(
    name: "deleteRouteResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_DeleteRouteResponse_602829, base: "/",
    url: url_DeleteRouteResponse_602830, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRouteSettings_602862 = ref object of OpenApiRestCall_601389
proc url_DeleteRouteSettings_602864(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "stageName" in path, "`stageName` is a required path parameter"
  assert "routeKey" in path, "`routeKey` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/stages/"),
               (kind: VariableSegment, value: "stageName"),
               (kind: ConstantSegment, value: "/routesettings/"),
               (kind: VariableSegment, value: "routeKey")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRouteSettings_602863(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes the RouteSettings for a stage.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stageName: JString (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   routeKey: JString (required)
  ##           : The route key.
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `stageName` field"
  var valid_602865 = path.getOrDefault("stageName")
  valid_602865 = validateParameter(valid_602865, JString, required = true,
                                 default = nil)
  if valid_602865 != nil:
    section.add "stageName", valid_602865
  var valid_602866 = path.getOrDefault("routeKey")
  valid_602866 = validateParameter(valid_602866, JString, required = true,
                                 default = nil)
  if valid_602866 != nil:
    section.add "routeKey", valid_602866
  var valid_602867 = path.getOrDefault("apiId")
  valid_602867 = validateParameter(valid_602867, JString, required = true,
                                 default = nil)
  if valid_602867 != nil:
    section.add "apiId", valid_602867
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
  var valid_602868 = header.getOrDefault("X-Amz-Signature")
  valid_602868 = validateParameter(valid_602868, JString, required = false,
                                 default = nil)
  if valid_602868 != nil:
    section.add "X-Amz-Signature", valid_602868
  var valid_602869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602869 = validateParameter(valid_602869, JString, required = false,
                                 default = nil)
  if valid_602869 != nil:
    section.add "X-Amz-Content-Sha256", valid_602869
  var valid_602870 = header.getOrDefault("X-Amz-Date")
  valid_602870 = validateParameter(valid_602870, JString, required = false,
                                 default = nil)
  if valid_602870 != nil:
    section.add "X-Amz-Date", valid_602870
  var valid_602871 = header.getOrDefault("X-Amz-Credential")
  valid_602871 = validateParameter(valid_602871, JString, required = false,
                                 default = nil)
  if valid_602871 != nil:
    section.add "X-Amz-Credential", valid_602871
  var valid_602872 = header.getOrDefault("X-Amz-Security-Token")
  valid_602872 = validateParameter(valid_602872, JString, required = false,
                                 default = nil)
  if valid_602872 != nil:
    section.add "X-Amz-Security-Token", valid_602872
  var valid_602873 = header.getOrDefault("X-Amz-Algorithm")
  valid_602873 = validateParameter(valid_602873, JString, required = false,
                                 default = nil)
  if valid_602873 != nil:
    section.add "X-Amz-Algorithm", valid_602873
  var valid_602874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602874 = validateParameter(valid_602874, JString, required = false,
                                 default = nil)
  if valid_602874 != nil:
    section.add "X-Amz-SignedHeaders", valid_602874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602875: Call_DeleteRouteSettings_602862; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the RouteSettings for a stage.
  ## 
  let valid = call_602875.validator(path, query, header, formData, body)
  let scheme = call_602875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602875.url(scheme.get, call_602875.host, call_602875.base,
                         call_602875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602875, url, valid)

proc call*(call_602876: Call_DeleteRouteSettings_602862; stageName: string;
          routeKey: string; apiId: string): Recallable =
  ## deleteRouteSettings
  ## Deletes the RouteSettings for a stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   routeKey: string (required)
  ##           : The route key.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_602877 = newJObject()
  add(path_602877, "stageName", newJString(stageName))
  add(path_602877, "routeKey", newJString(routeKey))
  add(path_602877, "apiId", newJString(apiId))
  result = call_602876.call(path_602877, nil, nil, nil, nil)

var deleteRouteSettings* = Call_DeleteRouteSettings_602862(
    name: "deleteRouteSettings", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/stages/{stageName}/routesettings/{routeKey}",
    validator: validate_DeleteRouteSettings_602863, base: "/",
    url: url_DeleteRouteSettings_602864, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStage_602878 = ref object of OpenApiRestCall_601389
proc url_GetStage_602880(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "stageName" in path, "`stageName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/stages/"),
               (kind: VariableSegment, value: "stageName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStage_602879(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a Stage.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stageName: JString (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `stageName` field"
  var valid_602881 = path.getOrDefault("stageName")
  valid_602881 = validateParameter(valid_602881, JString, required = true,
                                 default = nil)
  if valid_602881 != nil:
    section.add "stageName", valid_602881
  var valid_602882 = path.getOrDefault("apiId")
  valid_602882 = validateParameter(valid_602882, JString, required = true,
                                 default = nil)
  if valid_602882 != nil:
    section.add "apiId", valid_602882
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
  var valid_602883 = header.getOrDefault("X-Amz-Signature")
  valid_602883 = validateParameter(valid_602883, JString, required = false,
                                 default = nil)
  if valid_602883 != nil:
    section.add "X-Amz-Signature", valid_602883
  var valid_602884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "X-Amz-Content-Sha256", valid_602884
  var valid_602885 = header.getOrDefault("X-Amz-Date")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-Date", valid_602885
  var valid_602886 = header.getOrDefault("X-Amz-Credential")
  valid_602886 = validateParameter(valid_602886, JString, required = false,
                                 default = nil)
  if valid_602886 != nil:
    section.add "X-Amz-Credential", valid_602886
  var valid_602887 = header.getOrDefault("X-Amz-Security-Token")
  valid_602887 = validateParameter(valid_602887, JString, required = false,
                                 default = nil)
  if valid_602887 != nil:
    section.add "X-Amz-Security-Token", valid_602887
  var valid_602888 = header.getOrDefault("X-Amz-Algorithm")
  valid_602888 = validateParameter(valid_602888, JString, required = false,
                                 default = nil)
  if valid_602888 != nil:
    section.add "X-Amz-Algorithm", valid_602888
  var valid_602889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "X-Amz-SignedHeaders", valid_602889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602890: Call_GetStage_602878; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Stage.
  ## 
  let valid = call_602890.validator(path, query, header, formData, body)
  let scheme = call_602890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602890.url(scheme.get, call_602890.host, call_602890.base,
                         call_602890.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602890, url, valid)

proc call*(call_602891: Call_GetStage_602878; stageName: string; apiId: string): Recallable =
  ## getStage
  ## Gets a Stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_602892 = newJObject()
  add(path_602892, "stageName", newJString(stageName))
  add(path_602892, "apiId", newJString(apiId))
  result = call_602891.call(path_602892, nil, nil, nil, nil)

var getStage* = Call_GetStage_602878(name: "getStage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/stages/{stageName}",
                                  validator: validate_GetStage_602879, base: "/",
                                  url: url_GetStage_602880,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStage_602908 = ref object of OpenApiRestCall_601389
proc url_UpdateStage_602910(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "stageName" in path, "`stageName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/stages/"),
               (kind: VariableSegment, value: "stageName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateStage_602909(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a Stage.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stageName: JString (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `stageName` field"
  var valid_602911 = path.getOrDefault("stageName")
  valid_602911 = validateParameter(valid_602911, JString, required = true,
                                 default = nil)
  if valid_602911 != nil:
    section.add "stageName", valid_602911
  var valid_602912 = path.getOrDefault("apiId")
  valid_602912 = validateParameter(valid_602912, JString, required = true,
                                 default = nil)
  if valid_602912 != nil:
    section.add "apiId", valid_602912
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
  var valid_602913 = header.getOrDefault("X-Amz-Signature")
  valid_602913 = validateParameter(valid_602913, JString, required = false,
                                 default = nil)
  if valid_602913 != nil:
    section.add "X-Amz-Signature", valid_602913
  var valid_602914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602914 = validateParameter(valid_602914, JString, required = false,
                                 default = nil)
  if valid_602914 != nil:
    section.add "X-Amz-Content-Sha256", valid_602914
  var valid_602915 = header.getOrDefault("X-Amz-Date")
  valid_602915 = validateParameter(valid_602915, JString, required = false,
                                 default = nil)
  if valid_602915 != nil:
    section.add "X-Amz-Date", valid_602915
  var valid_602916 = header.getOrDefault("X-Amz-Credential")
  valid_602916 = validateParameter(valid_602916, JString, required = false,
                                 default = nil)
  if valid_602916 != nil:
    section.add "X-Amz-Credential", valid_602916
  var valid_602917 = header.getOrDefault("X-Amz-Security-Token")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Security-Token", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Algorithm")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Algorithm", valid_602918
  var valid_602919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602919 = validateParameter(valid_602919, JString, required = false,
                                 default = nil)
  if valid_602919 != nil:
    section.add "X-Amz-SignedHeaders", valid_602919
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602921: Call_UpdateStage_602908; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Stage.
  ## 
  let valid = call_602921.validator(path, query, header, formData, body)
  let scheme = call_602921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602921.url(scheme.get, call_602921.host, call_602921.base,
                         call_602921.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602921, url, valid)

proc call*(call_602922: Call_UpdateStage_602908; stageName: string; apiId: string;
          body: JsonNode): Recallable =
  ## updateStage
  ## Updates a Stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_602923 = newJObject()
  var body_602924 = newJObject()
  add(path_602923, "stageName", newJString(stageName))
  add(path_602923, "apiId", newJString(apiId))
  if body != nil:
    body_602924 = body
  result = call_602922.call(path_602923, nil, nil, nil, body_602924)

var updateStage* = Call_UpdateStage_602908(name: "updateStage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/stages/{stageName}",
                                        validator: validate_UpdateStage_602909,
                                        base: "/", url: url_UpdateStage_602910,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStage_602893 = ref object of OpenApiRestCall_601389
proc url_DeleteStage_602895(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "stageName" in path, "`stageName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/stages/"),
               (kind: VariableSegment, value: "stageName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteStage_602894(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a Stage.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stageName: JString (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `stageName` field"
  var valid_602896 = path.getOrDefault("stageName")
  valid_602896 = validateParameter(valid_602896, JString, required = true,
                                 default = nil)
  if valid_602896 != nil:
    section.add "stageName", valid_602896
  var valid_602897 = path.getOrDefault("apiId")
  valid_602897 = validateParameter(valid_602897, JString, required = true,
                                 default = nil)
  if valid_602897 != nil:
    section.add "apiId", valid_602897
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
  var valid_602898 = header.getOrDefault("X-Amz-Signature")
  valid_602898 = validateParameter(valid_602898, JString, required = false,
                                 default = nil)
  if valid_602898 != nil:
    section.add "X-Amz-Signature", valid_602898
  var valid_602899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602899 = validateParameter(valid_602899, JString, required = false,
                                 default = nil)
  if valid_602899 != nil:
    section.add "X-Amz-Content-Sha256", valid_602899
  var valid_602900 = header.getOrDefault("X-Amz-Date")
  valid_602900 = validateParameter(valid_602900, JString, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "X-Amz-Date", valid_602900
  var valid_602901 = header.getOrDefault("X-Amz-Credential")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "X-Amz-Credential", valid_602901
  var valid_602902 = header.getOrDefault("X-Amz-Security-Token")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Security-Token", valid_602902
  var valid_602903 = header.getOrDefault("X-Amz-Algorithm")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-Algorithm", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-SignedHeaders", valid_602904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602905: Call_DeleteStage_602893; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Stage.
  ## 
  let valid = call_602905.validator(path, query, header, formData, body)
  let scheme = call_602905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602905.url(scheme.get, call_602905.host, call_602905.base,
                         call_602905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602905, url, valid)

proc call*(call_602906: Call_DeleteStage_602893; stageName: string; apiId: string): Recallable =
  ## deleteStage
  ## Deletes a Stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_602907 = newJObject()
  add(path_602907, "stageName", newJString(stageName))
  add(path_602907, "apiId", newJString(apiId))
  result = call_602906.call(path_602907, nil, nil, nil, nil)

var deleteStage* = Call_DeleteStage_602893(name: "deleteStage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/stages/{stageName}",
                                        validator: validate_DeleteStage_602894,
                                        base: "/", url: url_DeleteStage_602895,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelTemplate_602925 = ref object of OpenApiRestCall_601389
proc url_GetModelTemplate_602927(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "modelId" in path, "`modelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/models/"),
               (kind: VariableSegment, value: "modelId"),
               (kind: ConstantSegment, value: "/template")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetModelTemplate_602926(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Gets a model template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   modelId: JString (required)
  ##          : The model ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602928 = path.getOrDefault("apiId")
  valid_602928 = validateParameter(valid_602928, JString, required = true,
                                 default = nil)
  if valid_602928 != nil:
    section.add "apiId", valid_602928
  var valid_602929 = path.getOrDefault("modelId")
  valid_602929 = validateParameter(valid_602929, JString, required = true,
                                 default = nil)
  if valid_602929 != nil:
    section.add "modelId", valid_602929
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
  var valid_602930 = header.getOrDefault("X-Amz-Signature")
  valid_602930 = validateParameter(valid_602930, JString, required = false,
                                 default = nil)
  if valid_602930 != nil:
    section.add "X-Amz-Signature", valid_602930
  var valid_602931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602931 = validateParameter(valid_602931, JString, required = false,
                                 default = nil)
  if valid_602931 != nil:
    section.add "X-Amz-Content-Sha256", valid_602931
  var valid_602932 = header.getOrDefault("X-Amz-Date")
  valid_602932 = validateParameter(valid_602932, JString, required = false,
                                 default = nil)
  if valid_602932 != nil:
    section.add "X-Amz-Date", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Credential")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Credential", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Security-Token")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Security-Token", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Algorithm")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Algorithm", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-SignedHeaders", valid_602936
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602937: Call_GetModelTemplate_602925; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a model template.
  ## 
  let valid = call_602937.validator(path, query, header, formData, body)
  let scheme = call_602937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602937.url(scheme.get, call_602937.host, call_602937.base,
                         call_602937.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602937, url, valid)

proc call*(call_602938: Call_GetModelTemplate_602925; apiId: string; modelId: string): Recallable =
  ## getModelTemplate
  ## Gets a model template.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_602939 = newJObject()
  add(path_602939, "apiId", newJString(apiId))
  add(path_602939, "modelId", newJString(modelId))
  result = call_602938.call(path_602939, nil, nil, nil, nil)

var getModelTemplate* = Call_GetModelTemplate_602925(name: "getModelTemplate",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/models/{modelId}/template",
    validator: validate_GetModelTemplate_602926, base: "/",
    url: url_GetModelTemplate_602927, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602954 = ref object of OpenApiRestCall_601389
proc url_TagResource_602956(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/tags/"),
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

proc validate_TagResource_602955(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new Tag resource to represent a tag.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The resource ARN for the tag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_602957 = path.getOrDefault("resource-arn")
  valid_602957 = validateParameter(valid_602957, JString, required = true,
                                 default = nil)
  if valid_602957 != nil:
    section.add "resource-arn", valid_602957
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
  var valid_602958 = header.getOrDefault("X-Amz-Signature")
  valid_602958 = validateParameter(valid_602958, JString, required = false,
                                 default = nil)
  if valid_602958 != nil:
    section.add "X-Amz-Signature", valid_602958
  var valid_602959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602959 = validateParameter(valid_602959, JString, required = false,
                                 default = nil)
  if valid_602959 != nil:
    section.add "X-Amz-Content-Sha256", valid_602959
  var valid_602960 = header.getOrDefault("X-Amz-Date")
  valid_602960 = validateParameter(valid_602960, JString, required = false,
                                 default = nil)
  if valid_602960 != nil:
    section.add "X-Amz-Date", valid_602960
  var valid_602961 = header.getOrDefault("X-Amz-Credential")
  valid_602961 = validateParameter(valid_602961, JString, required = false,
                                 default = nil)
  if valid_602961 != nil:
    section.add "X-Amz-Credential", valid_602961
  var valid_602962 = header.getOrDefault("X-Amz-Security-Token")
  valid_602962 = validateParameter(valid_602962, JString, required = false,
                                 default = nil)
  if valid_602962 != nil:
    section.add "X-Amz-Security-Token", valid_602962
  var valid_602963 = header.getOrDefault("X-Amz-Algorithm")
  valid_602963 = validateParameter(valid_602963, JString, required = false,
                                 default = nil)
  if valid_602963 != nil:
    section.add "X-Amz-Algorithm", valid_602963
  var valid_602964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602964 = validateParameter(valid_602964, JString, required = false,
                                 default = nil)
  if valid_602964 != nil:
    section.add "X-Amz-SignedHeaders", valid_602964
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602966: Call_TagResource_602954; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Tag resource to represent a tag.
  ## 
  let valid = call_602966.validator(path, query, header, formData, body)
  let scheme = call_602966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602966.url(scheme.get, call_602966.host, call_602966.base,
                         call_602966.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602966, url, valid)

proc call*(call_602967: Call_TagResource_602954; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Creates a new Tag resource to represent a tag.
  ##   resourceArn: string (required)
  ##              : The resource ARN for the tag.
  ##   body: JObject (required)
  var path_602968 = newJObject()
  var body_602969 = newJObject()
  add(path_602968, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_602969 = body
  result = call_602967.call(path_602968, nil, nil, nil, body_602969)

var tagResource* = Call_TagResource_602954(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/tags/{resource-arn}",
                                        validator: validate_TagResource_602955,
                                        base: "/", url: url_TagResource_602956,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_602940 = ref object of OpenApiRestCall_601389
proc url_GetTags_602942(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/tags/"),
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

proc validate_GetTags_602941(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a collection of Tag resources.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The resource ARN for the tag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_602943 = path.getOrDefault("resource-arn")
  valid_602943 = validateParameter(valid_602943, JString, required = true,
                                 default = nil)
  if valid_602943 != nil:
    section.add "resource-arn", valid_602943
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
  var valid_602944 = header.getOrDefault("X-Amz-Signature")
  valid_602944 = validateParameter(valid_602944, JString, required = false,
                                 default = nil)
  if valid_602944 != nil:
    section.add "X-Amz-Signature", valid_602944
  var valid_602945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602945 = validateParameter(valid_602945, JString, required = false,
                                 default = nil)
  if valid_602945 != nil:
    section.add "X-Amz-Content-Sha256", valid_602945
  var valid_602946 = header.getOrDefault("X-Amz-Date")
  valid_602946 = validateParameter(valid_602946, JString, required = false,
                                 default = nil)
  if valid_602946 != nil:
    section.add "X-Amz-Date", valid_602946
  var valid_602947 = header.getOrDefault("X-Amz-Credential")
  valid_602947 = validateParameter(valid_602947, JString, required = false,
                                 default = nil)
  if valid_602947 != nil:
    section.add "X-Amz-Credential", valid_602947
  var valid_602948 = header.getOrDefault("X-Amz-Security-Token")
  valid_602948 = validateParameter(valid_602948, JString, required = false,
                                 default = nil)
  if valid_602948 != nil:
    section.add "X-Amz-Security-Token", valid_602948
  var valid_602949 = header.getOrDefault("X-Amz-Algorithm")
  valid_602949 = validateParameter(valid_602949, JString, required = false,
                                 default = nil)
  if valid_602949 != nil:
    section.add "X-Amz-Algorithm", valid_602949
  var valid_602950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602950 = validateParameter(valid_602950, JString, required = false,
                                 default = nil)
  if valid_602950 != nil:
    section.add "X-Amz-SignedHeaders", valid_602950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602951: Call_GetTags_602940; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of Tag resources.
  ## 
  let valid = call_602951.validator(path, query, header, formData, body)
  let scheme = call_602951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602951.url(scheme.get, call_602951.host, call_602951.base,
                         call_602951.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602951, url, valid)

proc call*(call_602952: Call_GetTags_602940; resourceArn: string): Recallable =
  ## getTags
  ## Gets a collection of Tag resources.
  ##   resourceArn: string (required)
  ##              : The resource ARN for the tag.
  var path_602953 = newJObject()
  add(path_602953, "resource-arn", newJString(resourceArn))
  result = call_602952.call(path_602953, nil, nil, nil, nil)

var getTags* = Call_GetTags_602940(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/v2/tags/{resource-arn}",
                                validator: validate_GetTags_602941, base: "/",
                                url: url_GetTags_602942,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602970 = ref object of OpenApiRestCall_601389
proc url_UntagResource_602972(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/tags/"),
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

proc validate_UntagResource_602971(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a Tag.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The resource ARN for the tag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_602973 = path.getOrDefault("resource-arn")
  valid_602973 = validateParameter(valid_602973, JString, required = true,
                                 default = nil)
  if valid_602973 != nil:
    section.add "resource-arn", valid_602973
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : 
  ##             <p>The Tag keys to delete.</p>
  ##          
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_602974 = query.getOrDefault("tagKeys")
  valid_602974 = validateParameter(valid_602974, JArray, required = true, default = nil)
  if valid_602974 != nil:
    section.add "tagKeys", valid_602974
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
  var valid_602975 = header.getOrDefault("X-Amz-Signature")
  valid_602975 = validateParameter(valid_602975, JString, required = false,
                                 default = nil)
  if valid_602975 != nil:
    section.add "X-Amz-Signature", valid_602975
  var valid_602976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602976 = validateParameter(valid_602976, JString, required = false,
                                 default = nil)
  if valid_602976 != nil:
    section.add "X-Amz-Content-Sha256", valid_602976
  var valid_602977 = header.getOrDefault("X-Amz-Date")
  valid_602977 = validateParameter(valid_602977, JString, required = false,
                                 default = nil)
  if valid_602977 != nil:
    section.add "X-Amz-Date", valid_602977
  var valid_602978 = header.getOrDefault("X-Amz-Credential")
  valid_602978 = validateParameter(valid_602978, JString, required = false,
                                 default = nil)
  if valid_602978 != nil:
    section.add "X-Amz-Credential", valid_602978
  var valid_602979 = header.getOrDefault("X-Amz-Security-Token")
  valid_602979 = validateParameter(valid_602979, JString, required = false,
                                 default = nil)
  if valid_602979 != nil:
    section.add "X-Amz-Security-Token", valid_602979
  var valid_602980 = header.getOrDefault("X-Amz-Algorithm")
  valid_602980 = validateParameter(valid_602980, JString, required = false,
                                 default = nil)
  if valid_602980 != nil:
    section.add "X-Amz-Algorithm", valid_602980
  var valid_602981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602981 = validateParameter(valid_602981, JString, required = false,
                                 default = nil)
  if valid_602981 != nil:
    section.add "X-Amz-SignedHeaders", valid_602981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602982: Call_UntagResource_602970; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Tag.
  ## 
  let valid = call_602982.validator(path, query, header, formData, body)
  let scheme = call_602982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602982.url(scheme.get, call_602982.host, call_602982.base,
                         call_602982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602982, url, valid)

proc call*(call_602983: Call_UntagResource_602970; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Deletes a Tag.
  ##   resourceArn: string (required)
  ##              : The resource ARN for the tag.
  ##   tagKeys: JArray (required)
  ##          : 
  ##             <p>The Tag keys to delete.</p>
  ##          
  var path_602984 = newJObject()
  var query_602985 = newJObject()
  add(path_602984, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_602985.add "tagKeys", tagKeys
  result = call_602983.call(path_602984, query_602985, nil, nil, nil)

var untagResource* = Call_UntagResource_602970(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_602971,
    base: "/", url: url_UntagResource_602972, schemes: {Scheme.Https, Scheme.Http})
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
