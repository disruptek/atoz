
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Elemental MediaPackage
## version: 2017-10-12
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS Elemental MediaPackage
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/mediapackage/
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

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "mediapackage.ap-northeast-1.amazonaws.com", "ap-southeast-1": "mediapackage.ap-southeast-1.amazonaws.com",
                           "us-west-2": "mediapackage.us-west-2.amazonaws.com",
                           "eu-west-2": "mediapackage.eu-west-2.amazonaws.com", "ap-northeast-3": "mediapackage.ap-northeast-3.amazonaws.com", "eu-central-1": "mediapackage.eu-central-1.amazonaws.com",
                           "us-east-2": "mediapackage.us-east-2.amazonaws.com",
                           "us-east-1": "mediapackage.us-east-1.amazonaws.com", "cn-northwest-1": "mediapackage.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "mediapackage.ap-south-1.amazonaws.com", "eu-north-1": "mediapackage.eu-north-1.amazonaws.com", "ap-northeast-2": "mediapackage.ap-northeast-2.amazonaws.com",
                           "us-west-1": "mediapackage.us-west-1.amazonaws.com", "us-gov-east-1": "mediapackage.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "mediapackage.eu-west-3.amazonaws.com", "cn-north-1": "mediapackage.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "mediapackage.sa-east-1.amazonaws.com",
                           "eu-west-1": "mediapackage.eu-west-1.amazonaws.com", "us-gov-west-1": "mediapackage.us-gov-west-1.amazonaws.com", "ap-southeast-2": "mediapackage.ap-southeast-2.amazonaws.com", "ca-central-1": "mediapackage.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "mediapackage.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "mediapackage.ap-southeast-1.amazonaws.com",
      "us-west-2": "mediapackage.us-west-2.amazonaws.com",
      "eu-west-2": "mediapackage.eu-west-2.amazonaws.com",
      "ap-northeast-3": "mediapackage.ap-northeast-3.amazonaws.com",
      "eu-central-1": "mediapackage.eu-central-1.amazonaws.com",
      "us-east-2": "mediapackage.us-east-2.amazonaws.com",
      "us-east-1": "mediapackage.us-east-1.amazonaws.com",
      "cn-northwest-1": "mediapackage.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "mediapackage.ap-south-1.amazonaws.com",
      "eu-north-1": "mediapackage.eu-north-1.amazonaws.com",
      "ap-northeast-2": "mediapackage.ap-northeast-2.amazonaws.com",
      "us-west-1": "mediapackage.us-west-1.amazonaws.com",
      "us-gov-east-1": "mediapackage.us-gov-east-1.amazonaws.com",
      "eu-west-3": "mediapackage.eu-west-3.amazonaws.com",
      "cn-north-1": "mediapackage.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "mediapackage.sa-east-1.amazonaws.com",
      "eu-west-1": "mediapackage.eu-west-1.amazonaws.com",
      "us-gov-west-1": "mediapackage.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "mediapackage.ap-southeast-2.amazonaws.com",
      "ca-central-1": "mediapackage.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "mediapackage"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateChannel_773192 = ref object of OpenApiRestCall_772597
proc url_CreateChannel_773194(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateChannel_773193(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new Channel.
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
  var valid_773195 = header.getOrDefault("X-Amz-Date")
  valid_773195 = validateParameter(valid_773195, JString, required = false,
                                 default = nil)
  if valid_773195 != nil:
    section.add "X-Amz-Date", valid_773195
  var valid_773196 = header.getOrDefault("X-Amz-Security-Token")
  valid_773196 = validateParameter(valid_773196, JString, required = false,
                                 default = nil)
  if valid_773196 != nil:
    section.add "X-Amz-Security-Token", valid_773196
  var valid_773197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773197 = validateParameter(valid_773197, JString, required = false,
                                 default = nil)
  if valid_773197 != nil:
    section.add "X-Amz-Content-Sha256", valid_773197
  var valid_773198 = header.getOrDefault("X-Amz-Algorithm")
  valid_773198 = validateParameter(valid_773198, JString, required = false,
                                 default = nil)
  if valid_773198 != nil:
    section.add "X-Amz-Algorithm", valid_773198
  var valid_773199 = header.getOrDefault("X-Amz-Signature")
  valid_773199 = validateParameter(valid_773199, JString, required = false,
                                 default = nil)
  if valid_773199 != nil:
    section.add "X-Amz-Signature", valid_773199
  var valid_773200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773200 = validateParameter(valid_773200, JString, required = false,
                                 default = nil)
  if valid_773200 != nil:
    section.add "X-Amz-SignedHeaders", valid_773200
  var valid_773201 = header.getOrDefault("X-Amz-Credential")
  valid_773201 = validateParameter(valid_773201, JString, required = false,
                                 default = nil)
  if valid_773201 != nil:
    section.add "X-Amz-Credential", valid_773201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773203: Call_CreateChannel_773192; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Channel.
  ## 
  let valid = call_773203.validator(path, query, header, formData, body)
  let scheme = call_773203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773203.url(scheme.get, call_773203.host, call_773203.base,
                         call_773203.route, valid.getOrDefault("path"))
  result = hook(call_773203, url, valid)

proc call*(call_773204: Call_CreateChannel_773192; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a new Channel.
  ##   body: JObject (required)
  var body_773205 = newJObject()
  if body != nil:
    body_773205 = body
  result = call_773204.call(nil, nil, nil, nil, body_773205)

var createChannel* = Call_CreateChannel_773192(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "mediapackage.amazonaws.com",
    route: "/channels", validator: validate_CreateChannel_773193, base: "/",
    url: url_CreateChannel_773194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_772933 = ref object of OpenApiRestCall_772597
proc url_ListChannels_772935(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListChannels_772934(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a collection of Channels.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Upper bound on number of records to return.
  ##   nextToken: JString
  ##            : A token used to resume pagination from the end of a previous request.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_773047 = query.getOrDefault("NextToken")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "NextToken", valid_773047
  var valid_773048 = query.getOrDefault("maxResults")
  valid_773048 = validateParameter(valid_773048, JInt, required = false, default = nil)
  if valid_773048 != nil:
    section.add "maxResults", valid_773048
  var valid_773049 = query.getOrDefault("nextToken")
  valid_773049 = validateParameter(valid_773049, JString, required = false,
                                 default = nil)
  if valid_773049 != nil:
    section.add "nextToken", valid_773049
  var valid_773050 = query.getOrDefault("MaxResults")
  valid_773050 = validateParameter(valid_773050, JString, required = false,
                                 default = nil)
  if valid_773050 != nil:
    section.add "MaxResults", valid_773050
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
  var valid_773051 = header.getOrDefault("X-Amz-Date")
  valid_773051 = validateParameter(valid_773051, JString, required = false,
                                 default = nil)
  if valid_773051 != nil:
    section.add "X-Amz-Date", valid_773051
  var valid_773052 = header.getOrDefault("X-Amz-Security-Token")
  valid_773052 = validateParameter(valid_773052, JString, required = false,
                                 default = nil)
  if valid_773052 != nil:
    section.add "X-Amz-Security-Token", valid_773052
  var valid_773053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773053 = validateParameter(valid_773053, JString, required = false,
                                 default = nil)
  if valid_773053 != nil:
    section.add "X-Amz-Content-Sha256", valid_773053
  var valid_773054 = header.getOrDefault("X-Amz-Algorithm")
  valid_773054 = validateParameter(valid_773054, JString, required = false,
                                 default = nil)
  if valid_773054 != nil:
    section.add "X-Amz-Algorithm", valid_773054
  var valid_773055 = header.getOrDefault("X-Amz-Signature")
  valid_773055 = validateParameter(valid_773055, JString, required = false,
                                 default = nil)
  if valid_773055 != nil:
    section.add "X-Amz-Signature", valid_773055
  var valid_773056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773056 = validateParameter(valid_773056, JString, required = false,
                                 default = nil)
  if valid_773056 != nil:
    section.add "X-Amz-SignedHeaders", valid_773056
  var valid_773057 = header.getOrDefault("X-Amz-Credential")
  valid_773057 = validateParameter(valid_773057, JString, required = false,
                                 default = nil)
  if valid_773057 != nil:
    section.add "X-Amz-Credential", valid_773057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773080: Call_ListChannels_772933; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of Channels.
  ## 
  let valid = call_773080.validator(path, query, header, formData, body)
  let scheme = call_773080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773080.url(scheme.get, call_773080.host, call_773080.base,
                         call_773080.route, valid.getOrDefault("path"))
  result = hook(call_773080, url, valid)

proc call*(call_773151: Call_ListChannels_772933; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listChannels
  ## Returns a collection of Channels.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Upper bound on number of records to return.
  ##   nextToken: string
  ##            : A token used to resume pagination from the end of a previous request.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773152 = newJObject()
  add(query_773152, "NextToken", newJString(NextToken))
  add(query_773152, "maxResults", newJInt(maxResults))
  add(query_773152, "nextToken", newJString(nextToken))
  add(query_773152, "MaxResults", newJString(MaxResults))
  result = call_773151.call(nil, query_773152, nil, nil, nil)

var listChannels* = Call_ListChannels_772933(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "mediapackage.amazonaws.com",
    route: "/channels", validator: validate_ListChannels_772934, base: "/",
    url: url_ListChannels_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOriginEndpoint_773224 = ref object of OpenApiRestCall_772597
proc url_CreateOriginEndpoint_773226(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateOriginEndpoint_773225(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new OriginEndpoint record.
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
  var valid_773227 = header.getOrDefault("X-Amz-Date")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Date", valid_773227
  var valid_773228 = header.getOrDefault("X-Amz-Security-Token")
  valid_773228 = validateParameter(valid_773228, JString, required = false,
                                 default = nil)
  if valid_773228 != nil:
    section.add "X-Amz-Security-Token", valid_773228
  var valid_773229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773229 = validateParameter(valid_773229, JString, required = false,
                                 default = nil)
  if valid_773229 != nil:
    section.add "X-Amz-Content-Sha256", valid_773229
  var valid_773230 = header.getOrDefault("X-Amz-Algorithm")
  valid_773230 = validateParameter(valid_773230, JString, required = false,
                                 default = nil)
  if valid_773230 != nil:
    section.add "X-Amz-Algorithm", valid_773230
  var valid_773231 = header.getOrDefault("X-Amz-Signature")
  valid_773231 = validateParameter(valid_773231, JString, required = false,
                                 default = nil)
  if valid_773231 != nil:
    section.add "X-Amz-Signature", valid_773231
  var valid_773232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773232 = validateParameter(valid_773232, JString, required = false,
                                 default = nil)
  if valid_773232 != nil:
    section.add "X-Amz-SignedHeaders", valid_773232
  var valid_773233 = header.getOrDefault("X-Amz-Credential")
  valid_773233 = validateParameter(valid_773233, JString, required = false,
                                 default = nil)
  if valid_773233 != nil:
    section.add "X-Amz-Credential", valid_773233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773235: Call_CreateOriginEndpoint_773224; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new OriginEndpoint record.
  ## 
  let valid = call_773235.validator(path, query, header, formData, body)
  let scheme = call_773235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773235.url(scheme.get, call_773235.host, call_773235.base,
                         call_773235.route, valid.getOrDefault("path"))
  result = hook(call_773235, url, valid)

proc call*(call_773236: Call_CreateOriginEndpoint_773224; body: JsonNode): Recallable =
  ## createOriginEndpoint
  ## Creates a new OriginEndpoint record.
  ##   body: JObject (required)
  var body_773237 = newJObject()
  if body != nil:
    body_773237 = body
  result = call_773236.call(nil, nil, nil, nil, body_773237)

var createOriginEndpoint* = Call_CreateOriginEndpoint_773224(
    name: "createOriginEndpoint", meth: HttpMethod.HttpPost,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints",
    validator: validate_CreateOriginEndpoint_773225, base: "/",
    url: url_CreateOriginEndpoint_773226, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOriginEndpoints_773206 = ref object of OpenApiRestCall_772597
proc url_ListOriginEndpoints_773208(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListOriginEndpoints_773207(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a collection of OriginEndpoint records.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The upper bound on the number of records to return.
  ##   nextToken: JString
  ##            : A token used to resume pagination from the end of a previous request.
  ##   channelId: JString
  ##            : When specified, the request will return only OriginEndpoints associated with the given Channel ID.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_773209 = query.getOrDefault("NextToken")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "NextToken", valid_773209
  var valid_773210 = query.getOrDefault("maxResults")
  valid_773210 = validateParameter(valid_773210, JInt, required = false, default = nil)
  if valid_773210 != nil:
    section.add "maxResults", valid_773210
  var valid_773211 = query.getOrDefault("nextToken")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "nextToken", valid_773211
  var valid_773212 = query.getOrDefault("channelId")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "channelId", valid_773212
  var valid_773213 = query.getOrDefault("MaxResults")
  valid_773213 = validateParameter(valid_773213, JString, required = false,
                                 default = nil)
  if valid_773213 != nil:
    section.add "MaxResults", valid_773213
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
  var valid_773214 = header.getOrDefault("X-Amz-Date")
  valid_773214 = validateParameter(valid_773214, JString, required = false,
                                 default = nil)
  if valid_773214 != nil:
    section.add "X-Amz-Date", valid_773214
  var valid_773215 = header.getOrDefault("X-Amz-Security-Token")
  valid_773215 = validateParameter(valid_773215, JString, required = false,
                                 default = nil)
  if valid_773215 != nil:
    section.add "X-Amz-Security-Token", valid_773215
  var valid_773216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773216 = validateParameter(valid_773216, JString, required = false,
                                 default = nil)
  if valid_773216 != nil:
    section.add "X-Amz-Content-Sha256", valid_773216
  var valid_773217 = header.getOrDefault("X-Amz-Algorithm")
  valid_773217 = validateParameter(valid_773217, JString, required = false,
                                 default = nil)
  if valid_773217 != nil:
    section.add "X-Amz-Algorithm", valid_773217
  var valid_773218 = header.getOrDefault("X-Amz-Signature")
  valid_773218 = validateParameter(valid_773218, JString, required = false,
                                 default = nil)
  if valid_773218 != nil:
    section.add "X-Amz-Signature", valid_773218
  var valid_773219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773219 = validateParameter(valid_773219, JString, required = false,
                                 default = nil)
  if valid_773219 != nil:
    section.add "X-Amz-SignedHeaders", valid_773219
  var valid_773220 = header.getOrDefault("X-Amz-Credential")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "X-Amz-Credential", valid_773220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773221: Call_ListOriginEndpoints_773206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of OriginEndpoint records.
  ## 
  let valid = call_773221.validator(path, query, header, formData, body)
  let scheme = call_773221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773221.url(scheme.get, call_773221.host, call_773221.base,
                         call_773221.route, valid.getOrDefault("path"))
  result = hook(call_773221, url, valid)

proc call*(call_773222: Call_ListOriginEndpoints_773206; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; channelId: string = "";
          MaxResults: string = ""): Recallable =
  ## listOriginEndpoints
  ## Returns a collection of OriginEndpoint records.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The upper bound on the number of records to return.
  ##   nextToken: string
  ##            : A token used to resume pagination from the end of a previous request.
  ##   channelId: string
  ##            : When specified, the request will return only OriginEndpoints associated with the given Channel ID.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773223 = newJObject()
  add(query_773223, "NextToken", newJString(NextToken))
  add(query_773223, "maxResults", newJInt(maxResults))
  add(query_773223, "nextToken", newJString(nextToken))
  add(query_773223, "channelId", newJString(channelId))
  add(query_773223, "MaxResults", newJString(MaxResults))
  result = call_773222.call(nil, query_773223, nil, nil, nil)

var listOriginEndpoints* = Call_ListOriginEndpoints_773206(
    name: "listOriginEndpoints", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints",
    validator: validate_ListOriginEndpoints_773207, base: "/",
    url: url_ListOriginEndpoints_773208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_773266 = ref object of OpenApiRestCall_772597
proc url_UpdateChannel_773268(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/channels/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateChannel_773267(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing Channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the Channel to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_773269 = path.getOrDefault("id")
  valid_773269 = validateParameter(valid_773269, JString, required = true,
                                 default = nil)
  if valid_773269 != nil:
    section.add "id", valid_773269
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
  var valid_773270 = header.getOrDefault("X-Amz-Date")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Date", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-Security-Token")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-Security-Token", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-Content-Sha256", valid_773272
  var valid_773273 = header.getOrDefault("X-Amz-Algorithm")
  valid_773273 = validateParameter(valid_773273, JString, required = false,
                                 default = nil)
  if valid_773273 != nil:
    section.add "X-Amz-Algorithm", valid_773273
  var valid_773274 = header.getOrDefault("X-Amz-Signature")
  valid_773274 = validateParameter(valid_773274, JString, required = false,
                                 default = nil)
  if valid_773274 != nil:
    section.add "X-Amz-Signature", valid_773274
  var valid_773275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773275 = validateParameter(valid_773275, JString, required = false,
                                 default = nil)
  if valid_773275 != nil:
    section.add "X-Amz-SignedHeaders", valid_773275
  var valid_773276 = header.getOrDefault("X-Amz-Credential")
  valid_773276 = validateParameter(valid_773276, JString, required = false,
                                 default = nil)
  if valid_773276 != nil:
    section.add "X-Amz-Credential", valid_773276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773278: Call_UpdateChannel_773266; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing Channel.
  ## 
  let valid = call_773278.validator(path, query, header, formData, body)
  let scheme = call_773278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773278.url(scheme.get, call_773278.host, call_773278.base,
                         call_773278.route, valid.getOrDefault("path"))
  result = hook(call_773278, url, valid)

proc call*(call_773279: Call_UpdateChannel_773266; id: string; body: JsonNode): Recallable =
  ## updateChannel
  ## Updates an existing Channel.
  ##   id: string (required)
  ##     : The ID of the Channel to update.
  ##   body: JObject (required)
  var path_773280 = newJObject()
  var body_773281 = newJObject()
  add(path_773280, "id", newJString(id))
  if body != nil:
    body_773281 = body
  result = call_773279.call(path_773280, nil, nil, nil, body_773281)

var updateChannel* = Call_UpdateChannel_773266(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "mediapackage.amazonaws.com",
    route: "/channels/{id}", validator: validate_UpdateChannel_773267, base: "/",
    url: url_UpdateChannel_773268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_773238 = ref object of OpenApiRestCall_772597
proc url_DescribeChannel_773240(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/channels/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeChannel_773239(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Gets details about a Channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of a Channel.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_773255 = path.getOrDefault("id")
  valid_773255 = validateParameter(valid_773255, JString, required = true,
                                 default = nil)
  if valid_773255 != nil:
    section.add "id", valid_773255
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
  var valid_773256 = header.getOrDefault("X-Amz-Date")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-Date", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-Security-Token")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-Security-Token", valid_773257
  var valid_773258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773258 = validateParameter(valid_773258, JString, required = false,
                                 default = nil)
  if valid_773258 != nil:
    section.add "X-Amz-Content-Sha256", valid_773258
  var valid_773259 = header.getOrDefault("X-Amz-Algorithm")
  valid_773259 = validateParameter(valid_773259, JString, required = false,
                                 default = nil)
  if valid_773259 != nil:
    section.add "X-Amz-Algorithm", valid_773259
  var valid_773260 = header.getOrDefault("X-Amz-Signature")
  valid_773260 = validateParameter(valid_773260, JString, required = false,
                                 default = nil)
  if valid_773260 != nil:
    section.add "X-Amz-Signature", valid_773260
  var valid_773261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773261 = validateParameter(valid_773261, JString, required = false,
                                 default = nil)
  if valid_773261 != nil:
    section.add "X-Amz-SignedHeaders", valid_773261
  var valid_773262 = header.getOrDefault("X-Amz-Credential")
  valid_773262 = validateParameter(valid_773262, JString, required = false,
                                 default = nil)
  if valid_773262 != nil:
    section.add "X-Amz-Credential", valid_773262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773263: Call_DescribeChannel_773238; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about a Channel.
  ## 
  let valid = call_773263.validator(path, query, header, formData, body)
  let scheme = call_773263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773263.url(scheme.get, call_773263.host, call_773263.base,
                         call_773263.route, valid.getOrDefault("path"))
  result = hook(call_773263, url, valid)

proc call*(call_773264: Call_DescribeChannel_773238; id: string): Recallable =
  ## describeChannel
  ## Gets details about a Channel.
  ##   id: string (required)
  ##     : The ID of a Channel.
  var path_773265 = newJObject()
  add(path_773265, "id", newJString(id))
  result = call_773264.call(path_773265, nil, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_773238(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "mediapackage.amazonaws.com",
    route: "/channels/{id}", validator: validate_DescribeChannel_773239, base: "/",
    url: url_DescribeChannel_773240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_773282 = ref object of OpenApiRestCall_772597
proc url_DeleteChannel_773284(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/channels/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteChannel_773283(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing Channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the Channel to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_773285 = path.getOrDefault("id")
  valid_773285 = validateParameter(valid_773285, JString, required = true,
                                 default = nil)
  if valid_773285 != nil:
    section.add "id", valid_773285
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
  var valid_773286 = header.getOrDefault("X-Amz-Date")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-Date", valid_773286
  var valid_773287 = header.getOrDefault("X-Amz-Security-Token")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-Security-Token", valid_773287
  var valid_773288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773288 = validateParameter(valid_773288, JString, required = false,
                                 default = nil)
  if valid_773288 != nil:
    section.add "X-Amz-Content-Sha256", valid_773288
  var valid_773289 = header.getOrDefault("X-Amz-Algorithm")
  valid_773289 = validateParameter(valid_773289, JString, required = false,
                                 default = nil)
  if valid_773289 != nil:
    section.add "X-Amz-Algorithm", valid_773289
  var valid_773290 = header.getOrDefault("X-Amz-Signature")
  valid_773290 = validateParameter(valid_773290, JString, required = false,
                                 default = nil)
  if valid_773290 != nil:
    section.add "X-Amz-Signature", valid_773290
  var valid_773291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773291 = validateParameter(valid_773291, JString, required = false,
                                 default = nil)
  if valid_773291 != nil:
    section.add "X-Amz-SignedHeaders", valid_773291
  var valid_773292 = header.getOrDefault("X-Amz-Credential")
  valid_773292 = validateParameter(valid_773292, JString, required = false,
                                 default = nil)
  if valid_773292 != nil:
    section.add "X-Amz-Credential", valid_773292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773293: Call_DeleteChannel_773282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing Channel.
  ## 
  let valid = call_773293.validator(path, query, header, formData, body)
  let scheme = call_773293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773293.url(scheme.get, call_773293.host, call_773293.base,
                         call_773293.route, valid.getOrDefault("path"))
  result = hook(call_773293, url, valid)

proc call*(call_773294: Call_DeleteChannel_773282; id: string): Recallable =
  ## deleteChannel
  ## Deletes an existing Channel.
  ##   id: string (required)
  ##     : The ID of the Channel to delete.
  var path_773295 = newJObject()
  add(path_773295, "id", newJString(id))
  result = call_773294.call(path_773295, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_773282(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "mediapackage.amazonaws.com",
    route: "/channels/{id}", validator: validate_DeleteChannel_773283, base: "/",
    url: url_DeleteChannel_773284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateOriginEndpoint_773310 = ref object of OpenApiRestCall_772597
proc url_UpdateOriginEndpoint_773312(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/origin_endpoints/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateOriginEndpoint_773311(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing OriginEndpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the OriginEndpoint to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_773313 = path.getOrDefault("id")
  valid_773313 = validateParameter(valid_773313, JString, required = true,
                                 default = nil)
  if valid_773313 != nil:
    section.add "id", valid_773313
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
  var valid_773314 = header.getOrDefault("X-Amz-Date")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-Date", valid_773314
  var valid_773315 = header.getOrDefault("X-Amz-Security-Token")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "X-Amz-Security-Token", valid_773315
  var valid_773316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "X-Amz-Content-Sha256", valid_773316
  var valid_773317 = header.getOrDefault("X-Amz-Algorithm")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "X-Amz-Algorithm", valid_773317
  var valid_773318 = header.getOrDefault("X-Amz-Signature")
  valid_773318 = validateParameter(valid_773318, JString, required = false,
                                 default = nil)
  if valid_773318 != nil:
    section.add "X-Amz-Signature", valid_773318
  var valid_773319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773319 = validateParameter(valid_773319, JString, required = false,
                                 default = nil)
  if valid_773319 != nil:
    section.add "X-Amz-SignedHeaders", valid_773319
  var valid_773320 = header.getOrDefault("X-Amz-Credential")
  valid_773320 = validateParameter(valid_773320, JString, required = false,
                                 default = nil)
  if valid_773320 != nil:
    section.add "X-Amz-Credential", valid_773320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773322: Call_UpdateOriginEndpoint_773310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing OriginEndpoint.
  ## 
  let valid = call_773322.validator(path, query, header, formData, body)
  let scheme = call_773322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773322.url(scheme.get, call_773322.host, call_773322.base,
                         call_773322.route, valid.getOrDefault("path"))
  result = hook(call_773322, url, valid)

proc call*(call_773323: Call_UpdateOriginEndpoint_773310; id: string; body: JsonNode): Recallable =
  ## updateOriginEndpoint
  ## Updates an existing OriginEndpoint.
  ##   id: string (required)
  ##     : The ID of the OriginEndpoint to update.
  ##   body: JObject (required)
  var path_773324 = newJObject()
  var body_773325 = newJObject()
  add(path_773324, "id", newJString(id))
  if body != nil:
    body_773325 = body
  result = call_773323.call(path_773324, nil, nil, nil, body_773325)

var updateOriginEndpoint* = Call_UpdateOriginEndpoint_773310(
    name: "updateOriginEndpoint", meth: HttpMethod.HttpPut,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints/{id}",
    validator: validate_UpdateOriginEndpoint_773311, base: "/",
    url: url_UpdateOriginEndpoint_773312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOriginEndpoint_773296 = ref object of OpenApiRestCall_772597
proc url_DescribeOriginEndpoint_773298(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/origin_endpoints/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeOriginEndpoint_773297(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets details about an existing OriginEndpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the OriginEndpoint.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_773299 = path.getOrDefault("id")
  valid_773299 = validateParameter(valid_773299, JString, required = true,
                                 default = nil)
  if valid_773299 != nil:
    section.add "id", valid_773299
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
  var valid_773300 = header.getOrDefault("X-Amz-Date")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "X-Amz-Date", valid_773300
  var valid_773301 = header.getOrDefault("X-Amz-Security-Token")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-Security-Token", valid_773301
  var valid_773302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-Content-Sha256", valid_773302
  var valid_773303 = header.getOrDefault("X-Amz-Algorithm")
  valid_773303 = validateParameter(valid_773303, JString, required = false,
                                 default = nil)
  if valid_773303 != nil:
    section.add "X-Amz-Algorithm", valid_773303
  var valid_773304 = header.getOrDefault("X-Amz-Signature")
  valid_773304 = validateParameter(valid_773304, JString, required = false,
                                 default = nil)
  if valid_773304 != nil:
    section.add "X-Amz-Signature", valid_773304
  var valid_773305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773305 = validateParameter(valid_773305, JString, required = false,
                                 default = nil)
  if valid_773305 != nil:
    section.add "X-Amz-SignedHeaders", valid_773305
  var valid_773306 = header.getOrDefault("X-Amz-Credential")
  valid_773306 = validateParameter(valid_773306, JString, required = false,
                                 default = nil)
  if valid_773306 != nil:
    section.add "X-Amz-Credential", valid_773306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773307: Call_DescribeOriginEndpoint_773296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about an existing OriginEndpoint.
  ## 
  let valid = call_773307.validator(path, query, header, formData, body)
  let scheme = call_773307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773307.url(scheme.get, call_773307.host, call_773307.base,
                         call_773307.route, valid.getOrDefault("path"))
  result = hook(call_773307, url, valid)

proc call*(call_773308: Call_DescribeOriginEndpoint_773296; id: string): Recallable =
  ## describeOriginEndpoint
  ## Gets details about an existing OriginEndpoint.
  ##   id: string (required)
  ##     : The ID of the OriginEndpoint.
  var path_773309 = newJObject()
  add(path_773309, "id", newJString(id))
  result = call_773308.call(path_773309, nil, nil, nil, nil)

var describeOriginEndpoint* = Call_DescribeOriginEndpoint_773296(
    name: "describeOriginEndpoint", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints/{id}",
    validator: validate_DescribeOriginEndpoint_773297, base: "/",
    url: url_DescribeOriginEndpoint_773298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOriginEndpoint_773326 = ref object of OpenApiRestCall_772597
proc url_DeleteOriginEndpoint_773328(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/origin_endpoints/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteOriginEndpoint_773327(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing OriginEndpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the OriginEndpoint to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_773329 = path.getOrDefault("id")
  valid_773329 = validateParameter(valid_773329, JString, required = true,
                                 default = nil)
  if valid_773329 != nil:
    section.add "id", valid_773329
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
  var valid_773330 = header.getOrDefault("X-Amz-Date")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-Date", valid_773330
  var valid_773331 = header.getOrDefault("X-Amz-Security-Token")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-Security-Token", valid_773331
  var valid_773332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-Content-Sha256", valid_773332
  var valid_773333 = header.getOrDefault("X-Amz-Algorithm")
  valid_773333 = validateParameter(valid_773333, JString, required = false,
                                 default = nil)
  if valid_773333 != nil:
    section.add "X-Amz-Algorithm", valid_773333
  var valid_773334 = header.getOrDefault("X-Amz-Signature")
  valid_773334 = validateParameter(valid_773334, JString, required = false,
                                 default = nil)
  if valid_773334 != nil:
    section.add "X-Amz-Signature", valid_773334
  var valid_773335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773335 = validateParameter(valid_773335, JString, required = false,
                                 default = nil)
  if valid_773335 != nil:
    section.add "X-Amz-SignedHeaders", valid_773335
  var valid_773336 = header.getOrDefault("X-Amz-Credential")
  valid_773336 = validateParameter(valid_773336, JString, required = false,
                                 default = nil)
  if valid_773336 != nil:
    section.add "X-Amz-Credential", valid_773336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773337: Call_DeleteOriginEndpoint_773326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing OriginEndpoint.
  ## 
  let valid = call_773337.validator(path, query, header, formData, body)
  let scheme = call_773337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773337.url(scheme.get, call_773337.host, call_773337.base,
                         call_773337.route, valid.getOrDefault("path"))
  result = hook(call_773337, url, valid)

proc call*(call_773338: Call_DeleteOriginEndpoint_773326; id: string): Recallable =
  ## deleteOriginEndpoint
  ## Deletes an existing OriginEndpoint.
  ##   id: string (required)
  ##     : The ID of the OriginEndpoint to delete.
  var path_773339 = newJObject()
  add(path_773339, "id", newJString(id))
  result = call_773338.call(path_773339, nil, nil, nil, nil)

var deleteOriginEndpoint* = Call_DeleteOriginEndpoint_773326(
    name: "deleteOriginEndpoint", meth: HttpMethod.HttpDelete,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints/{id}",
    validator: validate_DeleteOriginEndpoint_773327, base: "/",
    url: url_DeleteOriginEndpoint_773328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_773354 = ref object of OpenApiRestCall_772597
proc url_TagResource_773356(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_TagResource_773355(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_773357 = path.getOrDefault("resource-arn")
  valid_773357 = validateParameter(valid_773357, JString, required = true,
                                 default = nil)
  if valid_773357 != nil:
    section.add "resource-arn", valid_773357
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
  var valid_773358 = header.getOrDefault("X-Amz-Date")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Date", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-Security-Token")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Security-Token", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Content-Sha256", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-Algorithm")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-Algorithm", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-Signature")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Signature", valid_773362
  var valid_773363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773363 = validateParameter(valid_773363, JString, required = false,
                                 default = nil)
  if valid_773363 != nil:
    section.add "X-Amz-SignedHeaders", valid_773363
  var valid_773364 = header.getOrDefault("X-Amz-Credential")
  valid_773364 = validateParameter(valid_773364, JString, required = false,
                                 default = nil)
  if valid_773364 != nil:
    section.add "X-Amz-Credential", valid_773364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773366: Call_TagResource_773354; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773366.validator(path, query, header, formData, body)
  let scheme = call_773366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773366.url(scheme.get, call_773366.host, call_773366.base,
                         call_773366.route, valid.getOrDefault("path"))
  result = hook(call_773366, url, valid)

proc call*(call_773367: Call_TagResource_773354; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ##   resourceArn: string (required)
  ##   body: JObject (required)
  var path_773368 = newJObject()
  var body_773369 = newJObject()
  add(path_773368, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_773369 = body
  result = call_773367.call(path_773368, nil, nil, nil, body_773369)

var tagResource* = Call_TagResource_773354(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediapackage.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_773355,
                                        base: "/", url: url_TagResource_773356,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_773340 = ref object of OpenApiRestCall_772597
proc url_ListTagsForResource_773342(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListTagsForResource_773341(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_773343 = path.getOrDefault("resource-arn")
  valid_773343 = validateParameter(valid_773343, JString, required = true,
                                 default = nil)
  if valid_773343 != nil:
    section.add "resource-arn", valid_773343
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
  var valid_773344 = header.getOrDefault("X-Amz-Date")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Date", valid_773344
  var valid_773345 = header.getOrDefault("X-Amz-Security-Token")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-Security-Token", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-Content-Sha256", valid_773346
  var valid_773347 = header.getOrDefault("X-Amz-Algorithm")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "X-Amz-Algorithm", valid_773347
  var valid_773348 = header.getOrDefault("X-Amz-Signature")
  valid_773348 = validateParameter(valid_773348, JString, required = false,
                                 default = nil)
  if valid_773348 != nil:
    section.add "X-Amz-Signature", valid_773348
  var valid_773349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773349 = validateParameter(valid_773349, JString, required = false,
                                 default = nil)
  if valid_773349 != nil:
    section.add "X-Amz-SignedHeaders", valid_773349
  var valid_773350 = header.getOrDefault("X-Amz-Credential")
  valid_773350 = validateParameter(valid_773350, JString, required = false,
                                 default = nil)
  if valid_773350 != nil:
    section.add "X-Amz-Credential", valid_773350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773351: Call_ListTagsForResource_773340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773351.validator(path, query, header, formData, body)
  let scheme = call_773351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773351.url(scheme.get, call_773351.host, call_773351.base,
                         call_773351.route, valid.getOrDefault("path"))
  result = hook(call_773351, url, valid)

proc call*(call_773352: Call_ListTagsForResource_773340; resourceArn: string): Recallable =
  ## listTagsForResource
  ##   resourceArn: string (required)
  var path_773353 = newJObject()
  add(path_773353, "resource-arn", newJString(resourceArn))
  result = call_773352.call(path_773353, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_773340(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_773341, base: "/",
    url: url_ListTagsForResource_773342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RotateChannelCredentials_773370 = ref object of OpenApiRestCall_772597
proc url_RotateChannelCredentials_773372(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/channels/"),
               (kind: VariableSegment, value: "id"),
               (kind: ConstantSegment, value: "/credentials")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_RotateChannelCredentials_773371(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Changes the Channel's first IngestEndpoint's username and password. WARNING - This API is deprecated. Please use RotateIngestEndpointCredentials instead
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the channel to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_773373 = path.getOrDefault("id")
  valid_773373 = validateParameter(valid_773373, JString, required = true,
                                 default = nil)
  if valid_773373 != nil:
    section.add "id", valid_773373
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
  var valid_773374 = header.getOrDefault("X-Amz-Date")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Date", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-Security-Token")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-Security-Token", valid_773375
  var valid_773376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "X-Amz-Content-Sha256", valid_773376
  var valid_773377 = header.getOrDefault("X-Amz-Algorithm")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-Algorithm", valid_773377
  var valid_773378 = header.getOrDefault("X-Amz-Signature")
  valid_773378 = validateParameter(valid_773378, JString, required = false,
                                 default = nil)
  if valid_773378 != nil:
    section.add "X-Amz-Signature", valid_773378
  var valid_773379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773379 = validateParameter(valid_773379, JString, required = false,
                                 default = nil)
  if valid_773379 != nil:
    section.add "X-Amz-SignedHeaders", valid_773379
  var valid_773380 = header.getOrDefault("X-Amz-Credential")
  valid_773380 = validateParameter(valid_773380, JString, required = false,
                                 default = nil)
  if valid_773380 != nil:
    section.add "X-Amz-Credential", valid_773380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773381: Call_RotateChannelCredentials_773370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the Channel's first IngestEndpoint's username and password. WARNING - This API is deprecated. Please use RotateIngestEndpointCredentials instead
  ## 
  let valid = call_773381.validator(path, query, header, formData, body)
  let scheme = call_773381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773381.url(scheme.get, call_773381.host, call_773381.base,
                         call_773381.route, valid.getOrDefault("path"))
  result = hook(call_773381, url, valid)

proc call*(call_773382: Call_RotateChannelCredentials_773370; id: string): Recallable =
  ## rotateChannelCredentials
  ## Changes the Channel's first IngestEndpoint's username and password. WARNING - This API is deprecated. Please use RotateIngestEndpointCredentials instead
  ##   id: string (required)
  ##     : The ID of the channel to update.
  var path_773383 = newJObject()
  add(path_773383, "id", newJString(id))
  result = call_773382.call(path_773383, nil, nil, nil, nil)

var rotateChannelCredentials* = Call_RotateChannelCredentials_773370(
    name: "rotateChannelCredentials", meth: HttpMethod.HttpPut,
    host: "mediapackage.amazonaws.com", route: "/channels/{id}/credentials",
    validator: validate_RotateChannelCredentials_773371, base: "/",
    url: url_RotateChannelCredentials_773372, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RotateIngestEndpointCredentials_773384 = ref object of OpenApiRestCall_772597
proc url_RotateIngestEndpointCredentials_773386(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  assert "ingest_endpoint_id" in path,
        "`ingest_endpoint_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/channels/"),
               (kind: VariableSegment, value: "id"),
               (kind: ConstantSegment, value: "/ingest_endpoints/"),
               (kind: VariableSegment, value: "ingest_endpoint_id"),
               (kind: ConstantSegment, value: "/credentials")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_RotateIngestEndpointCredentials_773385(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Rotate the IngestEndpoint's username and password, as specified by the IngestEndpoint's id.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ingest_endpoint_id: JString (required)
  ##                     : The id of the IngestEndpoint whose credentials should be rotated
  ##   id: JString (required)
  ##     : The ID of the channel the IngestEndpoint is on.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ingest_endpoint_id` field"
  var valid_773387 = path.getOrDefault("ingest_endpoint_id")
  valid_773387 = validateParameter(valid_773387, JString, required = true,
                                 default = nil)
  if valid_773387 != nil:
    section.add "ingest_endpoint_id", valid_773387
  var valid_773388 = path.getOrDefault("id")
  valid_773388 = validateParameter(valid_773388, JString, required = true,
                                 default = nil)
  if valid_773388 != nil:
    section.add "id", valid_773388
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
  var valid_773389 = header.getOrDefault("X-Amz-Date")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Date", valid_773389
  var valid_773390 = header.getOrDefault("X-Amz-Security-Token")
  valid_773390 = validateParameter(valid_773390, JString, required = false,
                                 default = nil)
  if valid_773390 != nil:
    section.add "X-Amz-Security-Token", valid_773390
  var valid_773391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "X-Amz-Content-Sha256", valid_773391
  var valid_773392 = header.getOrDefault("X-Amz-Algorithm")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "X-Amz-Algorithm", valid_773392
  var valid_773393 = header.getOrDefault("X-Amz-Signature")
  valid_773393 = validateParameter(valid_773393, JString, required = false,
                                 default = nil)
  if valid_773393 != nil:
    section.add "X-Amz-Signature", valid_773393
  var valid_773394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773394 = validateParameter(valid_773394, JString, required = false,
                                 default = nil)
  if valid_773394 != nil:
    section.add "X-Amz-SignedHeaders", valid_773394
  var valid_773395 = header.getOrDefault("X-Amz-Credential")
  valid_773395 = validateParameter(valid_773395, JString, required = false,
                                 default = nil)
  if valid_773395 != nil:
    section.add "X-Amz-Credential", valid_773395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773396: Call_RotateIngestEndpointCredentials_773384;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Rotate the IngestEndpoint's username and password, as specified by the IngestEndpoint's id.
  ## 
  let valid = call_773396.validator(path, query, header, formData, body)
  let scheme = call_773396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773396.url(scheme.get, call_773396.host, call_773396.base,
                         call_773396.route, valid.getOrDefault("path"))
  result = hook(call_773396, url, valid)

proc call*(call_773397: Call_RotateIngestEndpointCredentials_773384;
          ingestEndpointId: string; id: string): Recallable =
  ## rotateIngestEndpointCredentials
  ## Rotate the IngestEndpoint's username and password, as specified by the IngestEndpoint's id.
  ##   ingestEndpointId: string (required)
  ##                   : The id of the IngestEndpoint whose credentials should be rotated
  ##   id: string (required)
  ##     : The ID of the channel the IngestEndpoint is on.
  var path_773398 = newJObject()
  add(path_773398, "ingest_endpoint_id", newJString(ingestEndpointId))
  add(path_773398, "id", newJString(id))
  result = call_773397.call(path_773398, nil, nil, nil, nil)

var rotateIngestEndpointCredentials* = Call_RotateIngestEndpointCredentials_773384(
    name: "rotateIngestEndpointCredentials", meth: HttpMethod.HttpPut,
    host: "mediapackage.amazonaws.com",
    route: "/channels/{id}/ingest_endpoints/{ingest_endpoint_id}/credentials",
    validator: validate_RotateIngestEndpointCredentials_773385, base: "/",
    url: url_RotateIngestEndpointCredentials_773386,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_773399 = ref object of OpenApiRestCall_772597
proc url_UntagResource_773401(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource-arn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UntagResource_773400(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_773402 = path.getOrDefault("resource-arn")
  valid_773402 = validateParameter(valid_773402, JString, required = true,
                                 default = nil)
  if valid_773402 != nil:
    section.add "resource-arn", valid_773402
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key(s) of tag to be deleted
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_773403 = query.getOrDefault("tagKeys")
  valid_773403 = validateParameter(valid_773403, JArray, required = true, default = nil)
  if valid_773403 != nil:
    section.add "tagKeys", valid_773403
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
  var valid_773404 = header.getOrDefault("X-Amz-Date")
  valid_773404 = validateParameter(valid_773404, JString, required = false,
                                 default = nil)
  if valid_773404 != nil:
    section.add "X-Amz-Date", valid_773404
  var valid_773405 = header.getOrDefault("X-Amz-Security-Token")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "X-Amz-Security-Token", valid_773405
  var valid_773406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "X-Amz-Content-Sha256", valid_773406
  var valid_773407 = header.getOrDefault("X-Amz-Algorithm")
  valid_773407 = validateParameter(valid_773407, JString, required = false,
                                 default = nil)
  if valid_773407 != nil:
    section.add "X-Amz-Algorithm", valid_773407
  var valid_773408 = header.getOrDefault("X-Amz-Signature")
  valid_773408 = validateParameter(valid_773408, JString, required = false,
                                 default = nil)
  if valid_773408 != nil:
    section.add "X-Amz-Signature", valid_773408
  var valid_773409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773409 = validateParameter(valid_773409, JString, required = false,
                                 default = nil)
  if valid_773409 != nil:
    section.add "X-Amz-SignedHeaders", valid_773409
  var valid_773410 = header.getOrDefault("X-Amz-Credential")
  valid_773410 = validateParameter(valid_773410, JString, required = false,
                                 default = nil)
  if valid_773410 != nil:
    section.add "X-Amz-Credential", valid_773410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773411: Call_UntagResource_773399; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773411.validator(path, query, header, formData, body)
  let scheme = call_773411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773411.url(scheme.get, call_773411.host, call_773411.base,
                         call_773411.route, valid.getOrDefault("path"))
  result = hook(call_773411, url, valid)

proc call*(call_773412: Call_UntagResource_773399; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ##   tagKeys: JArray (required)
  ##          : The key(s) of tag to be deleted
  ##   resourceArn: string (required)
  var path_773413 = newJObject()
  var query_773414 = newJObject()
  if tagKeys != nil:
    query_773414.add "tagKeys", tagKeys
  add(path_773413, "resource-arn", newJString(resourceArn))
  result = call_773412.call(path_773413, query_773414, nil, nil, nil)

var untagResource* = Call_UntagResource_773399(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "mediapackage.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_773400,
    base: "/", url: url_UntagResource_773401, schemes: {Scheme.Https, Scheme.Http})
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
