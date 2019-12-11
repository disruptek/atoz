
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

  OpenApiRestCall_597389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_597389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_597389): Option[Scheme] {.used.} =
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
  Call_ImportApi_597984 = ref object of OpenApiRestCall_597389
proc url_ImportApi_597986(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ImportApi_597985(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_597987 = query.getOrDefault("failOnWarnings")
  valid_597987 = validateParameter(valid_597987, JBool, required = false, default = nil)
  if valid_597987 != nil:
    section.add "failOnWarnings", valid_597987
  var valid_597988 = query.getOrDefault("basepath")
  valid_597988 = validateParameter(valid_597988, JString, required = false,
                                 default = nil)
  if valid_597988 != nil:
    section.add "basepath", valid_597988
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
  var valid_597989 = header.getOrDefault("X-Amz-Signature")
  valid_597989 = validateParameter(valid_597989, JString, required = false,
                                 default = nil)
  if valid_597989 != nil:
    section.add "X-Amz-Signature", valid_597989
  var valid_597990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597990 = validateParameter(valid_597990, JString, required = false,
                                 default = nil)
  if valid_597990 != nil:
    section.add "X-Amz-Content-Sha256", valid_597990
  var valid_597991 = header.getOrDefault("X-Amz-Date")
  valid_597991 = validateParameter(valid_597991, JString, required = false,
                                 default = nil)
  if valid_597991 != nil:
    section.add "X-Amz-Date", valid_597991
  var valid_597992 = header.getOrDefault("X-Amz-Credential")
  valid_597992 = validateParameter(valid_597992, JString, required = false,
                                 default = nil)
  if valid_597992 != nil:
    section.add "X-Amz-Credential", valid_597992
  var valid_597993 = header.getOrDefault("X-Amz-Security-Token")
  valid_597993 = validateParameter(valid_597993, JString, required = false,
                                 default = nil)
  if valid_597993 != nil:
    section.add "X-Amz-Security-Token", valid_597993
  var valid_597994 = header.getOrDefault("X-Amz-Algorithm")
  valid_597994 = validateParameter(valid_597994, JString, required = false,
                                 default = nil)
  if valid_597994 != nil:
    section.add "X-Amz-Algorithm", valid_597994
  var valid_597995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597995 = validateParameter(valid_597995, JString, required = false,
                                 default = nil)
  if valid_597995 != nil:
    section.add "X-Amz-SignedHeaders", valid_597995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_597997: Call_ImportApi_597984; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports an API.
  ## 
  let valid = call_597997.validator(path, query, header, formData, body)
  let scheme = call_597997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597997.url(scheme.get, call_597997.host, call_597997.base,
                         call_597997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597997, url, valid)

proc call*(call_597998: Call_ImportApi_597984; body: JsonNode;
          failOnWarnings: bool = false; basepath: string = ""): Recallable =
  ## importApi
  ## Imports an API.
  ##   failOnWarnings: bool
  ##                 : Specifies whether to rollback the API creation (true) or not (false) when a warning is encountered. The default value is false.
  ##   body: JObject (required)
  ##   basepath: string
  ##           : Represents the base path of the imported API. Supported only for HTTP APIs.
  var query_597999 = newJObject()
  var body_598000 = newJObject()
  add(query_597999, "failOnWarnings", newJBool(failOnWarnings))
  if body != nil:
    body_598000 = body
  add(query_597999, "basepath", newJString(basepath))
  result = call_597998.call(nil, query_597999, nil, nil, body_598000)

var importApi* = Call_ImportApi_597984(name: "importApi", meth: HttpMethod.HttpPut,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis",
                                    validator: validate_ImportApi_597985,
                                    base: "/", url: url_ImportApi_597986,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApi_598001 = ref object of OpenApiRestCall_597389
proc url_CreateApi_598003(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateApi_598002(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598004 = header.getOrDefault("X-Amz-Signature")
  valid_598004 = validateParameter(valid_598004, JString, required = false,
                                 default = nil)
  if valid_598004 != nil:
    section.add "X-Amz-Signature", valid_598004
  var valid_598005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598005 = validateParameter(valid_598005, JString, required = false,
                                 default = nil)
  if valid_598005 != nil:
    section.add "X-Amz-Content-Sha256", valid_598005
  var valid_598006 = header.getOrDefault("X-Amz-Date")
  valid_598006 = validateParameter(valid_598006, JString, required = false,
                                 default = nil)
  if valid_598006 != nil:
    section.add "X-Amz-Date", valid_598006
  var valid_598007 = header.getOrDefault("X-Amz-Credential")
  valid_598007 = validateParameter(valid_598007, JString, required = false,
                                 default = nil)
  if valid_598007 != nil:
    section.add "X-Amz-Credential", valid_598007
  var valid_598008 = header.getOrDefault("X-Amz-Security-Token")
  valid_598008 = validateParameter(valid_598008, JString, required = false,
                                 default = nil)
  if valid_598008 != nil:
    section.add "X-Amz-Security-Token", valid_598008
  var valid_598009 = header.getOrDefault("X-Amz-Algorithm")
  valid_598009 = validateParameter(valid_598009, JString, required = false,
                                 default = nil)
  if valid_598009 != nil:
    section.add "X-Amz-Algorithm", valid_598009
  var valid_598010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598010 = validateParameter(valid_598010, JString, required = false,
                                 default = nil)
  if valid_598010 != nil:
    section.add "X-Amz-SignedHeaders", valid_598010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598012: Call_CreateApi_598001; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Api resource.
  ## 
  let valid = call_598012.validator(path, query, header, formData, body)
  let scheme = call_598012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598012.url(scheme.get, call_598012.host, call_598012.base,
                         call_598012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598012, url, valid)

proc call*(call_598013: Call_CreateApi_598001; body: JsonNode): Recallable =
  ## createApi
  ## Creates an Api resource.
  ##   body: JObject (required)
  var body_598014 = newJObject()
  if body != nil:
    body_598014 = body
  result = call_598013.call(nil, nil, nil, nil, body_598014)

var createApi* = Call_CreateApi_598001(name: "createApi", meth: HttpMethod.HttpPost,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis",
                                    validator: validate_CreateApi_598002,
                                    base: "/", url: url_CreateApi_598003,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApis_597727 = ref object of OpenApiRestCall_597389
proc url_GetApis_597729(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApis_597728(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_597841 = query.getOrDefault("nextToken")
  valid_597841 = validateParameter(valid_597841, JString, required = false,
                                 default = nil)
  if valid_597841 != nil:
    section.add "nextToken", valid_597841
  var valid_597842 = query.getOrDefault("maxResults")
  valid_597842 = validateParameter(valid_597842, JString, required = false,
                                 default = nil)
  if valid_597842 != nil:
    section.add "maxResults", valid_597842
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
  var valid_597843 = header.getOrDefault("X-Amz-Signature")
  valid_597843 = validateParameter(valid_597843, JString, required = false,
                                 default = nil)
  if valid_597843 != nil:
    section.add "X-Amz-Signature", valid_597843
  var valid_597844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597844 = validateParameter(valid_597844, JString, required = false,
                                 default = nil)
  if valid_597844 != nil:
    section.add "X-Amz-Content-Sha256", valid_597844
  var valid_597845 = header.getOrDefault("X-Amz-Date")
  valid_597845 = validateParameter(valid_597845, JString, required = false,
                                 default = nil)
  if valid_597845 != nil:
    section.add "X-Amz-Date", valid_597845
  var valid_597846 = header.getOrDefault("X-Amz-Credential")
  valid_597846 = validateParameter(valid_597846, JString, required = false,
                                 default = nil)
  if valid_597846 != nil:
    section.add "X-Amz-Credential", valid_597846
  var valid_597847 = header.getOrDefault("X-Amz-Security-Token")
  valid_597847 = validateParameter(valid_597847, JString, required = false,
                                 default = nil)
  if valid_597847 != nil:
    section.add "X-Amz-Security-Token", valid_597847
  var valid_597848 = header.getOrDefault("X-Amz-Algorithm")
  valid_597848 = validateParameter(valid_597848, JString, required = false,
                                 default = nil)
  if valid_597848 != nil:
    section.add "X-Amz-Algorithm", valid_597848
  var valid_597849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597849 = validateParameter(valid_597849, JString, required = false,
                                 default = nil)
  if valid_597849 != nil:
    section.add "X-Amz-SignedHeaders", valid_597849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_597872: Call_GetApis_597727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of Api resources.
  ## 
  let valid = call_597872.validator(path, query, header, formData, body)
  let scheme = call_597872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597872.url(scheme.get, call_597872.host, call_597872.base,
                         call_597872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597872, url, valid)

proc call*(call_597943: Call_GetApis_597727; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getApis
  ## Gets a collection of Api resources.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var query_597944 = newJObject()
  add(query_597944, "nextToken", newJString(nextToken))
  add(query_597944, "maxResults", newJString(maxResults))
  result = call_597943.call(nil, query_597944, nil, nil, nil)

var getApis* = Call_GetApis_597727(name: "getApis", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/v2/apis", validator: validate_GetApis_597728,
                                base: "/", url: url_GetApis_597729,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApiMapping_598046 = ref object of OpenApiRestCall_597389
proc url_CreateApiMapping_598048(protocol: Scheme; host: string; base: string;
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

proc validate_CreateApiMapping_598047(path: JsonNode; query: JsonNode;
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
  var valid_598049 = path.getOrDefault("domainName")
  valid_598049 = validateParameter(valid_598049, JString, required = true,
                                 default = nil)
  if valid_598049 != nil:
    section.add "domainName", valid_598049
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
  var valid_598050 = header.getOrDefault("X-Amz-Signature")
  valid_598050 = validateParameter(valid_598050, JString, required = false,
                                 default = nil)
  if valid_598050 != nil:
    section.add "X-Amz-Signature", valid_598050
  var valid_598051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598051 = validateParameter(valid_598051, JString, required = false,
                                 default = nil)
  if valid_598051 != nil:
    section.add "X-Amz-Content-Sha256", valid_598051
  var valid_598052 = header.getOrDefault("X-Amz-Date")
  valid_598052 = validateParameter(valid_598052, JString, required = false,
                                 default = nil)
  if valid_598052 != nil:
    section.add "X-Amz-Date", valid_598052
  var valid_598053 = header.getOrDefault("X-Amz-Credential")
  valid_598053 = validateParameter(valid_598053, JString, required = false,
                                 default = nil)
  if valid_598053 != nil:
    section.add "X-Amz-Credential", valid_598053
  var valid_598054 = header.getOrDefault("X-Amz-Security-Token")
  valid_598054 = validateParameter(valid_598054, JString, required = false,
                                 default = nil)
  if valid_598054 != nil:
    section.add "X-Amz-Security-Token", valid_598054
  var valid_598055 = header.getOrDefault("X-Amz-Algorithm")
  valid_598055 = validateParameter(valid_598055, JString, required = false,
                                 default = nil)
  if valid_598055 != nil:
    section.add "X-Amz-Algorithm", valid_598055
  var valid_598056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598056 = validateParameter(valid_598056, JString, required = false,
                                 default = nil)
  if valid_598056 != nil:
    section.add "X-Amz-SignedHeaders", valid_598056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598058: Call_CreateApiMapping_598046; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an API mapping.
  ## 
  let valid = call_598058.validator(path, query, header, formData, body)
  let scheme = call_598058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598058.url(scheme.get, call_598058.host, call_598058.base,
                         call_598058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598058, url, valid)

proc call*(call_598059: Call_CreateApiMapping_598046; body: JsonNode;
          domainName: string): Recallable =
  ## createApiMapping
  ## Creates an API mapping.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : The domain name.
  var path_598060 = newJObject()
  var body_598061 = newJObject()
  if body != nil:
    body_598061 = body
  add(path_598060, "domainName", newJString(domainName))
  result = call_598059.call(path_598060, nil, nil, nil, body_598061)

var createApiMapping* = Call_CreateApiMapping_598046(name: "createApiMapping",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings",
    validator: validate_CreateApiMapping_598047, base: "/",
    url: url_CreateApiMapping_598048, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiMappings_598015 = ref object of OpenApiRestCall_597389
proc url_GetApiMappings_598017(protocol: Scheme; host: string; base: string;
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

proc validate_GetApiMappings_598016(path: JsonNode; query: JsonNode;
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
  var valid_598032 = path.getOrDefault("domainName")
  valid_598032 = validateParameter(valid_598032, JString, required = true,
                                 default = nil)
  if valid_598032 != nil:
    section.add "domainName", valid_598032
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_598033 = query.getOrDefault("nextToken")
  valid_598033 = validateParameter(valid_598033, JString, required = false,
                                 default = nil)
  if valid_598033 != nil:
    section.add "nextToken", valid_598033
  var valid_598034 = query.getOrDefault("maxResults")
  valid_598034 = validateParameter(valid_598034, JString, required = false,
                                 default = nil)
  if valid_598034 != nil:
    section.add "maxResults", valid_598034
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
  var valid_598035 = header.getOrDefault("X-Amz-Signature")
  valid_598035 = validateParameter(valid_598035, JString, required = false,
                                 default = nil)
  if valid_598035 != nil:
    section.add "X-Amz-Signature", valid_598035
  var valid_598036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598036 = validateParameter(valid_598036, JString, required = false,
                                 default = nil)
  if valid_598036 != nil:
    section.add "X-Amz-Content-Sha256", valid_598036
  var valid_598037 = header.getOrDefault("X-Amz-Date")
  valid_598037 = validateParameter(valid_598037, JString, required = false,
                                 default = nil)
  if valid_598037 != nil:
    section.add "X-Amz-Date", valid_598037
  var valid_598038 = header.getOrDefault("X-Amz-Credential")
  valid_598038 = validateParameter(valid_598038, JString, required = false,
                                 default = nil)
  if valid_598038 != nil:
    section.add "X-Amz-Credential", valid_598038
  var valid_598039 = header.getOrDefault("X-Amz-Security-Token")
  valid_598039 = validateParameter(valid_598039, JString, required = false,
                                 default = nil)
  if valid_598039 != nil:
    section.add "X-Amz-Security-Token", valid_598039
  var valid_598040 = header.getOrDefault("X-Amz-Algorithm")
  valid_598040 = validateParameter(valid_598040, JString, required = false,
                                 default = nil)
  if valid_598040 != nil:
    section.add "X-Amz-Algorithm", valid_598040
  var valid_598041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598041 = validateParameter(valid_598041, JString, required = false,
                                 default = nil)
  if valid_598041 != nil:
    section.add "X-Amz-SignedHeaders", valid_598041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598042: Call_GetApiMappings_598015; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets API mappings.
  ## 
  let valid = call_598042.validator(path, query, header, formData, body)
  let scheme = call_598042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598042.url(scheme.get, call_598042.host, call_598042.base,
                         call_598042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598042, url, valid)

proc call*(call_598043: Call_GetApiMappings_598015; domainName: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getApiMappings
  ## Gets API mappings.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_598044 = newJObject()
  var query_598045 = newJObject()
  add(query_598045, "nextToken", newJString(nextToken))
  add(path_598044, "domainName", newJString(domainName))
  add(query_598045, "maxResults", newJString(maxResults))
  result = call_598043.call(path_598044, query_598045, nil, nil, nil)

var getApiMappings* = Call_GetApiMappings_598015(name: "getApiMappings",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings",
    validator: validate_GetApiMappings_598016, base: "/", url: url_GetApiMappings_598017,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAuthorizer_598079 = ref object of OpenApiRestCall_597389
proc url_CreateAuthorizer_598081(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAuthorizer_598080(path: JsonNode; query: JsonNode;
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
  var valid_598082 = path.getOrDefault("apiId")
  valid_598082 = validateParameter(valid_598082, JString, required = true,
                                 default = nil)
  if valid_598082 != nil:
    section.add "apiId", valid_598082
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
  var valid_598083 = header.getOrDefault("X-Amz-Signature")
  valid_598083 = validateParameter(valid_598083, JString, required = false,
                                 default = nil)
  if valid_598083 != nil:
    section.add "X-Amz-Signature", valid_598083
  var valid_598084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598084 = validateParameter(valid_598084, JString, required = false,
                                 default = nil)
  if valid_598084 != nil:
    section.add "X-Amz-Content-Sha256", valid_598084
  var valid_598085 = header.getOrDefault("X-Amz-Date")
  valid_598085 = validateParameter(valid_598085, JString, required = false,
                                 default = nil)
  if valid_598085 != nil:
    section.add "X-Amz-Date", valid_598085
  var valid_598086 = header.getOrDefault("X-Amz-Credential")
  valid_598086 = validateParameter(valid_598086, JString, required = false,
                                 default = nil)
  if valid_598086 != nil:
    section.add "X-Amz-Credential", valid_598086
  var valid_598087 = header.getOrDefault("X-Amz-Security-Token")
  valid_598087 = validateParameter(valid_598087, JString, required = false,
                                 default = nil)
  if valid_598087 != nil:
    section.add "X-Amz-Security-Token", valid_598087
  var valid_598088 = header.getOrDefault("X-Amz-Algorithm")
  valid_598088 = validateParameter(valid_598088, JString, required = false,
                                 default = nil)
  if valid_598088 != nil:
    section.add "X-Amz-Algorithm", valid_598088
  var valid_598089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598089 = validateParameter(valid_598089, JString, required = false,
                                 default = nil)
  if valid_598089 != nil:
    section.add "X-Amz-SignedHeaders", valid_598089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598091: Call_CreateAuthorizer_598079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Authorizer for an API.
  ## 
  let valid = call_598091.validator(path, query, header, formData, body)
  let scheme = call_598091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598091.url(scheme.get, call_598091.host, call_598091.base,
                         call_598091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598091, url, valid)

proc call*(call_598092: Call_CreateAuthorizer_598079; apiId: string; body: JsonNode): Recallable =
  ## createAuthorizer
  ## Creates an Authorizer for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_598093 = newJObject()
  var body_598094 = newJObject()
  add(path_598093, "apiId", newJString(apiId))
  if body != nil:
    body_598094 = body
  result = call_598092.call(path_598093, nil, nil, nil, body_598094)

var createAuthorizer* = Call_CreateAuthorizer_598079(name: "createAuthorizer",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers", validator: validate_CreateAuthorizer_598080,
    base: "/", url: url_CreateAuthorizer_598081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizers_598062 = ref object of OpenApiRestCall_597389
proc url_GetAuthorizers_598064(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizers_598063(path: JsonNode; query: JsonNode;
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
  var valid_598065 = path.getOrDefault("apiId")
  valid_598065 = validateParameter(valid_598065, JString, required = true,
                                 default = nil)
  if valid_598065 != nil:
    section.add "apiId", valid_598065
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_598066 = query.getOrDefault("nextToken")
  valid_598066 = validateParameter(valid_598066, JString, required = false,
                                 default = nil)
  if valid_598066 != nil:
    section.add "nextToken", valid_598066
  var valid_598067 = query.getOrDefault("maxResults")
  valid_598067 = validateParameter(valid_598067, JString, required = false,
                                 default = nil)
  if valid_598067 != nil:
    section.add "maxResults", valid_598067
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
  var valid_598068 = header.getOrDefault("X-Amz-Signature")
  valid_598068 = validateParameter(valid_598068, JString, required = false,
                                 default = nil)
  if valid_598068 != nil:
    section.add "X-Amz-Signature", valid_598068
  var valid_598069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598069 = validateParameter(valid_598069, JString, required = false,
                                 default = nil)
  if valid_598069 != nil:
    section.add "X-Amz-Content-Sha256", valid_598069
  var valid_598070 = header.getOrDefault("X-Amz-Date")
  valid_598070 = validateParameter(valid_598070, JString, required = false,
                                 default = nil)
  if valid_598070 != nil:
    section.add "X-Amz-Date", valid_598070
  var valid_598071 = header.getOrDefault("X-Amz-Credential")
  valid_598071 = validateParameter(valid_598071, JString, required = false,
                                 default = nil)
  if valid_598071 != nil:
    section.add "X-Amz-Credential", valid_598071
  var valid_598072 = header.getOrDefault("X-Amz-Security-Token")
  valid_598072 = validateParameter(valid_598072, JString, required = false,
                                 default = nil)
  if valid_598072 != nil:
    section.add "X-Amz-Security-Token", valid_598072
  var valid_598073 = header.getOrDefault("X-Amz-Algorithm")
  valid_598073 = validateParameter(valid_598073, JString, required = false,
                                 default = nil)
  if valid_598073 != nil:
    section.add "X-Amz-Algorithm", valid_598073
  var valid_598074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598074 = validateParameter(valid_598074, JString, required = false,
                                 default = nil)
  if valid_598074 != nil:
    section.add "X-Amz-SignedHeaders", valid_598074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598075: Call_GetAuthorizers_598062; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Authorizers for an API.
  ## 
  let valid = call_598075.validator(path, query, header, formData, body)
  let scheme = call_598075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598075.url(scheme.get, call_598075.host, call_598075.base,
                         call_598075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598075, url, valid)

proc call*(call_598076: Call_GetAuthorizers_598062; apiId: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getAuthorizers
  ## Gets the Authorizers for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_598077 = newJObject()
  var query_598078 = newJObject()
  add(query_598078, "nextToken", newJString(nextToken))
  add(path_598077, "apiId", newJString(apiId))
  add(query_598078, "maxResults", newJString(maxResults))
  result = call_598076.call(path_598077, query_598078, nil, nil, nil)

var getAuthorizers* = Call_GetAuthorizers_598062(name: "getAuthorizers",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers", validator: validate_GetAuthorizers_598063,
    base: "/", url: url_GetAuthorizers_598064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_598112 = ref object of OpenApiRestCall_597389
proc url_CreateDeployment_598114(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeployment_598113(path: JsonNode; query: JsonNode;
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
  var valid_598115 = path.getOrDefault("apiId")
  valid_598115 = validateParameter(valid_598115, JString, required = true,
                                 default = nil)
  if valid_598115 != nil:
    section.add "apiId", valid_598115
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
  var valid_598116 = header.getOrDefault("X-Amz-Signature")
  valid_598116 = validateParameter(valid_598116, JString, required = false,
                                 default = nil)
  if valid_598116 != nil:
    section.add "X-Amz-Signature", valid_598116
  var valid_598117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598117 = validateParameter(valid_598117, JString, required = false,
                                 default = nil)
  if valid_598117 != nil:
    section.add "X-Amz-Content-Sha256", valid_598117
  var valid_598118 = header.getOrDefault("X-Amz-Date")
  valid_598118 = validateParameter(valid_598118, JString, required = false,
                                 default = nil)
  if valid_598118 != nil:
    section.add "X-Amz-Date", valid_598118
  var valid_598119 = header.getOrDefault("X-Amz-Credential")
  valid_598119 = validateParameter(valid_598119, JString, required = false,
                                 default = nil)
  if valid_598119 != nil:
    section.add "X-Amz-Credential", valid_598119
  var valid_598120 = header.getOrDefault("X-Amz-Security-Token")
  valid_598120 = validateParameter(valid_598120, JString, required = false,
                                 default = nil)
  if valid_598120 != nil:
    section.add "X-Amz-Security-Token", valid_598120
  var valid_598121 = header.getOrDefault("X-Amz-Algorithm")
  valid_598121 = validateParameter(valid_598121, JString, required = false,
                                 default = nil)
  if valid_598121 != nil:
    section.add "X-Amz-Algorithm", valid_598121
  var valid_598122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598122 = validateParameter(valid_598122, JString, required = false,
                                 default = nil)
  if valid_598122 != nil:
    section.add "X-Amz-SignedHeaders", valid_598122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598124: Call_CreateDeployment_598112; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Deployment for an API.
  ## 
  let valid = call_598124.validator(path, query, header, formData, body)
  let scheme = call_598124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598124.url(scheme.get, call_598124.host, call_598124.base,
                         call_598124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598124, url, valid)

proc call*(call_598125: Call_CreateDeployment_598112; apiId: string; body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a Deployment for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_598126 = newJObject()
  var body_598127 = newJObject()
  add(path_598126, "apiId", newJString(apiId))
  if body != nil:
    body_598127 = body
  result = call_598125.call(path_598126, nil, nil, nil, body_598127)

var createDeployment* = Call_CreateDeployment_598112(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments", validator: validate_CreateDeployment_598113,
    base: "/", url: url_CreateDeployment_598114,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployments_598095 = ref object of OpenApiRestCall_597389
proc url_GetDeployments_598097(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployments_598096(path: JsonNode; query: JsonNode;
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
  var valid_598098 = path.getOrDefault("apiId")
  valid_598098 = validateParameter(valid_598098, JString, required = true,
                                 default = nil)
  if valid_598098 != nil:
    section.add "apiId", valid_598098
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_598099 = query.getOrDefault("nextToken")
  valid_598099 = validateParameter(valid_598099, JString, required = false,
                                 default = nil)
  if valid_598099 != nil:
    section.add "nextToken", valid_598099
  var valid_598100 = query.getOrDefault("maxResults")
  valid_598100 = validateParameter(valid_598100, JString, required = false,
                                 default = nil)
  if valid_598100 != nil:
    section.add "maxResults", valid_598100
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
  var valid_598101 = header.getOrDefault("X-Amz-Signature")
  valid_598101 = validateParameter(valid_598101, JString, required = false,
                                 default = nil)
  if valid_598101 != nil:
    section.add "X-Amz-Signature", valid_598101
  var valid_598102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598102 = validateParameter(valid_598102, JString, required = false,
                                 default = nil)
  if valid_598102 != nil:
    section.add "X-Amz-Content-Sha256", valid_598102
  var valid_598103 = header.getOrDefault("X-Amz-Date")
  valid_598103 = validateParameter(valid_598103, JString, required = false,
                                 default = nil)
  if valid_598103 != nil:
    section.add "X-Amz-Date", valid_598103
  var valid_598104 = header.getOrDefault("X-Amz-Credential")
  valid_598104 = validateParameter(valid_598104, JString, required = false,
                                 default = nil)
  if valid_598104 != nil:
    section.add "X-Amz-Credential", valid_598104
  var valid_598105 = header.getOrDefault("X-Amz-Security-Token")
  valid_598105 = validateParameter(valid_598105, JString, required = false,
                                 default = nil)
  if valid_598105 != nil:
    section.add "X-Amz-Security-Token", valid_598105
  var valid_598106 = header.getOrDefault("X-Amz-Algorithm")
  valid_598106 = validateParameter(valid_598106, JString, required = false,
                                 default = nil)
  if valid_598106 != nil:
    section.add "X-Amz-Algorithm", valid_598106
  var valid_598107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598107 = validateParameter(valid_598107, JString, required = false,
                                 default = nil)
  if valid_598107 != nil:
    section.add "X-Amz-SignedHeaders", valid_598107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598108: Call_GetDeployments_598095; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Deployments for an API.
  ## 
  let valid = call_598108.validator(path, query, header, formData, body)
  let scheme = call_598108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598108.url(scheme.get, call_598108.host, call_598108.base,
                         call_598108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598108, url, valid)

proc call*(call_598109: Call_GetDeployments_598095; apiId: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getDeployments
  ## Gets the Deployments for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_598110 = newJObject()
  var query_598111 = newJObject()
  add(query_598111, "nextToken", newJString(nextToken))
  add(path_598110, "apiId", newJString(apiId))
  add(query_598111, "maxResults", newJString(maxResults))
  result = call_598109.call(path_598110, query_598111, nil, nil, nil)

var getDeployments* = Call_GetDeployments_598095(name: "getDeployments",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments", validator: validate_GetDeployments_598096,
    base: "/", url: url_GetDeployments_598097, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainName_598143 = ref object of OpenApiRestCall_597389
proc url_CreateDomainName_598145(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDomainName_598144(path: JsonNode; query: JsonNode;
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
  var valid_598146 = header.getOrDefault("X-Amz-Signature")
  valid_598146 = validateParameter(valid_598146, JString, required = false,
                                 default = nil)
  if valid_598146 != nil:
    section.add "X-Amz-Signature", valid_598146
  var valid_598147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598147 = validateParameter(valid_598147, JString, required = false,
                                 default = nil)
  if valid_598147 != nil:
    section.add "X-Amz-Content-Sha256", valid_598147
  var valid_598148 = header.getOrDefault("X-Amz-Date")
  valid_598148 = validateParameter(valid_598148, JString, required = false,
                                 default = nil)
  if valid_598148 != nil:
    section.add "X-Amz-Date", valid_598148
  var valid_598149 = header.getOrDefault("X-Amz-Credential")
  valid_598149 = validateParameter(valid_598149, JString, required = false,
                                 default = nil)
  if valid_598149 != nil:
    section.add "X-Amz-Credential", valid_598149
  var valid_598150 = header.getOrDefault("X-Amz-Security-Token")
  valid_598150 = validateParameter(valid_598150, JString, required = false,
                                 default = nil)
  if valid_598150 != nil:
    section.add "X-Amz-Security-Token", valid_598150
  var valid_598151 = header.getOrDefault("X-Amz-Algorithm")
  valid_598151 = validateParameter(valid_598151, JString, required = false,
                                 default = nil)
  if valid_598151 != nil:
    section.add "X-Amz-Algorithm", valid_598151
  var valid_598152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598152 = validateParameter(valid_598152, JString, required = false,
                                 default = nil)
  if valid_598152 != nil:
    section.add "X-Amz-SignedHeaders", valid_598152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598154: Call_CreateDomainName_598143; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a domain name.
  ## 
  let valid = call_598154.validator(path, query, header, formData, body)
  let scheme = call_598154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598154.url(scheme.get, call_598154.host, call_598154.base,
                         call_598154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598154, url, valid)

proc call*(call_598155: Call_CreateDomainName_598143; body: JsonNode): Recallable =
  ## createDomainName
  ## Creates a domain name.
  ##   body: JObject (required)
  var body_598156 = newJObject()
  if body != nil:
    body_598156 = body
  result = call_598155.call(nil, nil, nil, nil, body_598156)

var createDomainName* = Call_CreateDomainName_598143(name: "createDomainName",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames", validator: validate_CreateDomainName_598144,
    base: "/", url: url_CreateDomainName_598145,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainNames_598128 = ref object of OpenApiRestCall_597389
proc url_GetDomainNames_598130(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainNames_598129(path: JsonNode; query: JsonNode;
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
  var valid_598131 = query.getOrDefault("nextToken")
  valid_598131 = validateParameter(valid_598131, JString, required = false,
                                 default = nil)
  if valid_598131 != nil:
    section.add "nextToken", valid_598131
  var valid_598132 = query.getOrDefault("maxResults")
  valid_598132 = validateParameter(valid_598132, JString, required = false,
                                 default = nil)
  if valid_598132 != nil:
    section.add "maxResults", valid_598132
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
  var valid_598133 = header.getOrDefault("X-Amz-Signature")
  valid_598133 = validateParameter(valid_598133, JString, required = false,
                                 default = nil)
  if valid_598133 != nil:
    section.add "X-Amz-Signature", valid_598133
  var valid_598134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598134 = validateParameter(valid_598134, JString, required = false,
                                 default = nil)
  if valid_598134 != nil:
    section.add "X-Amz-Content-Sha256", valid_598134
  var valid_598135 = header.getOrDefault("X-Amz-Date")
  valid_598135 = validateParameter(valid_598135, JString, required = false,
                                 default = nil)
  if valid_598135 != nil:
    section.add "X-Amz-Date", valid_598135
  var valid_598136 = header.getOrDefault("X-Amz-Credential")
  valid_598136 = validateParameter(valid_598136, JString, required = false,
                                 default = nil)
  if valid_598136 != nil:
    section.add "X-Amz-Credential", valid_598136
  var valid_598137 = header.getOrDefault("X-Amz-Security-Token")
  valid_598137 = validateParameter(valid_598137, JString, required = false,
                                 default = nil)
  if valid_598137 != nil:
    section.add "X-Amz-Security-Token", valid_598137
  var valid_598138 = header.getOrDefault("X-Amz-Algorithm")
  valid_598138 = validateParameter(valid_598138, JString, required = false,
                                 default = nil)
  if valid_598138 != nil:
    section.add "X-Amz-Algorithm", valid_598138
  var valid_598139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598139 = validateParameter(valid_598139, JString, required = false,
                                 default = nil)
  if valid_598139 != nil:
    section.add "X-Amz-SignedHeaders", valid_598139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598140: Call_GetDomainNames_598128; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the domain names for an AWS account.
  ## 
  let valid = call_598140.validator(path, query, header, formData, body)
  let scheme = call_598140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598140.url(scheme.get, call_598140.host, call_598140.base,
                         call_598140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598140, url, valid)

proc call*(call_598141: Call_GetDomainNames_598128; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getDomainNames
  ## Gets the domain names for an AWS account.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var query_598142 = newJObject()
  add(query_598142, "nextToken", newJString(nextToken))
  add(query_598142, "maxResults", newJString(maxResults))
  result = call_598141.call(nil, query_598142, nil, nil, nil)

var getDomainNames* = Call_GetDomainNames_598128(name: "getDomainNames",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames", validator: validate_GetDomainNames_598129, base: "/",
    url: url_GetDomainNames_598130, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntegration_598174 = ref object of OpenApiRestCall_597389
proc url_CreateIntegration_598176(protocol: Scheme; host: string; base: string;
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

proc validate_CreateIntegration_598175(path: JsonNode; query: JsonNode;
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
  var valid_598177 = path.getOrDefault("apiId")
  valid_598177 = validateParameter(valid_598177, JString, required = true,
                                 default = nil)
  if valid_598177 != nil:
    section.add "apiId", valid_598177
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
  var valid_598178 = header.getOrDefault("X-Amz-Signature")
  valid_598178 = validateParameter(valid_598178, JString, required = false,
                                 default = nil)
  if valid_598178 != nil:
    section.add "X-Amz-Signature", valid_598178
  var valid_598179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598179 = validateParameter(valid_598179, JString, required = false,
                                 default = nil)
  if valid_598179 != nil:
    section.add "X-Amz-Content-Sha256", valid_598179
  var valid_598180 = header.getOrDefault("X-Amz-Date")
  valid_598180 = validateParameter(valid_598180, JString, required = false,
                                 default = nil)
  if valid_598180 != nil:
    section.add "X-Amz-Date", valid_598180
  var valid_598181 = header.getOrDefault("X-Amz-Credential")
  valid_598181 = validateParameter(valid_598181, JString, required = false,
                                 default = nil)
  if valid_598181 != nil:
    section.add "X-Amz-Credential", valid_598181
  var valid_598182 = header.getOrDefault("X-Amz-Security-Token")
  valid_598182 = validateParameter(valid_598182, JString, required = false,
                                 default = nil)
  if valid_598182 != nil:
    section.add "X-Amz-Security-Token", valid_598182
  var valid_598183 = header.getOrDefault("X-Amz-Algorithm")
  valid_598183 = validateParameter(valid_598183, JString, required = false,
                                 default = nil)
  if valid_598183 != nil:
    section.add "X-Amz-Algorithm", valid_598183
  var valid_598184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598184 = validateParameter(valid_598184, JString, required = false,
                                 default = nil)
  if valid_598184 != nil:
    section.add "X-Amz-SignedHeaders", valid_598184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598186: Call_CreateIntegration_598174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Integration.
  ## 
  let valid = call_598186.validator(path, query, header, formData, body)
  let scheme = call_598186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598186.url(scheme.get, call_598186.host, call_598186.base,
                         call_598186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598186, url, valid)

proc call*(call_598187: Call_CreateIntegration_598174; apiId: string; body: JsonNode): Recallable =
  ## createIntegration
  ## Creates an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_598188 = newJObject()
  var body_598189 = newJObject()
  add(path_598188, "apiId", newJString(apiId))
  if body != nil:
    body_598189 = body
  result = call_598187.call(path_598188, nil, nil, nil, body_598189)

var createIntegration* = Call_CreateIntegration_598174(name: "createIntegration",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations", validator: validate_CreateIntegration_598175,
    base: "/", url: url_CreateIntegration_598176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrations_598157 = ref object of OpenApiRestCall_597389
proc url_GetIntegrations_598159(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegrations_598158(path: JsonNode; query: JsonNode;
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
  var valid_598160 = path.getOrDefault("apiId")
  valid_598160 = validateParameter(valid_598160, JString, required = true,
                                 default = nil)
  if valid_598160 != nil:
    section.add "apiId", valid_598160
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_598161 = query.getOrDefault("nextToken")
  valid_598161 = validateParameter(valid_598161, JString, required = false,
                                 default = nil)
  if valid_598161 != nil:
    section.add "nextToken", valid_598161
  var valid_598162 = query.getOrDefault("maxResults")
  valid_598162 = validateParameter(valid_598162, JString, required = false,
                                 default = nil)
  if valid_598162 != nil:
    section.add "maxResults", valid_598162
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
  var valid_598163 = header.getOrDefault("X-Amz-Signature")
  valid_598163 = validateParameter(valid_598163, JString, required = false,
                                 default = nil)
  if valid_598163 != nil:
    section.add "X-Amz-Signature", valid_598163
  var valid_598164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598164 = validateParameter(valid_598164, JString, required = false,
                                 default = nil)
  if valid_598164 != nil:
    section.add "X-Amz-Content-Sha256", valid_598164
  var valid_598165 = header.getOrDefault("X-Amz-Date")
  valid_598165 = validateParameter(valid_598165, JString, required = false,
                                 default = nil)
  if valid_598165 != nil:
    section.add "X-Amz-Date", valid_598165
  var valid_598166 = header.getOrDefault("X-Amz-Credential")
  valid_598166 = validateParameter(valid_598166, JString, required = false,
                                 default = nil)
  if valid_598166 != nil:
    section.add "X-Amz-Credential", valid_598166
  var valid_598167 = header.getOrDefault("X-Amz-Security-Token")
  valid_598167 = validateParameter(valid_598167, JString, required = false,
                                 default = nil)
  if valid_598167 != nil:
    section.add "X-Amz-Security-Token", valid_598167
  var valid_598168 = header.getOrDefault("X-Amz-Algorithm")
  valid_598168 = validateParameter(valid_598168, JString, required = false,
                                 default = nil)
  if valid_598168 != nil:
    section.add "X-Amz-Algorithm", valid_598168
  var valid_598169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598169 = validateParameter(valid_598169, JString, required = false,
                                 default = nil)
  if valid_598169 != nil:
    section.add "X-Amz-SignedHeaders", valid_598169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598170: Call_GetIntegrations_598157; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Integrations for an API.
  ## 
  let valid = call_598170.validator(path, query, header, formData, body)
  let scheme = call_598170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598170.url(scheme.get, call_598170.host, call_598170.base,
                         call_598170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598170, url, valid)

proc call*(call_598171: Call_GetIntegrations_598157; apiId: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getIntegrations
  ## Gets the Integrations for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_598172 = newJObject()
  var query_598173 = newJObject()
  add(query_598173, "nextToken", newJString(nextToken))
  add(path_598172, "apiId", newJString(apiId))
  add(query_598173, "maxResults", newJString(maxResults))
  result = call_598171.call(path_598172, query_598173, nil, nil, nil)

var getIntegrations* = Call_GetIntegrations_598157(name: "getIntegrations",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations", validator: validate_GetIntegrations_598158,
    base: "/", url: url_GetIntegrations_598159, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntegrationResponse_598208 = ref object of OpenApiRestCall_597389
proc url_CreateIntegrationResponse_598210(protocol: Scheme; host: string;
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

proc validate_CreateIntegrationResponse_598209(path: JsonNode; query: JsonNode;
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
  var valid_598211 = path.getOrDefault("apiId")
  valid_598211 = validateParameter(valid_598211, JString, required = true,
                                 default = nil)
  if valid_598211 != nil:
    section.add "apiId", valid_598211
  var valid_598212 = path.getOrDefault("integrationId")
  valid_598212 = validateParameter(valid_598212, JString, required = true,
                                 default = nil)
  if valid_598212 != nil:
    section.add "integrationId", valid_598212
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
  var valid_598213 = header.getOrDefault("X-Amz-Signature")
  valid_598213 = validateParameter(valid_598213, JString, required = false,
                                 default = nil)
  if valid_598213 != nil:
    section.add "X-Amz-Signature", valid_598213
  var valid_598214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598214 = validateParameter(valid_598214, JString, required = false,
                                 default = nil)
  if valid_598214 != nil:
    section.add "X-Amz-Content-Sha256", valid_598214
  var valid_598215 = header.getOrDefault("X-Amz-Date")
  valid_598215 = validateParameter(valid_598215, JString, required = false,
                                 default = nil)
  if valid_598215 != nil:
    section.add "X-Amz-Date", valid_598215
  var valid_598216 = header.getOrDefault("X-Amz-Credential")
  valid_598216 = validateParameter(valid_598216, JString, required = false,
                                 default = nil)
  if valid_598216 != nil:
    section.add "X-Amz-Credential", valid_598216
  var valid_598217 = header.getOrDefault("X-Amz-Security-Token")
  valid_598217 = validateParameter(valid_598217, JString, required = false,
                                 default = nil)
  if valid_598217 != nil:
    section.add "X-Amz-Security-Token", valid_598217
  var valid_598218 = header.getOrDefault("X-Amz-Algorithm")
  valid_598218 = validateParameter(valid_598218, JString, required = false,
                                 default = nil)
  if valid_598218 != nil:
    section.add "X-Amz-Algorithm", valid_598218
  var valid_598219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598219 = validateParameter(valid_598219, JString, required = false,
                                 default = nil)
  if valid_598219 != nil:
    section.add "X-Amz-SignedHeaders", valid_598219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598221: Call_CreateIntegrationResponse_598208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an IntegrationResponses.
  ## 
  let valid = call_598221.validator(path, query, header, formData, body)
  let scheme = call_598221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598221.url(scheme.get, call_598221.host, call_598221.base,
                         call_598221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598221, url, valid)

proc call*(call_598222: Call_CreateIntegrationResponse_598208; apiId: string;
          integrationId: string; body: JsonNode): Recallable =
  ## createIntegrationResponse
  ## Creates an IntegrationResponses.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  ##   body: JObject (required)
  var path_598223 = newJObject()
  var body_598224 = newJObject()
  add(path_598223, "apiId", newJString(apiId))
  add(path_598223, "integrationId", newJString(integrationId))
  if body != nil:
    body_598224 = body
  result = call_598222.call(path_598223, nil, nil, nil, body_598224)

var createIntegrationResponse* = Call_CreateIntegrationResponse_598208(
    name: "createIntegrationResponse", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses",
    validator: validate_CreateIntegrationResponse_598209, base: "/",
    url: url_CreateIntegrationResponse_598210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponses_598190 = ref object of OpenApiRestCall_597389
proc url_GetIntegrationResponses_598192(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegrationResponses_598191(path: JsonNode; query: JsonNode;
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
  var valid_598193 = path.getOrDefault("apiId")
  valid_598193 = validateParameter(valid_598193, JString, required = true,
                                 default = nil)
  if valid_598193 != nil:
    section.add "apiId", valid_598193
  var valid_598194 = path.getOrDefault("integrationId")
  valid_598194 = validateParameter(valid_598194, JString, required = true,
                                 default = nil)
  if valid_598194 != nil:
    section.add "integrationId", valid_598194
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_598195 = query.getOrDefault("nextToken")
  valid_598195 = validateParameter(valid_598195, JString, required = false,
                                 default = nil)
  if valid_598195 != nil:
    section.add "nextToken", valid_598195
  var valid_598196 = query.getOrDefault("maxResults")
  valid_598196 = validateParameter(valid_598196, JString, required = false,
                                 default = nil)
  if valid_598196 != nil:
    section.add "maxResults", valid_598196
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
  var valid_598197 = header.getOrDefault("X-Amz-Signature")
  valid_598197 = validateParameter(valid_598197, JString, required = false,
                                 default = nil)
  if valid_598197 != nil:
    section.add "X-Amz-Signature", valid_598197
  var valid_598198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598198 = validateParameter(valid_598198, JString, required = false,
                                 default = nil)
  if valid_598198 != nil:
    section.add "X-Amz-Content-Sha256", valid_598198
  var valid_598199 = header.getOrDefault("X-Amz-Date")
  valid_598199 = validateParameter(valid_598199, JString, required = false,
                                 default = nil)
  if valid_598199 != nil:
    section.add "X-Amz-Date", valid_598199
  var valid_598200 = header.getOrDefault("X-Amz-Credential")
  valid_598200 = validateParameter(valid_598200, JString, required = false,
                                 default = nil)
  if valid_598200 != nil:
    section.add "X-Amz-Credential", valid_598200
  var valid_598201 = header.getOrDefault("X-Amz-Security-Token")
  valid_598201 = validateParameter(valid_598201, JString, required = false,
                                 default = nil)
  if valid_598201 != nil:
    section.add "X-Amz-Security-Token", valid_598201
  var valid_598202 = header.getOrDefault("X-Amz-Algorithm")
  valid_598202 = validateParameter(valid_598202, JString, required = false,
                                 default = nil)
  if valid_598202 != nil:
    section.add "X-Amz-Algorithm", valid_598202
  var valid_598203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598203 = validateParameter(valid_598203, JString, required = false,
                                 default = nil)
  if valid_598203 != nil:
    section.add "X-Amz-SignedHeaders", valid_598203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598204: Call_GetIntegrationResponses_598190; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the IntegrationResponses for an Integration.
  ## 
  let valid = call_598204.validator(path, query, header, formData, body)
  let scheme = call_598204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598204.url(scheme.get, call_598204.host, call_598204.base,
                         call_598204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598204, url, valid)

proc call*(call_598205: Call_GetIntegrationResponses_598190; apiId: string;
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
  var path_598206 = newJObject()
  var query_598207 = newJObject()
  add(query_598207, "nextToken", newJString(nextToken))
  add(path_598206, "apiId", newJString(apiId))
  add(path_598206, "integrationId", newJString(integrationId))
  add(query_598207, "maxResults", newJString(maxResults))
  result = call_598205.call(path_598206, query_598207, nil, nil, nil)

var getIntegrationResponses* = Call_GetIntegrationResponses_598190(
    name: "getIntegrationResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses",
    validator: validate_GetIntegrationResponses_598191, base: "/",
    url: url_GetIntegrationResponses_598192, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_598242 = ref object of OpenApiRestCall_597389
proc url_CreateModel_598244(protocol: Scheme; host: string; base: string;
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

proc validate_CreateModel_598243(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598245 = path.getOrDefault("apiId")
  valid_598245 = validateParameter(valid_598245, JString, required = true,
                                 default = nil)
  if valid_598245 != nil:
    section.add "apiId", valid_598245
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
  var valid_598246 = header.getOrDefault("X-Amz-Signature")
  valid_598246 = validateParameter(valid_598246, JString, required = false,
                                 default = nil)
  if valid_598246 != nil:
    section.add "X-Amz-Signature", valid_598246
  var valid_598247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598247 = validateParameter(valid_598247, JString, required = false,
                                 default = nil)
  if valid_598247 != nil:
    section.add "X-Amz-Content-Sha256", valid_598247
  var valid_598248 = header.getOrDefault("X-Amz-Date")
  valid_598248 = validateParameter(valid_598248, JString, required = false,
                                 default = nil)
  if valid_598248 != nil:
    section.add "X-Amz-Date", valid_598248
  var valid_598249 = header.getOrDefault("X-Amz-Credential")
  valid_598249 = validateParameter(valid_598249, JString, required = false,
                                 default = nil)
  if valid_598249 != nil:
    section.add "X-Amz-Credential", valid_598249
  var valid_598250 = header.getOrDefault("X-Amz-Security-Token")
  valid_598250 = validateParameter(valid_598250, JString, required = false,
                                 default = nil)
  if valid_598250 != nil:
    section.add "X-Amz-Security-Token", valid_598250
  var valid_598251 = header.getOrDefault("X-Amz-Algorithm")
  valid_598251 = validateParameter(valid_598251, JString, required = false,
                                 default = nil)
  if valid_598251 != nil:
    section.add "X-Amz-Algorithm", valid_598251
  var valid_598252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598252 = validateParameter(valid_598252, JString, required = false,
                                 default = nil)
  if valid_598252 != nil:
    section.add "X-Amz-SignedHeaders", valid_598252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598254: Call_CreateModel_598242; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Model for an API.
  ## 
  let valid = call_598254.validator(path, query, header, formData, body)
  let scheme = call_598254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598254.url(scheme.get, call_598254.host, call_598254.base,
                         call_598254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598254, url, valid)

proc call*(call_598255: Call_CreateModel_598242; apiId: string; body: JsonNode): Recallable =
  ## createModel
  ## Creates a Model for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_598256 = newJObject()
  var body_598257 = newJObject()
  add(path_598256, "apiId", newJString(apiId))
  if body != nil:
    body_598257 = body
  result = call_598255.call(path_598256, nil, nil, nil, body_598257)

var createModel* = Call_CreateModel_598242(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/models",
                                        validator: validate_CreateModel_598243,
                                        base: "/", url: url_CreateModel_598244,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_598225 = ref object of OpenApiRestCall_597389
proc url_GetModels_598227(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetModels_598226(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598228 = path.getOrDefault("apiId")
  valid_598228 = validateParameter(valid_598228, JString, required = true,
                                 default = nil)
  if valid_598228 != nil:
    section.add "apiId", valid_598228
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_598229 = query.getOrDefault("nextToken")
  valid_598229 = validateParameter(valid_598229, JString, required = false,
                                 default = nil)
  if valid_598229 != nil:
    section.add "nextToken", valid_598229
  var valid_598230 = query.getOrDefault("maxResults")
  valid_598230 = validateParameter(valid_598230, JString, required = false,
                                 default = nil)
  if valid_598230 != nil:
    section.add "maxResults", valid_598230
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
  var valid_598231 = header.getOrDefault("X-Amz-Signature")
  valid_598231 = validateParameter(valid_598231, JString, required = false,
                                 default = nil)
  if valid_598231 != nil:
    section.add "X-Amz-Signature", valid_598231
  var valid_598232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598232 = validateParameter(valid_598232, JString, required = false,
                                 default = nil)
  if valid_598232 != nil:
    section.add "X-Amz-Content-Sha256", valid_598232
  var valid_598233 = header.getOrDefault("X-Amz-Date")
  valid_598233 = validateParameter(valid_598233, JString, required = false,
                                 default = nil)
  if valid_598233 != nil:
    section.add "X-Amz-Date", valid_598233
  var valid_598234 = header.getOrDefault("X-Amz-Credential")
  valid_598234 = validateParameter(valid_598234, JString, required = false,
                                 default = nil)
  if valid_598234 != nil:
    section.add "X-Amz-Credential", valid_598234
  var valid_598235 = header.getOrDefault("X-Amz-Security-Token")
  valid_598235 = validateParameter(valid_598235, JString, required = false,
                                 default = nil)
  if valid_598235 != nil:
    section.add "X-Amz-Security-Token", valid_598235
  var valid_598236 = header.getOrDefault("X-Amz-Algorithm")
  valid_598236 = validateParameter(valid_598236, JString, required = false,
                                 default = nil)
  if valid_598236 != nil:
    section.add "X-Amz-Algorithm", valid_598236
  var valid_598237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598237 = validateParameter(valid_598237, JString, required = false,
                                 default = nil)
  if valid_598237 != nil:
    section.add "X-Amz-SignedHeaders", valid_598237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598238: Call_GetModels_598225; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Models for an API.
  ## 
  let valid = call_598238.validator(path, query, header, formData, body)
  let scheme = call_598238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598238.url(scheme.get, call_598238.host, call_598238.base,
                         call_598238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598238, url, valid)

proc call*(call_598239: Call_GetModels_598225; apiId: string; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getModels
  ## Gets the Models for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_598240 = newJObject()
  var query_598241 = newJObject()
  add(query_598241, "nextToken", newJString(nextToken))
  add(path_598240, "apiId", newJString(apiId))
  add(query_598241, "maxResults", newJString(maxResults))
  result = call_598239.call(path_598240, query_598241, nil, nil, nil)

var getModels* = Call_GetModels_598225(name: "getModels", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/models",
                                    validator: validate_GetModels_598226,
                                    base: "/", url: url_GetModels_598227,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoute_598275 = ref object of OpenApiRestCall_597389
proc url_CreateRoute_598277(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRoute_598276(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598278 = path.getOrDefault("apiId")
  valid_598278 = validateParameter(valid_598278, JString, required = true,
                                 default = nil)
  if valid_598278 != nil:
    section.add "apiId", valid_598278
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
  var valid_598279 = header.getOrDefault("X-Amz-Signature")
  valid_598279 = validateParameter(valid_598279, JString, required = false,
                                 default = nil)
  if valid_598279 != nil:
    section.add "X-Amz-Signature", valid_598279
  var valid_598280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598280 = validateParameter(valid_598280, JString, required = false,
                                 default = nil)
  if valid_598280 != nil:
    section.add "X-Amz-Content-Sha256", valid_598280
  var valid_598281 = header.getOrDefault("X-Amz-Date")
  valid_598281 = validateParameter(valid_598281, JString, required = false,
                                 default = nil)
  if valid_598281 != nil:
    section.add "X-Amz-Date", valid_598281
  var valid_598282 = header.getOrDefault("X-Amz-Credential")
  valid_598282 = validateParameter(valid_598282, JString, required = false,
                                 default = nil)
  if valid_598282 != nil:
    section.add "X-Amz-Credential", valid_598282
  var valid_598283 = header.getOrDefault("X-Amz-Security-Token")
  valid_598283 = validateParameter(valid_598283, JString, required = false,
                                 default = nil)
  if valid_598283 != nil:
    section.add "X-Amz-Security-Token", valid_598283
  var valid_598284 = header.getOrDefault("X-Amz-Algorithm")
  valid_598284 = validateParameter(valid_598284, JString, required = false,
                                 default = nil)
  if valid_598284 != nil:
    section.add "X-Amz-Algorithm", valid_598284
  var valid_598285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598285 = validateParameter(valid_598285, JString, required = false,
                                 default = nil)
  if valid_598285 != nil:
    section.add "X-Amz-SignedHeaders", valid_598285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598287: Call_CreateRoute_598275; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Route for an API.
  ## 
  let valid = call_598287.validator(path, query, header, formData, body)
  let scheme = call_598287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598287.url(scheme.get, call_598287.host, call_598287.base,
                         call_598287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598287, url, valid)

proc call*(call_598288: Call_CreateRoute_598275; apiId: string; body: JsonNode): Recallable =
  ## createRoute
  ## Creates a Route for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_598289 = newJObject()
  var body_598290 = newJObject()
  add(path_598289, "apiId", newJString(apiId))
  if body != nil:
    body_598290 = body
  result = call_598288.call(path_598289, nil, nil, nil, body_598290)

var createRoute* = Call_CreateRoute_598275(name: "createRoute",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/routes",
                                        validator: validate_CreateRoute_598276,
                                        base: "/", url: url_CreateRoute_598277,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoutes_598258 = ref object of OpenApiRestCall_597389
proc url_GetRoutes_598260(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRoutes_598259(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598261 = path.getOrDefault("apiId")
  valid_598261 = validateParameter(valid_598261, JString, required = true,
                                 default = nil)
  if valid_598261 != nil:
    section.add "apiId", valid_598261
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_598262 = query.getOrDefault("nextToken")
  valid_598262 = validateParameter(valid_598262, JString, required = false,
                                 default = nil)
  if valid_598262 != nil:
    section.add "nextToken", valid_598262
  var valid_598263 = query.getOrDefault("maxResults")
  valid_598263 = validateParameter(valid_598263, JString, required = false,
                                 default = nil)
  if valid_598263 != nil:
    section.add "maxResults", valid_598263
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
  var valid_598264 = header.getOrDefault("X-Amz-Signature")
  valid_598264 = validateParameter(valid_598264, JString, required = false,
                                 default = nil)
  if valid_598264 != nil:
    section.add "X-Amz-Signature", valid_598264
  var valid_598265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598265 = validateParameter(valid_598265, JString, required = false,
                                 default = nil)
  if valid_598265 != nil:
    section.add "X-Amz-Content-Sha256", valid_598265
  var valid_598266 = header.getOrDefault("X-Amz-Date")
  valid_598266 = validateParameter(valid_598266, JString, required = false,
                                 default = nil)
  if valid_598266 != nil:
    section.add "X-Amz-Date", valid_598266
  var valid_598267 = header.getOrDefault("X-Amz-Credential")
  valid_598267 = validateParameter(valid_598267, JString, required = false,
                                 default = nil)
  if valid_598267 != nil:
    section.add "X-Amz-Credential", valid_598267
  var valid_598268 = header.getOrDefault("X-Amz-Security-Token")
  valid_598268 = validateParameter(valid_598268, JString, required = false,
                                 default = nil)
  if valid_598268 != nil:
    section.add "X-Amz-Security-Token", valid_598268
  var valid_598269 = header.getOrDefault("X-Amz-Algorithm")
  valid_598269 = validateParameter(valid_598269, JString, required = false,
                                 default = nil)
  if valid_598269 != nil:
    section.add "X-Amz-Algorithm", valid_598269
  var valid_598270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598270 = validateParameter(valid_598270, JString, required = false,
                                 default = nil)
  if valid_598270 != nil:
    section.add "X-Amz-SignedHeaders", valid_598270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598271: Call_GetRoutes_598258; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Routes for an API.
  ## 
  let valid = call_598271.validator(path, query, header, formData, body)
  let scheme = call_598271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598271.url(scheme.get, call_598271.host, call_598271.base,
                         call_598271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598271, url, valid)

proc call*(call_598272: Call_GetRoutes_598258; apiId: string; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getRoutes
  ## Gets the Routes for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_598273 = newJObject()
  var query_598274 = newJObject()
  add(query_598274, "nextToken", newJString(nextToken))
  add(path_598273, "apiId", newJString(apiId))
  add(query_598274, "maxResults", newJString(maxResults))
  result = call_598272.call(path_598273, query_598274, nil, nil, nil)

var getRoutes* = Call_GetRoutes_598258(name: "getRoutes", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/routes",
                                    validator: validate_GetRoutes_598259,
                                    base: "/", url: url_GetRoutes_598260,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRouteResponse_598309 = ref object of OpenApiRestCall_597389
proc url_CreateRouteResponse_598311(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRouteResponse_598310(path: JsonNode; query: JsonNode;
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
  var valid_598312 = path.getOrDefault("apiId")
  valid_598312 = validateParameter(valid_598312, JString, required = true,
                                 default = nil)
  if valid_598312 != nil:
    section.add "apiId", valid_598312
  var valid_598313 = path.getOrDefault("routeId")
  valid_598313 = validateParameter(valid_598313, JString, required = true,
                                 default = nil)
  if valid_598313 != nil:
    section.add "routeId", valid_598313
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
  var valid_598314 = header.getOrDefault("X-Amz-Signature")
  valid_598314 = validateParameter(valid_598314, JString, required = false,
                                 default = nil)
  if valid_598314 != nil:
    section.add "X-Amz-Signature", valid_598314
  var valid_598315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598315 = validateParameter(valid_598315, JString, required = false,
                                 default = nil)
  if valid_598315 != nil:
    section.add "X-Amz-Content-Sha256", valid_598315
  var valid_598316 = header.getOrDefault("X-Amz-Date")
  valid_598316 = validateParameter(valid_598316, JString, required = false,
                                 default = nil)
  if valid_598316 != nil:
    section.add "X-Amz-Date", valid_598316
  var valid_598317 = header.getOrDefault("X-Amz-Credential")
  valid_598317 = validateParameter(valid_598317, JString, required = false,
                                 default = nil)
  if valid_598317 != nil:
    section.add "X-Amz-Credential", valid_598317
  var valid_598318 = header.getOrDefault("X-Amz-Security-Token")
  valid_598318 = validateParameter(valid_598318, JString, required = false,
                                 default = nil)
  if valid_598318 != nil:
    section.add "X-Amz-Security-Token", valid_598318
  var valid_598319 = header.getOrDefault("X-Amz-Algorithm")
  valid_598319 = validateParameter(valid_598319, JString, required = false,
                                 default = nil)
  if valid_598319 != nil:
    section.add "X-Amz-Algorithm", valid_598319
  var valid_598320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598320 = validateParameter(valid_598320, JString, required = false,
                                 default = nil)
  if valid_598320 != nil:
    section.add "X-Amz-SignedHeaders", valid_598320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598322: Call_CreateRouteResponse_598309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a RouteResponse for a Route.
  ## 
  let valid = call_598322.validator(path, query, header, formData, body)
  let scheme = call_598322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598322.url(scheme.get, call_598322.host, call_598322.base,
                         call_598322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598322, url, valid)

proc call*(call_598323: Call_CreateRouteResponse_598309; apiId: string;
          body: JsonNode; routeId: string): Recallable =
  ## createRouteResponse
  ## Creates a RouteResponse for a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   routeId: string (required)
  ##          : The route ID.
  var path_598324 = newJObject()
  var body_598325 = newJObject()
  add(path_598324, "apiId", newJString(apiId))
  if body != nil:
    body_598325 = body
  add(path_598324, "routeId", newJString(routeId))
  result = call_598323.call(path_598324, nil, nil, nil, body_598325)

var createRouteResponse* = Call_CreateRouteResponse_598309(
    name: "createRouteResponse", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses",
    validator: validate_CreateRouteResponse_598310, base: "/",
    url: url_CreateRouteResponse_598311, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRouteResponses_598291 = ref object of OpenApiRestCall_597389
proc url_GetRouteResponses_598293(protocol: Scheme; host: string; base: string;
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

proc validate_GetRouteResponses_598292(path: JsonNode; query: JsonNode;
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
  var valid_598294 = path.getOrDefault("apiId")
  valid_598294 = validateParameter(valid_598294, JString, required = true,
                                 default = nil)
  if valid_598294 != nil:
    section.add "apiId", valid_598294
  var valid_598295 = path.getOrDefault("routeId")
  valid_598295 = validateParameter(valid_598295, JString, required = true,
                                 default = nil)
  if valid_598295 != nil:
    section.add "routeId", valid_598295
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_598296 = query.getOrDefault("nextToken")
  valid_598296 = validateParameter(valid_598296, JString, required = false,
                                 default = nil)
  if valid_598296 != nil:
    section.add "nextToken", valid_598296
  var valid_598297 = query.getOrDefault("maxResults")
  valid_598297 = validateParameter(valid_598297, JString, required = false,
                                 default = nil)
  if valid_598297 != nil:
    section.add "maxResults", valid_598297
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
  var valid_598298 = header.getOrDefault("X-Amz-Signature")
  valid_598298 = validateParameter(valid_598298, JString, required = false,
                                 default = nil)
  if valid_598298 != nil:
    section.add "X-Amz-Signature", valid_598298
  var valid_598299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598299 = validateParameter(valid_598299, JString, required = false,
                                 default = nil)
  if valid_598299 != nil:
    section.add "X-Amz-Content-Sha256", valid_598299
  var valid_598300 = header.getOrDefault("X-Amz-Date")
  valid_598300 = validateParameter(valid_598300, JString, required = false,
                                 default = nil)
  if valid_598300 != nil:
    section.add "X-Amz-Date", valid_598300
  var valid_598301 = header.getOrDefault("X-Amz-Credential")
  valid_598301 = validateParameter(valid_598301, JString, required = false,
                                 default = nil)
  if valid_598301 != nil:
    section.add "X-Amz-Credential", valid_598301
  var valid_598302 = header.getOrDefault("X-Amz-Security-Token")
  valid_598302 = validateParameter(valid_598302, JString, required = false,
                                 default = nil)
  if valid_598302 != nil:
    section.add "X-Amz-Security-Token", valid_598302
  var valid_598303 = header.getOrDefault("X-Amz-Algorithm")
  valid_598303 = validateParameter(valid_598303, JString, required = false,
                                 default = nil)
  if valid_598303 != nil:
    section.add "X-Amz-Algorithm", valid_598303
  var valid_598304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598304 = validateParameter(valid_598304, JString, required = false,
                                 default = nil)
  if valid_598304 != nil:
    section.add "X-Amz-SignedHeaders", valid_598304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598305: Call_GetRouteResponses_598291; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the RouteResponses for a Route.
  ## 
  let valid = call_598305.validator(path, query, header, formData, body)
  let scheme = call_598305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598305.url(scheme.get, call_598305.host, call_598305.base,
                         call_598305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598305, url, valid)

proc call*(call_598306: Call_GetRouteResponses_598291; apiId: string;
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
  var path_598307 = newJObject()
  var query_598308 = newJObject()
  add(query_598308, "nextToken", newJString(nextToken))
  add(path_598307, "apiId", newJString(apiId))
  add(path_598307, "routeId", newJString(routeId))
  add(query_598308, "maxResults", newJString(maxResults))
  result = call_598306.call(path_598307, query_598308, nil, nil, nil)

var getRouteResponses* = Call_GetRouteResponses_598291(name: "getRouteResponses",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses",
    validator: validate_GetRouteResponses_598292, base: "/",
    url: url_GetRouteResponses_598293, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStage_598343 = ref object of OpenApiRestCall_597389
proc url_CreateStage_598345(protocol: Scheme; host: string; base: string;
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

proc validate_CreateStage_598344(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598346 = path.getOrDefault("apiId")
  valid_598346 = validateParameter(valid_598346, JString, required = true,
                                 default = nil)
  if valid_598346 != nil:
    section.add "apiId", valid_598346
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
  var valid_598347 = header.getOrDefault("X-Amz-Signature")
  valid_598347 = validateParameter(valid_598347, JString, required = false,
                                 default = nil)
  if valid_598347 != nil:
    section.add "X-Amz-Signature", valid_598347
  var valid_598348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598348 = validateParameter(valid_598348, JString, required = false,
                                 default = nil)
  if valid_598348 != nil:
    section.add "X-Amz-Content-Sha256", valid_598348
  var valid_598349 = header.getOrDefault("X-Amz-Date")
  valid_598349 = validateParameter(valid_598349, JString, required = false,
                                 default = nil)
  if valid_598349 != nil:
    section.add "X-Amz-Date", valid_598349
  var valid_598350 = header.getOrDefault("X-Amz-Credential")
  valid_598350 = validateParameter(valid_598350, JString, required = false,
                                 default = nil)
  if valid_598350 != nil:
    section.add "X-Amz-Credential", valid_598350
  var valid_598351 = header.getOrDefault("X-Amz-Security-Token")
  valid_598351 = validateParameter(valid_598351, JString, required = false,
                                 default = nil)
  if valid_598351 != nil:
    section.add "X-Amz-Security-Token", valid_598351
  var valid_598352 = header.getOrDefault("X-Amz-Algorithm")
  valid_598352 = validateParameter(valid_598352, JString, required = false,
                                 default = nil)
  if valid_598352 != nil:
    section.add "X-Amz-Algorithm", valid_598352
  var valid_598353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598353 = validateParameter(valid_598353, JString, required = false,
                                 default = nil)
  if valid_598353 != nil:
    section.add "X-Amz-SignedHeaders", valid_598353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598355: Call_CreateStage_598343; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Stage for an API.
  ## 
  let valid = call_598355.validator(path, query, header, formData, body)
  let scheme = call_598355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598355.url(scheme.get, call_598355.host, call_598355.base,
                         call_598355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598355, url, valid)

proc call*(call_598356: Call_CreateStage_598343; apiId: string; body: JsonNode): Recallable =
  ## createStage
  ## Creates a Stage for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_598357 = newJObject()
  var body_598358 = newJObject()
  add(path_598357, "apiId", newJString(apiId))
  if body != nil:
    body_598358 = body
  result = call_598356.call(path_598357, nil, nil, nil, body_598358)

var createStage* = Call_CreateStage_598343(name: "createStage",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/stages",
                                        validator: validate_CreateStage_598344,
                                        base: "/", url: url_CreateStage_598345,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStages_598326 = ref object of OpenApiRestCall_597389
proc url_GetStages_598328(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetStages_598327(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598329 = path.getOrDefault("apiId")
  valid_598329 = validateParameter(valid_598329, JString, required = true,
                                 default = nil)
  if valid_598329 != nil:
    section.add "apiId", valid_598329
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_598330 = query.getOrDefault("nextToken")
  valid_598330 = validateParameter(valid_598330, JString, required = false,
                                 default = nil)
  if valid_598330 != nil:
    section.add "nextToken", valid_598330
  var valid_598331 = query.getOrDefault("maxResults")
  valid_598331 = validateParameter(valid_598331, JString, required = false,
                                 default = nil)
  if valid_598331 != nil:
    section.add "maxResults", valid_598331
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
  var valid_598332 = header.getOrDefault("X-Amz-Signature")
  valid_598332 = validateParameter(valid_598332, JString, required = false,
                                 default = nil)
  if valid_598332 != nil:
    section.add "X-Amz-Signature", valid_598332
  var valid_598333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598333 = validateParameter(valid_598333, JString, required = false,
                                 default = nil)
  if valid_598333 != nil:
    section.add "X-Amz-Content-Sha256", valid_598333
  var valid_598334 = header.getOrDefault("X-Amz-Date")
  valid_598334 = validateParameter(valid_598334, JString, required = false,
                                 default = nil)
  if valid_598334 != nil:
    section.add "X-Amz-Date", valid_598334
  var valid_598335 = header.getOrDefault("X-Amz-Credential")
  valid_598335 = validateParameter(valid_598335, JString, required = false,
                                 default = nil)
  if valid_598335 != nil:
    section.add "X-Amz-Credential", valid_598335
  var valid_598336 = header.getOrDefault("X-Amz-Security-Token")
  valid_598336 = validateParameter(valid_598336, JString, required = false,
                                 default = nil)
  if valid_598336 != nil:
    section.add "X-Amz-Security-Token", valid_598336
  var valid_598337 = header.getOrDefault("X-Amz-Algorithm")
  valid_598337 = validateParameter(valid_598337, JString, required = false,
                                 default = nil)
  if valid_598337 != nil:
    section.add "X-Amz-Algorithm", valid_598337
  var valid_598338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598338 = validateParameter(valid_598338, JString, required = false,
                                 default = nil)
  if valid_598338 != nil:
    section.add "X-Amz-SignedHeaders", valid_598338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598339: Call_GetStages_598326; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Stages for an API.
  ## 
  let valid = call_598339.validator(path, query, header, formData, body)
  let scheme = call_598339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598339.url(scheme.get, call_598339.host, call_598339.base,
                         call_598339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598339, url, valid)

proc call*(call_598340: Call_GetStages_598326; apiId: string; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getStages
  ## Gets the Stages for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_598341 = newJObject()
  var query_598342 = newJObject()
  add(query_598342, "nextToken", newJString(nextToken))
  add(path_598341, "apiId", newJString(apiId))
  add(query_598342, "maxResults", newJString(maxResults))
  result = call_598340.call(path_598341, query_598342, nil, nil, nil)

var getStages* = Call_GetStages_598326(name: "getStages", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/stages",
                                    validator: validate_GetStages_598327,
                                    base: "/", url: url_GetStages_598328,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReimportApi_598373 = ref object of OpenApiRestCall_597389
proc url_ReimportApi_598375(protocol: Scheme; host: string; base: string;
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

proc validate_ReimportApi_598374(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598376 = path.getOrDefault("apiId")
  valid_598376 = validateParameter(valid_598376, JString, required = true,
                                 default = nil)
  if valid_598376 != nil:
    section.add "apiId", valid_598376
  result.add "path", section
  ## parameters in `query` object:
  ##   failOnWarnings: JBool
  ##                 : Specifies whether to rollback the API creation (true) or not (false) when a warning is encountered. The default value is false.
  ##   basepath: JString
  ##           : Represents the base path of the imported API. Supported only for HTTP APIs.
  section = newJObject()
  var valid_598377 = query.getOrDefault("failOnWarnings")
  valid_598377 = validateParameter(valid_598377, JBool, required = false, default = nil)
  if valid_598377 != nil:
    section.add "failOnWarnings", valid_598377
  var valid_598378 = query.getOrDefault("basepath")
  valid_598378 = validateParameter(valid_598378, JString, required = false,
                                 default = nil)
  if valid_598378 != nil:
    section.add "basepath", valid_598378
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
  var valid_598379 = header.getOrDefault("X-Amz-Signature")
  valid_598379 = validateParameter(valid_598379, JString, required = false,
                                 default = nil)
  if valid_598379 != nil:
    section.add "X-Amz-Signature", valid_598379
  var valid_598380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598380 = validateParameter(valid_598380, JString, required = false,
                                 default = nil)
  if valid_598380 != nil:
    section.add "X-Amz-Content-Sha256", valid_598380
  var valid_598381 = header.getOrDefault("X-Amz-Date")
  valid_598381 = validateParameter(valid_598381, JString, required = false,
                                 default = nil)
  if valid_598381 != nil:
    section.add "X-Amz-Date", valid_598381
  var valid_598382 = header.getOrDefault("X-Amz-Credential")
  valid_598382 = validateParameter(valid_598382, JString, required = false,
                                 default = nil)
  if valid_598382 != nil:
    section.add "X-Amz-Credential", valid_598382
  var valid_598383 = header.getOrDefault("X-Amz-Security-Token")
  valid_598383 = validateParameter(valid_598383, JString, required = false,
                                 default = nil)
  if valid_598383 != nil:
    section.add "X-Amz-Security-Token", valid_598383
  var valid_598384 = header.getOrDefault("X-Amz-Algorithm")
  valid_598384 = validateParameter(valid_598384, JString, required = false,
                                 default = nil)
  if valid_598384 != nil:
    section.add "X-Amz-Algorithm", valid_598384
  var valid_598385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598385 = validateParameter(valid_598385, JString, required = false,
                                 default = nil)
  if valid_598385 != nil:
    section.add "X-Amz-SignedHeaders", valid_598385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598387: Call_ReimportApi_598373; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Puts an Api resource.
  ## 
  let valid = call_598387.validator(path, query, header, formData, body)
  let scheme = call_598387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598387.url(scheme.get, call_598387.host, call_598387.base,
                         call_598387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598387, url, valid)

proc call*(call_598388: Call_ReimportApi_598373; apiId: string; body: JsonNode;
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
  var path_598389 = newJObject()
  var query_598390 = newJObject()
  var body_598391 = newJObject()
  add(query_598390, "failOnWarnings", newJBool(failOnWarnings))
  add(path_598389, "apiId", newJString(apiId))
  if body != nil:
    body_598391 = body
  add(query_598390, "basepath", newJString(basepath))
  result = call_598388.call(path_598389, query_598390, nil, nil, body_598391)

var reimportApi* = Call_ReimportApi_598373(name: "reimportApi",
                                        meth: HttpMethod.HttpPut,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}",
                                        validator: validate_ReimportApi_598374,
                                        base: "/", url: url_ReimportApi_598375,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApi_598359 = ref object of OpenApiRestCall_597389
proc url_GetApi_598361(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApi_598360(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598362 = path.getOrDefault("apiId")
  valid_598362 = validateParameter(valid_598362, JString, required = true,
                                 default = nil)
  if valid_598362 != nil:
    section.add "apiId", valid_598362
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
  var valid_598363 = header.getOrDefault("X-Amz-Signature")
  valid_598363 = validateParameter(valid_598363, JString, required = false,
                                 default = nil)
  if valid_598363 != nil:
    section.add "X-Amz-Signature", valid_598363
  var valid_598364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598364 = validateParameter(valid_598364, JString, required = false,
                                 default = nil)
  if valid_598364 != nil:
    section.add "X-Amz-Content-Sha256", valid_598364
  var valid_598365 = header.getOrDefault("X-Amz-Date")
  valid_598365 = validateParameter(valid_598365, JString, required = false,
                                 default = nil)
  if valid_598365 != nil:
    section.add "X-Amz-Date", valid_598365
  var valid_598366 = header.getOrDefault("X-Amz-Credential")
  valid_598366 = validateParameter(valid_598366, JString, required = false,
                                 default = nil)
  if valid_598366 != nil:
    section.add "X-Amz-Credential", valid_598366
  var valid_598367 = header.getOrDefault("X-Amz-Security-Token")
  valid_598367 = validateParameter(valid_598367, JString, required = false,
                                 default = nil)
  if valid_598367 != nil:
    section.add "X-Amz-Security-Token", valid_598367
  var valid_598368 = header.getOrDefault("X-Amz-Algorithm")
  valid_598368 = validateParameter(valid_598368, JString, required = false,
                                 default = nil)
  if valid_598368 != nil:
    section.add "X-Amz-Algorithm", valid_598368
  var valid_598369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598369 = validateParameter(valid_598369, JString, required = false,
                                 default = nil)
  if valid_598369 != nil:
    section.add "X-Amz-SignedHeaders", valid_598369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598370: Call_GetApi_598359; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Api resource.
  ## 
  let valid = call_598370.validator(path, query, header, formData, body)
  let scheme = call_598370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598370.url(scheme.get, call_598370.host, call_598370.base,
                         call_598370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598370, url, valid)

proc call*(call_598371: Call_GetApi_598359; apiId: string): Recallable =
  ## getApi
  ## Gets an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_598372 = newJObject()
  add(path_598372, "apiId", newJString(apiId))
  result = call_598371.call(path_598372, nil, nil, nil, nil)

var getApi* = Call_GetApi_598359(name: "getApi", meth: HttpMethod.HttpGet,
                              host: "apigateway.amazonaws.com",
                              route: "/v2/apis/{apiId}",
                              validator: validate_GetApi_598360, base: "/",
                              url: url_GetApi_598361,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApi_598406 = ref object of OpenApiRestCall_597389
proc url_UpdateApi_598408(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateApi_598407(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598409 = path.getOrDefault("apiId")
  valid_598409 = validateParameter(valid_598409, JString, required = true,
                                 default = nil)
  if valid_598409 != nil:
    section.add "apiId", valid_598409
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
  var valid_598410 = header.getOrDefault("X-Amz-Signature")
  valid_598410 = validateParameter(valid_598410, JString, required = false,
                                 default = nil)
  if valid_598410 != nil:
    section.add "X-Amz-Signature", valid_598410
  var valid_598411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598411 = validateParameter(valid_598411, JString, required = false,
                                 default = nil)
  if valid_598411 != nil:
    section.add "X-Amz-Content-Sha256", valid_598411
  var valid_598412 = header.getOrDefault("X-Amz-Date")
  valid_598412 = validateParameter(valid_598412, JString, required = false,
                                 default = nil)
  if valid_598412 != nil:
    section.add "X-Amz-Date", valid_598412
  var valid_598413 = header.getOrDefault("X-Amz-Credential")
  valid_598413 = validateParameter(valid_598413, JString, required = false,
                                 default = nil)
  if valid_598413 != nil:
    section.add "X-Amz-Credential", valid_598413
  var valid_598414 = header.getOrDefault("X-Amz-Security-Token")
  valid_598414 = validateParameter(valid_598414, JString, required = false,
                                 default = nil)
  if valid_598414 != nil:
    section.add "X-Amz-Security-Token", valid_598414
  var valid_598415 = header.getOrDefault("X-Amz-Algorithm")
  valid_598415 = validateParameter(valid_598415, JString, required = false,
                                 default = nil)
  if valid_598415 != nil:
    section.add "X-Amz-Algorithm", valid_598415
  var valid_598416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598416 = validateParameter(valid_598416, JString, required = false,
                                 default = nil)
  if valid_598416 != nil:
    section.add "X-Amz-SignedHeaders", valid_598416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598418: Call_UpdateApi_598406; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Api resource.
  ## 
  let valid = call_598418.validator(path, query, header, formData, body)
  let scheme = call_598418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598418.url(scheme.get, call_598418.host, call_598418.base,
                         call_598418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598418, url, valid)

proc call*(call_598419: Call_UpdateApi_598406; apiId: string; body: JsonNode): Recallable =
  ## updateApi
  ## Updates an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_598420 = newJObject()
  var body_598421 = newJObject()
  add(path_598420, "apiId", newJString(apiId))
  if body != nil:
    body_598421 = body
  result = call_598419.call(path_598420, nil, nil, nil, body_598421)

var updateApi* = Call_UpdateApi_598406(name: "updateApi", meth: HttpMethod.HttpPatch,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}",
                                    validator: validate_UpdateApi_598407,
                                    base: "/", url: url_UpdateApi_598408,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApi_598392 = ref object of OpenApiRestCall_597389
proc url_DeleteApi_598394(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteApi_598393(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598395 = path.getOrDefault("apiId")
  valid_598395 = validateParameter(valid_598395, JString, required = true,
                                 default = nil)
  if valid_598395 != nil:
    section.add "apiId", valid_598395
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
  var valid_598396 = header.getOrDefault("X-Amz-Signature")
  valid_598396 = validateParameter(valid_598396, JString, required = false,
                                 default = nil)
  if valid_598396 != nil:
    section.add "X-Amz-Signature", valid_598396
  var valid_598397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598397 = validateParameter(valid_598397, JString, required = false,
                                 default = nil)
  if valid_598397 != nil:
    section.add "X-Amz-Content-Sha256", valid_598397
  var valid_598398 = header.getOrDefault("X-Amz-Date")
  valid_598398 = validateParameter(valid_598398, JString, required = false,
                                 default = nil)
  if valid_598398 != nil:
    section.add "X-Amz-Date", valid_598398
  var valid_598399 = header.getOrDefault("X-Amz-Credential")
  valid_598399 = validateParameter(valid_598399, JString, required = false,
                                 default = nil)
  if valid_598399 != nil:
    section.add "X-Amz-Credential", valid_598399
  var valid_598400 = header.getOrDefault("X-Amz-Security-Token")
  valid_598400 = validateParameter(valid_598400, JString, required = false,
                                 default = nil)
  if valid_598400 != nil:
    section.add "X-Amz-Security-Token", valid_598400
  var valid_598401 = header.getOrDefault("X-Amz-Algorithm")
  valid_598401 = validateParameter(valid_598401, JString, required = false,
                                 default = nil)
  if valid_598401 != nil:
    section.add "X-Amz-Algorithm", valid_598401
  var valid_598402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598402 = validateParameter(valid_598402, JString, required = false,
                                 default = nil)
  if valid_598402 != nil:
    section.add "X-Amz-SignedHeaders", valid_598402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598403: Call_DeleteApi_598392; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Api resource.
  ## 
  let valid = call_598403.validator(path, query, header, formData, body)
  let scheme = call_598403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598403.url(scheme.get, call_598403.host, call_598403.base,
                         call_598403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598403, url, valid)

proc call*(call_598404: Call_DeleteApi_598392; apiId: string): Recallable =
  ## deleteApi
  ## Deletes an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_598405 = newJObject()
  add(path_598405, "apiId", newJString(apiId))
  result = call_598404.call(path_598405, nil, nil, nil, nil)

var deleteApi* = Call_DeleteApi_598392(name: "deleteApi",
                                    meth: HttpMethod.HttpDelete,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}",
                                    validator: validate_DeleteApi_598393,
                                    base: "/", url: url_DeleteApi_598394,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiMapping_598422 = ref object of OpenApiRestCall_597389
proc url_GetApiMapping_598424(protocol: Scheme; host: string; base: string;
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

proc validate_GetApiMapping_598423(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598425 = path.getOrDefault("apiMappingId")
  valid_598425 = validateParameter(valid_598425, JString, required = true,
                                 default = nil)
  if valid_598425 != nil:
    section.add "apiMappingId", valid_598425
  var valid_598426 = path.getOrDefault("domainName")
  valid_598426 = validateParameter(valid_598426, JString, required = true,
                                 default = nil)
  if valid_598426 != nil:
    section.add "domainName", valid_598426
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
  var valid_598427 = header.getOrDefault("X-Amz-Signature")
  valid_598427 = validateParameter(valid_598427, JString, required = false,
                                 default = nil)
  if valid_598427 != nil:
    section.add "X-Amz-Signature", valid_598427
  var valid_598428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598428 = validateParameter(valid_598428, JString, required = false,
                                 default = nil)
  if valid_598428 != nil:
    section.add "X-Amz-Content-Sha256", valid_598428
  var valid_598429 = header.getOrDefault("X-Amz-Date")
  valid_598429 = validateParameter(valid_598429, JString, required = false,
                                 default = nil)
  if valid_598429 != nil:
    section.add "X-Amz-Date", valid_598429
  var valid_598430 = header.getOrDefault("X-Amz-Credential")
  valid_598430 = validateParameter(valid_598430, JString, required = false,
                                 default = nil)
  if valid_598430 != nil:
    section.add "X-Amz-Credential", valid_598430
  var valid_598431 = header.getOrDefault("X-Amz-Security-Token")
  valid_598431 = validateParameter(valid_598431, JString, required = false,
                                 default = nil)
  if valid_598431 != nil:
    section.add "X-Amz-Security-Token", valid_598431
  var valid_598432 = header.getOrDefault("X-Amz-Algorithm")
  valid_598432 = validateParameter(valid_598432, JString, required = false,
                                 default = nil)
  if valid_598432 != nil:
    section.add "X-Amz-Algorithm", valid_598432
  var valid_598433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598433 = validateParameter(valid_598433, JString, required = false,
                                 default = nil)
  if valid_598433 != nil:
    section.add "X-Amz-SignedHeaders", valid_598433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598434: Call_GetApiMapping_598422; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an API mapping.
  ## 
  let valid = call_598434.validator(path, query, header, formData, body)
  let scheme = call_598434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598434.url(scheme.get, call_598434.host, call_598434.base,
                         call_598434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598434, url, valid)

proc call*(call_598435: Call_GetApiMapping_598422; apiMappingId: string;
          domainName: string): Recallable =
  ## getApiMapping
  ## Gets an API mapping.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_598436 = newJObject()
  add(path_598436, "apiMappingId", newJString(apiMappingId))
  add(path_598436, "domainName", newJString(domainName))
  result = call_598435.call(path_598436, nil, nil, nil, nil)

var getApiMapping* = Call_GetApiMapping_598422(name: "getApiMapping",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_GetApiMapping_598423, base: "/", url: url_GetApiMapping_598424,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiMapping_598452 = ref object of OpenApiRestCall_597389
proc url_UpdateApiMapping_598454(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApiMapping_598453(path: JsonNode; query: JsonNode;
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
  var valid_598455 = path.getOrDefault("apiMappingId")
  valid_598455 = validateParameter(valid_598455, JString, required = true,
                                 default = nil)
  if valid_598455 != nil:
    section.add "apiMappingId", valid_598455
  var valid_598456 = path.getOrDefault("domainName")
  valid_598456 = validateParameter(valid_598456, JString, required = true,
                                 default = nil)
  if valid_598456 != nil:
    section.add "domainName", valid_598456
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
  var valid_598457 = header.getOrDefault("X-Amz-Signature")
  valid_598457 = validateParameter(valid_598457, JString, required = false,
                                 default = nil)
  if valid_598457 != nil:
    section.add "X-Amz-Signature", valid_598457
  var valid_598458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598458 = validateParameter(valid_598458, JString, required = false,
                                 default = nil)
  if valid_598458 != nil:
    section.add "X-Amz-Content-Sha256", valid_598458
  var valid_598459 = header.getOrDefault("X-Amz-Date")
  valid_598459 = validateParameter(valid_598459, JString, required = false,
                                 default = nil)
  if valid_598459 != nil:
    section.add "X-Amz-Date", valid_598459
  var valid_598460 = header.getOrDefault("X-Amz-Credential")
  valid_598460 = validateParameter(valid_598460, JString, required = false,
                                 default = nil)
  if valid_598460 != nil:
    section.add "X-Amz-Credential", valid_598460
  var valid_598461 = header.getOrDefault("X-Amz-Security-Token")
  valid_598461 = validateParameter(valid_598461, JString, required = false,
                                 default = nil)
  if valid_598461 != nil:
    section.add "X-Amz-Security-Token", valid_598461
  var valid_598462 = header.getOrDefault("X-Amz-Algorithm")
  valid_598462 = validateParameter(valid_598462, JString, required = false,
                                 default = nil)
  if valid_598462 != nil:
    section.add "X-Amz-Algorithm", valid_598462
  var valid_598463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598463 = validateParameter(valid_598463, JString, required = false,
                                 default = nil)
  if valid_598463 != nil:
    section.add "X-Amz-SignedHeaders", valid_598463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598465: Call_UpdateApiMapping_598452; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The API mapping.
  ## 
  let valid = call_598465.validator(path, query, header, formData, body)
  let scheme = call_598465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598465.url(scheme.get, call_598465.host, call_598465.base,
                         call_598465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598465, url, valid)

proc call*(call_598466: Call_UpdateApiMapping_598452; apiMappingId: string;
          body: JsonNode; domainName: string): Recallable =
  ## updateApiMapping
  ## The API mapping.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : The domain name.
  var path_598467 = newJObject()
  var body_598468 = newJObject()
  add(path_598467, "apiMappingId", newJString(apiMappingId))
  if body != nil:
    body_598468 = body
  add(path_598467, "domainName", newJString(domainName))
  result = call_598466.call(path_598467, nil, nil, nil, body_598468)

var updateApiMapping* = Call_UpdateApiMapping_598452(name: "updateApiMapping",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_UpdateApiMapping_598453, base: "/",
    url: url_UpdateApiMapping_598454, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiMapping_598437 = ref object of OpenApiRestCall_597389
proc url_DeleteApiMapping_598439(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApiMapping_598438(path: JsonNode; query: JsonNode;
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
  var valid_598440 = path.getOrDefault("apiMappingId")
  valid_598440 = validateParameter(valid_598440, JString, required = true,
                                 default = nil)
  if valid_598440 != nil:
    section.add "apiMappingId", valid_598440
  var valid_598441 = path.getOrDefault("domainName")
  valid_598441 = validateParameter(valid_598441, JString, required = true,
                                 default = nil)
  if valid_598441 != nil:
    section.add "domainName", valid_598441
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
  var valid_598442 = header.getOrDefault("X-Amz-Signature")
  valid_598442 = validateParameter(valid_598442, JString, required = false,
                                 default = nil)
  if valid_598442 != nil:
    section.add "X-Amz-Signature", valid_598442
  var valid_598443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598443 = validateParameter(valid_598443, JString, required = false,
                                 default = nil)
  if valid_598443 != nil:
    section.add "X-Amz-Content-Sha256", valid_598443
  var valid_598444 = header.getOrDefault("X-Amz-Date")
  valid_598444 = validateParameter(valid_598444, JString, required = false,
                                 default = nil)
  if valid_598444 != nil:
    section.add "X-Amz-Date", valid_598444
  var valid_598445 = header.getOrDefault("X-Amz-Credential")
  valid_598445 = validateParameter(valid_598445, JString, required = false,
                                 default = nil)
  if valid_598445 != nil:
    section.add "X-Amz-Credential", valid_598445
  var valid_598446 = header.getOrDefault("X-Amz-Security-Token")
  valid_598446 = validateParameter(valid_598446, JString, required = false,
                                 default = nil)
  if valid_598446 != nil:
    section.add "X-Amz-Security-Token", valid_598446
  var valid_598447 = header.getOrDefault("X-Amz-Algorithm")
  valid_598447 = validateParameter(valid_598447, JString, required = false,
                                 default = nil)
  if valid_598447 != nil:
    section.add "X-Amz-Algorithm", valid_598447
  var valid_598448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598448 = validateParameter(valid_598448, JString, required = false,
                                 default = nil)
  if valid_598448 != nil:
    section.add "X-Amz-SignedHeaders", valid_598448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598449: Call_DeleteApiMapping_598437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an API mapping.
  ## 
  let valid = call_598449.validator(path, query, header, formData, body)
  let scheme = call_598449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598449.url(scheme.get, call_598449.host, call_598449.base,
                         call_598449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598449, url, valid)

proc call*(call_598450: Call_DeleteApiMapping_598437; apiMappingId: string;
          domainName: string): Recallable =
  ## deleteApiMapping
  ## Deletes an API mapping.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_598451 = newJObject()
  add(path_598451, "apiMappingId", newJString(apiMappingId))
  add(path_598451, "domainName", newJString(domainName))
  result = call_598450.call(path_598451, nil, nil, nil, nil)

var deleteApiMapping* = Call_DeleteApiMapping_598437(name: "deleteApiMapping",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_DeleteApiMapping_598438, base: "/",
    url: url_DeleteApiMapping_598439, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizer_598469 = ref object of OpenApiRestCall_597389
proc url_GetAuthorizer_598471(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizer_598470(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598472 = path.getOrDefault("apiId")
  valid_598472 = validateParameter(valid_598472, JString, required = true,
                                 default = nil)
  if valid_598472 != nil:
    section.add "apiId", valid_598472
  var valid_598473 = path.getOrDefault("authorizerId")
  valid_598473 = validateParameter(valid_598473, JString, required = true,
                                 default = nil)
  if valid_598473 != nil:
    section.add "authorizerId", valid_598473
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
  var valid_598474 = header.getOrDefault("X-Amz-Signature")
  valid_598474 = validateParameter(valid_598474, JString, required = false,
                                 default = nil)
  if valid_598474 != nil:
    section.add "X-Amz-Signature", valid_598474
  var valid_598475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598475 = validateParameter(valid_598475, JString, required = false,
                                 default = nil)
  if valid_598475 != nil:
    section.add "X-Amz-Content-Sha256", valid_598475
  var valid_598476 = header.getOrDefault("X-Amz-Date")
  valid_598476 = validateParameter(valid_598476, JString, required = false,
                                 default = nil)
  if valid_598476 != nil:
    section.add "X-Amz-Date", valid_598476
  var valid_598477 = header.getOrDefault("X-Amz-Credential")
  valid_598477 = validateParameter(valid_598477, JString, required = false,
                                 default = nil)
  if valid_598477 != nil:
    section.add "X-Amz-Credential", valid_598477
  var valid_598478 = header.getOrDefault("X-Amz-Security-Token")
  valid_598478 = validateParameter(valid_598478, JString, required = false,
                                 default = nil)
  if valid_598478 != nil:
    section.add "X-Amz-Security-Token", valid_598478
  var valid_598479 = header.getOrDefault("X-Amz-Algorithm")
  valid_598479 = validateParameter(valid_598479, JString, required = false,
                                 default = nil)
  if valid_598479 != nil:
    section.add "X-Amz-Algorithm", valid_598479
  var valid_598480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598480 = validateParameter(valid_598480, JString, required = false,
                                 default = nil)
  if valid_598480 != nil:
    section.add "X-Amz-SignedHeaders", valid_598480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598481: Call_GetAuthorizer_598469; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Authorizer.
  ## 
  let valid = call_598481.validator(path, query, header, formData, body)
  let scheme = call_598481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598481.url(scheme.get, call_598481.host, call_598481.base,
                         call_598481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598481, url, valid)

proc call*(call_598482: Call_GetAuthorizer_598469; apiId: string;
          authorizerId: string): Recallable =
  ## getAuthorizer
  ## Gets an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  var path_598483 = newJObject()
  add(path_598483, "apiId", newJString(apiId))
  add(path_598483, "authorizerId", newJString(authorizerId))
  result = call_598482.call(path_598483, nil, nil, nil, nil)

var getAuthorizer* = Call_GetAuthorizer_598469(name: "getAuthorizer",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_GetAuthorizer_598470, base: "/", url: url_GetAuthorizer_598471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthorizer_598499 = ref object of OpenApiRestCall_597389
proc url_UpdateAuthorizer_598501(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAuthorizer_598500(path: JsonNode; query: JsonNode;
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
  var valid_598502 = path.getOrDefault("apiId")
  valid_598502 = validateParameter(valid_598502, JString, required = true,
                                 default = nil)
  if valid_598502 != nil:
    section.add "apiId", valid_598502
  var valid_598503 = path.getOrDefault("authorizerId")
  valid_598503 = validateParameter(valid_598503, JString, required = true,
                                 default = nil)
  if valid_598503 != nil:
    section.add "authorizerId", valid_598503
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
  var valid_598504 = header.getOrDefault("X-Amz-Signature")
  valid_598504 = validateParameter(valid_598504, JString, required = false,
                                 default = nil)
  if valid_598504 != nil:
    section.add "X-Amz-Signature", valid_598504
  var valid_598505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598505 = validateParameter(valid_598505, JString, required = false,
                                 default = nil)
  if valid_598505 != nil:
    section.add "X-Amz-Content-Sha256", valid_598505
  var valid_598506 = header.getOrDefault("X-Amz-Date")
  valid_598506 = validateParameter(valid_598506, JString, required = false,
                                 default = nil)
  if valid_598506 != nil:
    section.add "X-Amz-Date", valid_598506
  var valid_598507 = header.getOrDefault("X-Amz-Credential")
  valid_598507 = validateParameter(valid_598507, JString, required = false,
                                 default = nil)
  if valid_598507 != nil:
    section.add "X-Amz-Credential", valid_598507
  var valid_598508 = header.getOrDefault("X-Amz-Security-Token")
  valid_598508 = validateParameter(valid_598508, JString, required = false,
                                 default = nil)
  if valid_598508 != nil:
    section.add "X-Amz-Security-Token", valid_598508
  var valid_598509 = header.getOrDefault("X-Amz-Algorithm")
  valid_598509 = validateParameter(valid_598509, JString, required = false,
                                 default = nil)
  if valid_598509 != nil:
    section.add "X-Amz-Algorithm", valid_598509
  var valid_598510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598510 = validateParameter(valid_598510, JString, required = false,
                                 default = nil)
  if valid_598510 != nil:
    section.add "X-Amz-SignedHeaders", valid_598510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598512: Call_UpdateAuthorizer_598499; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Authorizer.
  ## 
  let valid = call_598512.validator(path, query, header, formData, body)
  let scheme = call_598512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598512.url(scheme.get, call_598512.host, call_598512.base,
                         call_598512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598512, url, valid)

proc call*(call_598513: Call_UpdateAuthorizer_598499; apiId: string;
          authorizerId: string; body: JsonNode): Recallable =
  ## updateAuthorizer
  ## Updates an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  ##   body: JObject (required)
  var path_598514 = newJObject()
  var body_598515 = newJObject()
  add(path_598514, "apiId", newJString(apiId))
  add(path_598514, "authorizerId", newJString(authorizerId))
  if body != nil:
    body_598515 = body
  result = call_598513.call(path_598514, nil, nil, nil, body_598515)

var updateAuthorizer* = Call_UpdateAuthorizer_598499(name: "updateAuthorizer",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_UpdateAuthorizer_598500, base: "/",
    url: url_UpdateAuthorizer_598501, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAuthorizer_598484 = ref object of OpenApiRestCall_597389
proc url_DeleteAuthorizer_598486(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAuthorizer_598485(path: JsonNode; query: JsonNode;
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
  var valid_598487 = path.getOrDefault("apiId")
  valid_598487 = validateParameter(valid_598487, JString, required = true,
                                 default = nil)
  if valid_598487 != nil:
    section.add "apiId", valid_598487
  var valid_598488 = path.getOrDefault("authorizerId")
  valid_598488 = validateParameter(valid_598488, JString, required = true,
                                 default = nil)
  if valid_598488 != nil:
    section.add "authorizerId", valid_598488
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
  var valid_598489 = header.getOrDefault("X-Amz-Signature")
  valid_598489 = validateParameter(valid_598489, JString, required = false,
                                 default = nil)
  if valid_598489 != nil:
    section.add "X-Amz-Signature", valid_598489
  var valid_598490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598490 = validateParameter(valid_598490, JString, required = false,
                                 default = nil)
  if valid_598490 != nil:
    section.add "X-Amz-Content-Sha256", valid_598490
  var valid_598491 = header.getOrDefault("X-Amz-Date")
  valid_598491 = validateParameter(valid_598491, JString, required = false,
                                 default = nil)
  if valid_598491 != nil:
    section.add "X-Amz-Date", valid_598491
  var valid_598492 = header.getOrDefault("X-Amz-Credential")
  valid_598492 = validateParameter(valid_598492, JString, required = false,
                                 default = nil)
  if valid_598492 != nil:
    section.add "X-Amz-Credential", valid_598492
  var valid_598493 = header.getOrDefault("X-Amz-Security-Token")
  valid_598493 = validateParameter(valid_598493, JString, required = false,
                                 default = nil)
  if valid_598493 != nil:
    section.add "X-Amz-Security-Token", valid_598493
  var valid_598494 = header.getOrDefault("X-Amz-Algorithm")
  valid_598494 = validateParameter(valid_598494, JString, required = false,
                                 default = nil)
  if valid_598494 != nil:
    section.add "X-Amz-Algorithm", valid_598494
  var valid_598495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598495 = validateParameter(valid_598495, JString, required = false,
                                 default = nil)
  if valid_598495 != nil:
    section.add "X-Amz-SignedHeaders", valid_598495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598496: Call_DeleteAuthorizer_598484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Authorizer.
  ## 
  let valid = call_598496.validator(path, query, header, formData, body)
  let scheme = call_598496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598496.url(scheme.get, call_598496.host, call_598496.base,
                         call_598496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598496, url, valid)

proc call*(call_598497: Call_DeleteAuthorizer_598484; apiId: string;
          authorizerId: string): Recallable =
  ## deleteAuthorizer
  ## Deletes an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  var path_598498 = newJObject()
  add(path_598498, "apiId", newJString(apiId))
  add(path_598498, "authorizerId", newJString(authorizerId))
  result = call_598497.call(path_598498, nil, nil, nil, nil)

var deleteAuthorizer* = Call_DeleteAuthorizer_598484(name: "deleteAuthorizer",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_DeleteAuthorizer_598485, base: "/",
    url: url_DeleteAuthorizer_598486, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCorsConfiguration_598516 = ref object of OpenApiRestCall_597389
proc url_DeleteCorsConfiguration_598518(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCorsConfiguration_598517(path: JsonNode; query: JsonNode;
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
  var valid_598519 = path.getOrDefault("apiId")
  valid_598519 = validateParameter(valid_598519, JString, required = true,
                                 default = nil)
  if valid_598519 != nil:
    section.add "apiId", valid_598519
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
  var valid_598520 = header.getOrDefault("X-Amz-Signature")
  valid_598520 = validateParameter(valid_598520, JString, required = false,
                                 default = nil)
  if valid_598520 != nil:
    section.add "X-Amz-Signature", valid_598520
  var valid_598521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598521 = validateParameter(valid_598521, JString, required = false,
                                 default = nil)
  if valid_598521 != nil:
    section.add "X-Amz-Content-Sha256", valid_598521
  var valid_598522 = header.getOrDefault("X-Amz-Date")
  valid_598522 = validateParameter(valid_598522, JString, required = false,
                                 default = nil)
  if valid_598522 != nil:
    section.add "X-Amz-Date", valid_598522
  var valid_598523 = header.getOrDefault("X-Amz-Credential")
  valid_598523 = validateParameter(valid_598523, JString, required = false,
                                 default = nil)
  if valid_598523 != nil:
    section.add "X-Amz-Credential", valid_598523
  var valid_598524 = header.getOrDefault("X-Amz-Security-Token")
  valid_598524 = validateParameter(valid_598524, JString, required = false,
                                 default = nil)
  if valid_598524 != nil:
    section.add "X-Amz-Security-Token", valid_598524
  var valid_598525 = header.getOrDefault("X-Amz-Algorithm")
  valid_598525 = validateParameter(valid_598525, JString, required = false,
                                 default = nil)
  if valid_598525 != nil:
    section.add "X-Amz-Algorithm", valid_598525
  var valid_598526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598526 = validateParameter(valid_598526, JString, required = false,
                                 default = nil)
  if valid_598526 != nil:
    section.add "X-Amz-SignedHeaders", valid_598526
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598527: Call_DeleteCorsConfiguration_598516; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a CORS configuration.
  ## 
  let valid = call_598527.validator(path, query, header, formData, body)
  let scheme = call_598527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598527.url(scheme.get, call_598527.host, call_598527.base,
                         call_598527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598527, url, valid)

proc call*(call_598528: Call_DeleteCorsConfiguration_598516; apiId: string): Recallable =
  ## deleteCorsConfiguration
  ## Deletes a CORS configuration.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_598529 = newJObject()
  add(path_598529, "apiId", newJString(apiId))
  result = call_598528.call(path_598529, nil, nil, nil, nil)

var deleteCorsConfiguration* = Call_DeleteCorsConfiguration_598516(
    name: "deleteCorsConfiguration", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/cors",
    validator: validate_DeleteCorsConfiguration_598517, base: "/",
    url: url_DeleteCorsConfiguration_598518, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_598530 = ref object of OpenApiRestCall_597389
proc url_GetDeployment_598532(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployment_598531(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598533 = path.getOrDefault("apiId")
  valid_598533 = validateParameter(valid_598533, JString, required = true,
                                 default = nil)
  if valid_598533 != nil:
    section.add "apiId", valid_598533
  var valid_598534 = path.getOrDefault("deploymentId")
  valid_598534 = validateParameter(valid_598534, JString, required = true,
                                 default = nil)
  if valid_598534 != nil:
    section.add "deploymentId", valid_598534
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
  var valid_598535 = header.getOrDefault("X-Amz-Signature")
  valid_598535 = validateParameter(valid_598535, JString, required = false,
                                 default = nil)
  if valid_598535 != nil:
    section.add "X-Amz-Signature", valid_598535
  var valid_598536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598536 = validateParameter(valid_598536, JString, required = false,
                                 default = nil)
  if valid_598536 != nil:
    section.add "X-Amz-Content-Sha256", valid_598536
  var valid_598537 = header.getOrDefault("X-Amz-Date")
  valid_598537 = validateParameter(valid_598537, JString, required = false,
                                 default = nil)
  if valid_598537 != nil:
    section.add "X-Amz-Date", valid_598537
  var valid_598538 = header.getOrDefault("X-Amz-Credential")
  valid_598538 = validateParameter(valid_598538, JString, required = false,
                                 default = nil)
  if valid_598538 != nil:
    section.add "X-Amz-Credential", valid_598538
  var valid_598539 = header.getOrDefault("X-Amz-Security-Token")
  valid_598539 = validateParameter(valid_598539, JString, required = false,
                                 default = nil)
  if valid_598539 != nil:
    section.add "X-Amz-Security-Token", valid_598539
  var valid_598540 = header.getOrDefault("X-Amz-Algorithm")
  valid_598540 = validateParameter(valid_598540, JString, required = false,
                                 default = nil)
  if valid_598540 != nil:
    section.add "X-Amz-Algorithm", valid_598540
  var valid_598541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598541 = validateParameter(valid_598541, JString, required = false,
                                 default = nil)
  if valid_598541 != nil:
    section.add "X-Amz-SignedHeaders", valid_598541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598542: Call_GetDeployment_598530; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Deployment.
  ## 
  let valid = call_598542.validator(path, query, header, formData, body)
  let scheme = call_598542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598542.url(scheme.get, call_598542.host, call_598542.base,
                         call_598542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598542, url, valid)

proc call*(call_598543: Call_GetDeployment_598530; apiId: string;
          deploymentId: string): Recallable =
  ## getDeployment
  ## Gets a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_598544 = newJObject()
  add(path_598544, "apiId", newJString(apiId))
  add(path_598544, "deploymentId", newJString(deploymentId))
  result = call_598543.call(path_598544, nil, nil, nil, nil)

var getDeployment* = Call_GetDeployment_598530(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_GetDeployment_598531, base: "/", url: url_GetDeployment_598532,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeployment_598560 = ref object of OpenApiRestCall_597389
proc url_UpdateDeployment_598562(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDeployment_598561(path: JsonNode; query: JsonNode;
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
  var valid_598563 = path.getOrDefault("apiId")
  valid_598563 = validateParameter(valid_598563, JString, required = true,
                                 default = nil)
  if valid_598563 != nil:
    section.add "apiId", valid_598563
  var valid_598564 = path.getOrDefault("deploymentId")
  valid_598564 = validateParameter(valid_598564, JString, required = true,
                                 default = nil)
  if valid_598564 != nil:
    section.add "deploymentId", valid_598564
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
  var valid_598565 = header.getOrDefault("X-Amz-Signature")
  valid_598565 = validateParameter(valid_598565, JString, required = false,
                                 default = nil)
  if valid_598565 != nil:
    section.add "X-Amz-Signature", valid_598565
  var valid_598566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598566 = validateParameter(valid_598566, JString, required = false,
                                 default = nil)
  if valid_598566 != nil:
    section.add "X-Amz-Content-Sha256", valid_598566
  var valid_598567 = header.getOrDefault("X-Amz-Date")
  valid_598567 = validateParameter(valid_598567, JString, required = false,
                                 default = nil)
  if valid_598567 != nil:
    section.add "X-Amz-Date", valid_598567
  var valid_598568 = header.getOrDefault("X-Amz-Credential")
  valid_598568 = validateParameter(valid_598568, JString, required = false,
                                 default = nil)
  if valid_598568 != nil:
    section.add "X-Amz-Credential", valid_598568
  var valid_598569 = header.getOrDefault("X-Amz-Security-Token")
  valid_598569 = validateParameter(valid_598569, JString, required = false,
                                 default = nil)
  if valid_598569 != nil:
    section.add "X-Amz-Security-Token", valid_598569
  var valid_598570 = header.getOrDefault("X-Amz-Algorithm")
  valid_598570 = validateParameter(valid_598570, JString, required = false,
                                 default = nil)
  if valid_598570 != nil:
    section.add "X-Amz-Algorithm", valid_598570
  var valid_598571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598571 = validateParameter(valid_598571, JString, required = false,
                                 default = nil)
  if valid_598571 != nil:
    section.add "X-Amz-SignedHeaders", valid_598571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598573: Call_UpdateDeployment_598560; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Deployment.
  ## 
  let valid = call_598573.validator(path, query, header, formData, body)
  let scheme = call_598573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598573.url(scheme.get, call_598573.host, call_598573.base,
                         call_598573.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598573, url, valid)

proc call*(call_598574: Call_UpdateDeployment_598560; apiId: string; body: JsonNode;
          deploymentId: string): Recallable =
  ## updateDeployment
  ## Updates a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_598575 = newJObject()
  var body_598576 = newJObject()
  add(path_598575, "apiId", newJString(apiId))
  if body != nil:
    body_598576 = body
  add(path_598575, "deploymentId", newJString(deploymentId))
  result = call_598574.call(path_598575, nil, nil, nil, body_598576)

var updateDeployment* = Call_UpdateDeployment_598560(name: "updateDeployment",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_UpdateDeployment_598561, base: "/",
    url: url_UpdateDeployment_598562, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeployment_598545 = ref object of OpenApiRestCall_597389
proc url_DeleteDeployment_598547(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDeployment_598546(path: JsonNode; query: JsonNode;
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
  var valid_598548 = path.getOrDefault("apiId")
  valid_598548 = validateParameter(valid_598548, JString, required = true,
                                 default = nil)
  if valid_598548 != nil:
    section.add "apiId", valid_598548
  var valid_598549 = path.getOrDefault("deploymentId")
  valid_598549 = validateParameter(valid_598549, JString, required = true,
                                 default = nil)
  if valid_598549 != nil:
    section.add "deploymentId", valid_598549
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
  var valid_598550 = header.getOrDefault("X-Amz-Signature")
  valid_598550 = validateParameter(valid_598550, JString, required = false,
                                 default = nil)
  if valid_598550 != nil:
    section.add "X-Amz-Signature", valid_598550
  var valid_598551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598551 = validateParameter(valid_598551, JString, required = false,
                                 default = nil)
  if valid_598551 != nil:
    section.add "X-Amz-Content-Sha256", valid_598551
  var valid_598552 = header.getOrDefault("X-Amz-Date")
  valid_598552 = validateParameter(valid_598552, JString, required = false,
                                 default = nil)
  if valid_598552 != nil:
    section.add "X-Amz-Date", valid_598552
  var valid_598553 = header.getOrDefault("X-Amz-Credential")
  valid_598553 = validateParameter(valid_598553, JString, required = false,
                                 default = nil)
  if valid_598553 != nil:
    section.add "X-Amz-Credential", valid_598553
  var valid_598554 = header.getOrDefault("X-Amz-Security-Token")
  valid_598554 = validateParameter(valid_598554, JString, required = false,
                                 default = nil)
  if valid_598554 != nil:
    section.add "X-Amz-Security-Token", valid_598554
  var valid_598555 = header.getOrDefault("X-Amz-Algorithm")
  valid_598555 = validateParameter(valid_598555, JString, required = false,
                                 default = nil)
  if valid_598555 != nil:
    section.add "X-Amz-Algorithm", valid_598555
  var valid_598556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598556 = validateParameter(valid_598556, JString, required = false,
                                 default = nil)
  if valid_598556 != nil:
    section.add "X-Amz-SignedHeaders", valid_598556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598557: Call_DeleteDeployment_598545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Deployment.
  ## 
  let valid = call_598557.validator(path, query, header, formData, body)
  let scheme = call_598557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598557.url(scheme.get, call_598557.host, call_598557.base,
                         call_598557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598557, url, valid)

proc call*(call_598558: Call_DeleteDeployment_598545; apiId: string;
          deploymentId: string): Recallable =
  ## deleteDeployment
  ## Deletes a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_598559 = newJObject()
  add(path_598559, "apiId", newJString(apiId))
  add(path_598559, "deploymentId", newJString(deploymentId))
  result = call_598558.call(path_598559, nil, nil, nil, nil)

var deleteDeployment* = Call_DeleteDeployment_598545(name: "deleteDeployment",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_DeleteDeployment_598546, base: "/",
    url: url_DeleteDeployment_598547, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainName_598577 = ref object of OpenApiRestCall_597389
proc url_GetDomainName_598579(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainName_598578(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598580 = path.getOrDefault("domainName")
  valid_598580 = validateParameter(valid_598580, JString, required = true,
                                 default = nil)
  if valid_598580 != nil:
    section.add "domainName", valid_598580
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
  var valid_598581 = header.getOrDefault("X-Amz-Signature")
  valid_598581 = validateParameter(valid_598581, JString, required = false,
                                 default = nil)
  if valid_598581 != nil:
    section.add "X-Amz-Signature", valid_598581
  var valid_598582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598582 = validateParameter(valid_598582, JString, required = false,
                                 default = nil)
  if valid_598582 != nil:
    section.add "X-Amz-Content-Sha256", valid_598582
  var valid_598583 = header.getOrDefault("X-Amz-Date")
  valid_598583 = validateParameter(valid_598583, JString, required = false,
                                 default = nil)
  if valid_598583 != nil:
    section.add "X-Amz-Date", valid_598583
  var valid_598584 = header.getOrDefault("X-Amz-Credential")
  valid_598584 = validateParameter(valid_598584, JString, required = false,
                                 default = nil)
  if valid_598584 != nil:
    section.add "X-Amz-Credential", valid_598584
  var valid_598585 = header.getOrDefault("X-Amz-Security-Token")
  valid_598585 = validateParameter(valid_598585, JString, required = false,
                                 default = nil)
  if valid_598585 != nil:
    section.add "X-Amz-Security-Token", valid_598585
  var valid_598586 = header.getOrDefault("X-Amz-Algorithm")
  valid_598586 = validateParameter(valid_598586, JString, required = false,
                                 default = nil)
  if valid_598586 != nil:
    section.add "X-Amz-Algorithm", valid_598586
  var valid_598587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598587 = validateParameter(valid_598587, JString, required = false,
                                 default = nil)
  if valid_598587 != nil:
    section.add "X-Amz-SignedHeaders", valid_598587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598588: Call_GetDomainName_598577; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a domain name.
  ## 
  let valid = call_598588.validator(path, query, header, formData, body)
  let scheme = call_598588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598588.url(scheme.get, call_598588.host, call_598588.base,
                         call_598588.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598588, url, valid)

proc call*(call_598589: Call_GetDomainName_598577; domainName: string): Recallable =
  ## getDomainName
  ## Gets a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_598590 = newJObject()
  add(path_598590, "domainName", newJString(domainName))
  result = call_598589.call(path_598590, nil, nil, nil, nil)

var getDomainName* = Call_GetDomainName_598577(name: "getDomainName",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_GetDomainName_598578,
    base: "/", url: url_GetDomainName_598579, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainName_598605 = ref object of OpenApiRestCall_597389
proc url_UpdateDomainName_598607(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDomainName_598606(path: JsonNode; query: JsonNode;
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
  var valid_598608 = path.getOrDefault("domainName")
  valid_598608 = validateParameter(valid_598608, JString, required = true,
                                 default = nil)
  if valid_598608 != nil:
    section.add "domainName", valid_598608
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
  var valid_598609 = header.getOrDefault("X-Amz-Signature")
  valid_598609 = validateParameter(valid_598609, JString, required = false,
                                 default = nil)
  if valid_598609 != nil:
    section.add "X-Amz-Signature", valid_598609
  var valid_598610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598610 = validateParameter(valid_598610, JString, required = false,
                                 default = nil)
  if valid_598610 != nil:
    section.add "X-Amz-Content-Sha256", valid_598610
  var valid_598611 = header.getOrDefault("X-Amz-Date")
  valid_598611 = validateParameter(valid_598611, JString, required = false,
                                 default = nil)
  if valid_598611 != nil:
    section.add "X-Amz-Date", valid_598611
  var valid_598612 = header.getOrDefault("X-Amz-Credential")
  valid_598612 = validateParameter(valid_598612, JString, required = false,
                                 default = nil)
  if valid_598612 != nil:
    section.add "X-Amz-Credential", valid_598612
  var valid_598613 = header.getOrDefault("X-Amz-Security-Token")
  valid_598613 = validateParameter(valid_598613, JString, required = false,
                                 default = nil)
  if valid_598613 != nil:
    section.add "X-Amz-Security-Token", valid_598613
  var valid_598614 = header.getOrDefault("X-Amz-Algorithm")
  valid_598614 = validateParameter(valid_598614, JString, required = false,
                                 default = nil)
  if valid_598614 != nil:
    section.add "X-Amz-Algorithm", valid_598614
  var valid_598615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598615 = validateParameter(valid_598615, JString, required = false,
                                 default = nil)
  if valid_598615 != nil:
    section.add "X-Amz-SignedHeaders", valid_598615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598617: Call_UpdateDomainName_598605; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a domain name.
  ## 
  let valid = call_598617.validator(path, query, header, formData, body)
  let scheme = call_598617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598617.url(scheme.get, call_598617.host, call_598617.base,
                         call_598617.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598617, url, valid)

proc call*(call_598618: Call_UpdateDomainName_598605; body: JsonNode;
          domainName: string): Recallable =
  ## updateDomainName
  ## Updates a domain name.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : The domain name.
  var path_598619 = newJObject()
  var body_598620 = newJObject()
  if body != nil:
    body_598620 = body
  add(path_598619, "domainName", newJString(domainName))
  result = call_598618.call(path_598619, nil, nil, nil, body_598620)

var updateDomainName* = Call_UpdateDomainName_598605(name: "updateDomainName",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_UpdateDomainName_598606,
    base: "/", url: url_UpdateDomainName_598607,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainName_598591 = ref object of OpenApiRestCall_597389
proc url_DeleteDomainName_598593(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDomainName_598592(path: JsonNode; query: JsonNode;
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
  var valid_598594 = path.getOrDefault("domainName")
  valid_598594 = validateParameter(valid_598594, JString, required = true,
                                 default = nil)
  if valid_598594 != nil:
    section.add "domainName", valid_598594
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
  var valid_598595 = header.getOrDefault("X-Amz-Signature")
  valid_598595 = validateParameter(valid_598595, JString, required = false,
                                 default = nil)
  if valid_598595 != nil:
    section.add "X-Amz-Signature", valid_598595
  var valid_598596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598596 = validateParameter(valid_598596, JString, required = false,
                                 default = nil)
  if valid_598596 != nil:
    section.add "X-Amz-Content-Sha256", valid_598596
  var valid_598597 = header.getOrDefault("X-Amz-Date")
  valid_598597 = validateParameter(valid_598597, JString, required = false,
                                 default = nil)
  if valid_598597 != nil:
    section.add "X-Amz-Date", valid_598597
  var valid_598598 = header.getOrDefault("X-Amz-Credential")
  valid_598598 = validateParameter(valid_598598, JString, required = false,
                                 default = nil)
  if valid_598598 != nil:
    section.add "X-Amz-Credential", valid_598598
  var valid_598599 = header.getOrDefault("X-Amz-Security-Token")
  valid_598599 = validateParameter(valid_598599, JString, required = false,
                                 default = nil)
  if valid_598599 != nil:
    section.add "X-Amz-Security-Token", valid_598599
  var valid_598600 = header.getOrDefault("X-Amz-Algorithm")
  valid_598600 = validateParameter(valid_598600, JString, required = false,
                                 default = nil)
  if valid_598600 != nil:
    section.add "X-Amz-Algorithm", valid_598600
  var valid_598601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598601 = validateParameter(valid_598601, JString, required = false,
                                 default = nil)
  if valid_598601 != nil:
    section.add "X-Amz-SignedHeaders", valid_598601
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598602: Call_DeleteDomainName_598591; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a domain name.
  ## 
  let valid = call_598602.validator(path, query, header, formData, body)
  let scheme = call_598602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598602.url(scheme.get, call_598602.host, call_598602.base,
                         call_598602.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598602, url, valid)

proc call*(call_598603: Call_DeleteDomainName_598591; domainName: string): Recallable =
  ## deleteDomainName
  ## Deletes a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_598604 = newJObject()
  add(path_598604, "domainName", newJString(domainName))
  result = call_598603.call(path_598604, nil, nil, nil, nil)

var deleteDomainName* = Call_DeleteDomainName_598591(name: "deleteDomainName",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_DeleteDomainName_598592,
    base: "/", url: url_DeleteDomainName_598593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegration_598621 = ref object of OpenApiRestCall_597389
proc url_GetIntegration_598623(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegration_598622(path: JsonNode; query: JsonNode;
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
  var valid_598624 = path.getOrDefault("apiId")
  valid_598624 = validateParameter(valid_598624, JString, required = true,
                                 default = nil)
  if valid_598624 != nil:
    section.add "apiId", valid_598624
  var valid_598625 = path.getOrDefault("integrationId")
  valid_598625 = validateParameter(valid_598625, JString, required = true,
                                 default = nil)
  if valid_598625 != nil:
    section.add "integrationId", valid_598625
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
  var valid_598626 = header.getOrDefault("X-Amz-Signature")
  valid_598626 = validateParameter(valid_598626, JString, required = false,
                                 default = nil)
  if valid_598626 != nil:
    section.add "X-Amz-Signature", valid_598626
  var valid_598627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598627 = validateParameter(valid_598627, JString, required = false,
                                 default = nil)
  if valid_598627 != nil:
    section.add "X-Amz-Content-Sha256", valid_598627
  var valid_598628 = header.getOrDefault("X-Amz-Date")
  valid_598628 = validateParameter(valid_598628, JString, required = false,
                                 default = nil)
  if valid_598628 != nil:
    section.add "X-Amz-Date", valid_598628
  var valid_598629 = header.getOrDefault("X-Amz-Credential")
  valid_598629 = validateParameter(valid_598629, JString, required = false,
                                 default = nil)
  if valid_598629 != nil:
    section.add "X-Amz-Credential", valid_598629
  var valid_598630 = header.getOrDefault("X-Amz-Security-Token")
  valid_598630 = validateParameter(valid_598630, JString, required = false,
                                 default = nil)
  if valid_598630 != nil:
    section.add "X-Amz-Security-Token", valid_598630
  var valid_598631 = header.getOrDefault("X-Amz-Algorithm")
  valid_598631 = validateParameter(valid_598631, JString, required = false,
                                 default = nil)
  if valid_598631 != nil:
    section.add "X-Amz-Algorithm", valid_598631
  var valid_598632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598632 = validateParameter(valid_598632, JString, required = false,
                                 default = nil)
  if valid_598632 != nil:
    section.add "X-Amz-SignedHeaders", valid_598632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598633: Call_GetIntegration_598621; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Integration.
  ## 
  let valid = call_598633.validator(path, query, header, formData, body)
  let scheme = call_598633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598633.url(scheme.get, call_598633.host, call_598633.base,
                         call_598633.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598633, url, valid)

proc call*(call_598634: Call_GetIntegration_598621; apiId: string;
          integrationId: string): Recallable =
  ## getIntegration
  ## Gets an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_598635 = newJObject()
  add(path_598635, "apiId", newJString(apiId))
  add(path_598635, "integrationId", newJString(integrationId))
  result = call_598634.call(path_598635, nil, nil, nil, nil)

var getIntegration* = Call_GetIntegration_598621(name: "getIntegration",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_GetIntegration_598622, base: "/", url: url_GetIntegration_598623,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegration_598651 = ref object of OpenApiRestCall_597389
proc url_UpdateIntegration_598653(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateIntegration_598652(path: JsonNode; query: JsonNode;
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
  var valid_598654 = path.getOrDefault("apiId")
  valid_598654 = validateParameter(valid_598654, JString, required = true,
                                 default = nil)
  if valid_598654 != nil:
    section.add "apiId", valid_598654
  var valid_598655 = path.getOrDefault("integrationId")
  valid_598655 = validateParameter(valid_598655, JString, required = true,
                                 default = nil)
  if valid_598655 != nil:
    section.add "integrationId", valid_598655
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
  var valid_598656 = header.getOrDefault("X-Amz-Signature")
  valid_598656 = validateParameter(valid_598656, JString, required = false,
                                 default = nil)
  if valid_598656 != nil:
    section.add "X-Amz-Signature", valid_598656
  var valid_598657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598657 = validateParameter(valid_598657, JString, required = false,
                                 default = nil)
  if valid_598657 != nil:
    section.add "X-Amz-Content-Sha256", valid_598657
  var valid_598658 = header.getOrDefault("X-Amz-Date")
  valid_598658 = validateParameter(valid_598658, JString, required = false,
                                 default = nil)
  if valid_598658 != nil:
    section.add "X-Amz-Date", valid_598658
  var valid_598659 = header.getOrDefault("X-Amz-Credential")
  valid_598659 = validateParameter(valid_598659, JString, required = false,
                                 default = nil)
  if valid_598659 != nil:
    section.add "X-Amz-Credential", valid_598659
  var valid_598660 = header.getOrDefault("X-Amz-Security-Token")
  valid_598660 = validateParameter(valid_598660, JString, required = false,
                                 default = nil)
  if valid_598660 != nil:
    section.add "X-Amz-Security-Token", valid_598660
  var valid_598661 = header.getOrDefault("X-Amz-Algorithm")
  valid_598661 = validateParameter(valid_598661, JString, required = false,
                                 default = nil)
  if valid_598661 != nil:
    section.add "X-Amz-Algorithm", valid_598661
  var valid_598662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598662 = validateParameter(valid_598662, JString, required = false,
                                 default = nil)
  if valid_598662 != nil:
    section.add "X-Amz-SignedHeaders", valid_598662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598664: Call_UpdateIntegration_598651; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Integration.
  ## 
  let valid = call_598664.validator(path, query, header, formData, body)
  let scheme = call_598664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598664.url(scheme.get, call_598664.host, call_598664.base,
                         call_598664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598664, url, valid)

proc call*(call_598665: Call_UpdateIntegration_598651; apiId: string;
          integrationId: string; body: JsonNode): Recallable =
  ## updateIntegration
  ## Updates an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  ##   body: JObject (required)
  var path_598666 = newJObject()
  var body_598667 = newJObject()
  add(path_598666, "apiId", newJString(apiId))
  add(path_598666, "integrationId", newJString(integrationId))
  if body != nil:
    body_598667 = body
  result = call_598665.call(path_598666, nil, nil, nil, body_598667)

var updateIntegration* = Call_UpdateIntegration_598651(name: "updateIntegration",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_UpdateIntegration_598652, base: "/",
    url: url_UpdateIntegration_598653, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegration_598636 = ref object of OpenApiRestCall_597389
proc url_DeleteIntegration_598638(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIntegration_598637(path: JsonNode; query: JsonNode;
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
  var valid_598639 = path.getOrDefault("apiId")
  valid_598639 = validateParameter(valid_598639, JString, required = true,
                                 default = nil)
  if valid_598639 != nil:
    section.add "apiId", valid_598639
  var valid_598640 = path.getOrDefault("integrationId")
  valid_598640 = validateParameter(valid_598640, JString, required = true,
                                 default = nil)
  if valid_598640 != nil:
    section.add "integrationId", valid_598640
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
  var valid_598641 = header.getOrDefault("X-Amz-Signature")
  valid_598641 = validateParameter(valid_598641, JString, required = false,
                                 default = nil)
  if valid_598641 != nil:
    section.add "X-Amz-Signature", valid_598641
  var valid_598642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598642 = validateParameter(valid_598642, JString, required = false,
                                 default = nil)
  if valid_598642 != nil:
    section.add "X-Amz-Content-Sha256", valid_598642
  var valid_598643 = header.getOrDefault("X-Amz-Date")
  valid_598643 = validateParameter(valid_598643, JString, required = false,
                                 default = nil)
  if valid_598643 != nil:
    section.add "X-Amz-Date", valid_598643
  var valid_598644 = header.getOrDefault("X-Amz-Credential")
  valid_598644 = validateParameter(valid_598644, JString, required = false,
                                 default = nil)
  if valid_598644 != nil:
    section.add "X-Amz-Credential", valid_598644
  var valid_598645 = header.getOrDefault("X-Amz-Security-Token")
  valid_598645 = validateParameter(valid_598645, JString, required = false,
                                 default = nil)
  if valid_598645 != nil:
    section.add "X-Amz-Security-Token", valid_598645
  var valid_598646 = header.getOrDefault("X-Amz-Algorithm")
  valid_598646 = validateParameter(valid_598646, JString, required = false,
                                 default = nil)
  if valid_598646 != nil:
    section.add "X-Amz-Algorithm", valid_598646
  var valid_598647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598647 = validateParameter(valid_598647, JString, required = false,
                                 default = nil)
  if valid_598647 != nil:
    section.add "X-Amz-SignedHeaders", valid_598647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598648: Call_DeleteIntegration_598636; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Integration.
  ## 
  let valid = call_598648.validator(path, query, header, formData, body)
  let scheme = call_598648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598648.url(scheme.get, call_598648.host, call_598648.base,
                         call_598648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598648, url, valid)

proc call*(call_598649: Call_DeleteIntegration_598636; apiId: string;
          integrationId: string): Recallable =
  ## deleteIntegration
  ## Deletes an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_598650 = newJObject()
  add(path_598650, "apiId", newJString(apiId))
  add(path_598650, "integrationId", newJString(integrationId))
  result = call_598649.call(path_598650, nil, nil, nil, nil)

var deleteIntegration* = Call_DeleteIntegration_598636(name: "deleteIntegration",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_DeleteIntegration_598637, base: "/",
    url: url_DeleteIntegration_598638, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponse_598668 = ref object of OpenApiRestCall_597389
proc url_GetIntegrationResponse_598670(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegrationResponse_598669(path: JsonNode; query: JsonNode;
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
  var valid_598671 = path.getOrDefault("integrationResponseId")
  valid_598671 = validateParameter(valid_598671, JString, required = true,
                                 default = nil)
  if valid_598671 != nil:
    section.add "integrationResponseId", valid_598671
  var valid_598672 = path.getOrDefault("apiId")
  valid_598672 = validateParameter(valid_598672, JString, required = true,
                                 default = nil)
  if valid_598672 != nil:
    section.add "apiId", valid_598672
  var valid_598673 = path.getOrDefault("integrationId")
  valid_598673 = validateParameter(valid_598673, JString, required = true,
                                 default = nil)
  if valid_598673 != nil:
    section.add "integrationId", valid_598673
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
  var valid_598674 = header.getOrDefault("X-Amz-Signature")
  valid_598674 = validateParameter(valid_598674, JString, required = false,
                                 default = nil)
  if valid_598674 != nil:
    section.add "X-Amz-Signature", valid_598674
  var valid_598675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598675 = validateParameter(valid_598675, JString, required = false,
                                 default = nil)
  if valid_598675 != nil:
    section.add "X-Amz-Content-Sha256", valid_598675
  var valid_598676 = header.getOrDefault("X-Amz-Date")
  valid_598676 = validateParameter(valid_598676, JString, required = false,
                                 default = nil)
  if valid_598676 != nil:
    section.add "X-Amz-Date", valid_598676
  var valid_598677 = header.getOrDefault("X-Amz-Credential")
  valid_598677 = validateParameter(valid_598677, JString, required = false,
                                 default = nil)
  if valid_598677 != nil:
    section.add "X-Amz-Credential", valid_598677
  var valid_598678 = header.getOrDefault("X-Amz-Security-Token")
  valid_598678 = validateParameter(valid_598678, JString, required = false,
                                 default = nil)
  if valid_598678 != nil:
    section.add "X-Amz-Security-Token", valid_598678
  var valid_598679 = header.getOrDefault("X-Amz-Algorithm")
  valid_598679 = validateParameter(valid_598679, JString, required = false,
                                 default = nil)
  if valid_598679 != nil:
    section.add "X-Amz-Algorithm", valid_598679
  var valid_598680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598680 = validateParameter(valid_598680, JString, required = false,
                                 default = nil)
  if valid_598680 != nil:
    section.add "X-Amz-SignedHeaders", valid_598680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598681: Call_GetIntegrationResponse_598668; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an IntegrationResponses.
  ## 
  let valid = call_598681.validator(path, query, header, formData, body)
  let scheme = call_598681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598681.url(scheme.get, call_598681.host, call_598681.base,
                         call_598681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598681, url, valid)

proc call*(call_598682: Call_GetIntegrationResponse_598668;
          integrationResponseId: string; apiId: string; integrationId: string): Recallable =
  ## getIntegrationResponse
  ## Gets an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_598683 = newJObject()
  add(path_598683, "integrationResponseId", newJString(integrationResponseId))
  add(path_598683, "apiId", newJString(apiId))
  add(path_598683, "integrationId", newJString(integrationId))
  result = call_598682.call(path_598683, nil, nil, nil, nil)

var getIntegrationResponse* = Call_GetIntegrationResponse_598668(
    name: "getIntegrationResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_GetIntegrationResponse_598669, base: "/",
    url: url_GetIntegrationResponse_598670, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegrationResponse_598700 = ref object of OpenApiRestCall_597389
proc url_UpdateIntegrationResponse_598702(protocol: Scheme; host: string;
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

proc validate_UpdateIntegrationResponse_598701(path: JsonNode; query: JsonNode;
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
  var valid_598703 = path.getOrDefault("integrationResponseId")
  valid_598703 = validateParameter(valid_598703, JString, required = true,
                                 default = nil)
  if valid_598703 != nil:
    section.add "integrationResponseId", valid_598703
  var valid_598704 = path.getOrDefault("apiId")
  valid_598704 = validateParameter(valid_598704, JString, required = true,
                                 default = nil)
  if valid_598704 != nil:
    section.add "apiId", valid_598704
  var valid_598705 = path.getOrDefault("integrationId")
  valid_598705 = validateParameter(valid_598705, JString, required = true,
                                 default = nil)
  if valid_598705 != nil:
    section.add "integrationId", valid_598705
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
  var valid_598706 = header.getOrDefault("X-Amz-Signature")
  valid_598706 = validateParameter(valid_598706, JString, required = false,
                                 default = nil)
  if valid_598706 != nil:
    section.add "X-Amz-Signature", valid_598706
  var valid_598707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598707 = validateParameter(valid_598707, JString, required = false,
                                 default = nil)
  if valid_598707 != nil:
    section.add "X-Amz-Content-Sha256", valid_598707
  var valid_598708 = header.getOrDefault("X-Amz-Date")
  valid_598708 = validateParameter(valid_598708, JString, required = false,
                                 default = nil)
  if valid_598708 != nil:
    section.add "X-Amz-Date", valid_598708
  var valid_598709 = header.getOrDefault("X-Amz-Credential")
  valid_598709 = validateParameter(valid_598709, JString, required = false,
                                 default = nil)
  if valid_598709 != nil:
    section.add "X-Amz-Credential", valid_598709
  var valid_598710 = header.getOrDefault("X-Amz-Security-Token")
  valid_598710 = validateParameter(valid_598710, JString, required = false,
                                 default = nil)
  if valid_598710 != nil:
    section.add "X-Amz-Security-Token", valid_598710
  var valid_598711 = header.getOrDefault("X-Amz-Algorithm")
  valid_598711 = validateParameter(valid_598711, JString, required = false,
                                 default = nil)
  if valid_598711 != nil:
    section.add "X-Amz-Algorithm", valid_598711
  var valid_598712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598712 = validateParameter(valid_598712, JString, required = false,
                                 default = nil)
  if valid_598712 != nil:
    section.add "X-Amz-SignedHeaders", valid_598712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598714: Call_UpdateIntegrationResponse_598700; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an IntegrationResponses.
  ## 
  let valid = call_598714.validator(path, query, header, formData, body)
  let scheme = call_598714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598714.url(scheme.get, call_598714.host, call_598714.base,
                         call_598714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598714, url, valid)

proc call*(call_598715: Call_UpdateIntegrationResponse_598700;
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
  var path_598716 = newJObject()
  var body_598717 = newJObject()
  add(path_598716, "integrationResponseId", newJString(integrationResponseId))
  add(path_598716, "apiId", newJString(apiId))
  add(path_598716, "integrationId", newJString(integrationId))
  if body != nil:
    body_598717 = body
  result = call_598715.call(path_598716, nil, nil, nil, body_598717)

var updateIntegrationResponse* = Call_UpdateIntegrationResponse_598700(
    name: "updateIntegrationResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_UpdateIntegrationResponse_598701, base: "/",
    url: url_UpdateIntegrationResponse_598702,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegrationResponse_598684 = ref object of OpenApiRestCall_597389
proc url_DeleteIntegrationResponse_598686(protocol: Scheme; host: string;
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

proc validate_DeleteIntegrationResponse_598685(path: JsonNode; query: JsonNode;
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
  var valid_598687 = path.getOrDefault("integrationResponseId")
  valid_598687 = validateParameter(valid_598687, JString, required = true,
                                 default = nil)
  if valid_598687 != nil:
    section.add "integrationResponseId", valid_598687
  var valid_598688 = path.getOrDefault("apiId")
  valid_598688 = validateParameter(valid_598688, JString, required = true,
                                 default = nil)
  if valid_598688 != nil:
    section.add "apiId", valid_598688
  var valid_598689 = path.getOrDefault("integrationId")
  valid_598689 = validateParameter(valid_598689, JString, required = true,
                                 default = nil)
  if valid_598689 != nil:
    section.add "integrationId", valid_598689
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
  var valid_598690 = header.getOrDefault("X-Amz-Signature")
  valid_598690 = validateParameter(valid_598690, JString, required = false,
                                 default = nil)
  if valid_598690 != nil:
    section.add "X-Amz-Signature", valid_598690
  var valid_598691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598691 = validateParameter(valid_598691, JString, required = false,
                                 default = nil)
  if valid_598691 != nil:
    section.add "X-Amz-Content-Sha256", valid_598691
  var valid_598692 = header.getOrDefault("X-Amz-Date")
  valid_598692 = validateParameter(valid_598692, JString, required = false,
                                 default = nil)
  if valid_598692 != nil:
    section.add "X-Amz-Date", valid_598692
  var valid_598693 = header.getOrDefault("X-Amz-Credential")
  valid_598693 = validateParameter(valid_598693, JString, required = false,
                                 default = nil)
  if valid_598693 != nil:
    section.add "X-Amz-Credential", valid_598693
  var valid_598694 = header.getOrDefault("X-Amz-Security-Token")
  valid_598694 = validateParameter(valid_598694, JString, required = false,
                                 default = nil)
  if valid_598694 != nil:
    section.add "X-Amz-Security-Token", valid_598694
  var valid_598695 = header.getOrDefault("X-Amz-Algorithm")
  valid_598695 = validateParameter(valid_598695, JString, required = false,
                                 default = nil)
  if valid_598695 != nil:
    section.add "X-Amz-Algorithm", valid_598695
  var valid_598696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598696 = validateParameter(valid_598696, JString, required = false,
                                 default = nil)
  if valid_598696 != nil:
    section.add "X-Amz-SignedHeaders", valid_598696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598697: Call_DeleteIntegrationResponse_598684; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an IntegrationResponses.
  ## 
  let valid = call_598697.validator(path, query, header, formData, body)
  let scheme = call_598697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598697.url(scheme.get, call_598697.host, call_598697.base,
                         call_598697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598697, url, valid)

proc call*(call_598698: Call_DeleteIntegrationResponse_598684;
          integrationResponseId: string; apiId: string; integrationId: string): Recallable =
  ## deleteIntegrationResponse
  ## Deletes an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_598699 = newJObject()
  add(path_598699, "integrationResponseId", newJString(integrationResponseId))
  add(path_598699, "apiId", newJString(apiId))
  add(path_598699, "integrationId", newJString(integrationId))
  result = call_598698.call(path_598699, nil, nil, nil, nil)

var deleteIntegrationResponse* = Call_DeleteIntegrationResponse_598684(
    name: "deleteIntegrationResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_DeleteIntegrationResponse_598685, base: "/",
    url: url_DeleteIntegrationResponse_598686,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModel_598718 = ref object of OpenApiRestCall_597389
proc url_GetModel_598720(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetModel_598719(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598721 = path.getOrDefault("apiId")
  valid_598721 = validateParameter(valid_598721, JString, required = true,
                                 default = nil)
  if valid_598721 != nil:
    section.add "apiId", valid_598721
  var valid_598722 = path.getOrDefault("modelId")
  valid_598722 = validateParameter(valid_598722, JString, required = true,
                                 default = nil)
  if valid_598722 != nil:
    section.add "modelId", valid_598722
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
  var valid_598723 = header.getOrDefault("X-Amz-Signature")
  valid_598723 = validateParameter(valid_598723, JString, required = false,
                                 default = nil)
  if valid_598723 != nil:
    section.add "X-Amz-Signature", valid_598723
  var valid_598724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598724 = validateParameter(valid_598724, JString, required = false,
                                 default = nil)
  if valid_598724 != nil:
    section.add "X-Amz-Content-Sha256", valid_598724
  var valid_598725 = header.getOrDefault("X-Amz-Date")
  valid_598725 = validateParameter(valid_598725, JString, required = false,
                                 default = nil)
  if valid_598725 != nil:
    section.add "X-Amz-Date", valid_598725
  var valid_598726 = header.getOrDefault("X-Amz-Credential")
  valid_598726 = validateParameter(valid_598726, JString, required = false,
                                 default = nil)
  if valid_598726 != nil:
    section.add "X-Amz-Credential", valid_598726
  var valid_598727 = header.getOrDefault("X-Amz-Security-Token")
  valid_598727 = validateParameter(valid_598727, JString, required = false,
                                 default = nil)
  if valid_598727 != nil:
    section.add "X-Amz-Security-Token", valid_598727
  var valid_598728 = header.getOrDefault("X-Amz-Algorithm")
  valid_598728 = validateParameter(valid_598728, JString, required = false,
                                 default = nil)
  if valid_598728 != nil:
    section.add "X-Amz-Algorithm", valid_598728
  var valid_598729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598729 = validateParameter(valid_598729, JString, required = false,
                                 default = nil)
  if valid_598729 != nil:
    section.add "X-Amz-SignedHeaders", valid_598729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598730: Call_GetModel_598718; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Model.
  ## 
  let valid = call_598730.validator(path, query, header, formData, body)
  let scheme = call_598730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598730.url(scheme.get, call_598730.host, call_598730.base,
                         call_598730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598730, url, valid)

proc call*(call_598731: Call_GetModel_598718; apiId: string; modelId: string): Recallable =
  ## getModel
  ## Gets a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_598732 = newJObject()
  add(path_598732, "apiId", newJString(apiId))
  add(path_598732, "modelId", newJString(modelId))
  result = call_598731.call(path_598732, nil, nil, nil, nil)

var getModel* = Call_GetModel_598718(name: "getModel", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/models/{modelId}",
                                  validator: validate_GetModel_598719, base: "/",
                                  url: url_GetModel_598720,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModel_598748 = ref object of OpenApiRestCall_597389
proc url_UpdateModel_598750(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateModel_598749(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598751 = path.getOrDefault("apiId")
  valid_598751 = validateParameter(valid_598751, JString, required = true,
                                 default = nil)
  if valid_598751 != nil:
    section.add "apiId", valid_598751
  var valid_598752 = path.getOrDefault("modelId")
  valid_598752 = validateParameter(valid_598752, JString, required = true,
                                 default = nil)
  if valid_598752 != nil:
    section.add "modelId", valid_598752
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
  var valid_598753 = header.getOrDefault("X-Amz-Signature")
  valid_598753 = validateParameter(valid_598753, JString, required = false,
                                 default = nil)
  if valid_598753 != nil:
    section.add "X-Amz-Signature", valid_598753
  var valid_598754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598754 = validateParameter(valid_598754, JString, required = false,
                                 default = nil)
  if valid_598754 != nil:
    section.add "X-Amz-Content-Sha256", valid_598754
  var valid_598755 = header.getOrDefault("X-Amz-Date")
  valid_598755 = validateParameter(valid_598755, JString, required = false,
                                 default = nil)
  if valid_598755 != nil:
    section.add "X-Amz-Date", valid_598755
  var valid_598756 = header.getOrDefault("X-Amz-Credential")
  valid_598756 = validateParameter(valid_598756, JString, required = false,
                                 default = nil)
  if valid_598756 != nil:
    section.add "X-Amz-Credential", valid_598756
  var valid_598757 = header.getOrDefault("X-Amz-Security-Token")
  valid_598757 = validateParameter(valid_598757, JString, required = false,
                                 default = nil)
  if valid_598757 != nil:
    section.add "X-Amz-Security-Token", valid_598757
  var valid_598758 = header.getOrDefault("X-Amz-Algorithm")
  valid_598758 = validateParameter(valid_598758, JString, required = false,
                                 default = nil)
  if valid_598758 != nil:
    section.add "X-Amz-Algorithm", valid_598758
  var valid_598759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598759 = validateParameter(valid_598759, JString, required = false,
                                 default = nil)
  if valid_598759 != nil:
    section.add "X-Amz-SignedHeaders", valid_598759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598761: Call_UpdateModel_598748; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Model.
  ## 
  let valid = call_598761.validator(path, query, header, formData, body)
  let scheme = call_598761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598761.url(scheme.get, call_598761.host, call_598761.base,
                         call_598761.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598761, url, valid)

proc call*(call_598762: Call_UpdateModel_598748; apiId: string; body: JsonNode;
          modelId: string): Recallable =
  ## updateModel
  ## Updates a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   modelId: string (required)
  ##          : The model ID.
  var path_598763 = newJObject()
  var body_598764 = newJObject()
  add(path_598763, "apiId", newJString(apiId))
  if body != nil:
    body_598764 = body
  add(path_598763, "modelId", newJString(modelId))
  result = call_598762.call(path_598763, nil, nil, nil, body_598764)

var updateModel* = Call_UpdateModel_598748(name: "updateModel",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/models/{modelId}",
                                        validator: validate_UpdateModel_598749,
                                        base: "/", url: url_UpdateModel_598750,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_598733 = ref object of OpenApiRestCall_597389
proc url_DeleteModel_598735(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteModel_598734(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598736 = path.getOrDefault("apiId")
  valid_598736 = validateParameter(valid_598736, JString, required = true,
                                 default = nil)
  if valid_598736 != nil:
    section.add "apiId", valid_598736
  var valid_598737 = path.getOrDefault("modelId")
  valid_598737 = validateParameter(valid_598737, JString, required = true,
                                 default = nil)
  if valid_598737 != nil:
    section.add "modelId", valid_598737
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
  var valid_598738 = header.getOrDefault("X-Amz-Signature")
  valid_598738 = validateParameter(valid_598738, JString, required = false,
                                 default = nil)
  if valid_598738 != nil:
    section.add "X-Amz-Signature", valid_598738
  var valid_598739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598739 = validateParameter(valid_598739, JString, required = false,
                                 default = nil)
  if valid_598739 != nil:
    section.add "X-Amz-Content-Sha256", valid_598739
  var valid_598740 = header.getOrDefault("X-Amz-Date")
  valid_598740 = validateParameter(valid_598740, JString, required = false,
                                 default = nil)
  if valid_598740 != nil:
    section.add "X-Amz-Date", valid_598740
  var valid_598741 = header.getOrDefault("X-Amz-Credential")
  valid_598741 = validateParameter(valid_598741, JString, required = false,
                                 default = nil)
  if valid_598741 != nil:
    section.add "X-Amz-Credential", valid_598741
  var valid_598742 = header.getOrDefault("X-Amz-Security-Token")
  valid_598742 = validateParameter(valid_598742, JString, required = false,
                                 default = nil)
  if valid_598742 != nil:
    section.add "X-Amz-Security-Token", valid_598742
  var valid_598743 = header.getOrDefault("X-Amz-Algorithm")
  valid_598743 = validateParameter(valid_598743, JString, required = false,
                                 default = nil)
  if valid_598743 != nil:
    section.add "X-Amz-Algorithm", valid_598743
  var valid_598744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598744 = validateParameter(valid_598744, JString, required = false,
                                 default = nil)
  if valid_598744 != nil:
    section.add "X-Amz-SignedHeaders", valid_598744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598745: Call_DeleteModel_598733; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Model.
  ## 
  let valid = call_598745.validator(path, query, header, formData, body)
  let scheme = call_598745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598745.url(scheme.get, call_598745.host, call_598745.base,
                         call_598745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598745, url, valid)

proc call*(call_598746: Call_DeleteModel_598733; apiId: string; modelId: string): Recallable =
  ## deleteModel
  ## Deletes a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_598747 = newJObject()
  add(path_598747, "apiId", newJString(apiId))
  add(path_598747, "modelId", newJString(modelId))
  result = call_598746.call(path_598747, nil, nil, nil, nil)

var deleteModel* = Call_DeleteModel_598733(name: "deleteModel",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/models/{modelId}",
                                        validator: validate_DeleteModel_598734,
                                        base: "/", url: url_DeleteModel_598735,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoute_598765 = ref object of OpenApiRestCall_597389
proc url_GetRoute_598767(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRoute_598766(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598768 = path.getOrDefault("apiId")
  valid_598768 = validateParameter(valid_598768, JString, required = true,
                                 default = nil)
  if valid_598768 != nil:
    section.add "apiId", valid_598768
  var valid_598769 = path.getOrDefault("routeId")
  valid_598769 = validateParameter(valid_598769, JString, required = true,
                                 default = nil)
  if valid_598769 != nil:
    section.add "routeId", valid_598769
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
  var valid_598770 = header.getOrDefault("X-Amz-Signature")
  valid_598770 = validateParameter(valid_598770, JString, required = false,
                                 default = nil)
  if valid_598770 != nil:
    section.add "X-Amz-Signature", valid_598770
  var valid_598771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598771 = validateParameter(valid_598771, JString, required = false,
                                 default = nil)
  if valid_598771 != nil:
    section.add "X-Amz-Content-Sha256", valid_598771
  var valid_598772 = header.getOrDefault("X-Amz-Date")
  valid_598772 = validateParameter(valid_598772, JString, required = false,
                                 default = nil)
  if valid_598772 != nil:
    section.add "X-Amz-Date", valid_598772
  var valid_598773 = header.getOrDefault("X-Amz-Credential")
  valid_598773 = validateParameter(valid_598773, JString, required = false,
                                 default = nil)
  if valid_598773 != nil:
    section.add "X-Amz-Credential", valid_598773
  var valid_598774 = header.getOrDefault("X-Amz-Security-Token")
  valid_598774 = validateParameter(valid_598774, JString, required = false,
                                 default = nil)
  if valid_598774 != nil:
    section.add "X-Amz-Security-Token", valid_598774
  var valid_598775 = header.getOrDefault("X-Amz-Algorithm")
  valid_598775 = validateParameter(valid_598775, JString, required = false,
                                 default = nil)
  if valid_598775 != nil:
    section.add "X-Amz-Algorithm", valid_598775
  var valid_598776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598776 = validateParameter(valid_598776, JString, required = false,
                                 default = nil)
  if valid_598776 != nil:
    section.add "X-Amz-SignedHeaders", valid_598776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598777: Call_GetRoute_598765; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Route.
  ## 
  let valid = call_598777.validator(path, query, header, formData, body)
  let scheme = call_598777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598777.url(scheme.get, call_598777.host, call_598777.base,
                         call_598777.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598777, url, valid)

proc call*(call_598778: Call_GetRoute_598765; apiId: string; routeId: string): Recallable =
  ## getRoute
  ## Gets a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_598779 = newJObject()
  add(path_598779, "apiId", newJString(apiId))
  add(path_598779, "routeId", newJString(routeId))
  result = call_598778.call(path_598779, nil, nil, nil, nil)

var getRoute* = Call_GetRoute_598765(name: "getRoute", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/routes/{routeId}",
                                  validator: validate_GetRoute_598766, base: "/",
                                  url: url_GetRoute_598767,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoute_598795 = ref object of OpenApiRestCall_597389
proc url_UpdateRoute_598797(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRoute_598796(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598798 = path.getOrDefault("apiId")
  valid_598798 = validateParameter(valid_598798, JString, required = true,
                                 default = nil)
  if valid_598798 != nil:
    section.add "apiId", valid_598798
  var valid_598799 = path.getOrDefault("routeId")
  valid_598799 = validateParameter(valid_598799, JString, required = true,
                                 default = nil)
  if valid_598799 != nil:
    section.add "routeId", valid_598799
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
  var valid_598800 = header.getOrDefault("X-Amz-Signature")
  valid_598800 = validateParameter(valid_598800, JString, required = false,
                                 default = nil)
  if valid_598800 != nil:
    section.add "X-Amz-Signature", valid_598800
  var valid_598801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598801 = validateParameter(valid_598801, JString, required = false,
                                 default = nil)
  if valid_598801 != nil:
    section.add "X-Amz-Content-Sha256", valid_598801
  var valid_598802 = header.getOrDefault("X-Amz-Date")
  valid_598802 = validateParameter(valid_598802, JString, required = false,
                                 default = nil)
  if valid_598802 != nil:
    section.add "X-Amz-Date", valid_598802
  var valid_598803 = header.getOrDefault("X-Amz-Credential")
  valid_598803 = validateParameter(valid_598803, JString, required = false,
                                 default = nil)
  if valid_598803 != nil:
    section.add "X-Amz-Credential", valid_598803
  var valid_598804 = header.getOrDefault("X-Amz-Security-Token")
  valid_598804 = validateParameter(valid_598804, JString, required = false,
                                 default = nil)
  if valid_598804 != nil:
    section.add "X-Amz-Security-Token", valid_598804
  var valid_598805 = header.getOrDefault("X-Amz-Algorithm")
  valid_598805 = validateParameter(valid_598805, JString, required = false,
                                 default = nil)
  if valid_598805 != nil:
    section.add "X-Amz-Algorithm", valid_598805
  var valid_598806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598806 = validateParameter(valid_598806, JString, required = false,
                                 default = nil)
  if valid_598806 != nil:
    section.add "X-Amz-SignedHeaders", valid_598806
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598808: Call_UpdateRoute_598795; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Route.
  ## 
  let valid = call_598808.validator(path, query, header, formData, body)
  let scheme = call_598808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598808.url(scheme.get, call_598808.host, call_598808.base,
                         call_598808.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598808, url, valid)

proc call*(call_598809: Call_UpdateRoute_598795; apiId: string; body: JsonNode;
          routeId: string): Recallable =
  ## updateRoute
  ## Updates a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   routeId: string (required)
  ##          : The route ID.
  var path_598810 = newJObject()
  var body_598811 = newJObject()
  add(path_598810, "apiId", newJString(apiId))
  if body != nil:
    body_598811 = body
  add(path_598810, "routeId", newJString(routeId))
  result = call_598809.call(path_598810, nil, nil, nil, body_598811)

var updateRoute* = Call_UpdateRoute_598795(name: "updateRoute",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}",
                                        validator: validate_UpdateRoute_598796,
                                        base: "/", url: url_UpdateRoute_598797,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoute_598780 = ref object of OpenApiRestCall_597389
proc url_DeleteRoute_598782(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRoute_598781(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598783 = path.getOrDefault("apiId")
  valid_598783 = validateParameter(valid_598783, JString, required = true,
                                 default = nil)
  if valid_598783 != nil:
    section.add "apiId", valid_598783
  var valid_598784 = path.getOrDefault("routeId")
  valid_598784 = validateParameter(valid_598784, JString, required = true,
                                 default = nil)
  if valid_598784 != nil:
    section.add "routeId", valid_598784
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
  var valid_598785 = header.getOrDefault("X-Amz-Signature")
  valid_598785 = validateParameter(valid_598785, JString, required = false,
                                 default = nil)
  if valid_598785 != nil:
    section.add "X-Amz-Signature", valid_598785
  var valid_598786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598786 = validateParameter(valid_598786, JString, required = false,
                                 default = nil)
  if valid_598786 != nil:
    section.add "X-Amz-Content-Sha256", valid_598786
  var valid_598787 = header.getOrDefault("X-Amz-Date")
  valid_598787 = validateParameter(valid_598787, JString, required = false,
                                 default = nil)
  if valid_598787 != nil:
    section.add "X-Amz-Date", valid_598787
  var valid_598788 = header.getOrDefault("X-Amz-Credential")
  valid_598788 = validateParameter(valid_598788, JString, required = false,
                                 default = nil)
  if valid_598788 != nil:
    section.add "X-Amz-Credential", valid_598788
  var valid_598789 = header.getOrDefault("X-Amz-Security-Token")
  valid_598789 = validateParameter(valid_598789, JString, required = false,
                                 default = nil)
  if valid_598789 != nil:
    section.add "X-Amz-Security-Token", valid_598789
  var valid_598790 = header.getOrDefault("X-Amz-Algorithm")
  valid_598790 = validateParameter(valid_598790, JString, required = false,
                                 default = nil)
  if valid_598790 != nil:
    section.add "X-Amz-Algorithm", valid_598790
  var valid_598791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598791 = validateParameter(valid_598791, JString, required = false,
                                 default = nil)
  if valid_598791 != nil:
    section.add "X-Amz-SignedHeaders", valid_598791
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598792: Call_DeleteRoute_598780; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Route.
  ## 
  let valid = call_598792.validator(path, query, header, formData, body)
  let scheme = call_598792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598792.url(scheme.get, call_598792.host, call_598792.base,
                         call_598792.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598792, url, valid)

proc call*(call_598793: Call_DeleteRoute_598780; apiId: string; routeId: string): Recallable =
  ## deleteRoute
  ## Deletes a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_598794 = newJObject()
  add(path_598794, "apiId", newJString(apiId))
  add(path_598794, "routeId", newJString(routeId))
  result = call_598793.call(path_598794, nil, nil, nil, nil)

var deleteRoute* = Call_DeleteRoute_598780(name: "deleteRoute",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}",
                                        validator: validate_DeleteRoute_598781,
                                        base: "/", url: url_DeleteRoute_598782,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRouteResponse_598812 = ref object of OpenApiRestCall_597389
proc url_GetRouteResponse_598814(protocol: Scheme; host: string; base: string;
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

proc validate_GetRouteResponse_598813(path: JsonNode; query: JsonNode;
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
  var valid_598815 = path.getOrDefault("apiId")
  valid_598815 = validateParameter(valid_598815, JString, required = true,
                                 default = nil)
  if valid_598815 != nil:
    section.add "apiId", valid_598815
  var valid_598816 = path.getOrDefault("routeResponseId")
  valid_598816 = validateParameter(valid_598816, JString, required = true,
                                 default = nil)
  if valid_598816 != nil:
    section.add "routeResponseId", valid_598816
  var valid_598817 = path.getOrDefault("routeId")
  valid_598817 = validateParameter(valid_598817, JString, required = true,
                                 default = nil)
  if valid_598817 != nil:
    section.add "routeId", valid_598817
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
  var valid_598818 = header.getOrDefault("X-Amz-Signature")
  valid_598818 = validateParameter(valid_598818, JString, required = false,
                                 default = nil)
  if valid_598818 != nil:
    section.add "X-Amz-Signature", valid_598818
  var valid_598819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598819 = validateParameter(valid_598819, JString, required = false,
                                 default = nil)
  if valid_598819 != nil:
    section.add "X-Amz-Content-Sha256", valid_598819
  var valid_598820 = header.getOrDefault("X-Amz-Date")
  valid_598820 = validateParameter(valid_598820, JString, required = false,
                                 default = nil)
  if valid_598820 != nil:
    section.add "X-Amz-Date", valid_598820
  var valid_598821 = header.getOrDefault("X-Amz-Credential")
  valid_598821 = validateParameter(valid_598821, JString, required = false,
                                 default = nil)
  if valid_598821 != nil:
    section.add "X-Amz-Credential", valid_598821
  var valid_598822 = header.getOrDefault("X-Amz-Security-Token")
  valid_598822 = validateParameter(valid_598822, JString, required = false,
                                 default = nil)
  if valid_598822 != nil:
    section.add "X-Amz-Security-Token", valid_598822
  var valid_598823 = header.getOrDefault("X-Amz-Algorithm")
  valid_598823 = validateParameter(valid_598823, JString, required = false,
                                 default = nil)
  if valid_598823 != nil:
    section.add "X-Amz-Algorithm", valid_598823
  var valid_598824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598824 = validateParameter(valid_598824, JString, required = false,
                                 default = nil)
  if valid_598824 != nil:
    section.add "X-Amz-SignedHeaders", valid_598824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598825: Call_GetRouteResponse_598812; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a RouteResponse.
  ## 
  let valid = call_598825.validator(path, query, header, formData, body)
  let scheme = call_598825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598825.url(scheme.get, call_598825.host, call_598825.base,
                         call_598825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598825, url, valid)

proc call*(call_598826: Call_GetRouteResponse_598812; apiId: string;
          routeResponseId: string; routeId: string): Recallable =
  ## getRouteResponse
  ## Gets a RouteResponse.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeResponseId: string (required)
  ##                  : The route response ID.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_598827 = newJObject()
  add(path_598827, "apiId", newJString(apiId))
  add(path_598827, "routeResponseId", newJString(routeResponseId))
  add(path_598827, "routeId", newJString(routeId))
  result = call_598826.call(path_598827, nil, nil, nil, nil)

var getRouteResponse* = Call_GetRouteResponse_598812(name: "getRouteResponse",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_GetRouteResponse_598813, base: "/",
    url: url_GetRouteResponse_598814, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRouteResponse_598844 = ref object of OpenApiRestCall_597389
proc url_UpdateRouteResponse_598846(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRouteResponse_598845(path: JsonNode; query: JsonNode;
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
  var valid_598847 = path.getOrDefault("apiId")
  valid_598847 = validateParameter(valid_598847, JString, required = true,
                                 default = nil)
  if valid_598847 != nil:
    section.add "apiId", valid_598847
  var valid_598848 = path.getOrDefault("routeResponseId")
  valid_598848 = validateParameter(valid_598848, JString, required = true,
                                 default = nil)
  if valid_598848 != nil:
    section.add "routeResponseId", valid_598848
  var valid_598849 = path.getOrDefault("routeId")
  valid_598849 = validateParameter(valid_598849, JString, required = true,
                                 default = nil)
  if valid_598849 != nil:
    section.add "routeId", valid_598849
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
  var valid_598850 = header.getOrDefault("X-Amz-Signature")
  valid_598850 = validateParameter(valid_598850, JString, required = false,
                                 default = nil)
  if valid_598850 != nil:
    section.add "X-Amz-Signature", valid_598850
  var valid_598851 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598851 = validateParameter(valid_598851, JString, required = false,
                                 default = nil)
  if valid_598851 != nil:
    section.add "X-Amz-Content-Sha256", valid_598851
  var valid_598852 = header.getOrDefault("X-Amz-Date")
  valid_598852 = validateParameter(valid_598852, JString, required = false,
                                 default = nil)
  if valid_598852 != nil:
    section.add "X-Amz-Date", valid_598852
  var valid_598853 = header.getOrDefault("X-Amz-Credential")
  valid_598853 = validateParameter(valid_598853, JString, required = false,
                                 default = nil)
  if valid_598853 != nil:
    section.add "X-Amz-Credential", valid_598853
  var valid_598854 = header.getOrDefault("X-Amz-Security-Token")
  valid_598854 = validateParameter(valid_598854, JString, required = false,
                                 default = nil)
  if valid_598854 != nil:
    section.add "X-Amz-Security-Token", valid_598854
  var valid_598855 = header.getOrDefault("X-Amz-Algorithm")
  valid_598855 = validateParameter(valid_598855, JString, required = false,
                                 default = nil)
  if valid_598855 != nil:
    section.add "X-Amz-Algorithm", valid_598855
  var valid_598856 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598856 = validateParameter(valid_598856, JString, required = false,
                                 default = nil)
  if valid_598856 != nil:
    section.add "X-Amz-SignedHeaders", valid_598856
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598858: Call_UpdateRouteResponse_598844; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a RouteResponse.
  ## 
  let valid = call_598858.validator(path, query, header, formData, body)
  let scheme = call_598858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598858.url(scheme.get, call_598858.host, call_598858.base,
                         call_598858.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598858, url, valid)

proc call*(call_598859: Call_UpdateRouteResponse_598844; apiId: string;
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
  var path_598860 = newJObject()
  var body_598861 = newJObject()
  add(path_598860, "apiId", newJString(apiId))
  add(path_598860, "routeResponseId", newJString(routeResponseId))
  if body != nil:
    body_598861 = body
  add(path_598860, "routeId", newJString(routeId))
  result = call_598859.call(path_598860, nil, nil, nil, body_598861)

var updateRouteResponse* = Call_UpdateRouteResponse_598844(
    name: "updateRouteResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_UpdateRouteResponse_598845, base: "/",
    url: url_UpdateRouteResponse_598846, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRouteResponse_598828 = ref object of OpenApiRestCall_597389
proc url_DeleteRouteResponse_598830(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRouteResponse_598829(path: JsonNode; query: JsonNode;
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
  var valid_598831 = path.getOrDefault("apiId")
  valid_598831 = validateParameter(valid_598831, JString, required = true,
                                 default = nil)
  if valid_598831 != nil:
    section.add "apiId", valid_598831
  var valid_598832 = path.getOrDefault("routeResponseId")
  valid_598832 = validateParameter(valid_598832, JString, required = true,
                                 default = nil)
  if valid_598832 != nil:
    section.add "routeResponseId", valid_598832
  var valid_598833 = path.getOrDefault("routeId")
  valid_598833 = validateParameter(valid_598833, JString, required = true,
                                 default = nil)
  if valid_598833 != nil:
    section.add "routeId", valid_598833
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
  var valid_598834 = header.getOrDefault("X-Amz-Signature")
  valid_598834 = validateParameter(valid_598834, JString, required = false,
                                 default = nil)
  if valid_598834 != nil:
    section.add "X-Amz-Signature", valid_598834
  var valid_598835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598835 = validateParameter(valid_598835, JString, required = false,
                                 default = nil)
  if valid_598835 != nil:
    section.add "X-Amz-Content-Sha256", valid_598835
  var valid_598836 = header.getOrDefault("X-Amz-Date")
  valid_598836 = validateParameter(valid_598836, JString, required = false,
                                 default = nil)
  if valid_598836 != nil:
    section.add "X-Amz-Date", valid_598836
  var valid_598837 = header.getOrDefault("X-Amz-Credential")
  valid_598837 = validateParameter(valid_598837, JString, required = false,
                                 default = nil)
  if valid_598837 != nil:
    section.add "X-Amz-Credential", valid_598837
  var valid_598838 = header.getOrDefault("X-Amz-Security-Token")
  valid_598838 = validateParameter(valid_598838, JString, required = false,
                                 default = nil)
  if valid_598838 != nil:
    section.add "X-Amz-Security-Token", valid_598838
  var valid_598839 = header.getOrDefault("X-Amz-Algorithm")
  valid_598839 = validateParameter(valid_598839, JString, required = false,
                                 default = nil)
  if valid_598839 != nil:
    section.add "X-Amz-Algorithm", valid_598839
  var valid_598840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598840 = validateParameter(valid_598840, JString, required = false,
                                 default = nil)
  if valid_598840 != nil:
    section.add "X-Amz-SignedHeaders", valid_598840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598841: Call_DeleteRouteResponse_598828; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a RouteResponse.
  ## 
  let valid = call_598841.validator(path, query, header, formData, body)
  let scheme = call_598841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598841.url(scheme.get, call_598841.host, call_598841.base,
                         call_598841.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598841, url, valid)

proc call*(call_598842: Call_DeleteRouteResponse_598828; apiId: string;
          routeResponseId: string; routeId: string): Recallable =
  ## deleteRouteResponse
  ## Deletes a RouteResponse.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeResponseId: string (required)
  ##                  : The route response ID.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_598843 = newJObject()
  add(path_598843, "apiId", newJString(apiId))
  add(path_598843, "routeResponseId", newJString(routeResponseId))
  add(path_598843, "routeId", newJString(routeId))
  result = call_598842.call(path_598843, nil, nil, nil, nil)

var deleteRouteResponse* = Call_DeleteRouteResponse_598828(
    name: "deleteRouteResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_DeleteRouteResponse_598829, base: "/",
    url: url_DeleteRouteResponse_598830, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRouteSettings_598862 = ref object of OpenApiRestCall_597389
proc url_DeleteRouteSettings_598864(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRouteSettings_598863(path: JsonNode; query: JsonNode;
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
  var valid_598865 = path.getOrDefault("stageName")
  valid_598865 = validateParameter(valid_598865, JString, required = true,
                                 default = nil)
  if valid_598865 != nil:
    section.add "stageName", valid_598865
  var valid_598866 = path.getOrDefault("routeKey")
  valid_598866 = validateParameter(valid_598866, JString, required = true,
                                 default = nil)
  if valid_598866 != nil:
    section.add "routeKey", valid_598866
  var valid_598867 = path.getOrDefault("apiId")
  valid_598867 = validateParameter(valid_598867, JString, required = true,
                                 default = nil)
  if valid_598867 != nil:
    section.add "apiId", valid_598867
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
  var valid_598868 = header.getOrDefault("X-Amz-Signature")
  valid_598868 = validateParameter(valid_598868, JString, required = false,
                                 default = nil)
  if valid_598868 != nil:
    section.add "X-Amz-Signature", valid_598868
  var valid_598869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598869 = validateParameter(valid_598869, JString, required = false,
                                 default = nil)
  if valid_598869 != nil:
    section.add "X-Amz-Content-Sha256", valid_598869
  var valid_598870 = header.getOrDefault("X-Amz-Date")
  valid_598870 = validateParameter(valid_598870, JString, required = false,
                                 default = nil)
  if valid_598870 != nil:
    section.add "X-Amz-Date", valid_598870
  var valid_598871 = header.getOrDefault("X-Amz-Credential")
  valid_598871 = validateParameter(valid_598871, JString, required = false,
                                 default = nil)
  if valid_598871 != nil:
    section.add "X-Amz-Credential", valid_598871
  var valid_598872 = header.getOrDefault("X-Amz-Security-Token")
  valid_598872 = validateParameter(valid_598872, JString, required = false,
                                 default = nil)
  if valid_598872 != nil:
    section.add "X-Amz-Security-Token", valid_598872
  var valid_598873 = header.getOrDefault("X-Amz-Algorithm")
  valid_598873 = validateParameter(valid_598873, JString, required = false,
                                 default = nil)
  if valid_598873 != nil:
    section.add "X-Amz-Algorithm", valid_598873
  var valid_598874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598874 = validateParameter(valid_598874, JString, required = false,
                                 default = nil)
  if valid_598874 != nil:
    section.add "X-Amz-SignedHeaders", valid_598874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598875: Call_DeleteRouteSettings_598862; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the RouteSettings for a stage.
  ## 
  let valid = call_598875.validator(path, query, header, formData, body)
  let scheme = call_598875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598875.url(scheme.get, call_598875.host, call_598875.base,
                         call_598875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598875, url, valid)

proc call*(call_598876: Call_DeleteRouteSettings_598862; stageName: string;
          routeKey: string; apiId: string): Recallable =
  ## deleteRouteSettings
  ## Deletes the RouteSettings for a stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   routeKey: string (required)
  ##           : The route key.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_598877 = newJObject()
  add(path_598877, "stageName", newJString(stageName))
  add(path_598877, "routeKey", newJString(routeKey))
  add(path_598877, "apiId", newJString(apiId))
  result = call_598876.call(path_598877, nil, nil, nil, nil)

var deleteRouteSettings* = Call_DeleteRouteSettings_598862(
    name: "deleteRouteSettings", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/stages/{stageName}/routesettings/{routeKey}",
    validator: validate_DeleteRouteSettings_598863, base: "/",
    url: url_DeleteRouteSettings_598864, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStage_598878 = ref object of OpenApiRestCall_597389
proc url_GetStage_598880(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetStage_598879(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598881 = path.getOrDefault("stageName")
  valid_598881 = validateParameter(valid_598881, JString, required = true,
                                 default = nil)
  if valid_598881 != nil:
    section.add "stageName", valid_598881
  var valid_598882 = path.getOrDefault("apiId")
  valid_598882 = validateParameter(valid_598882, JString, required = true,
                                 default = nil)
  if valid_598882 != nil:
    section.add "apiId", valid_598882
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
  var valid_598883 = header.getOrDefault("X-Amz-Signature")
  valid_598883 = validateParameter(valid_598883, JString, required = false,
                                 default = nil)
  if valid_598883 != nil:
    section.add "X-Amz-Signature", valid_598883
  var valid_598884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598884 = validateParameter(valid_598884, JString, required = false,
                                 default = nil)
  if valid_598884 != nil:
    section.add "X-Amz-Content-Sha256", valid_598884
  var valid_598885 = header.getOrDefault("X-Amz-Date")
  valid_598885 = validateParameter(valid_598885, JString, required = false,
                                 default = nil)
  if valid_598885 != nil:
    section.add "X-Amz-Date", valid_598885
  var valid_598886 = header.getOrDefault("X-Amz-Credential")
  valid_598886 = validateParameter(valid_598886, JString, required = false,
                                 default = nil)
  if valid_598886 != nil:
    section.add "X-Amz-Credential", valid_598886
  var valid_598887 = header.getOrDefault("X-Amz-Security-Token")
  valid_598887 = validateParameter(valid_598887, JString, required = false,
                                 default = nil)
  if valid_598887 != nil:
    section.add "X-Amz-Security-Token", valid_598887
  var valid_598888 = header.getOrDefault("X-Amz-Algorithm")
  valid_598888 = validateParameter(valid_598888, JString, required = false,
                                 default = nil)
  if valid_598888 != nil:
    section.add "X-Amz-Algorithm", valid_598888
  var valid_598889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598889 = validateParameter(valid_598889, JString, required = false,
                                 default = nil)
  if valid_598889 != nil:
    section.add "X-Amz-SignedHeaders", valid_598889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598890: Call_GetStage_598878; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Stage.
  ## 
  let valid = call_598890.validator(path, query, header, formData, body)
  let scheme = call_598890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598890.url(scheme.get, call_598890.host, call_598890.base,
                         call_598890.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598890, url, valid)

proc call*(call_598891: Call_GetStage_598878; stageName: string; apiId: string): Recallable =
  ## getStage
  ## Gets a Stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_598892 = newJObject()
  add(path_598892, "stageName", newJString(stageName))
  add(path_598892, "apiId", newJString(apiId))
  result = call_598891.call(path_598892, nil, nil, nil, nil)

var getStage* = Call_GetStage_598878(name: "getStage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/stages/{stageName}",
                                  validator: validate_GetStage_598879, base: "/",
                                  url: url_GetStage_598880,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStage_598908 = ref object of OpenApiRestCall_597389
proc url_UpdateStage_598910(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateStage_598909(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598911 = path.getOrDefault("stageName")
  valid_598911 = validateParameter(valid_598911, JString, required = true,
                                 default = nil)
  if valid_598911 != nil:
    section.add "stageName", valid_598911
  var valid_598912 = path.getOrDefault("apiId")
  valid_598912 = validateParameter(valid_598912, JString, required = true,
                                 default = nil)
  if valid_598912 != nil:
    section.add "apiId", valid_598912
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
  var valid_598913 = header.getOrDefault("X-Amz-Signature")
  valid_598913 = validateParameter(valid_598913, JString, required = false,
                                 default = nil)
  if valid_598913 != nil:
    section.add "X-Amz-Signature", valid_598913
  var valid_598914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598914 = validateParameter(valid_598914, JString, required = false,
                                 default = nil)
  if valid_598914 != nil:
    section.add "X-Amz-Content-Sha256", valid_598914
  var valid_598915 = header.getOrDefault("X-Amz-Date")
  valid_598915 = validateParameter(valid_598915, JString, required = false,
                                 default = nil)
  if valid_598915 != nil:
    section.add "X-Amz-Date", valid_598915
  var valid_598916 = header.getOrDefault("X-Amz-Credential")
  valid_598916 = validateParameter(valid_598916, JString, required = false,
                                 default = nil)
  if valid_598916 != nil:
    section.add "X-Amz-Credential", valid_598916
  var valid_598917 = header.getOrDefault("X-Amz-Security-Token")
  valid_598917 = validateParameter(valid_598917, JString, required = false,
                                 default = nil)
  if valid_598917 != nil:
    section.add "X-Amz-Security-Token", valid_598917
  var valid_598918 = header.getOrDefault("X-Amz-Algorithm")
  valid_598918 = validateParameter(valid_598918, JString, required = false,
                                 default = nil)
  if valid_598918 != nil:
    section.add "X-Amz-Algorithm", valid_598918
  var valid_598919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598919 = validateParameter(valid_598919, JString, required = false,
                                 default = nil)
  if valid_598919 != nil:
    section.add "X-Amz-SignedHeaders", valid_598919
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598921: Call_UpdateStage_598908; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Stage.
  ## 
  let valid = call_598921.validator(path, query, header, formData, body)
  let scheme = call_598921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598921.url(scheme.get, call_598921.host, call_598921.base,
                         call_598921.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598921, url, valid)

proc call*(call_598922: Call_UpdateStage_598908; stageName: string; apiId: string;
          body: JsonNode): Recallable =
  ## updateStage
  ## Updates a Stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_598923 = newJObject()
  var body_598924 = newJObject()
  add(path_598923, "stageName", newJString(stageName))
  add(path_598923, "apiId", newJString(apiId))
  if body != nil:
    body_598924 = body
  result = call_598922.call(path_598923, nil, nil, nil, body_598924)

var updateStage* = Call_UpdateStage_598908(name: "updateStage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/stages/{stageName}",
                                        validator: validate_UpdateStage_598909,
                                        base: "/", url: url_UpdateStage_598910,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStage_598893 = ref object of OpenApiRestCall_597389
proc url_DeleteStage_598895(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteStage_598894(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598896 = path.getOrDefault("stageName")
  valid_598896 = validateParameter(valid_598896, JString, required = true,
                                 default = nil)
  if valid_598896 != nil:
    section.add "stageName", valid_598896
  var valid_598897 = path.getOrDefault("apiId")
  valid_598897 = validateParameter(valid_598897, JString, required = true,
                                 default = nil)
  if valid_598897 != nil:
    section.add "apiId", valid_598897
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
  var valid_598898 = header.getOrDefault("X-Amz-Signature")
  valid_598898 = validateParameter(valid_598898, JString, required = false,
                                 default = nil)
  if valid_598898 != nil:
    section.add "X-Amz-Signature", valid_598898
  var valid_598899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598899 = validateParameter(valid_598899, JString, required = false,
                                 default = nil)
  if valid_598899 != nil:
    section.add "X-Amz-Content-Sha256", valid_598899
  var valid_598900 = header.getOrDefault("X-Amz-Date")
  valid_598900 = validateParameter(valid_598900, JString, required = false,
                                 default = nil)
  if valid_598900 != nil:
    section.add "X-Amz-Date", valid_598900
  var valid_598901 = header.getOrDefault("X-Amz-Credential")
  valid_598901 = validateParameter(valid_598901, JString, required = false,
                                 default = nil)
  if valid_598901 != nil:
    section.add "X-Amz-Credential", valid_598901
  var valid_598902 = header.getOrDefault("X-Amz-Security-Token")
  valid_598902 = validateParameter(valid_598902, JString, required = false,
                                 default = nil)
  if valid_598902 != nil:
    section.add "X-Amz-Security-Token", valid_598902
  var valid_598903 = header.getOrDefault("X-Amz-Algorithm")
  valid_598903 = validateParameter(valid_598903, JString, required = false,
                                 default = nil)
  if valid_598903 != nil:
    section.add "X-Amz-Algorithm", valid_598903
  var valid_598904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598904 = validateParameter(valid_598904, JString, required = false,
                                 default = nil)
  if valid_598904 != nil:
    section.add "X-Amz-SignedHeaders", valid_598904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598905: Call_DeleteStage_598893; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Stage.
  ## 
  let valid = call_598905.validator(path, query, header, formData, body)
  let scheme = call_598905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598905.url(scheme.get, call_598905.host, call_598905.base,
                         call_598905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598905, url, valid)

proc call*(call_598906: Call_DeleteStage_598893; stageName: string; apiId: string): Recallable =
  ## deleteStage
  ## Deletes a Stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_598907 = newJObject()
  add(path_598907, "stageName", newJString(stageName))
  add(path_598907, "apiId", newJString(apiId))
  result = call_598906.call(path_598907, nil, nil, nil, nil)

var deleteStage* = Call_DeleteStage_598893(name: "deleteStage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/stages/{stageName}",
                                        validator: validate_DeleteStage_598894,
                                        base: "/", url: url_DeleteStage_598895,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelTemplate_598925 = ref object of OpenApiRestCall_597389
proc url_GetModelTemplate_598927(protocol: Scheme; host: string; base: string;
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

proc validate_GetModelTemplate_598926(path: JsonNode; query: JsonNode;
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
  var valid_598928 = path.getOrDefault("apiId")
  valid_598928 = validateParameter(valid_598928, JString, required = true,
                                 default = nil)
  if valid_598928 != nil:
    section.add "apiId", valid_598928
  var valid_598929 = path.getOrDefault("modelId")
  valid_598929 = validateParameter(valid_598929, JString, required = true,
                                 default = nil)
  if valid_598929 != nil:
    section.add "modelId", valid_598929
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
  var valid_598930 = header.getOrDefault("X-Amz-Signature")
  valid_598930 = validateParameter(valid_598930, JString, required = false,
                                 default = nil)
  if valid_598930 != nil:
    section.add "X-Amz-Signature", valid_598930
  var valid_598931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598931 = validateParameter(valid_598931, JString, required = false,
                                 default = nil)
  if valid_598931 != nil:
    section.add "X-Amz-Content-Sha256", valid_598931
  var valid_598932 = header.getOrDefault("X-Amz-Date")
  valid_598932 = validateParameter(valid_598932, JString, required = false,
                                 default = nil)
  if valid_598932 != nil:
    section.add "X-Amz-Date", valid_598932
  var valid_598933 = header.getOrDefault("X-Amz-Credential")
  valid_598933 = validateParameter(valid_598933, JString, required = false,
                                 default = nil)
  if valid_598933 != nil:
    section.add "X-Amz-Credential", valid_598933
  var valid_598934 = header.getOrDefault("X-Amz-Security-Token")
  valid_598934 = validateParameter(valid_598934, JString, required = false,
                                 default = nil)
  if valid_598934 != nil:
    section.add "X-Amz-Security-Token", valid_598934
  var valid_598935 = header.getOrDefault("X-Amz-Algorithm")
  valid_598935 = validateParameter(valid_598935, JString, required = false,
                                 default = nil)
  if valid_598935 != nil:
    section.add "X-Amz-Algorithm", valid_598935
  var valid_598936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598936 = validateParameter(valid_598936, JString, required = false,
                                 default = nil)
  if valid_598936 != nil:
    section.add "X-Amz-SignedHeaders", valid_598936
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598937: Call_GetModelTemplate_598925; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a model template.
  ## 
  let valid = call_598937.validator(path, query, header, formData, body)
  let scheme = call_598937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598937.url(scheme.get, call_598937.host, call_598937.base,
                         call_598937.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598937, url, valid)

proc call*(call_598938: Call_GetModelTemplate_598925; apiId: string; modelId: string): Recallable =
  ## getModelTemplate
  ## Gets a model template.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_598939 = newJObject()
  add(path_598939, "apiId", newJString(apiId))
  add(path_598939, "modelId", newJString(modelId))
  result = call_598938.call(path_598939, nil, nil, nil, nil)

var getModelTemplate* = Call_GetModelTemplate_598925(name: "getModelTemplate",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/models/{modelId}/template",
    validator: validate_GetModelTemplate_598926, base: "/",
    url: url_GetModelTemplate_598927, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_598954 = ref object of OpenApiRestCall_597389
proc url_TagResource_598956(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_598955(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598957 = path.getOrDefault("resource-arn")
  valid_598957 = validateParameter(valid_598957, JString, required = true,
                                 default = nil)
  if valid_598957 != nil:
    section.add "resource-arn", valid_598957
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
  var valid_598958 = header.getOrDefault("X-Amz-Signature")
  valid_598958 = validateParameter(valid_598958, JString, required = false,
                                 default = nil)
  if valid_598958 != nil:
    section.add "X-Amz-Signature", valid_598958
  var valid_598959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598959 = validateParameter(valid_598959, JString, required = false,
                                 default = nil)
  if valid_598959 != nil:
    section.add "X-Amz-Content-Sha256", valid_598959
  var valid_598960 = header.getOrDefault("X-Amz-Date")
  valid_598960 = validateParameter(valid_598960, JString, required = false,
                                 default = nil)
  if valid_598960 != nil:
    section.add "X-Amz-Date", valid_598960
  var valid_598961 = header.getOrDefault("X-Amz-Credential")
  valid_598961 = validateParameter(valid_598961, JString, required = false,
                                 default = nil)
  if valid_598961 != nil:
    section.add "X-Amz-Credential", valid_598961
  var valid_598962 = header.getOrDefault("X-Amz-Security-Token")
  valid_598962 = validateParameter(valid_598962, JString, required = false,
                                 default = nil)
  if valid_598962 != nil:
    section.add "X-Amz-Security-Token", valid_598962
  var valid_598963 = header.getOrDefault("X-Amz-Algorithm")
  valid_598963 = validateParameter(valid_598963, JString, required = false,
                                 default = nil)
  if valid_598963 != nil:
    section.add "X-Amz-Algorithm", valid_598963
  var valid_598964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598964 = validateParameter(valid_598964, JString, required = false,
                                 default = nil)
  if valid_598964 != nil:
    section.add "X-Amz-SignedHeaders", valid_598964
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598966: Call_TagResource_598954; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Tag resource to represent a tag.
  ## 
  let valid = call_598966.validator(path, query, header, formData, body)
  let scheme = call_598966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598966.url(scheme.get, call_598966.host, call_598966.base,
                         call_598966.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598966, url, valid)

proc call*(call_598967: Call_TagResource_598954; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Creates a new Tag resource to represent a tag.
  ##   resourceArn: string (required)
  ##              : The resource ARN for the tag.
  ##   body: JObject (required)
  var path_598968 = newJObject()
  var body_598969 = newJObject()
  add(path_598968, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_598969 = body
  result = call_598967.call(path_598968, nil, nil, nil, body_598969)

var tagResource* = Call_TagResource_598954(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/tags/{resource-arn}",
                                        validator: validate_TagResource_598955,
                                        base: "/", url: url_TagResource_598956,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_598940 = ref object of OpenApiRestCall_597389
proc url_GetTags_598942(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTags_598941(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598943 = path.getOrDefault("resource-arn")
  valid_598943 = validateParameter(valid_598943, JString, required = true,
                                 default = nil)
  if valid_598943 != nil:
    section.add "resource-arn", valid_598943
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
  var valid_598944 = header.getOrDefault("X-Amz-Signature")
  valid_598944 = validateParameter(valid_598944, JString, required = false,
                                 default = nil)
  if valid_598944 != nil:
    section.add "X-Amz-Signature", valid_598944
  var valid_598945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598945 = validateParameter(valid_598945, JString, required = false,
                                 default = nil)
  if valid_598945 != nil:
    section.add "X-Amz-Content-Sha256", valid_598945
  var valid_598946 = header.getOrDefault("X-Amz-Date")
  valid_598946 = validateParameter(valid_598946, JString, required = false,
                                 default = nil)
  if valid_598946 != nil:
    section.add "X-Amz-Date", valid_598946
  var valid_598947 = header.getOrDefault("X-Amz-Credential")
  valid_598947 = validateParameter(valid_598947, JString, required = false,
                                 default = nil)
  if valid_598947 != nil:
    section.add "X-Amz-Credential", valid_598947
  var valid_598948 = header.getOrDefault("X-Amz-Security-Token")
  valid_598948 = validateParameter(valid_598948, JString, required = false,
                                 default = nil)
  if valid_598948 != nil:
    section.add "X-Amz-Security-Token", valid_598948
  var valid_598949 = header.getOrDefault("X-Amz-Algorithm")
  valid_598949 = validateParameter(valid_598949, JString, required = false,
                                 default = nil)
  if valid_598949 != nil:
    section.add "X-Amz-Algorithm", valid_598949
  var valid_598950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598950 = validateParameter(valid_598950, JString, required = false,
                                 default = nil)
  if valid_598950 != nil:
    section.add "X-Amz-SignedHeaders", valid_598950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598951: Call_GetTags_598940; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of Tag resources.
  ## 
  let valid = call_598951.validator(path, query, header, formData, body)
  let scheme = call_598951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598951.url(scheme.get, call_598951.host, call_598951.base,
                         call_598951.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598951, url, valid)

proc call*(call_598952: Call_GetTags_598940; resourceArn: string): Recallable =
  ## getTags
  ## Gets a collection of Tag resources.
  ##   resourceArn: string (required)
  ##              : The resource ARN for the tag.
  var path_598953 = newJObject()
  add(path_598953, "resource-arn", newJString(resourceArn))
  result = call_598952.call(path_598953, nil, nil, nil, nil)

var getTags* = Call_GetTags_598940(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/v2/tags/{resource-arn}",
                                validator: validate_GetTags_598941, base: "/",
                                url: url_GetTags_598942,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_598970 = ref object of OpenApiRestCall_597389
proc url_UntagResource_598972(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_598971(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598973 = path.getOrDefault("resource-arn")
  valid_598973 = validateParameter(valid_598973, JString, required = true,
                                 default = nil)
  if valid_598973 != nil:
    section.add "resource-arn", valid_598973
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : 
  ##             <p>The Tag keys to delete.</p>
  ##          
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_598974 = query.getOrDefault("tagKeys")
  valid_598974 = validateParameter(valid_598974, JArray, required = true, default = nil)
  if valid_598974 != nil:
    section.add "tagKeys", valid_598974
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
  var valid_598975 = header.getOrDefault("X-Amz-Signature")
  valid_598975 = validateParameter(valid_598975, JString, required = false,
                                 default = nil)
  if valid_598975 != nil:
    section.add "X-Amz-Signature", valid_598975
  var valid_598976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598976 = validateParameter(valid_598976, JString, required = false,
                                 default = nil)
  if valid_598976 != nil:
    section.add "X-Amz-Content-Sha256", valid_598976
  var valid_598977 = header.getOrDefault("X-Amz-Date")
  valid_598977 = validateParameter(valid_598977, JString, required = false,
                                 default = nil)
  if valid_598977 != nil:
    section.add "X-Amz-Date", valid_598977
  var valid_598978 = header.getOrDefault("X-Amz-Credential")
  valid_598978 = validateParameter(valid_598978, JString, required = false,
                                 default = nil)
  if valid_598978 != nil:
    section.add "X-Amz-Credential", valid_598978
  var valid_598979 = header.getOrDefault("X-Amz-Security-Token")
  valid_598979 = validateParameter(valid_598979, JString, required = false,
                                 default = nil)
  if valid_598979 != nil:
    section.add "X-Amz-Security-Token", valid_598979
  var valid_598980 = header.getOrDefault("X-Amz-Algorithm")
  valid_598980 = validateParameter(valid_598980, JString, required = false,
                                 default = nil)
  if valid_598980 != nil:
    section.add "X-Amz-Algorithm", valid_598980
  var valid_598981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598981 = validateParameter(valid_598981, JString, required = false,
                                 default = nil)
  if valid_598981 != nil:
    section.add "X-Amz-SignedHeaders", valid_598981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598982: Call_UntagResource_598970; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Tag.
  ## 
  let valid = call_598982.validator(path, query, header, formData, body)
  let scheme = call_598982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598982.url(scheme.get, call_598982.host, call_598982.base,
                         call_598982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598982, url, valid)

proc call*(call_598983: Call_UntagResource_598970; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Deletes a Tag.
  ##   resourceArn: string (required)
  ##              : The resource ARN for the tag.
  ##   tagKeys: JArray (required)
  ##          : 
  ##             <p>The Tag keys to delete.</p>
  ##          
  var path_598984 = newJObject()
  var query_598985 = newJObject()
  add(path_598984, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_598985.add "tagKeys", tagKeys
  result = call_598983.call(path_598984, query_598985, nil, nil, nil)

var untagResource* = Call_UntagResource_598970(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_598971,
    base: "/", url: url_UntagResource_598972, schemes: {Scheme.Https, Scheme.Http})
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
