
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Elemental MediaLive
## version: 2017-10-14
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## API for AWS Elemental MediaLive
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/medialive/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "medialive.ap-northeast-1.amazonaws.com", "ap-southeast-1": "medialive.ap-southeast-1.amazonaws.com",
                           "us-west-2": "medialive.us-west-2.amazonaws.com",
                           "eu-west-2": "medialive.eu-west-2.amazonaws.com", "ap-northeast-3": "medialive.ap-northeast-3.amazonaws.com", "eu-central-1": "medialive.eu-central-1.amazonaws.com",
                           "us-east-2": "medialive.us-east-2.amazonaws.com",
                           "us-east-1": "medialive.us-east-1.amazonaws.com", "cn-northwest-1": "medialive.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "medialive.ap-south-1.amazonaws.com",
                           "eu-north-1": "medialive.eu-north-1.amazonaws.com", "ap-northeast-2": "medialive.ap-northeast-2.amazonaws.com",
                           "us-west-1": "medialive.us-west-1.amazonaws.com", "us-gov-east-1": "medialive.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "medialive.eu-west-3.amazonaws.com", "cn-north-1": "medialive.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "medialive.sa-east-1.amazonaws.com",
                           "eu-west-1": "medialive.eu-west-1.amazonaws.com", "us-gov-west-1": "medialive.us-gov-west-1.amazonaws.com", "ap-southeast-2": "medialive.ap-southeast-2.amazonaws.com", "ca-central-1": "medialive.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "medialive.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "medialive.ap-southeast-1.amazonaws.com",
      "us-west-2": "medialive.us-west-2.amazonaws.com",
      "eu-west-2": "medialive.eu-west-2.amazonaws.com",
      "ap-northeast-3": "medialive.ap-northeast-3.amazonaws.com",
      "eu-central-1": "medialive.eu-central-1.amazonaws.com",
      "us-east-2": "medialive.us-east-2.amazonaws.com",
      "us-east-1": "medialive.us-east-1.amazonaws.com",
      "cn-northwest-1": "medialive.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "medialive.ap-south-1.amazonaws.com",
      "eu-north-1": "medialive.eu-north-1.amazonaws.com",
      "ap-northeast-2": "medialive.ap-northeast-2.amazonaws.com",
      "us-west-1": "medialive.us-west-1.amazonaws.com",
      "us-gov-east-1": "medialive.us-gov-east-1.amazonaws.com",
      "eu-west-3": "medialive.eu-west-3.amazonaws.com",
      "cn-north-1": "medialive.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "medialive.sa-east-1.amazonaws.com",
      "eu-west-1": "medialive.eu-west-1.amazonaws.com",
      "us-gov-west-1": "medialive.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "medialive.ap-southeast-2.amazonaws.com",
      "ca-central-1": "medialive.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "medialive"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_BatchUpdateSchedule_773208 = ref object of OpenApiRestCall_772597
proc url_BatchUpdateSchedule_773210(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId"),
               (kind: ConstantSegment, value: "/schedule")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_BatchUpdateSchedule_773209(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Update a channel schedule
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_773211 = path.getOrDefault("channelId")
  valid_773211 = validateParameter(valid_773211, JString, required = true,
                                 default = nil)
  if valid_773211 != nil:
    section.add "channelId", valid_773211
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
  var valid_773212 = header.getOrDefault("X-Amz-Date")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Date", valid_773212
  var valid_773213 = header.getOrDefault("X-Amz-Security-Token")
  valid_773213 = validateParameter(valid_773213, JString, required = false,
                                 default = nil)
  if valid_773213 != nil:
    section.add "X-Amz-Security-Token", valid_773213
  var valid_773214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773214 = validateParameter(valid_773214, JString, required = false,
                                 default = nil)
  if valid_773214 != nil:
    section.add "X-Amz-Content-Sha256", valid_773214
  var valid_773215 = header.getOrDefault("X-Amz-Algorithm")
  valid_773215 = validateParameter(valid_773215, JString, required = false,
                                 default = nil)
  if valid_773215 != nil:
    section.add "X-Amz-Algorithm", valid_773215
  var valid_773216 = header.getOrDefault("X-Amz-Signature")
  valid_773216 = validateParameter(valid_773216, JString, required = false,
                                 default = nil)
  if valid_773216 != nil:
    section.add "X-Amz-Signature", valid_773216
  var valid_773217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773217 = validateParameter(valid_773217, JString, required = false,
                                 default = nil)
  if valid_773217 != nil:
    section.add "X-Amz-SignedHeaders", valid_773217
  var valid_773218 = header.getOrDefault("X-Amz-Credential")
  valid_773218 = validateParameter(valid_773218, JString, required = false,
                                 default = nil)
  if valid_773218 != nil:
    section.add "X-Amz-Credential", valid_773218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773220: Call_BatchUpdateSchedule_773208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update a channel schedule
  ## 
  let valid = call_773220.validator(path, query, header, formData, body)
  let scheme = call_773220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773220.url(scheme.get, call_773220.host, call_773220.base,
                         call_773220.route, valid.getOrDefault("path"))
  result = hook(call_773220, url, valid)

proc call*(call_773221: Call_BatchUpdateSchedule_773208; channelId: string;
          body: JsonNode): Recallable =
  ## batchUpdateSchedule
  ## Update a channel schedule
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_773222 = newJObject()
  var body_773223 = newJObject()
  add(path_773222, "channelId", newJString(channelId))
  if body != nil:
    body_773223 = body
  result = call_773221.call(path_773222, nil, nil, nil, body_773223)

var batchUpdateSchedule* = Call_BatchUpdateSchedule_773208(
    name: "batchUpdateSchedule", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com", route: "/prod/channels/{channelId}/schedule",
    validator: validate_BatchUpdateSchedule_773209, base: "/",
    url: url_BatchUpdateSchedule_773210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSchedule_772933 = ref object of OpenApiRestCall_772597
proc url_DescribeSchedule_772935(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId"),
               (kind: ConstantSegment, value: "/schedule")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeSchedule_772934(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Get a channel schedule
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_773061 = path.getOrDefault("channelId")
  valid_773061 = validateParameter(valid_773061, JString, required = true,
                                 default = nil)
  if valid_773061 != nil:
    section.add "channelId", valid_773061
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_773062 = query.getOrDefault("NextToken")
  valid_773062 = validateParameter(valid_773062, JString, required = false,
                                 default = nil)
  if valid_773062 != nil:
    section.add "NextToken", valid_773062
  var valid_773063 = query.getOrDefault("maxResults")
  valid_773063 = validateParameter(valid_773063, JInt, required = false, default = nil)
  if valid_773063 != nil:
    section.add "maxResults", valid_773063
  var valid_773064 = query.getOrDefault("nextToken")
  valid_773064 = validateParameter(valid_773064, JString, required = false,
                                 default = nil)
  if valid_773064 != nil:
    section.add "nextToken", valid_773064
  var valid_773065 = query.getOrDefault("MaxResults")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "MaxResults", valid_773065
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
  var valid_773066 = header.getOrDefault("X-Amz-Date")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-Date", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-Security-Token")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-Security-Token", valid_773067
  var valid_773068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773068 = validateParameter(valid_773068, JString, required = false,
                                 default = nil)
  if valid_773068 != nil:
    section.add "X-Amz-Content-Sha256", valid_773068
  var valid_773069 = header.getOrDefault("X-Amz-Algorithm")
  valid_773069 = validateParameter(valid_773069, JString, required = false,
                                 default = nil)
  if valid_773069 != nil:
    section.add "X-Amz-Algorithm", valid_773069
  var valid_773070 = header.getOrDefault("X-Amz-Signature")
  valid_773070 = validateParameter(valid_773070, JString, required = false,
                                 default = nil)
  if valid_773070 != nil:
    section.add "X-Amz-Signature", valid_773070
  var valid_773071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773071 = validateParameter(valid_773071, JString, required = false,
                                 default = nil)
  if valid_773071 != nil:
    section.add "X-Amz-SignedHeaders", valid_773071
  var valid_773072 = header.getOrDefault("X-Amz-Credential")
  valid_773072 = validateParameter(valid_773072, JString, required = false,
                                 default = nil)
  if valid_773072 != nil:
    section.add "X-Amz-Credential", valid_773072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773095: Call_DescribeSchedule_772933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get a channel schedule
  ## 
  let valid = call_773095.validator(path, query, header, formData, body)
  let scheme = call_773095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773095.url(scheme.get, call_773095.host, call_773095.base,
                         call_773095.route, valid.getOrDefault("path"))
  result = hook(call_773095, url, valid)

proc call*(call_773166: Call_DescribeSchedule_772933; channelId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## describeSchedule
  ## Get a channel schedule
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  var path_773167 = newJObject()
  var query_773169 = newJObject()
  add(path_773167, "channelId", newJString(channelId))
  add(query_773169, "NextToken", newJString(NextToken))
  add(query_773169, "maxResults", newJInt(maxResults))
  add(query_773169, "nextToken", newJString(nextToken))
  add(query_773169, "MaxResults", newJString(MaxResults))
  result = call_773166.call(path_773167, query_773169, nil, nil, nil)

var describeSchedule* = Call_DescribeSchedule_772933(name: "describeSchedule",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/schedule",
    validator: validate_DescribeSchedule_772934, base: "/",
    url: url_DescribeSchedule_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchedule_773224 = ref object of OpenApiRestCall_772597
proc url_DeleteSchedule_773226(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId"),
               (kind: ConstantSegment, value: "/schedule")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteSchedule_773225(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Delete all schedule actions on a channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_773227 = path.getOrDefault("channelId")
  valid_773227 = validateParameter(valid_773227, JString, required = true,
                                 default = nil)
  if valid_773227 != nil:
    section.add "channelId", valid_773227
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
  var valid_773228 = header.getOrDefault("X-Amz-Date")
  valid_773228 = validateParameter(valid_773228, JString, required = false,
                                 default = nil)
  if valid_773228 != nil:
    section.add "X-Amz-Date", valid_773228
  var valid_773229 = header.getOrDefault("X-Amz-Security-Token")
  valid_773229 = validateParameter(valid_773229, JString, required = false,
                                 default = nil)
  if valid_773229 != nil:
    section.add "X-Amz-Security-Token", valid_773229
  var valid_773230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773230 = validateParameter(valid_773230, JString, required = false,
                                 default = nil)
  if valid_773230 != nil:
    section.add "X-Amz-Content-Sha256", valid_773230
  var valid_773231 = header.getOrDefault("X-Amz-Algorithm")
  valid_773231 = validateParameter(valid_773231, JString, required = false,
                                 default = nil)
  if valid_773231 != nil:
    section.add "X-Amz-Algorithm", valid_773231
  var valid_773232 = header.getOrDefault("X-Amz-Signature")
  valid_773232 = validateParameter(valid_773232, JString, required = false,
                                 default = nil)
  if valid_773232 != nil:
    section.add "X-Amz-Signature", valid_773232
  var valid_773233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773233 = validateParameter(valid_773233, JString, required = false,
                                 default = nil)
  if valid_773233 != nil:
    section.add "X-Amz-SignedHeaders", valid_773233
  var valid_773234 = header.getOrDefault("X-Amz-Credential")
  valid_773234 = validateParameter(valid_773234, JString, required = false,
                                 default = nil)
  if valid_773234 != nil:
    section.add "X-Amz-Credential", valid_773234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773235: Call_DeleteSchedule_773224; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete all schedule actions on a channel.
  ## 
  let valid = call_773235.validator(path, query, header, formData, body)
  let scheme = call_773235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773235.url(scheme.get, call_773235.host, call_773235.base,
                         call_773235.route, valid.getOrDefault("path"))
  result = hook(call_773235, url, valid)

proc call*(call_773236: Call_DeleteSchedule_773224; channelId: string): Recallable =
  ## deleteSchedule
  ## Delete all schedule actions on a channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_773237 = newJObject()
  add(path_773237, "channelId", newJString(channelId))
  result = call_773236.call(path_773237, nil, nil, nil, nil)

var deleteSchedule* = Call_DeleteSchedule_773224(name: "deleteSchedule",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/schedule",
    validator: validate_DeleteSchedule_773225, base: "/", url: url_DeleteSchedule_773226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateChannel_773255 = ref object of OpenApiRestCall_772597
proc url_CreateChannel_773257(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateChannel_773256(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new channel
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
  var valid_773258 = header.getOrDefault("X-Amz-Date")
  valid_773258 = validateParameter(valid_773258, JString, required = false,
                                 default = nil)
  if valid_773258 != nil:
    section.add "X-Amz-Date", valid_773258
  var valid_773259 = header.getOrDefault("X-Amz-Security-Token")
  valid_773259 = validateParameter(valid_773259, JString, required = false,
                                 default = nil)
  if valid_773259 != nil:
    section.add "X-Amz-Security-Token", valid_773259
  var valid_773260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773260 = validateParameter(valid_773260, JString, required = false,
                                 default = nil)
  if valid_773260 != nil:
    section.add "X-Amz-Content-Sha256", valid_773260
  var valid_773261 = header.getOrDefault("X-Amz-Algorithm")
  valid_773261 = validateParameter(valid_773261, JString, required = false,
                                 default = nil)
  if valid_773261 != nil:
    section.add "X-Amz-Algorithm", valid_773261
  var valid_773262 = header.getOrDefault("X-Amz-Signature")
  valid_773262 = validateParameter(valid_773262, JString, required = false,
                                 default = nil)
  if valid_773262 != nil:
    section.add "X-Amz-Signature", valid_773262
  var valid_773263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773263 = validateParameter(valid_773263, JString, required = false,
                                 default = nil)
  if valid_773263 != nil:
    section.add "X-Amz-SignedHeaders", valid_773263
  var valid_773264 = header.getOrDefault("X-Amz-Credential")
  valid_773264 = validateParameter(valid_773264, JString, required = false,
                                 default = nil)
  if valid_773264 != nil:
    section.add "X-Amz-Credential", valid_773264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773266: Call_CreateChannel_773255; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new channel
  ## 
  let valid = call_773266.validator(path, query, header, formData, body)
  let scheme = call_773266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773266.url(scheme.get, call_773266.host, call_773266.base,
                         call_773266.route, valid.getOrDefault("path"))
  result = hook(call_773266, url, valid)

proc call*(call_773267: Call_CreateChannel_773255; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a new channel
  ##   body: JObject (required)
  var body_773268 = newJObject()
  if body != nil:
    body_773268 = body
  result = call_773267.call(nil, nil, nil, nil, body_773268)

var createChannel* = Call_CreateChannel_773255(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/channels", validator: validate_CreateChannel_773256, base: "/",
    url: url_CreateChannel_773257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_773238 = ref object of OpenApiRestCall_772597
proc url_ListChannels_773240(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListChannels_773239(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Produces list of channels that have been created
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_773241 = query.getOrDefault("NextToken")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "NextToken", valid_773241
  var valid_773242 = query.getOrDefault("maxResults")
  valid_773242 = validateParameter(valid_773242, JInt, required = false, default = nil)
  if valid_773242 != nil:
    section.add "maxResults", valid_773242
  var valid_773243 = query.getOrDefault("nextToken")
  valid_773243 = validateParameter(valid_773243, JString, required = false,
                                 default = nil)
  if valid_773243 != nil:
    section.add "nextToken", valid_773243
  var valid_773244 = query.getOrDefault("MaxResults")
  valid_773244 = validateParameter(valid_773244, JString, required = false,
                                 default = nil)
  if valid_773244 != nil:
    section.add "MaxResults", valid_773244
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
  var valid_773245 = header.getOrDefault("X-Amz-Date")
  valid_773245 = validateParameter(valid_773245, JString, required = false,
                                 default = nil)
  if valid_773245 != nil:
    section.add "X-Amz-Date", valid_773245
  var valid_773246 = header.getOrDefault("X-Amz-Security-Token")
  valid_773246 = validateParameter(valid_773246, JString, required = false,
                                 default = nil)
  if valid_773246 != nil:
    section.add "X-Amz-Security-Token", valid_773246
  var valid_773247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773247 = validateParameter(valid_773247, JString, required = false,
                                 default = nil)
  if valid_773247 != nil:
    section.add "X-Amz-Content-Sha256", valid_773247
  var valid_773248 = header.getOrDefault("X-Amz-Algorithm")
  valid_773248 = validateParameter(valid_773248, JString, required = false,
                                 default = nil)
  if valid_773248 != nil:
    section.add "X-Amz-Algorithm", valid_773248
  var valid_773249 = header.getOrDefault("X-Amz-Signature")
  valid_773249 = validateParameter(valid_773249, JString, required = false,
                                 default = nil)
  if valid_773249 != nil:
    section.add "X-Amz-Signature", valid_773249
  var valid_773250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-SignedHeaders", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Credential")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Credential", valid_773251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773252: Call_ListChannels_773238; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces list of channels that have been created
  ## 
  let valid = call_773252.validator(path, query, header, formData, body)
  let scheme = call_773252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773252.url(scheme.get, call_773252.host, call_773252.base,
                         call_773252.route, valid.getOrDefault("path"))
  result = hook(call_773252, url, valid)

proc call*(call_773253: Call_ListChannels_773238; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listChannels
  ## Produces list of channels that have been created
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773254 = newJObject()
  add(query_773254, "NextToken", newJString(NextToken))
  add(query_773254, "maxResults", newJInt(maxResults))
  add(query_773254, "nextToken", newJString(nextToken))
  add(query_773254, "MaxResults", newJString(MaxResults))
  result = call_773253.call(nil, query_773254, nil, nil, nil)

var listChannels* = Call_ListChannels_773238(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels", validator: validate_ListChannels_773239, base: "/",
    url: url_ListChannels_773240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInput_773286 = ref object of OpenApiRestCall_772597
proc url_CreateInput_773288(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateInput_773287(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Create an input
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
  var valid_773289 = header.getOrDefault("X-Amz-Date")
  valid_773289 = validateParameter(valid_773289, JString, required = false,
                                 default = nil)
  if valid_773289 != nil:
    section.add "X-Amz-Date", valid_773289
  var valid_773290 = header.getOrDefault("X-Amz-Security-Token")
  valid_773290 = validateParameter(valid_773290, JString, required = false,
                                 default = nil)
  if valid_773290 != nil:
    section.add "X-Amz-Security-Token", valid_773290
  var valid_773291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773291 = validateParameter(valid_773291, JString, required = false,
                                 default = nil)
  if valid_773291 != nil:
    section.add "X-Amz-Content-Sha256", valid_773291
  var valid_773292 = header.getOrDefault("X-Amz-Algorithm")
  valid_773292 = validateParameter(valid_773292, JString, required = false,
                                 default = nil)
  if valid_773292 != nil:
    section.add "X-Amz-Algorithm", valid_773292
  var valid_773293 = header.getOrDefault("X-Amz-Signature")
  valid_773293 = validateParameter(valid_773293, JString, required = false,
                                 default = nil)
  if valid_773293 != nil:
    section.add "X-Amz-Signature", valid_773293
  var valid_773294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773294 = validateParameter(valid_773294, JString, required = false,
                                 default = nil)
  if valid_773294 != nil:
    section.add "X-Amz-SignedHeaders", valid_773294
  var valid_773295 = header.getOrDefault("X-Amz-Credential")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Credential", valid_773295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773297: Call_CreateInput_773286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create an input
  ## 
  let valid = call_773297.validator(path, query, header, formData, body)
  let scheme = call_773297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773297.url(scheme.get, call_773297.host, call_773297.base,
                         call_773297.route, valid.getOrDefault("path"))
  result = hook(call_773297, url, valid)

proc call*(call_773298: Call_CreateInput_773286; body: JsonNode): Recallable =
  ## createInput
  ## Create an input
  ##   body: JObject (required)
  var body_773299 = newJObject()
  if body != nil:
    body_773299 = body
  result = call_773298.call(nil, nil, nil, nil, body_773299)

var createInput* = Call_CreateInput_773286(name: "createInput",
                                        meth: HttpMethod.HttpPost,
                                        host: "medialive.amazonaws.com",
                                        route: "/prod/inputs",
                                        validator: validate_CreateInput_773287,
                                        base: "/", url: url_CreateInput_773288,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputs_773269 = ref object of OpenApiRestCall_772597
proc url_ListInputs_773271(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListInputs_773270(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Produces list of inputs that have been created
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_773272 = query.getOrDefault("NextToken")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "NextToken", valid_773272
  var valid_773273 = query.getOrDefault("maxResults")
  valid_773273 = validateParameter(valid_773273, JInt, required = false, default = nil)
  if valid_773273 != nil:
    section.add "maxResults", valid_773273
  var valid_773274 = query.getOrDefault("nextToken")
  valid_773274 = validateParameter(valid_773274, JString, required = false,
                                 default = nil)
  if valid_773274 != nil:
    section.add "nextToken", valid_773274
  var valid_773275 = query.getOrDefault("MaxResults")
  valid_773275 = validateParameter(valid_773275, JString, required = false,
                                 default = nil)
  if valid_773275 != nil:
    section.add "MaxResults", valid_773275
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
  var valid_773276 = header.getOrDefault("X-Amz-Date")
  valid_773276 = validateParameter(valid_773276, JString, required = false,
                                 default = nil)
  if valid_773276 != nil:
    section.add "X-Amz-Date", valid_773276
  var valid_773277 = header.getOrDefault("X-Amz-Security-Token")
  valid_773277 = validateParameter(valid_773277, JString, required = false,
                                 default = nil)
  if valid_773277 != nil:
    section.add "X-Amz-Security-Token", valid_773277
  var valid_773278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773278 = validateParameter(valid_773278, JString, required = false,
                                 default = nil)
  if valid_773278 != nil:
    section.add "X-Amz-Content-Sha256", valid_773278
  var valid_773279 = header.getOrDefault("X-Amz-Algorithm")
  valid_773279 = validateParameter(valid_773279, JString, required = false,
                                 default = nil)
  if valid_773279 != nil:
    section.add "X-Amz-Algorithm", valid_773279
  var valid_773280 = header.getOrDefault("X-Amz-Signature")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Signature", valid_773280
  var valid_773281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "X-Amz-SignedHeaders", valid_773281
  var valid_773282 = header.getOrDefault("X-Amz-Credential")
  valid_773282 = validateParameter(valid_773282, JString, required = false,
                                 default = nil)
  if valid_773282 != nil:
    section.add "X-Amz-Credential", valid_773282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773283: Call_ListInputs_773269; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces list of inputs that have been created
  ## 
  let valid = call_773283.validator(path, query, header, formData, body)
  let scheme = call_773283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773283.url(scheme.get, call_773283.host, call_773283.base,
                         call_773283.route, valid.getOrDefault("path"))
  result = hook(call_773283, url, valid)

proc call*(call_773284: Call_ListInputs_773269; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listInputs
  ## Produces list of inputs that have been created
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773285 = newJObject()
  add(query_773285, "NextToken", newJString(NextToken))
  add(query_773285, "maxResults", newJInt(maxResults))
  add(query_773285, "nextToken", newJString(nextToken))
  add(query_773285, "MaxResults", newJString(MaxResults))
  result = call_773284.call(nil, query_773285, nil, nil, nil)

var listInputs* = Call_ListInputs_773269(name: "listInputs",
                                      meth: HttpMethod.HttpGet,
                                      host: "medialive.amazonaws.com",
                                      route: "/prod/inputs",
                                      validator: validate_ListInputs_773270,
                                      base: "/", url: url_ListInputs_773271,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInputSecurityGroup_773317 = ref object of OpenApiRestCall_772597
proc url_CreateInputSecurityGroup_773319(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateInputSecurityGroup_773318(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a Input Security Group
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
  var valid_773320 = header.getOrDefault("X-Amz-Date")
  valid_773320 = validateParameter(valid_773320, JString, required = false,
                                 default = nil)
  if valid_773320 != nil:
    section.add "X-Amz-Date", valid_773320
  var valid_773321 = header.getOrDefault("X-Amz-Security-Token")
  valid_773321 = validateParameter(valid_773321, JString, required = false,
                                 default = nil)
  if valid_773321 != nil:
    section.add "X-Amz-Security-Token", valid_773321
  var valid_773322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773322 = validateParameter(valid_773322, JString, required = false,
                                 default = nil)
  if valid_773322 != nil:
    section.add "X-Amz-Content-Sha256", valid_773322
  var valid_773323 = header.getOrDefault("X-Amz-Algorithm")
  valid_773323 = validateParameter(valid_773323, JString, required = false,
                                 default = nil)
  if valid_773323 != nil:
    section.add "X-Amz-Algorithm", valid_773323
  var valid_773324 = header.getOrDefault("X-Amz-Signature")
  valid_773324 = validateParameter(valid_773324, JString, required = false,
                                 default = nil)
  if valid_773324 != nil:
    section.add "X-Amz-Signature", valid_773324
  var valid_773325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-SignedHeaders", valid_773325
  var valid_773326 = header.getOrDefault("X-Amz-Credential")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "X-Amz-Credential", valid_773326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773328: Call_CreateInputSecurityGroup_773317; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Input Security Group
  ## 
  let valid = call_773328.validator(path, query, header, formData, body)
  let scheme = call_773328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773328.url(scheme.get, call_773328.host, call_773328.base,
                         call_773328.route, valid.getOrDefault("path"))
  result = hook(call_773328, url, valid)

proc call*(call_773329: Call_CreateInputSecurityGroup_773317; body: JsonNode): Recallable =
  ## createInputSecurityGroup
  ## Creates a Input Security Group
  ##   body: JObject (required)
  var body_773330 = newJObject()
  if body != nil:
    body_773330 = body
  result = call_773329.call(nil, nil, nil, nil, body_773330)

var createInputSecurityGroup* = Call_CreateInputSecurityGroup_773317(
    name: "createInputSecurityGroup", meth: HttpMethod.HttpPost,
    host: "medialive.amazonaws.com", route: "/prod/inputSecurityGroups",
    validator: validate_CreateInputSecurityGroup_773318, base: "/",
    url: url_CreateInputSecurityGroup_773319, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputSecurityGroups_773300 = ref object of OpenApiRestCall_772597
proc url_ListInputSecurityGroups_773302(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListInputSecurityGroups_773301(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Produces a list of Input Security Groups for an account
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_773303 = query.getOrDefault("NextToken")
  valid_773303 = validateParameter(valid_773303, JString, required = false,
                                 default = nil)
  if valid_773303 != nil:
    section.add "NextToken", valid_773303
  var valid_773304 = query.getOrDefault("maxResults")
  valid_773304 = validateParameter(valid_773304, JInt, required = false, default = nil)
  if valid_773304 != nil:
    section.add "maxResults", valid_773304
  var valid_773305 = query.getOrDefault("nextToken")
  valid_773305 = validateParameter(valid_773305, JString, required = false,
                                 default = nil)
  if valid_773305 != nil:
    section.add "nextToken", valid_773305
  var valid_773306 = query.getOrDefault("MaxResults")
  valid_773306 = validateParameter(valid_773306, JString, required = false,
                                 default = nil)
  if valid_773306 != nil:
    section.add "MaxResults", valid_773306
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
  var valid_773307 = header.getOrDefault("X-Amz-Date")
  valid_773307 = validateParameter(valid_773307, JString, required = false,
                                 default = nil)
  if valid_773307 != nil:
    section.add "X-Amz-Date", valid_773307
  var valid_773308 = header.getOrDefault("X-Amz-Security-Token")
  valid_773308 = validateParameter(valid_773308, JString, required = false,
                                 default = nil)
  if valid_773308 != nil:
    section.add "X-Amz-Security-Token", valid_773308
  var valid_773309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773309 = validateParameter(valid_773309, JString, required = false,
                                 default = nil)
  if valid_773309 != nil:
    section.add "X-Amz-Content-Sha256", valid_773309
  var valid_773310 = header.getOrDefault("X-Amz-Algorithm")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-Algorithm", valid_773310
  var valid_773311 = header.getOrDefault("X-Amz-Signature")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-Signature", valid_773311
  var valid_773312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773312 = validateParameter(valid_773312, JString, required = false,
                                 default = nil)
  if valid_773312 != nil:
    section.add "X-Amz-SignedHeaders", valid_773312
  var valid_773313 = header.getOrDefault("X-Amz-Credential")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Credential", valid_773313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773314: Call_ListInputSecurityGroups_773300; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces a list of Input Security Groups for an account
  ## 
  let valid = call_773314.validator(path, query, header, formData, body)
  let scheme = call_773314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773314.url(scheme.get, call_773314.host, call_773314.base,
                         call_773314.route, valid.getOrDefault("path"))
  result = hook(call_773314, url, valid)

proc call*(call_773315: Call_ListInputSecurityGroups_773300;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listInputSecurityGroups
  ## Produces a list of Input Security Groups for an account
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773316 = newJObject()
  add(query_773316, "NextToken", newJString(NextToken))
  add(query_773316, "maxResults", newJInt(maxResults))
  add(query_773316, "nextToken", newJString(nextToken))
  add(query_773316, "MaxResults", newJString(MaxResults))
  result = call_773315.call(nil, query_773316, nil, nil, nil)

var listInputSecurityGroups* = Call_ListInputSecurityGroups_773300(
    name: "listInputSecurityGroups", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/inputSecurityGroups",
    validator: validate_ListInputSecurityGroups_773301, base: "/",
    url: url_ListInputSecurityGroups_773302, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_773345 = ref object of OpenApiRestCall_772597
proc url_CreateTags_773347(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateTags_773346(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Create tags for a resource
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_773348 = path.getOrDefault("resource-arn")
  valid_773348 = validateParameter(valid_773348, JString, required = true,
                                 default = nil)
  if valid_773348 != nil:
    section.add "resource-arn", valid_773348
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
  var valid_773349 = header.getOrDefault("X-Amz-Date")
  valid_773349 = validateParameter(valid_773349, JString, required = false,
                                 default = nil)
  if valid_773349 != nil:
    section.add "X-Amz-Date", valid_773349
  var valid_773350 = header.getOrDefault("X-Amz-Security-Token")
  valid_773350 = validateParameter(valid_773350, JString, required = false,
                                 default = nil)
  if valid_773350 != nil:
    section.add "X-Amz-Security-Token", valid_773350
  var valid_773351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773351 = validateParameter(valid_773351, JString, required = false,
                                 default = nil)
  if valid_773351 != nil:
    section.add "X-Amz-Content-Sha256", valid_773351
  var valid_773352 = header.getOrDefault("X-Amz-Algorithm")
  valid_773352 = validateParameter(valid_773352, JString, required = false,
                                 default = nil)
  if valid_773352 != nil:
    section.add "X-Amz-Algorithm", valid_773352
  var valid_773353 = header.getOrDefault("X-Amz-Signature")
  valid_773353 = validateParameter(valid_773353, JString, required = false,
                                 default = nil)
  if valid_773353 != nil:
    section.add "X-Amz-Signature", valid_773353
  var valid_773354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773354 = validateParameter(valid_773354, JString, required = false,
                                 default = nil)
  if valid_773354 != nil:
    section.add "X-Amz-SignedHeaders", valid_773354
  var valid_773355 = header.getOrDefault("X-Amz-Credential")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-Credential", valid_773355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773357: Call_CreateTags_773345; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create tags for a resource
  ## 
  let valid = call_773357.validator(path, query, header, formData, body)
  let scheme = call_773357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773357.url(scheme.get, call_773357.host, call_773357.base,
                         call_773357.route, valid.getOrDefault("path"))
  result = hook(call_773357, url, valid)

proc call*(call_773358: Call_CreateTags_773345; resourceArn: string; body: JsonNode): Recallable =
  ## createTags
  ## Create tags for a resource
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_773359 = newJObject()
  var body_773360 = newJObject()
  add(path_773359, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_773360 = body
  result = call_773358.call(path_773359, nil, nil, nil, body_773360)

var createTags* = Call_CreateTags_773345(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "medialive.amazonaws.com",
                                      route: "/prod/tags/{resource-arn}",
                                      validator: validate_CreateTags_773346,
                                      base: "/", url: url_CreateTags_773347,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_773331 = ref object of OpenApiRestCall_772597
proc url_ListTagsForResource_773333(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListTagsForResource_773332(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Produces list of tags that have been created for a resource
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_773334 = path.getOrDefault("resource-arn")
  valid_773334 = validateParameter(valid_773334, JString, required = true,
                                 default = nil)
  if valid_773334 != nil:
    section.add "resource-arn", valid_773334
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
  var valid_773335 = header.getOrDefault("X-Amz-Date")
  valid_773335 = validateParameter(valid_773335, JString, required = false,
                                 default = nil)
  if valid_773335 != nil:
    section.add "X-Amz-Date", valid_773335
  var valid_773336 = header.getOrDefault("X-Amz-Security-Token")
  valid_773336 = validateParameter(valid_773336, JString, required = false,
                                 default = nil)
  if valid_773336 != nil:
    section.add "X-Amz-Security-Token", valid_773336
  var valid_773337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773337 = validateParameter(valid_773337, JString, required = false,
                                 default = nil)
  if valid_773337 != nil:
    section.add "X-Amz-Content-Sha256", valid_773337
  var valid_773338 = header.getOrDefault("X-Amz-Algorithm")
  valid_773338 = validateParameter(valid_773338, JString, required = false,
                                 default = nil)
  if valid_773338 != nil:
    section.add "X-Amz-Algorithm", valid_773338
  var valid_773339 = header.getOrDefault("X-Amz-Signature")
  valid_773339 = validateParameter(valid_773339, JString, required = false,
                                 default = nil)
  if valid_773339 != nil:
    section.add "X-Amz-Signature", valid_773339
  var valid_773340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "X-Amz-SignedHeaders", valid_773340
  var valid_773341 = header.getOrDefault("X-Amz-Credential")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "X-Amz-Credential", valid_773341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773342: Call_ListTagsForResource_773331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces list of tags that have been created for a resource
  ## 
  let valid = call_773342.validator(path, query, header, formData, body)
  let scheme = call_773342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773342.url(scheme.get, call_773342.host, call_773342.base,
                         call_773342.route, valid.getOrDefault("path"))
  result = hook(call_773342, url, valid)

proc call*(call_773343: Call_ListTagsForResource_773331; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Produces list of tags that have been created for a resource
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  var path_773344 = newJObject()
  add(path_773344, "resource-arn", newJString(resourceArn))
  result = call_773343.call(path_773344, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_773331(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/tags/{resource-arn}",
    validator: validate_ListTagsForResource_773332, base: "/",
    url: url_ListTagsForResource_773333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_773375 = ref object of OpenApiRestCall_772597
proc url_UpdateChannel_773377(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateChannel_773376(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_773378 = path.getOrDefault("channelId")
  valid_773378 = validateParameter(valid_773378, JString, required = true,
                                 default = nil)
  if valid_773378 != nil:
    section.add "channelId", valid_773378
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
  var valid_773379 = header.getOrDefault("X-Amz-Date")
  valid_773379 = validateParameter(valid_773379, JString, required = false,
                                 default = nil)
  if valid_773379 != nil:
    section.add "X-Amz-Date", valid_773379
  var valid_773380 = header.getOrDefault("X-Amz-Security-Token")
  valid_773380 = validateParameter(valid_773380, JString, required = false,
                                 default = nil)
  if valid_773380 != nil:
    section.add "X-Amz-Security-Token", valid_773380
  var valid_773381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773381 = validateParameter(valid_773381, JString, required = false,
                                 default = nil)
  if valid_773381 != nil:
    section.add "X-Amz-Content-Sha256", valid_773381
  var valid_773382 = header.getOrDefault("X-Amz-Algorithm")
  valid_773382 = validateParameter(valid_773382, JString, required = false,
                                 default = nil)
  if valid_773382 != nil:
    section.add "X-Amz-Algorithm", valid_773382
  var valid_773383 = header.getOrDefault("X-Amz-Signature")
  valid_773383 = validateParameter(valid_773383, JString, required = false,
                                 default = nil)
  if valid_773383 != nil:
    section.add "X-Amz-Signature", valid_773383
  var valid_773384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773384 = validateParameter(valid_773384, JString, required = false,
                                 default = nil)
  if valid_773384 != nil:
    section.add "X-Amz-SignedHeaders", valid_773384
  var valid_773385 = header.getOrDefault("X-Amz-Credential")
  valid_773385 = validateParameter(valid_773385, JString, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "X-Amz-Credential", valid_773385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773387: Call_UpdateChannel_773375; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a channel.
  ## 
  let valid = call_773387.validator(path, query, header, formData, body)
  let scheme = call_773387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773387.url(scheme.get, call_773387.host, call_773387.base,
                         call_773387.route, valid.getOrDefault("path"))
  result = hook(call_773387, url, valid)

proc call*(call_773388: Call_UpdateChannel_773375; channelId: string; body: JsonNode): Recallable =
  ## updateChannel
  ## Updates a channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_773389 = newJObject()
  var body_773390 = newJObject()
  add(path_773389, "channelId", newJString(channelId))
  if body != nil:
    body_773390 = body
  result = call_773388.call(path_773389, nil, nil, nil, body_773390)

var updateChannel* = Call_UpdateChannel_773375(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_UpdateChannel_773376,
    base: "/", url: url_UpdateChannel_773377, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_773361 = ref object of OpenApiRestCall_772597
proc url_DescribeChannel_773363(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeChannel_773362(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Gets details about a channel
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_773364 = path.getOrDefault("channelId")
  valid_773364 = validateParameter(valid_773364, JString, required = true,
                                 default = nil)
  if valid_773364 != nil:
    section.add "channelId", valid_773364
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
  var valid_773365 = header.getOrDefault("X-Amz-Date")
  valid_773365 = validateParameter(valid_773365, JString, required = false,
                                 default = nil)
  if valid_773365 != nil:
    section.add "X-Amz-Date", valid_773365
  var valid_773366 = header.getOrDefault("X-Amz-Security-Token")
  valid_773366 = validateParameter(valid_773366, JString, required = false,
                                 default = nil)
  if valid_773366 != nil:
    section.add "X-Amz-Security-Token", valid_773366
  var valid_773367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773367 = validateParameter(valid_773367, JString, required = false,
                                 default = nil)
  if valid_773367 != nil:
    section.add "X-Amz-Content-Sha256", valid_773367
  var valid_773368 = header.getOrDefault("X-Amz-Algorithm")
  valid_773368 = validateParameter(valid_773368, JString, required = false,
                                 default = nil)
  if valid_773368 != nil:
    section.add "X-Amz-Algorithm", valid_773368
  var valid_773369 = header.getOrDefault("X-Amz-Signature")
  valid_773369 = validateParameter(valid_773369, JString, required = false,
                                 default = nil)
  if valid_773369 != nil:
    section.add "X-Amz-Signature", valid_773369
  var valid_773370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-SignedHeaders", valid_773370
  var valid_773371 = header.getOrDefault("X-Amz-Credential")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Credential", valid_773371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773372: Call_DescribeChannel_773361; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about a channel
  ## 
  let valid = call_773372.validator(path, query, header, formData, body)
  let scheme = call_773372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773372.url(scheme.get, call_773372.host, call_773372.base,
                         call_773372.route, valid.getOrDefault("path"))
  result = hook(call_773372, url, valid)

proc call*(call_773373: Call_DescribeChannel_773361; channelId: string): Recallable =
  ## describeChannel
  ## Gets details about a channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_773374 = newJObject()
  add(path_773374, "channelId", newJString(channelId))
  result = call_773373.call(path_773374, nil, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_773361(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_DescribeChannel_773362,
    base: "/", url: url_DescribeChannel_773363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_773391 = ref object of OpenApiRestCall_772597
proc url_DeleteChannel_773393(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteChannel_773392(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts deletion of channel. The associated outputs are also deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_773394 = path.getOrDefault("channelId")
  valid_773394 = validateParameter(valid_773394, JString, required = true,
                                 default = nil)
  if valid_773394 != nil:
    section.add "channelId", valid_773394
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
  var valid_773395 = header.getOrDefault("X-Amz-Date")
  valid_773395 = validateParameter(valid_773395, JString, required = false,
                                 default = nil)
  if valid_773395 != nil:
    section.add "X-Amz-Date", valid_773395
  var valid_773396 = header.getOrDefault("X-Amz-Security-Token")
  valid_773396 = validateParameter(valid_773396, JString, required = false,
                                 default = nil)
  if valid_773396 != nil:
    section.add "X-Amz-Security-Token", valid_773396
  var valid_773397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773397 = validateParameter(valid_773397, JString, required = false,
                                 default = nil)
  if valid_773397 != nil:
    section.add "X-Amz-Content-Sha256", valid_773397
  var valid_773398 = header.getOrDefault("X-Amz-Algorithm")
  valid_773398 = validateParameter(valid_773398, JString, required = false,
                                 default = nil)
  if valid_773398 != nil:
    section.add "X-Amz-Algorithm", valid_773398
  var valid_773399 = header.getOrDefault("X-Amz-Signature")
  valid_773399 = validateParameter(valid_773399, JString, required = false,
                                 default = nil)
  if valid_773399 != nil:
    section.add "X-Amz-Signature", valid_773399
  var valid_773400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773400 = validateParameter(valid_773400, JString, required = false,
                                 default = nil)
  if valid_773400 != nil:
    section.add "X-Amz-SignedHeaders", valid_773400
  var valid_773401 = header.getOrDefault("X-Amz-Credential")
  valid_773401 = validateParameter(valid_773401, JString, required = false,
                                 default = nil)
  if valid_773401 != nil:
    section.add "X-Amz-Credential", valid_773401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773402: Call_DeleteChannel_773391; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts deletion of channel. The associated outputs are also deleted.
  ## 
  let valid = call_773402.validator(path, query, header, formData, body)
  let scheme = call_773402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773402.url(scheme.get, call_773402.host, call_773402.base,
                         call_773402.route, valid.getOrDefault("path"))
  result = hook(call_773402, url, valid)

proc call*(call_773403: Call_DeleteChannel_773391; channelId: string): Recallable =
  ## deleteChannel
  ## Starts deletion of channel. The associated outputs are also deleted.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_773404 = newJObject()
  add(path_773404, "channelId", newJString(channelId))
  result = call_773403.call(path_773404, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_773391(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_DeleteChannel_773392,
    base: "/", url: url_DeleteChannel_773393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInput_773419 = ref object of OpenApiRestCall_772597
proc url_UpdateInput_773421(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "inputId" in path, "`inputId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputs/"),
               (kind: VariableSegment, value: "inputId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateInput_773420(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an input.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputId: JString (required)
  ##          : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputId` field"
  var valid_773422 = path.getOrDefault("inputId")
  valid_773422 = validateParameter(valid_773422, JString, required = true,
                                 default = nil)
  if valid_773422 != nil:
    section.add "inputId", valid_773422
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
  var valid_773423 = header.getOrDefault("X-Amz-Date")
  valid_773423 = validateParameter(valid_773423, JString, required = false,
                                 default = nil)
  if valid_773423 != nil:
    section.add "X-Amz-Date", valid_773423
  var valid_773424 = header.getOrDefault("X-Amz-Security-Token")
  valid_773424 = validateParameter(valid_773424, JString, required = false,
                                 default = nil)
  if valid_773424 != nil:
    section.add "X-Amz-Security-Token", valid_773424
  var valid_773425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773425 = validateParameter(valid_773425, JString, required = false,
                                 default = nil)
  if valid_773425 != nil:
    section.add "X-Amz-Content-Sha256", valid_773425
  var valid_773426 = header.getOrDefault("X-Amz-Algorithm")
  valid_773426 = validateParameter(valid_773426, JString, required = false,
                                 default = nil)
  if valid_773426 != nil:
    section.add "X-Amz-Algorithm", valid_773426
  var valid_773427 = header.getOrDefault("X-Amz-Signature")
  valid_773427 = validateParameter(valid_773427, JString, required = false,
                                 default = nil)
  if valid_773427 != nil:
    section.add "X-Amz-Signature", valid_773427
  var valid_773428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773428 = validateParameter(valid_773428, JString, required = false,
                                 default = nil)
  if valid_773428 != nil:
    section.add "X-Amz-SignedHeaders", valid_773428
  var valid_773429 = header.getOrDefault("X-Amz-Credential")
  valid_773429 = validateParameter(valid_773429, JString, required = false,
                                 default = nil)
  if valid_773429 != nil:
    section.add "X-Amz-Credential", valid_773429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773431: Call_UpdateInput_773419; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an input.
  ## 
  let valid = call_773431.validator(path, query, header, formData, body)
  let scheme = call_773431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773431.url(scheme.get, call_773431.host, call_773431.base,
                         call_773431.route, valid.getOrDefault("path"))
  result = hook(call_773431, url, valid)

proc call*(call_773432: Call_UpdateInput_773419; inputId: string; body: JsonNode): Recallable =
  ## updateInput
  ## Updates an input.
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_773433 = newJObject()
  var body_773434 = newJObject()
  add(path_773433, "inputId", newJString(inputId))
  if body != nil:
    body_773434 = body
  result = call_773432.call(path_773433, nil, nil, nil, body_773434)

var updateInput* = Call_UpdateInput_773419(name: "updateInput",
                                        meth: HttpMethod.HttpPut,
                                        host: "medialive.amazonaws.com",
                                        route: "/prod/inputs/{inputId}",
                                        validator: validate_UpdateInput_773420,
                                        base: "/", url: url_UpdateInput_773421,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInput_773405 = ref object of OpenApiRestCall_772597
proc url_DescribeInput_773407(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "inputId" in path, "`inputId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputs/"),
               (kind: VariableSegment, value: "inputId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeInput_773406(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Produces details about an input
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputId: JString (required)
  ##          : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputId` field"
  var valid_773408 = path.getOrDefault("inputId")
  valid_773408 = validateParameter(valid_773408, JString, required = true,
                                 default = nil)
  if valid_773408 != nil:
    section.add "inputId", valid_773408
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
  var valid_773409 = header.getOrDefault("X-Amz-Date")
  valid_773409 = validateParameter(valid_773409, JString, required = false,
                                 default = nil)
  if valid_773409 != nil:
    section.add "X-Amz-Date", valid_773409
  var valid_773410 = header.getOrDefault("X-Amz-Security-Token")
  valid_773410 = validateParameter(valid_773410, JString, required = false,
                                 default = nil)
  if valid_773410 != nil:
    section.add "X-Amz-Security-Token", valid_773410
  var valid_773411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773411 = validateParameter(valid_773411, JString, required = false,
                                 default = nil)
  if valid_773411 != nil:
    section.add "X-Amz-Content-Sha256", valid_773411
  var valid_773412 = header.getOrDefault("X-Amz-Algorithm")
  valid_773412 = validateParameter(valid_773412, JString, required = false,
                                 default = nil)
  if valid_773412 != nil:
    section.add "X-Amz-Algorithm", valid_773412
  var valid_773413 = header.getOrDefault("X-Amz-Signature")
  valid_773413 = validateParameter(valid_773413, JString, required = false,
                                 default = nil)
  if valid_773413 != nil:
    section.add "X-Amz-Signature", valid_773413
  var valid_773414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773414 = validateParameter(valid_773414, JString, required = false,
                                 default = nil)
  if valid_773414 != nil:
    section.add "X-Amz-SignedHeaders", valid_773414
  var valid_773415 = header.getOrDefault("X-Amz-Credential")
  valid_773415 = validateParameter(valid_773415, JString, required = false,
                                 default = nil)
  if valid_773415 != nil:
    section.add "X-Amz-Credential", valid_773415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773416: Call_DescribeInput_773405; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces details about an input
  ## 
  let valid = call_773416.validator(path, query, header, formData, body)
  let scheme = call_773416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773416.url(scheme.get, call_773416.host, call_773416.base,
                         call_773416.route, valid.getOrDefault("path"))
  result = hook(call_773416, url, valid)

proc call*(call_773417: Call_DescribeInput_773405; inputId: string): Recallable =
  ## describeInput
  ## Produces details about an input
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  var path_773418 = newJObject()
  add(path_773418, "inputId", newJString(inputId))
  result = call_773417.call(path_773418, nil, nil, nil, nil)

var describeInput* = Call_DescribeInput_773405(name: "describeInput",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/inputs/{inputId}", validator: validate_DescribeInput_773406,
    base: "/", url: url_DescribeInput_773407, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInput_773435 = ref object of OpenApiRestCall_772597
proc url_DeleteInput_773437(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "inputId" in path, "`inputId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputs/"),
               (kind: VariableSegment, value: "inputId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteInput_773436(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the input end point
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputId: JString (required)
  ##          : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputId` field"
  var valid_773438 = path.getOrDefault("inputId")
  valid_773438 = validateParameter(valid_773438, JString, required = true,
                                 default = nil)
  if valid_773438 != nil:
    section.add "inputId", valid_773438
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
  var valid_773439 = header.getOrDefault("X-Amz-Date")
  valid_773439 = validateParameter(valid_773439, JString, required = false,
                                 default = nil)
  if valid_773439 != nil:
    section.add "X-Amz-Date", valid_773439
  var valid_773440 = header.getOrDefault("X-Amz-Security-Token")
  valid_773440 = validateParameter(valid_773440, JString, required = false,
                                 default = nil)
  if valid_773440 != nil:
    section.add "X-Amz-Security-Token", valid_773440
  var valid_773441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773441 = validateParameter(valid_773441, JString, required = false,
                                 default = nil)
  if valid_773441 != nil:
    section.add "X-Amz-Content-Sha256", valid_773441
  var valid_773442 = header.getOrDefault("X-Amz-Algorithm")
  valid_773442 = validateParameter(valid_773442, JString, required = false,
                                 default = nil)
  if valid_773442 != nil:
    section.add "X-Amz-Algorithm", valid_773442
  var valid_773443 = header.getOrDefault("X-Amz-Signature")
  valid_773443 = validateParameter(valid_773443, JString, required = false,
                                 default = nil)
  if valid_773443 != nil:
    section.add "X-Amz-Signature", valid_773443
  var valid_773444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773444 = validateParameter(valid_773444, JString, required = false,
                                 default = nil)
  if valid_773444 != nil:
    section.add "X-Amz-SignedHeaders", valid_773444
  var valid_773445 = header.getOrDefault("X-Amz-Credential")
  valid_773445 = validateParameter(valid_773445, JString, required = false,
                                 default = nil)
  if valid_773445 != nil:
    section.add "X-Amz-Credential", valid_773445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773446: Call_DeleteInput_773435; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the input end point
  ## 
  let valid = call_773446.validator(path, query, header, formData, body)
  let scheme = call_773446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773446.url(scheme.get, call_773446.host, call_773446.base,
                         call_773446.route, valid.getOrDefault("path"))
  result = hook(call_773446, url, valid)

proc call*(call_773447: Call_DeleteInput_773435; inputId: string): Recallable =
  ## deleteInput
  ## Deletes the input end point
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  var path_773448 = newJObject()
  add(path_773448, "inputId", newJString(inputId))
  result = call_773447.call(path_773448, nil, nil, nil, nil)

var deleteInput* = Call_DeleteInput_773435(name: "deleteInput",
                                        meth: HttpMethod.HttpDelete,
                                        host: "medialive.amazonaws.com",
                                        route: "/prod/inputs/{inputId}",
                                        validator: validate_DeleteInput_773436,
                                        base: "/", url: url_DeleteInput_773437,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInputSecurityGroup_773463 = ref object of OpenApiRestCall_772597
proc url_UpdateInputSecurityGroup_773465(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "inputSecurityGroupId" in path,
        "`inputSecurityGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputSecurityGroups/"),
               (kind: VariableSegment, value: "inputSecurityGroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateInputSecurityGroup_773464(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update an Input Security Group's Whilelists.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputSecurityGroupId: JString (required)
  ##                       : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputSecurityGroupId` field"
  var valid_773466 = path.getOrDefault("inputSecurityGroupId")
  valid_773466 = validateParameter(valid_773466, JString, required = true,
                                 default = nil)
  if valid_773466 != nil:
    section.add "inputSecurityGroupId", valid_773466
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
  var valid_773467 = header.getOrDefault("X-Amz-Date")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-Date", valid_773467
  var valid_773468 = header.getOrDefault("X-Amz-Security-Token")
  valid_773468 = validateParameter(valid_773468, JString, required = false,
                                 default = nil)
  if valid_773468 != nil:
    section.add "X-Amz-Security-Token", valid_773468
  var valid_773469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773469 = validateParameter(valid_773469, JString, required = false,
                                 default = nil)
  if valid_773469 != nil:
    section.add "X-Amz-Content-Sha256", valid_773469
  var valid_773470 = header.getOrDefault("X-Amz-Algorithm")
  valid_773470 = validateParameter(valid_773470, JString, required = false,
                                 default = nil)
  if valid_773470 != nil:
    section.add "X-Amz-Algorithm", valid_773470
  var valid_773471 = header.getOrDefault("X-Amz-Signature")
  valid_773471 = validateParameter(valid_773471, JString, required = false,
                                 default = nil)
  if valid_773471 != nil:
    section.add "X-Amz-Signature", valid_773471
  var valid_773472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773472 = validateParameter(valid_773472, JString, required = false,
                                 default = nil)
  if valid_773472 != nil:
    section.add "X-Amz-SignedHeaders", valid_773472
  var valid_773473 = header.getOrDefault("X-Amz-Credential")
  valid_773473 = validateParameter(valid_773473, JString, required = false,
                                 default = nil)
  if valid_773473 != nil:
    section.add "X-Amz-Credential", valid_773473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773475: Call_UpdateInputSecurityGroup_773463; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update an Input Security Group's Whilelists.
  ## 
  let valid = call_773475.validator(path, query, header, formData, body)
  let scheme = call_773475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773475.url(scheme.get, call_773475.host, call_773475.base,
                         call_773475.route, valid.getOrDefault("path"))
  result = hook(call_773475, url, valid)

proc call*(call_773476: Call_UpdateInputSecurityGroup_773463;
          inputSecurityGroupId: string; body: JsonNode): Recallable =
  ## updateInputSecurityGroup
  ## Update an Input Security Group's Whilelists.
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_773477 = newJObject()
  var body_773478 = newJObject()
  add(path_773477, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  if body != nil:
    body_773478 = body
  result = call_773476.call(path_773477, nil, nil, nil, body_773478)

var updateInputSecurityGroup* = Call_UpdateInputSecurityGroup_773463(
    name: "updateInputSecurityGroup", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_UpdateInputSecurityGroup_773464, base: "/",
    url: url_UpdateInputSecurityGroup_773465, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInputSecurityGroup_773449 = ref object of OpenApiRestCall_772597
proc url_DescribeInputSecurityGroup_773451(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "inputSecurityGroupId" in path,
        "`inputSecurityGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputSecurityGroups/"),
               (kind: VariableSegment, value: "inputSecurityGroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeInputSecurityGroup_773450(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Produces a summary of an Input Security Group
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputSecurityGroupId: JString (required)
  ##                       : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputSecurityGroupId` field"
  var valid_773452 = path.getOrDefault("inputSecurityGroupId")
  valid_773452 = validateParameter(valid_773452, JString, required = true,
                                 default = nil)
  if valid_773452 != nil:
    section.add "inputSecurityGroupId", valid_773452
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
  var valid_773453 = header.getOrDefault("X-Amz-Date")
  valid_773453 = validateParameter(valid_773453, JString, required = false,
                                 default = nil)
  if valid_773453 != nil:
    section.add "X-Amz-Date", valid_773453
  var valid_773454 = header.getOrDefault("X-Amz-Security-Token")
  valid_773454 = validateParameter(valid_773454, JString, required = false,
                                 default = nil)
  if valid_773454 != nil:
    section.add "X-Amz-Security-Token", valid_773454
  var valid_773455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773455 = validateParameter(valid_773455, JString, required = false,
                                 default = nil)
  if valid_773455 != nil:
    section.add "X-Amz-Content-Sha256", valid_773455
  var valid_773456 = header.getOrDefault("X-Amz-Algorithm")
  valid_773456 = validateParameter(valid_773456, JString, required = false,
                                 default = nil)
  if valid_773456 != nil:
    section.add "X-Amz-Algorithm", valid_773456
  var valid_773457 = header.getOrDefault("X-Amz-Signature")
  valid_773457 = validateParameter(valid_773457, JString, required = false,
                                 default = nil)
  if valid_773457 != nil:
    section.add "X-Amz-Signature", valid_773457
  var valid_773458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773458 = validateParameter(valid_773458, JString, required = false,
                                 default = nil)
  if valid_773458 != nil:
    section.add "X-Amz-SignedHeaders", valid_773458
  var valid_773459 = header.getOrDefault("X-Amz-Credential")
  valid_773459 = validateParameter(valid_773459, JString, required = false,
                                 default = nil)
  if valid_773459 != nil:
    section.add "X-Amz-Credential", valid_773459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773460: Call_DescribeInputSecurityGroup_773449; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces a summary of an Input Security Group
  ## 
  let valid = call_773460.validator(path, query, header, formData, body)
  let scheme = call_773460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773460.url(scheme.get, call_773460.host, call_773460.base,
                         call_773460.route, valid.getOrDefault("path"))
  result = hook(call_773460, url, valid)

proc call*(call_773461: Call_DescribeInputSecurityGroup_773449;
          inputSecurityGroupId: string): Recallable =
  ## describeInputSecurityGroup
  ## Produces a summary of an Input Security Group
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  var path_773462 = newJObject()
  add(path_773462, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  result = call_773461.call(path_773462, nil, nil, nil, nil)

var describeInputSecurityGroup* = Call_DescribeInputSecurityGroup_773449(
    name: "describeInputSecurityGroup", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_DescribeInputSecurityGroup_773450, base: "/",
    url: url_DescribeInputSecurityGroup_773451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInputSecurityGroup_773479 = ref object of OpenApiRestCall_772597
proc url_DeleteInputSecurityGroup_773481(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "inputSecurityGroupId" in path,
        "`inputSecurityGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputSecurityGroups/"),
               (kind: VariableSegment, value: "inputSecurityGroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteInputSecurityGroup_773480(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an Input Security Group
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputSecurityGroupId: JString (required)
  ##                       : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputSecurityGroupId` field"
  var valid_773482 = path.getOrDefault("inputSecurityGroupId")
  valid_773482 = validateParameter(valid_773482, JString, required = true,
                                 default = nil)
  if valid_773482 != nil:
    section.add "inputSecurityGroupId", valid_773482
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
  var valid_773483 = header.getOrDefault("X-Amz-Date")
  valid_773483 = validateParameter(valid_773483, JString, required = false,
                                 default = nil)
  if valid_773483 != nil:
    section.add "X-Amz-Date", valid_773483
  var valid_773484 = header.getOrDefault("X-Amz-Security-Token")
  valid_773484 = validateParameter(valid_773484, JString, required = false,
                                 default = nil)
  if valid_773484 != nil:
    section.add "X-Amz-Security-Token", valid_773484
  var valid_773485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773485 = validateParameter(valid_773485, JString, required = false,
                                 default = nil)
  if valid_773485 != nil:
    section.add "X-Amz-Content-Sha256", valid_773485
  var valid_773486 = header.getOrDefault("X-Amz-Algorithm")
  valid_773486 = validateParameter(valid_773486, JString, required = false,
                                 default = nil)
  if valid_773486 != nil:
    section.add "X-Amz-Algorithm", valid_773486
  var valid_773487 = header.getOrDefault("X-Amz-Signature")
  valid_773487 = validateParameter(valid_773487, JString, required = false,
                                 default = nil)
  if valid_773487 != nil:
    section.add "X-Amz-Signature", valid_773487
  var valid_773488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773488 = validateParameter(valid_773488, JString, required = false,
                                 default = nil)
  if valid_773488 != nil:
    section.add "X-Amz-SignedHeaders", valid_773488
  var valid_773489 = header.getOrDefault("X-Amz-Credential")
  valid_773489 = validateParameter(valid_773489, JString, required = false,
                                 default = nil)
  if valid_773489 != nil:
    section.add "X-Amz-Credential", valid_773489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773490: Call_DeleteInputSecurityGroup_773479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Input Security Group
  ## 
  let valid = call_773490.validator(path, query, header, formData, body)
  let scheme = call_773490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773490.url(scheme.get, call_773490.host, call_773490.base,
                         call_773490.route, valid.getOrDefault("path"))
  result = hook(call_773490, url, valid)

proc call*(call_773491: Call_DeleteInputSecurityGroup_773479;
          inputSecurityGroupId: string): Recallable =
  ## deleteInputSecurityGroup
  ## Deletes an Input Security Group
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  var path_773492 = newJObject()
  add(path_773492, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  result = call_773491.call(path_773492, nil, nil, nil, nil)

var deleteInputSecurityGroup* = Call_DeleteInputSecurityGroup_773479(
    name: "deleteInputSecurityGroup", meth: HttpMethod.HttpDelete,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_DeleteInputSecurityGroup_773480, base: "/",
    url: url_DeleteInputSecurityGroup_773481, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateReservation_773507 = ref object of OpenApiRestCall_772597
proc url_UpdateReservation_773509(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "reservationId" in path, "`reservationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/reservations/"),
               (kind: VariableSegment, value: "reservationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateReservation_773508(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Update reservation.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   reservationId: JString (required)
  ##                : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `reservationId` field"
  var valid_773510 = path.getOrDefault("reservationId")
  valid_773510 = validateParameter(valid_773510, JString, required = true,
                                 default = nil)
  if valid_773510 != nil:
    section.add "reservationId", valid_773510
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
  var valid_773511 = header.getOrDefault("X-Amz-Date")
  valid_773511 = validateParameter(valid_773511, JString, required = false,
                                 default = nil)
  if valid_773511 != nil:
    section.add "X-Amz-Date", valid_773511
  var valid_773512 = header.getOrDefault("X-Amz-Security-Token")
  valid_773512 = validateParameter(valid_773512, JString, required = false,
                                 default = nil)
  if valid_773512 != nil:
    section.add "X-Amz-Security-Token", valid_773512
  var valid_773513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773513 = validateParameter(valid_773513, JString, required = false,
                                 default = nil)
  if valid_773513 != nil:
    section.add "X-Amz-Content-Sha256", valid_773513
  var valid_773514 = header.getOrDefault("X-Amz-Algorithm")
  valid_773514 = validateParameter(valid_773514, JString, required = false,
                                 default = nil)
  if valid_773514 != nil:
    section.add "X-Amz-Algorithm", valid_773514
  var valid_773515 = header.getOrDefault("X-Amz-Signature")
  valid_773515 = validateParameter(valid_773515, JString, required = false,
                                 default = nil)
  if valid_773515 != nil:
    section.add "X-Amz-Signature", valid_773515
  var valid_773516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773516 = validateParameter(valid_773516, JString, required = false,
                                 default = nil)
  if valid_773516 != nil:
    section.add "X-Amz-SignedHeaders", valid_773516
  var valid_773517 = header.getOrDefault("X-Amz-Credential")
  valid_773517 = validateParameter(valid_773517, JString, required = false,
                                 default = nil)
  if valid_773517 != nil:
    section.add "X-Amz-Credential", valid_773517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773519: Call_UpdateReservation_773507; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update reservation.
  ## 
  let valid = call_773519.validator(path, query, header, formData, body)
  let scheme = call_773519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773519.url(scheme.get, call_773519.host, call_773519.base,
                         call_773519.route, valid.getOrDefault("path"))
  result = hook(call_773519, url, valid)

proc call*(call_773520: Call_UpdateReservation_773507; reservationId: string;
          body: JsonNode): Recallable =
  ## updateReservation
  ## Update reservation.
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_773521 = newJObject()
  var body_773522 = newJObject()
  add(path_773521, "reservationId", newJString(reservationId))
  if body != nil:
    body_773522 = body
  result = call_773520.call(path_773521, nil, nil, nil, body_773522)

var updateReservation* = Call_UpdateReservation_773507(name: "updateReservation",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/reservations/{reservationId}",
    validator: validate_UpdateReservation_773508, base: "/",
    url: url_UpdateReservation_773509, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReservation_773493 = ref object of OpenApiRestCall_772597
proc url_DescribeReservation_773495(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "reservationId" in path, "`reservationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/reservations/"),
               (kind: VariableSegment, value: "reservationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeReservation_773494(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Get details for a reservation.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   reservationId: JString (required)
  ##                : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `reservationId` field"
  var valid_773496 = path.getOrDefault("reservationId")
  valid_773496 = validateParameter(valid_773496, JString, required = true,
                                 default = nil)
  if valid_773496 != nil:
    section.add "reservationId", valid_773496
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
  var valid_773497 = header.getOrDefault("X-Amz-Date")
  valid_773497 = validateParameter(valid_773497, JString, required = false,
                                 default = nil)
  if valid_773497 != nil:
    section.add "X-Amz-Date", valid_773497
  var valid_773498 = header.getOrDefault("X-Amz-Security-Token")
  valid_773498 = validateParameter(valid_773498, JString, required = false,
                                 default = nil)
  if valid_773498 != nil:
    section.add "X-Amz-Security-Token", valid_773498
  var valid_773499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773499 = validateParameter(valid_773499, JString, required = false,
                                 default = nil)
  if valid_773499 != nil:
    section.add "X-Amz-Content-Sha256", valid_773499
  var valid_773500 = header.getOrDefault("X-Amz-Algorithm")
  valid_773500 = validateParameter(valid_773500, JString, required = false,
                                 default = nil)
  if valid_773500 != nil:
    section.add "X-Amz-Algorithm", valid_773500
  var valid_773501 = header.getOrDefault("X-Amz-Signature")
  valid_773501 = validateParameter(valid_773501, JString, required = false,
                                 default = nil)
  if valid_773501 != nil:
    section.add "X-Amz-Signature", valid_773501
  var valid_773502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773502 = validateParameter(valid_773502, JString, required = false,
                                 default = nil)
  if valid_773502 != nil:
    section.add "X-Amz-SignedHeaders", valid_773502
  var valid_773503 = header.getOrDefault("X-Amz-Credential")
  valid_773503 = validateParameter(valid_773503, JString, required = false,
                                 default = nil)
  if valid_773503 != nil:
    section.add "X-Amz-Credential", valid_773503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773504: Call_DescribeReservation_773493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get details for a reservation.
  ## 
  let valid = call_773504.validator(path, query, header, formData, body)
  let scheme = call_773504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773504.url(scheme.get, call_773504.host, call_773504.base,
                         call_773504.route, valid.getOrDefault("path"))
  result = hook(call_773504, url, valid)

proc call*(call_773505: Call_DescribeReservation_773493; reservationId: string): Recallable =
  ## describeReservation
  ## Get details for a reservation.
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  var path_773506 = newJObject()
  add(path_773506, "reservationId", newJString(reservationId))
  result = call_773505.call(path_773506, nil, nil, nil, nil)

var describeReservation* = Call_DescribeReservation_773493(
    name: "describeReservation", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/reservations/{reservationId}",
    validator: validate_DescribeReservation_773494, base: "/",
    url: url_DescribeReservation_773495, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReservation_773523 = ref object of OpenApiRestCall_772597
proc url_DeleteReservation_773525(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "reservationId" in path, "`reservationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/reservations/"),
               (kind: VariableSegment, value: "reservationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteReservation_773524(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Delete an expired reservation.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   reservationId: JString (required)
  ##                : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `reservationId` field"
  var valid_773526 = path.getOrDefault("reservationId")
  valid_773526 = validateParameter(valid_773526, JString, required = true,
                                 default = nil)
  if valid_773526 != nil:
    section.add "reservationId", valid_773526
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
  var valid_773527 = header.getOrDefault("X-Amz-Date")
  valid_773527 = validateParameter(valid_773527, JString, required = false,
                                 default = nil)
  if valid_773527 != nil:
    section.add "X-Amz-Date", valid_773527
  var valid_773528 = header.getOrDefault("X-Amz-Security-Token")
  valid_773528 = validateParameter(valid_773528, JString, required = false,
                                 default = nil)
  if valid_773528 != nil:
    section.add "X-Amz-Security-Token", valid_773528
  var valid_773529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773529 = validateParameter(valid_773529, JString, required = false,
                                 default = nil)
  if valid_773529 != nil:
    section.add "X-Amz-Content-Sha256", valid_773529
  var valid_773530 = header.getOrDefault("X-Amz-Algorithm")
  valid_773530 = validateParameter(valid_773530, JString, required = false,
                                 default = nil)
  if valid_773530 != nil:
    section.add "X-Amz-Algorithm", valid_773530
  var valid_773531 = header.getOrDefault("X-Amz-Signature")
  valid_773531 = validateParameter(valid_773531, JString, required = false,
                                 default = nil)
  if valid_773531 != nil:
    section.add "X-Amz-Signature", valid_773531
  var valid_773532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773532 = validateParameter(valid_773532, JString, required = false,
                                 default = nil)
  if valid_773532 != nil:
    section.add "X-Amz-SignedHeaders", valid_773532
  var valid_773533 = header.getOrDefault("X-Amz-Credential")
  valid_773533 = validateParameter(valid_773533, JString, required = false,
                                 default = nil)
  if valid_773533 != nil:
    section.add "X-Amz-Credential", valid_773533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773534: Call_DeleteReservation_773523; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete an expired reservation.
  ## 
  let valid = call_773534.validator(path, query, header, formData, body)
  let scheme = call_773534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773534.url(scheme.get, call_773534.host, call_773534.base,
                         call_773534.route, valid.getOrDefault("path"))
  result = hook(call_773534, url, valid)

proc call*(call_773535: Call_DeleteReservation_773523; reservationId: string): Recallable =
  ## deleteReservation
  ## Delete an expired reservation.
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  var path_773536 = newJObject()
  add(path_773536, "reservationId", newJString(reservationId))
  result = call_773535.call(path_773536, nil, nil, nil, nil)

var deleteReservation* = Call_DeleteReservation_773523(name: "deleteReservation",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/reservations/{reservationId}",
    validator: validate_DeleteReservation_773524, base: "/",
    url: url_DeleteReservation_773525, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_773537 = ref object of OpenApiRestCall_772597
proc url_DeleteTags_773539(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/tags/"),
               (kind: VariableSegment, value: "resource-arn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteTags_773538(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes tags for a resource
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_773540 = path.getOrDefault("resource-arn")
  valid_773540 = validateParameter(valid_773540, JString, required = true,
                                 default = nil)
  if valid_773540 != nil:
    section.add "resource-arn", valid_773540
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : Placeholder documentation for __listOf__string
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_773541 = query.getOrDefault("tagKeys")
  valid_773541 = validateParameter(valid_773541, JArray, required = true, default = nil)
  if valid_773541 != nil:
    section.add "tagKeys", valid_773541
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
  var valid_773542 = header.getOrDefault("X-Amz-Date")
  valid_773542 = validateParameter(valid_773542, JString, required = false,
                                 default = nil)
  if valid_773542 != nil:
    section.add "X-Amz-Date", valid_773542
  var valid_773543 = header.getOrDefault("X-Amz-Security-Token")
  valid_773543 = validateParameter(valid_773543, JString, required = false,
                                 default = nil)
  if valid_773543 != nil:
    section.add "X-Amz-Security-Token", valid_773543
  var valid_773544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773544 = validateParameter(valid_773544, JString, required = false,
                                 default = nil)
  if valid_773544 != nil:
    section.add "X-Amz-Content-Sha256", valid_773544
  var valid_773545 = header.getOrDefault("X-Amz-Algorithm")
  valid_773545 = validateParameter(valid_773545, JString, required = false,
                                 default = nil)
  if valid_773545 != nil:
    section.add "X-Amz-Algorithm", valid_773545
  var valid_773546 = header.getOrDefault("X-Amz-Signature")
  valid_773546 = validateParameter(valid_773546, JString, required = false,
                                 default = nil)
  if valid_773546 != nil:
    section.add "X-Amz-Signature", valid_773546
  var valid_773547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773547 = validateParameter(valid_773547, JString, required = false,
                                 default = nil)
  if valid_773547 != nil:
    section.add "X-Amz-SignedHeaders", valid_773547
  var valid_773548 = header.getOrDefault("X-Amz-Credential")
  valid_773548 = validateParameter(valid_773548, JString, required = false,
                                 default = nil)
  if valid_773548 != nil:
    section.add "X-Amz-Credential", valid_773548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773549: Call_DeleteTags_773537; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags for a resource
  ## 
  let valid = call_773549.validator(path, query, header, formData, body)
  let scheme = call_773549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773549.url(scheme.get, call_773549.host, call_773549.base,
                         call_773549.route, valid.getOrDefault("path"))
  result = hook(call_773549, url, valid)

proc call*(call_773550: Call_DeleteTags_773537; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## deleteTags
  ## Removes tags for a resource
  ##   tagKeys: JArray (required)
  ##          : Placeholder documentation for __listOf__string
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  var path_773551 = newJObject()
  var query_773552 = newJObject()
  if tagKeys != nil:
    query_773552.add "tagKeys", tagKeys
  add(path_773551, "resource-arn", newJString(resourceArn))
  result = call_773550.call(path_773551, query_773552, nil, nil, nil)

var deleteTags* = Call_DeleteTags_773537(name: "deleteTags",
                                      meth: HttpMethod.HttpDelete,
                                      host: "medialive.amazonaws.com", route: "/prod/tags/{resource-arn}#tagKeys",
                                      validator: validate_DeleteTags_773538,
                                      base: "/", url: url_DeleteTags_773539,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOffering_773553 = ref object of OpenApiRestCall_772597
proc url_DescribeOffering_773555(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "offeringId" in path, "`offeringId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/offerings/"),
               (kind: VariableSegment, value: "offeringId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeOffering_773554(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Get details for an offering.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   offeringId: JString (required)
  ##             : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `offeringId` field"
  var valid_773556 = path.getOrDefault("offeringId")
  valid_773556 = validateParameter(valid_773556, JString, required = true,
                                 default = nil)
  if valid_773556 != nil:
    section.add "offeringId", valid_773556
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
  var valid_773557 = header.getOrDefault("X-Amz-Date")
  valid_773557 = validateParameter(valid_773557, JString, required = false,
                                 default = nil)
  if valid_773557 != nil:
    section.add "X-Amz-Date", valid_773557
  var valid_773558 = header.getOrDefault("X-Amz-Security-Token")
  valid_773558 = validateParameter(valid_773558, JString, required = false,
                                 default = nil)
  if valid_773558 != nil:
    section.add "X-Amz-Security-Token", valid_773558
  var valid_773559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773559 = validateParameter(valid_773559, JString, required = false,
                                 default = nil)
  if valid_773559 != nil:
    section.add "X-Amz-Content-Sha256", valid_773559
  var valid_773560 = header.getOrDefault("X-Amz-Algorithm")
  valid_773560 = validateParameter(valid_773560, JString, required = false,
                                 default = nil)
  if valid_773560 != nil:
    section.add "X-Amz-Algorithm", valid_773560
  var valid_773561 = header.getOrDefault("X-Amz-Signature")
  valid_773561 = validateParameter(valid_773561, JString, required = false,
                                 default = nil)
  if valid_773561 != nil:
    section.add "X-Amz-Signature", valid_773561
  var valid_773562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773562 = validateParameter(valid_773562, JString, required = false,
                                 default = nil)
  if valid_773562 != nil:
    section.add "X-Amz-SignedHeaders", valid_773562
  var valid_773563 = header.getOrDefault("X-Amz-Credential")
  valid_773563 = validateParameter(valid_773563, JString, required = false,
                                 default = nil)
  if valid_773563 != nil:
    section.add "X-Amz-Credential", valid_773563
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773564: Call_DescribeOffering_773553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get details for an offering.
  ## 
  let valid = call_773564.validator(path, query, header, formData, body)
  let scheme = call_773564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773564.url(scheme.get, call_773564.host, call_773564.base,
                         call_773564.route, valid.getOrDefault("path"))
  result = hook(call_773564, url, valid)

proc call*(call_773565: Call_DescribeOffering_773553; offeringId: string): Recallable =
  ## describeOffering
  ## Get details for an offering.
  ##   offeringId: string (required)
  ##             : Placeholder documentation for __string
  var path_773566 = newJObject()
  add(path_773566, "offeringId", newJString(offeringId))
  result = call_773565.call(path_773566, nil, nil, nil, nil)

var describeOffering* = Call_DescribeOffering_773553(name: "describeOffering",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/offerings/{offeringId}", validator: validate_DescribeOffering_773554,
    base: "/", url: url_DescribeOffering_773555,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferings_773567 = ref object of OpenApiRestCall_772597
proc url_ListOfferings_773569(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListOfferings_773568(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## List offerings available for purchase.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   codec: JString
  ##        : Placeholder documentation for __string
  ##   channelClass: JString
  ##               : Placeholder documentation for __string
  ##   channelConfiguration: JString
  ##                       : Placeholder documentation for __string
  ##   resolution: JString
  ##             : Placeholder documentation for __string
  ##   maximumFramerate: JString
  ##                   : Placeholder documentation for __string
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   videoQuality: JString
  ##               : Placeholder documentation for __string
  ##   maximumBitrate: JString
  ##                 : Placeholder documentation for __string
  ##   specialFeature: JString
  ##                 : Placeholder documentation for __string
  ##   resourceType: JString
  ##               : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_773570 = query.getOrDefault("codec")
  valid_773570 = validateParameter(valid_773570, JString, required = false,
                                 default = nil)
  if valid_773570 != nil:
    section.add "codec", valid_773570
  var valid_773571 = query.getOrDefault("channelClass")
  valid_773571 = validateParameter(valid_773571, JString, required = false,
                                 default = nil)
  if valid_773571 != nil:
    section.add "channelClass", valid_773571
  var valid_773572 = query.getOrDefault("channelConfiguration")
  valid_773572 = validateParameter(valid_773572, JString, required = false,
                                 default = nil)
  if valid_773572 != nil:
    section.add "channelConfiguration", valid_773572
  var valid_773573 = query.getOrDefault("resolution")
  valid_773573 = validateParameter(valid_773573, JString, required = false,
                                 default = nil)
  if valid_773573 != nil:
    section.add "resolution", valid_773573
  var valid_773574 = query.getOrDefault("maximumFramerate")
  valid_773574 = validateParameter(valid_773574, JString, required = false,
                                 default = nil)
  if valid_773574 != nil:
    section.add "maximumFramerate", valid_773574
  var valid_773575 = query.getOrDefault("NextToken")
  valid_773575 = validateParameter(valid_773575, JString, required = false,
                                 default = nil)
  if valid_773575 != nil:
    section.add "NextToken", valid_773575
  var valid_773576 = query.getOrDefault("maxResults")
  valid_773576 = validateParameter(valid_773576, JInt, required = false, default = nil)
  if valid_773576 != nil:
    section.add "maxResults", valid_773576
  var valid_773577 = query.getOrDefault("nextToken")
  valid_773577 = validateParameter(valid_773577, JString, required = false,
                                 default = nil)
  if valid_773577 != nil:
    section.add "nextToken", valid_773577
  var valid_773578 = query.getOrDefault("videoQuality")
  valid_773578 = validateParameter(valid_773578, JString, required = false,
                                 default = nil)
  if valid_773578 != nil:
    section.add "videoQuality", valid_773578
  var valid_773579 = query.getOrDefault("maximumBitrate")
  valid_773579 = validateParameter(valid_773579, JString, required = false,
                                 default = nil)
  if valid_773579 != nil:
    section.add "maximumBitrate", valid_773579
  var valid_773580 = query.getOrDefault("specialFeature")
  valid_773580 = validateParameter(valid_773580, JString, required = false,
                                 default = nil)
  if valid_773580 != nil:
    section.add "specialFeature", valid_773580
  var valid_773581 = query.getOrDefault("resourceType")
  valid_773581 = validateParameter(valid_773581, JString, required = false,
                                 default = nil)
  if valid_773581 != nil:
    section.add "resourceType", valid_773581
  var valid_773582 = query.getOrDefault("MaxResults")
  valid_773582 = validateParameter(valid_773582, JString, required = false,
                                 default = nil)
  if valid_773582 != nil:
    section.add "MaxResults", valid_773582
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
  var valid_773583 = header.getOrDefault("X-Amz-Date")
  valid_773583 = validateParameter(valid_773583, JString, required = false,
                                 default = nil)
  if valid_773583 != nil:
    section.add "X-Amz-Date", valid_773583
  var valid_773584 = header.getOrDefault("X-Amz-Security-Token")
  valid_773584 = validateParameter(valid_773584, JString, required = false,
                                 default = nil)
  if valid_773584 != nil:
    section.add "X-Amz-Security-Token", valid_773584
  var valid_773585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773585 = validateParameter(valid_773585, JString, required = false,
                                 default = nil)
  if valid_773585 != nil:
    section.add "X-Amz-Content-Sha256", valid_773585
  var valid_773586 = header.getOrDefault("X-Amz-Algorithm")
  valid_773586 = validateParameter(valid_773586, JString, required = false,
                                 default = nil)
  if valid_773586 != nil:
    section.add "X-Amz-Algorithm", valid_773586
  var valid_773587 = header.getOrDefault("X-Amz-Signature")
  valid_773587 = validateParameter(valid_773587, JString, required = false,
                                 default = nil)
  if valid_773587 != nil:
    section.add "X-Amz-Signature", valid_773587
  var valid_773588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773588 = validateParameter(valid_773588, JString, required = false,
                                 default = nil)
  if valid_773588 != nil:
    section.add "X-Amz-SignedHeaders", valid_773588
  var valid_773589 = header.getOrDefault("X-Amz-Credential")
  valid_773589 = validateParameter(valid_773589, JString, required = false,
                                 default = nil)
  if valid_773589 != nil:
    section.add "X-Amz-Credential", valid_773589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773590: Call_ListOfferings_773567; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List offerings available for purchase.
  ## 
  let valid = call_773590.validator(path, query, header, formData, body)
  let scheme = call_773590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773590.url(scheme.get, call_773590.host, call_773590.base,
                         call_773590.route, valid.getOrDefault("path"))
  result = hook(call_773590, url, valid)

proc call*(call_773591: Call_ListOfferings_773567; codec: string = "";
          channelClass: string = ""; channelConfiguration: string = "";
          resolution: string = ""; maximumFramerate: string = "";
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          videoQuality: string = ""; maximumBitrate: string = "";
          specialFeature: string = ""; resourceType: string = "";
          MaxResults: string = ""): Recallable =
  ## listOfferings
  ## List offerings available for purchase.
  ##   codec: string
  ##        : Placeholder documentation for __string
  ##   channelClass: string
  ##               : Placeholder documentation for __string
  ##   channelConfiguration: string
  ##                       : Placeholder documentation for __string
  ##   resolution: string
  ##             : Placeholder documentation for __string
  ##   maximumFramerate: string
  ##                   : Placeholder documentation for __string
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   videoQuality: string
  ##               : Placeholder documentation for __string
  ##   maximumBitrate: string
  ##                 : Placeholder documentation for __string
  ##   specialFeature: string
  ##                 : Placeholder documentation for __string
  ##   resourceType: string
  ##               : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773592 = newJObject()
  add(query_773592, "codec", newJString(codec))
  add(query_773592, "channelClass", newJString(channelClass))
  add(query_773592, "channelConfiguration", newJString(channelConfiguration))
  add(query_773592, "resolution", newJString(resolution))
  add(query_773592, "maximumFramerate", newJString(maximumFramerate))
  add(query_773592, "NextToken", newJString(NextToken))
  add(query_773592, "maxResults", newJInt(maxResults))
  add(query_773592, "nextToken", newJString(nextToken))
  add(query_773592, "videoQuality", newJString(videoQuality))
  add(query_773592, "maximumBitrate", newJString(maximumBitrate))
  add(query_773592, "specialFeature", newJString(specialFeature))
  add(query_773592, "resourceType", newJString(resourceType))
  add(query_773592, "MaxResults", newJString(MaxResults))
  result = call_773591.call(nil, query_773592, nil, nil, nil)

var listOfferings* = Call_ListOfferings_773567(name: "listOfferings",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/offerings", validator: validate_ListOfferings_773568, base: "/",
    url: url_ListOfferings_773569, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReservations_773593 = ref object of OpenApiRestCall_772597
proc url_ListReservations_773595(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListReservations_773594(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## List purchased reservations.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   codec: JString
  ##        : Placeholder documentation for __string
  ##   channelClass: JString
  ##               : Placeholder documentation for __string
  ##   resolution: JString
  ##             : Placeholder documentation for __string
  ##   maximumFramerate: JString
  ##                   : Placeholder documentation for __string
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   videoQuality: JString
  ##               : Placeholder documentation for __string
  ##   maximumBitrate: JString
  ##                 : Placeholder documentation for __string
  ##   specialFeature: JString
  ##                 : Placeholder documentation for __string
  ##   resourceType: JString
  ##               : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_773596 = query.getOrDefault("codec")
  valid_773596 = validateParameter(valid_773596, JString, required = false,
                                 default = nil)
  if valid_773596 != nil:
    section.add "codec", valid_773596
  var valid_773597 = query.getOrDefault("channelClass")
  valid_773597 = validateParameter(valid_773597, JString, required = false,
                                 default = nil)
  if valid_773597 != nil:
    section.add "channelClass", valid_773597
  var valid_773598 = query.getOrDefault("resolution")
  valid_773598 = validateParameter(valid_773598, JString, required = false,
                                 default = nil)
  if valid_773598 != nil:
    section.add "resolution", valid_773598
  var valid_773599 = query.getOrDefault("maximumFramerate")
  valid_773599 = validateParameter(valid_773599, JString, required = false,
                                 default = nil)
  if valid_773599 != nil:
    section.add "maximumFramerate", valid_773599
  var valid_773600 = query.getOrDefault("NextToken")
  valid_773600 = validateParameter(valid_773600, JString, required = false,
                                 default = nil)
  if valid_773600 != nil:
    section.add "NextToken", valid_773600
  var valid_773601 = query.getOrDefault("maxResults")
  valid_773601 = validateParameter(valid_773601, JInt, required = false, default = nil)
  if valid_773601 != nil:
    section.add "maxResults", valid_773601
  var valid_773602 = query.getOrDefault("nextToken")
  valid_773602 = validateParameter(valid_773602, JString, required = false,
                                 default = nil)
  if valid_773602 != nil:
    section.add "nextToken", valid_773602
  var valid_773603 = query.getOrDefault("videoQuality")
  valid_773603 = validateParameter(valid_773603, JString, required = false,
                                 default = nil)
  if valid_773603 != nil:
    section.add "videoQuality", valid_773603
  var valid_773604 = query.getOrDefault("maximumBitrate")
  valid_773604 = validateParameter(valid_773604, JString, required = false,
                                 default = nil)
  if valid_773604 != nil:
    section.add "maximumBitrate", valid_773604
  var valid_773605 = query.getOrDefault("specialFeature")
  valid_773605 = validateParameter(valid_773605, JString, required = false,
                                 default = nil)
  if valid_773605 != nil:
    section.add "specialFeature", valid_773605
  var valid_773606 = query.getOrDefault("resourceType")
  valid_773606 = validateParameter(valid_773606, JString, required = false,
                                 default = nil)
  if valid_773606 != nil:
    section.add "resourceType", valid_773606
  var valid_773607 = query.getOrDefault("MaxResults")
  valid_773607 = validateParameter(valid_773607, JString, required = false,
                                 default = nil)
  if valid_773607 != nil:
    section.add "MaxResults", valid_773607
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
  var valid_773608 = header.getOrDefault("X-Amz-Date")
  valid_773608 = validateParameter(valid_773608, JString, required = false,
                                 default = nil)
  if valid_773608 != nil:
    section.add "X-Amz-Date", valid_773608
  var valid_773609 = header.getOrDefault("X-Amz-Security-Token")
  valid_773609 = validateParameter(valid_773609, JString, required = false,
                                 default = nil)
  if valid_773609 != nil:
    section.add "X-Amz-Security-Token", valid_773609
  var valid_773610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773610 = validateParameter(valid_773610, JString, required = false,
                                 default = nil)
  if valid_773610 != nil:
    section.add "X-Amz-Content-Sha256", valid_773610
  var valid_773611 = header.getOrDefault("X-Amz-Algorithm")
  valid_773611 = validateParameter(valid_773611, JString, required = false,
                                 default = nil)
  if valid_773611 != nil:
    section.add "X-Amz-Algorithm", valid_773611
  var valid_773612 = header.getOrDefault("X-Amz-Signature")
  valid_773612 = validateParameter(valid_773612, JString, required = false,
                                 default = nil)
  if valid_773612 != nil:
    section.add "X-Amz-Signature", valid_773612
  var valid_773613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773613 = validateParameter(valid_773613, JString, required = false,
                                 default = nil)
  if valid_773613 != nil:
    section.add "X-Amz-SignedHeaders", valid_773613
  var valid_773614 = header.getOrDefault("X-Amz-Credential")
  valid_773614 = validateParameter(valid_773614, JString, required = false,
                                 default = nil)
  if valid_773614 != nil:
    section.add "X-Amz-Credential", valid_773614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773615: Call_ListReservations_773593; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List purchased reservations.
  ## 
  let valid = call_773615.validator(path, query, header, formData, body)
  let scheme = call_773615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773615.url(scheme.get, call_773615.host, call_773615.base,
                         call_773615.route, valid.getOrDefault("path"))
  result = hook(call_773615, url, valid)

proc call*(call_773616: Call_ListReservations_773593; codec: string = "";
          channelClass: string = ""; resolution: string = "";
          maximumFramerate: string = ""; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; videoQuality: string = "";
          maximumBitrate: string = ""; specialFeature: string = "";
          resourceType: string = ""; MaxResults: string = ""): Recallable =
  ## listReservations
  ## List purchased reservations.
  ##   codec: string
  ##        : Placeholder documentation for __string
  ##   channelClass: string
  ##               : Placeholder documentation for __string
  ##   resolution: string
  ##             : Placeholder documentation for __string
  ##   maximumFramerate: string
  ##                   : Placeholder documentation for __string
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   videoQuality: string
  ##               : Placeholder documentation for __string
  ##   maximumBitrate: string
  ##                 : Placeholder documentation for __string
  ##   specialFeature: string
  ##                 : Placeholder documentation for __string
  ##   resourceType: string
  ##               : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773617 = newJObject()
  add(query_773617, "codec", newJString(codec))
  add(query_773617, "channelClass", newJString(channelClass))
  add(query_773617, "resolution", newJString(resolution))
  add(query_773617, "maximumFramerate", newJString(maximumFramerate))
  add(query_773617, "NextToken", newJString(NextToken))
  add(query_773617, "maxResults", newJInt(maxResults))
  add(query_773617, "nextToken", newJString(nextToken))
  add(query_773617, "videoQuality", newJString(videoQuality))
  add(query_773617, "maximumBitrate", newJString(maximumBitrate))
  add(query_773617, "specialFeature", newJString(specialFeature))
  add(query_773617, "resourceType", newJString(resourceType))
  add(query_773617, "MaxResults", newJString(MaxResults))
  result = call_773616.call(nil, query_773617, nil, nil, nil)

var listReservations* = Call_ListReservations_773593(name: "listReservations",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/reservations", validator: validate_ListReservations_773594,
    base: "/", url: url_ListReservations_773595,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseOffering_773618 = ref object of OpenApiRestCall_772597
proc url_PurchaseOffering_773620(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "offeringId" in path, "`offeringId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/offerings/"),
               (kind: VariableSegment, value: "offeringId"),
               (kind: ConstantSegment, value: "/purchase")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PurchaseOffering_773619(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Purchase an offering and create a reservation.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   offeringId: JString (required)
  ##             : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `offeringId` field"
  var valid_773621 = path.getOrDefault("offeringId")
  valid_773621 = validateParameter(valid_773621, JString, required = true,
                                 default = nil)
  if valid_773621 != nil:
    section.add "offeringId", valid_773621
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
  var valid_773622 = header.getOrDefault("X-Amz-Date")
  valid_773622 = validateParameter(valid_773622, JString, required = false,
                                 default = nil)
  if valid_773622 != nil:
    section.add "X-Amz-Date", valid_773622
  var valid_773623 = header.getOrDefault("X-Amz-Security-Token")
  valid_773623 = validateParameter(valid_773623, JString, required = false,
                                 default = nil)
  if valid_773623 != nil:
    section.add "X-Amz-Security-Token", valid_773623
  var valid_773624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773624 = validateParameter(valid_773624, JString, required = false,
                                 default = nil)
  if valid_773624 != nil:
    section.add "X-Amz-Content-Sha256", valid_773624
  var valid_773625 = header.getOrDefault("X-Amz-Algorithm")
  valid_773625 = validateParameter(valid_773625, JString, required = false,
                                 default = nil)
  if valid_773625 != nil:
    section.add "X-Amz-Algorithm", valid_773625
  var valid_773626 = header.getOrDefault("X-Amz-Signature")
  valid_773626 = validateParameter(valid_773626, JString, required = false,
                                 default = nil)
  if valid_773626 != nil:
    section.add "X-Amz-Signature", valid_773626
  var valid_773627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773627 = validateParameter(valid_773627, JString, required = false,
                                 default = nil)
  if valid_773627 != nil:
    section.add "X-Amz-SignedHeaders", valid_773627
  var valid_773628 = header.getOrDefault("X-Amz-Credential")
  valid_773628 = validateParameter(valid_773628, JString, required = false,
                                 default = nil)
  if valid_773628 != nil:
    section.add "X-Amz-Credential", valid_773628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773630: Call_PurchaseOffering_773618; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Purchase an offering and create a reservation.
  ## 
  let valid = call_773630.validator(path, query, header, formData, body)
  let scheme = call_773630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773630.url(scheme.get, call_773630.host, call_773630.base,
                         call_773630.route, valid.getOrDefault("path"))
  result = hook(call_773630, url, valid)

proc call*(call_773631: Call_PurchaseOffering_773618; offeringId: string;
          body: JsonNode): Recallable =
  ## purchaseOffering
  ## Purchase an offering and create a reservation.
  ##   offeringId: string (required)
  ##             : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_773632 = newJObject()
  var body_773633 = newJObject()
  add(path_773632, "offeringId", newJString(offeringId))
  if body != nil:
    body_773633 = body
  result = call_773631.call(path_773632, nil, nil, nil, body_773633)

var purchaseOffering* = Call_PurchaseOffering_773618(name: "purchaseOffering",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/offerings/{offeringId}/purchase",
    validator: validate_PurchaseOffering_773619, base: "/",
    url: url_PurchaseOffering_773620, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartChannel_773634 = ref object of OpenApiRestCall_772597
proc url_StartChannel_773636(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId"),
               (kind: ConstantSegment, value: "/start")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_StartChannel_773635(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts an existing channel
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_773637 = path.getOrDefault("channelId")
  valid_773637 = validateParameter(valid_773637, JString, required = true,
                                 default = nil)
  if valid_773637 != nil:
    section.add "channelId", valid_773637
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
  var valid_773638 = header.getOrDefault("X-Amz-Date")
  valid_773638 = validateParameter(valid_773638, JString, required = false,
                                 default = nil)
  if valid_773638 != nil:
    section.add "X-Amz-Date", valid_773638
  var valid_773639 = header.getOrDefault("X-Amz-Security-Token")
  valid_773639 = validateParameter(valid_773639, JString, required = false,
                                 default = nil)
  if valid_773639 != nil:
    section.add "X-Amz-Security-Token", valid_773639
  var valid_773640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773640 = validateParameter(valid_773640, JString, required = false,
                                 default = nil)
  if valid_773640 != nil:
    section.add "X-Amz-Content-Sha256", valid_773640
  var valid_773641 = header.getOrDefault("X-Amz-Algorithm")
  valid_773641 = validateParameter(valid_773641, JString, required = false,
                                 default = nil)
  if valid_773641 != nil:
    section.add "X-Amz-Algorithm", valid_773641
  var valid_773642 = header.getOrDefault("X-Amz-Signature")
  valid_773642 = validateParameter(valid_773642, JString, required = false,
                                 default = nil)
  if valid_773642 != nil:
    section.add "X-Amz-Signature", valid_773642
  var valid_773643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773643 = validateParameter(valid_773643, JString, required = false,
                                 default = nil)
  if valid_773643 != nil:
    section.add "X-Amz-SignedHeaders", valid_773643
  var valid_773644 = header.getOrDefault("X-Amz-Credential")
  valid_773644 = validateParameter(valid_773644, JString, required = false,
                                 default = nil)
  if valid_773644 != nil:
    section.add "X-Amz-Credential", valid_773644
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773645: Call_StartChannel_773634; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an existing channel
  ## 
  let valid = call_773645.validator(path, query, header, formData, body)
  let scheme = call_773645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773645.url(scheme.get, call_773645.host, call_773645.base,
                         call_773645.route, valid.getOrDefault("path"))
  result = hook(call_773645, url, valid)

proc call*(call_773646: Call_StartChannel_773634; channelId: string): Recallable =
  ## startChannel
  ## Starts an existing channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_773647 = newJObject()
  add(path_773647, "channelId", newJString(channelId))
  result = call_773646.call(path_773647, nil, nil, nil, nil)

var startChannel* = Call_StartChannel_773634(name: "startChannel",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/start", validator: validate_StartChannel_773635,
    base: "/", url: url_StartChannel_773636, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopChannel_773648 = ref object of OpenApiRestCall_772597
proc url_StopChannel_773650(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId"),
               (kind: ConstantSegment, value: "/stop")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_StopChannel_773649(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Stops a running channel
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_773651 = path.getOrDefault("channelId")
  valid_773651 = validateParameter(valid_773651, JString, required = true,
                                 default = nil)
  if valid_773651 != nil:
    section.add "channelId", valid_773651
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
  var valid_773652 = header.getOrDefault("X-Amz-Date")
  valid_773652 = validateParameter(valid_773652, JString, required = false,
                                 default = nil)
  if valid_773652 != nil:
    section.add "X-Amz-Date", valid_773652
  var valid_773653 = header.getOrDefault("X-Amz-Security-Token")
  valid_773653 = validateParameter(valid_773653, JString, required = false,
                                 default = nil)
  if valid_773653 != nil:
    section.add "X-Amz-Security-Token", valid_773653
  var valid_773654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773654 = validateParameter(valid_773654, JString, required = false,
                                 default = nil)
  if valid_773654 != nil:
    section.add "X-Amz-Content-Sha256", valid_773654
  var valid_773655 = header.getOrDefault("X-Amz-Algorithm")
  valid_773655 = validateParameter(valid_773655, JString, required = false,
                                 default = nil)
  if valid_773655 != nil:
    section.add "X-Amz-Algorithm", valid_773655
  var valid_773656 = header.getOrDefault("X-Amz-Signature")
  valid_773656 = validateParameter(valid_773656, JString, required = false,
                                 default = nil)
  if valid_773656 != nil:
    section.add "X-Amz-Signature", valid_773656
  var valid_773657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773657 = validateParameter(valid_773657, JString, required = false,
                                 default = nil)
  if valid_773657 != nil:
    section.add "X-Amz-SignedHeaders", valid_773657
  var valid_773658 = header.getOrDefault("X-Amz-Credential")
  valid_773658 = validateParameter(valid_773658, JString, required = false,
                                 default = nil)
  if valid_773658 != nil:
    section.add "X-Amz-Credential", valid_773658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773659: Call_StopChannel_773648; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running channel
  ## 
  let valid = call_773659.validator(path, query, header, formData, body)
  let scheme = call_773659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773659.url(scheme.get, call_773659.host, call_773659.base,
                         call_773659.route, valid.getOrDefault("path"))
  result = hook(call_773659, url, valid)

proc call*(call_773660: Call_StopChannel_773648; channelId: string): Recallable =
  ## stopChannel
  ## Stops a running channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_773661 = newJObject()
  add(path_773661, "channelId", newJString(channelId))
  result = call_773660.call(path_773661, nil, nil, nil, nil)

var stopChannel* = Call_StopChannel_773648(name: "stopChannel",
                                        meth: HttpMethod.HttpPost,
                                        host: "medialive.amazonaws.com", route: "/prod/channels/{channelId}/stop",
                                        validator: validate_StopChannel_773649,
                                        base: "/", url: url_StopChannel_773650,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannelClass_773662 = ref object of OpenApiRestCall_772597
proc url_UpdateChannelClass_773664(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId"),
               (kind: ConstantSegment, value: "/channelClass")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateChannelClass_773663(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Changes the class of the channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_773665 = path.getOrDefault("channelId")
  valid_773665 = validateParameter(valid_773665, JString, required = true,
                                 default = nil)
  if valid_773665 != nil:
    section.add "channelId", valid_773665
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
  var valid_773666 = header.getOrDefault("X-Amz-Date")
  valid_773666 = validateParameter(valid_773666, JString, required = false,
                                 default = nil)
  if valid_773666 != nil:
    section.add "X-Amz-Date", valid_773666
  var valid_773667 = header.getOrDefault("X-Amz-Security-Token")
  valid_773667 = validateParameter(valid_773667, JString, required = false,
                                 default = nil)
  if valid_773667 != nil:
    section.add "X-Amz-Security-Token", valid_773667
  var valid_773668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773668 = validateParameter(valid_773668, JString, required = false,
                                 default = nil)
  if valid_773668 != nil:
    section.add "X-Amz-Content-Sha256", valid_773668
  var valid_773669 = header.getOrDefault("X-Amz-Algorithm")
  valid_773669 = validateParameter(valid_773669, JString, required = false,
                                 default = nil)
  if valid_773669 != nil:
    section.add "X-Amz-Algorithm", valid_773669
  var valid_773670 = header.getOrDefault("X-Amz-Signature")
  valid_773670 = validateParameter(valid_773670, JString, required = false,
                                 default = nil)
  if valid_773670 != nil:
    section.add "X-Amz-Signature", valid_773670
  var valid_773671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773671 = validateParameter(valid_773671, JString, required = false,
                                 default = nil)
  if valid_773671 != nil:
    section.add "X-Amz-SignedHeaders", valid_773671
  var valid_773672 = header.getOrDefault("X-Amz-Credential")
  valid_773672 = validateParameter(valid_773672, JString, required = false,
                                 default = nil)
  if valid_773672 != nil:
    section.add "X-Amz-Credential", valid_773672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773674: Call_UpdateChannelClass_773662; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the class of the channel.
  ## 
  let valid = call_773674.validator(path, query, header, formData, body)
  let scheme = call_773674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773674.url(scheme.get, call_773674.host, call_773674.base,
                         call_773674.route, valid.getOrDefault("path"))
  result = hook(call_773674, url, valid)

proc call*(call_773675: Call_UpdateChannelClass_773662; channelId: string;
          body: JsonNode): Recallable =
  ## updateChannelClass
  ## Changes the class of the channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_773676 = newJObject()
  var body_773677 = newJObject()
  add(path_773676, "channelId", newJString(channelId))
  if body != nil:
    body_773677 = body
  result = call_773675.call(path_773676, nil, nil, nil, body_773677)

var updateChannelClass* = Call_UpdateChannelClass_773662(
    name: "updateChannelClass", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/channelClass",
    validator: validate_UpdateChannelClass_773663, base: "/",
    url: url_UpdateChannelClass_773664, schemes: {Scheme.Https, Scheme.Http})
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
