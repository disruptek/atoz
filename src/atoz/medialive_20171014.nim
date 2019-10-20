
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchUpdateSchedule_592978 = ref object of OpenApiRestCall_592364
proc url_BatchUpdateSchedule_592980(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId"),
               (kind: ConstantSegment, value: "/schedule")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_BatchUpdateSchedule_592979(path: JsonNode; query: JsonNode;
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
  var valid_592981 = path.getOrDefault("channelId")
  valid_592981 = validateParameter(valid_592981, JString, required = true,
                                 default = nil)
  if valid_592981 != nil:
    section.add "channelId", valid_592981
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
  var valid_592982 = header.getOrDefault("X-Amz-Signature")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Signature", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Content-Sha256", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-Date")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Date", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-Credential")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Credential", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-Security-Token")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-Security-Token", valid_592986
  var valid_592987 = header.getOrDefault("X-Amz-Algorithm")
  valid_592987 = validateParameter(valid_592987, JString, required = false,
                                 default = nil)
  if valid_592987 != nil:
    section.add "X-Amz-Algorithm", valid_592987
  var valid_592988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592988 = validateParameter(valid_592988, JString, required = false,
                                 default = nil)
  if valid_592988 != nil:
    section.add "X-Amz-SignedHeaders", valid_592988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592990: Call_BatchUpdateSchedule_592978; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update a channel schedule
  ## 
  let valid = call_592990.validator(path, query, header, formData, body)
  let scheme = call_592990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592990.url(scheme.get, call_592990.host, call_592990.base,
                         call_592990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592990, url, valid)

proc call*(call_592991: Call_BatchUpdateSchedule_592978; channelId: string;
          body: JsonNode): Recallable =
  ## batchUpdateSchedule
  ## Update a channel schedule
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_592992 = newJObject()
  var body_592993 = newJObject()
  add(path_592992, "channelId", newJString(channelId))
  if body != nil:
    body_592993 = body
  result = call_592991.call(path_592992, nil, nil, nil, body_592993)

var batchUpdateSchedule* = Call_BatchUpdateSchedule_592978(
    name: "batchUpdateSchedule", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com", route: "/prod/channels/{channelId}/schedule",
    validator: validate_BatchUpdateSchedule_592979, base: "/",
    url: url_BatchUpdateSchedule_592980, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSchedule_592703 = ref object of OpenApiRestCall_592364
proc url_DescribeSchedule_592705(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId"),
               (kind: ConstantSegment, value: "/schedule")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeSchedule_592704(path: JsonNode; query: JsonNode;
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
  var valid_592831 = path.getOrDefault("channelId")
  valid_592831 = validateParameter(valid_592831, JString, required = true,
                                 default = nil)
  if valid_592831 != nil:
    section.add "channelId", valid_592831
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  section = newJObject()
  var valid_592832 = query.getOrDefault("nextToken")
  valid_592832 = validateParameter(valid_592832, JString, required = false,
                                 default = nil)
  if valid_592832 != nil:
    section.add "nextToken", valid_592832
  var valid_592833 = query.getOrDefault("MaxResults")
  valid_592833 = validateParameter(valid_592833, JString, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "MaxResults", valid_592833
  var valid_592834 = query.getOrDefault("NextToken")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "NextToken", valid_592834
  var valid_592835 = query.getOrDefault("maxResults")
  valid_592835 = validateParameter(valid_592835, JInt, required = false, default = nil)
  if valid_592835 != nil:
    section.add "maxResults", valid_592835
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
  var valid_592836 = header.getOrDefault("X-Amz-Signature")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Signature", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-Content-Sha256", valid_592837
  var valid_592838 = header.getOrDefault("X-Amz-Date")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "X-Amz-Date", valid_592838
  var valid_592839 = header.getOrDefault("X-Amz-Credential")
  valid_592839 = validateParameter(valid_592839, JString, required = false,
                                 default = nil)
  if valid_592839 != nil:
    section.add "X-Amz-Credential", valid_592839
  var valid_592840 = header.getOrDefault("X-Amz-Security-Token")
  valid_592840 = validateParameter(valid_592840, JString, required = false,
                                 default = nil)
  if valid_592840 != nil:
    section.add "X-Amz-Security-Token", valid_592840
  var valid_592841 = header.getOrDefault("X-Amz-Algorithm")
  valid_592841 = validateParameter(valid_592841, JString, required = false,
                                 default = nil)
  if valid_592841 != nil:
    section.add "X-Amz-Algorithm", valid_592841
  var valid_592842 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592842 = validateParameter(valid_592842, JString, required = false,
                                 default = nil)
  if valid_592842 != nil:
    section.add "X-Amz-SignedHeaders", valid_592842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592865: Call_DescribeSchedule_592703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get a channel schedule
  ## 
  let valid = call_592865.validator(path, query, header, formData, body)
  let scheme = call_592865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592865.url(scheme.get, call_592865.host, call_592865.base,
                         call_592865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592865, url, valid)

proc call*(call_592936: Call_DescribeSchedule_592703; channelId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## describeSchedule
  ## Get a channel schedule
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  var path_592937 = newJObject()
  var query_592939 = newJObject()
  add(query_592939, "nextToken", newJString(nextToken))
  add(query_592939, "MaxResults", newJString(MaxResults))
  add(query_592939, "NextToken", newJString(NextToken))
  add(path_592937, "channelId", newJString(channelId))
  add(query_592939, "maxResults", newJInt(maxResults))
  result = call_592936.call(path_592937, query_592939, nil, nil, nil)

var describeSchedule* = Call_DescribeSchedule_592703(name: "describeSchedule",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/schedule",
    validator: validate_DescribeSchedule_592704, base: "/",
    url: url_DescribeSchedule_592705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchedule_592994 = ref object of OpenApiRestCall_592364
proc url_DeleteSchedule_592996(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId"),
               (kind: ConstantSegment, value: "/schedule")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteSchedule_592995(path: JsonNode; query: JsonNode;
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
  var valid_592997 = path.getOrDefault("channelId")
  valid_592997 = validateParameter(valid_592997, JString, required = true,
                                 default = nil)
  if valid_592997 != nil:
    section.add "channelId", valid_592997
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
  var valid_592998 = header.getOrDefault("X-Amz-Signature")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-Signature", valid_592998
  var valid_592999 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Content-Sha256", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-Date")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Date", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-Credential")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Credential", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-Security-Token")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Security-Token", valid_593002
  var valid_593003 = header.getOrDefault("X-Amz-Algorithm")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Algorithm", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-SignedHeaders", valid_593004
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593005: Call_DeleteSchedule_592994; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete all schedule actions on a channel.
  ## 
  let valid = call_593005.validator(path, query, header, formData, body)
  let scheme = call_593005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593005.url(scheme.get, call_593005.host, call_593005.base,
                         call_593005.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593005, url, valid)

proc call*(call_593006: Call_DeleteSchedule_592994; channelId: string): Recallable =
  ## deleteSchedule
  ## Delete all schedule actions on a channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_593007 = newJObject()
  add(path_593007, "channelId", newJString(channelId))
  result = call_593006.call(path_593007, nil, nil, nil, nil)

var deleteSchedule* = Call_DeleteSchedule_592994(name: "deleteSchedule",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/schedule",
    validator: validate_DeleteSchedule_592995, base: "/", url: url_DeleteSchedule_592996,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateChannel_593025 = ref object of OpenApiRestCall_592364
proc url_CreateChannel_593027(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateChannel_593026(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593028 = header.getOrDefault("X-Amz-Signature")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "X-Amz-Signature", valid_593028
  var valid_593029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "X-Amz-Content-Sha256", valid_593029
  var valid_593030 = header.getOrDefault("X-Amz-Date")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "X-Amz-Date", valid_593030
  var valid_593031 = header.getOrDefault("X-Amz-Credential")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "X-Amz-Credential", valid_593031
  var valid_593032 = header.getOrDefault("X-Amz-Security-Token")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "X-Amz-Security-Token", valid_593032
  var valid_593033 = header.getOrDefault("X-Amz-Algorithm")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "X-Amz-Algorithm", valid_593033
  var valid_593034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "X-Amz-SignedHeaders", valid_593034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593036: Call_CreateChannel_593025; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new channel
  ## 
  let valid = call_593036.validator(path, query, header, formData, body)
  let scheme = call_593036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593036.url(scheme.get, call_593036.host, call_593036.base,
                         call_593036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593036, url, valid)

proc call*(call_593037: Call_CreateChannel_593025; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a new channel
  ##   body: JObject (required)
  var body_593038 = newJObject()
  if body != nil:
    body_593038 = body
  result = call_593037.call(nil, nil, nil, nil, body_593038)

var createChannel* = Call_CreateChannel_593025(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/channels", validator: validate_CreateChannel_593026, base: "/",
    url: url_CreateChannel_593027, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_593008 = ref object of OpenApiRestCall_592364
proc url_ListChannels_593010(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListChannels_593009(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Produces list of channels that have been created
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  section = newJObject()
  var valid_593011 = query.getOrDefault("nextToken")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "nextToken", valid_593011
  var valid_593012 = query.getOrDefault("MaxResults")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "MaxResults", valid_593012
  var valid_593013 = query.getOrDefault("NextToken")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "NextToken", valid_593013
  var valid_593014 = query.getOrDefault("maxResults")
  valid_593014 = validateParameter(valid_593014, JInt, required = false, default = nil)
  if valid_593014 != nil:
    section.add "maxResults", valid_593014
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
  var valid_593015 = header.getOrDefault("X-Amz-Signature")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "X-Amz-Signature", valid_593015
  var valid_593016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "X-Amz-Content-Sha256", valid_593016
  var valid_593017 = header.getOrDefault("X-Amz-Date")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-Date", valid_593017
  var valid_593018 = header.getOrDefault("X-Amz-Credential")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "X-Amz-Credential", valid_593018
  var valid_593019 = header.getOrDefault("X-Amz-Security-Token")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-Security-Token", valid_593019
  var valid_593020 = header.getOrDefault("X-Amz-Algorithm")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "X-Amz-Algorithm", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-SignedHeaders", valid_593021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593022: Call_ListChannels_593008; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces list of channels that have been created
  ## 
  let valid = call_593022.validator(path, query, header, formData, body)
  let scheme = call_593022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593022.url(scheme.get, call_593022.host, call_593022.base,
                         call_593022.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593022, url, valid)

proc call*(call_593023: Call_ListChannels_593008; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listChannels
  ## Produces list of channels that have been created
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  var query_593024 = newJObject()
  add(query_593024, "nextToken", newJString(nextToken))
  add(query_593024, "MaxResults", newJString(MaxResults))
  add(query_593024, "NextToken", newJString(NextToken))
  add(query_593024, "maxResults", newJInt(maxResults))
  result = call_593023.call(nil, query_593024, nil, nil, nil)

var listChannels* = Call_ListChannels_593008(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels", validator: validate_ListChannels_593009, base: "/",
    url: url_ListChannels_593010, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInput_593056 = ref object of OpenApiRestCall_592364
proc url_CreateInput_593058(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateInput_593057(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593059 = header.getOrDefault("X-Amz-Signature")
  valid_593059 = validateParameter(valid_593059, JString, required = false,
                                 default = nil)
  if valid_593059 != nil:
    section.add "X-Amz-Signature", valid_593059
  var valid_593060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-Content-Sha256", valid_593060
  var valid_593061 = header.getOrDefault("X-Amz-Date")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "X-Amz-Date", valid_593061
  var valid_593062 = header.getOrDefault("X-Amz-Credential")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "X-Amz-Credential", valid_593062
  var valid_593063 = header.getOrDefault("X-Amz-Security-Token")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Security-Token", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-Algorithm")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-Algorithm", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-SignedHeaders", valid_593065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593067: Call_CreateInput_593056; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create an input
  ## 
  let valid = call_593067.validator(path, query, header, formData, body)
  let scheme = call_593067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593067.url(scheme.get, call_593067.host, call_593067.base,
                         call_593067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593067, url, valid)

proc call*(call_593068: Call_CreateInput_593056; body: JsonNode): Recallable =
  ## createInput
  ## Create an input
  ##   body: JObject (required)
  var body_593069 = newJObject()
  if body != nil:
    body_593069 = body
  result = call_593068.call(nil, nil, nil, nil, body_593069)

var createInput* = Call_CreateInput_593056(name: "createInput",
                                        meth: HttpMethod.HttpPost,
                                        host: "medialive.amazonaws.com",
                                        route: "/prod/inputs",
                                        validator: validate_CreateInput_593057,
                                        base: "/", url: url_CreateInput_593058,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputs_593039 = ref object of OpenApiRestCall_592364
proc url_ListInputs_593041(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListInputs_593040(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Produces list of inputs that have been created
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  section = newJObject()
  var valid_593042 = query.getOrDefault("nextToken")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "nextToken", valid_593042
  var valid_593043 = query.getOrDefault("MaxResults")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "MaxResults", valid_593043
  var valid_593044 = query.getOrDefault("NextToken")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "NextToken", valid_593044
  var valid_593045 = query.getOrDefault("maxResults")
  valid_593045 = validateParameter(valid_593045, JInt, required = false, default = nil)
  if valid_593045 != nil:
    section.add "maxResults", valid_593045
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
  var valid_593046 = header.getOrDefault("X-Amz-Signature")
  valid_593046 = validateParameter(valid_593046, JString, required = false,
                                 default = nil)
  if valid_593046 != nil:
    section.add "X-Amz-Signature", valid_593046
  var valid_593047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593047 = validateParameter(valid_593047, JString, required = false,
                                 default = nil)
  if valid_593047 != nil:
    section.add "X-Amz-Content-Sha256", valid_593047
  var valid_593048 = header.getOrDefault("X-Amz-Date")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "X-Amz-Date", valid_593048
  var valid_593049 = header.getOrDefault("X-Amz-Credential")
  valid_593049 = validateParameter(valid_593049, JString, required = false,
                                 default = nil)
  if valid_593049 != nil:
    section.add "X-Amz-Credential", valid_593049
  var valid_593050 = header.getOrDefault("X-Amz-Security-Token")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "X-Amz-Security-Token", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-Algorithm")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-Algorithm", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-SignedHeaders", valid_593052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593053: Call_ListInputs_593039; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces list of inputs that have been created
  ## 
  let valid = call_593053.validator(path, query, header, formData, body)
  let scheme = call_593053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593053.url(scheme.get, call_593053.host, call_593053.base,
                         call_593053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593053, url, valid)

proc call*(call_593054: Call_ListInputs_593039; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listInputs
  ## Produces list of inputs that have been created
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  var query_593055 = newJObject()
  add(query_593055, "nextToken", newJString(nextToken))
  add(query_593055, "MaxResults", newJString(MaxResults))
  add(query_593055, "NextToken", newJString(NextToken))
  add(query_593055, "maxResults", newJInt(maxResults))
  result = call_593054.call(nil, query_593055, nil, nil, nil)

var listInputs* = Call_ListInputs_593039(name: "listInputs",
                                      meth: HttpMethod.HttpGet,
                                      host: "medialive.amazonaws.com",
                                      route: "/prod/inputs",
                                      validator: validate_ListInputs_593040,
                                      base: "/", url: url_ListInputs_593041,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInputSecurityGroup_593087 = ref object of OpenApiRestCall_592364
proc url_CreateInputSecurityGroup_593089(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateInputSecurityGroup_593088(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593090 = header.getOrDefault("X-Amz-Signature")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "X-Amz-Signature", valid_593090
  var valid_593091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593091 = validateParameter(valid_593091, JString, required = false,
                                 default = nil)
  if valid_593091 != nil:
    section.add "X-Amz-Content-Sha256", valid_593091
  var valid_593092 = header.getOrDefault("X-Amz-Date")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "X-Amz-Date", valid_593092
  var valid_593093 = header.getOrDefault("X-Amz-Credential")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "X-Amz-Credential", valid_593093
  var valid_593094 = header.getOrDefault("X-Amz-Security-Token")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "X-Amz-Security-Token", valid_593094
  var valid_593095 = header.getOrDefault("X-Amz-Algorithm")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "X-Amz-Algorithm", valid_593095
  var valid_593096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-SignedHeaders", valid_593096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593098: Call_CreateInputSecurityGroup_593087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Input Security Group
  ## 
  let valid = call_593098.validator(path, query, header, formData, body)
  let scheme = call_593098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593098.url(scheme.get, call_593098.host, call_593098.base,
                         call_593098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593098, url, valid)

proc call*(call_593099: Call_CreateInputSecurityGroup_593087; body: JsonNode): Recallable =
  ## createInputSecurityGroup
  ## Creates a Input Security Group
  ##   body: JObject (required)
  var body_593100 = newJObject()
  if body != nil:
    body_593100 = body
  result = call_593099.call(nil, nil, nil, nil, body_593100)

var createInputSecurityGroup* = Call_CreateInputSecurityGroup_593087(
    name: "createInputSecurityGroup", meth: HttpMethod.HttpPost,
    host: "medialive.amazonaws.com", route: "/prod/inputSecurityGroups",
    validator: validate_CreateInputSecurityGroup_593088, base: "/",
    url: url_CreateInputSecurityGroup_593089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputSecurityGroups_593070 = ref object of OpenApiRestCall_592364
proc url_ListInputSecurityGroups_593072(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListInputSecurityGroups_593071(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Produces a list of Input Security Groups for an account
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  section = newJObject()
  var valid_593073 = query.getOrDefault("nextToken")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "nextToken", valid_593073
  var valid_593074 = query.getOrDefault("MaxResults")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "MaxResults", valid_593074
  var valid_593075 = query.getOrDefault("NextToken")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "NextToken", valid_593075
  var valid_593076 = query.getOrDefault("maxResults")
  valid_593076 = validateParameter(valid_593076, JInt, required = false, default = nil)
  if valid_593076 != nil:
    section.add "maxResults", valid_593076
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
  var valid_593077 = header.getOrDefault("X-Amz-Signature")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Signature", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-Content-Sha256", valid_593078
  var valid_593079 = header.getOrDefault("X-Amz-Date")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-Date", valid_593079
  var valid_593080 = header.getOrDefault("X-Amz-Credential")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "X-Amz-Credential", valid_593080
  var valid_593081 = header.getOrDefault("X-Amz-Security-Token")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-Security-Token", valid_593081
  var valid_593082 = header.getOrDefault("X-Amz-Algorithm")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-Algorithm", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-SignedHeaders", valid_593083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593084: Call_ListInputSecurityGroups_593070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces a list of Input Security Groups for an account
  ## 
  let valid = call_593084.validator(path, query, header, formData, body)
  let scheme = call_593084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593084.url(scheme.get, call_593084.host, call_593084.base,
                         call_593084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593084, url, valid)

proc call*(call_593085: Call_ListInputSecurityGroups_593070;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listInputSecurityGroups
  ## Produces a list of Input Security Groups for an account
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  var query_593086 = newJObject()
  add(query_593086, "nextToken", newJString(nextToken))
  add(query_593086, "MaxResults", newJString(MaxResults))
  add(query_593086, "NextToken", newJString(NextToken))
  add(query_593086, "maxResults", newJInt(maxResults))
  result = call_593085.call(nil, query_593086, nil, nil, nil)

var listInputSecurityGroups* = Call_ListInputSecurityGroups_593070(
    name: "listInputSecurityGroups", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/inputSecurityGroups",
    validator: validate_ListInputSecurityGroups_593071, base: "/",
    url: url_ListInputSecurityGroups_593072, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_593115 = ref object of OpenApiRestCall_592364
proc url_CreateTags_593117(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateTags_593116(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593118 = path.getOrDefault("resource-arn")
  valid_593118 = validateParameter(valid_593118, JString, required = true,
                                 default = nil)
  if valid_593118 != nil:
    section.add "resource-arn", valid_593118
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
  var valid_593119 = header.getOrDefault("X-Amz-Signature")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "X-Amz-Signature", valid_593119
  var valid_593120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-Content-Sha256", valid_593120
  var valid_593121 = header.getOrDefault("X-Amz-Date")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-Date", valid_593121
  var valid_593122 = header.getOrDefault("X-Amz-Credential")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Credential", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-Security-Token")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-Security-Token", valid_593123
  var valid_593124 = header.getOrDefault("X-Amz-Algorithm")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = nil)
  if valid_593124 != nil:
    section.add "X-Amz-Algorithm", valid_593124
  var valid_593125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "X-Amz-SignedHeaders", valid_593125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593127: Call_CreateTags_593115; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create tags for a resource
  ## 
  let valid = call_593127.validator(path, query, header, formData, body)
  let scheme = call_593127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593127.url(scheme.get, call_593127.host, call_593127.base,
                         call_593127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593127, url, valid)

proc call*(call_593128: Call_CreateTags_593115; resourceArn: string; body: JsonNode): Recallable =
  ## createTags
  ## Create tags for a resource
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_593129 = newJObject()
  var body_593130 = newJObject()
  add(path_593129, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_593130 = body
  result = call_593128.call(path_593129, nil, nil, nil, body_593130)

var createTags* = Call_CreateTags_593115(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "medialive.amazonaws.com",
                                      route: "/prod/tags/{resource-arn}",
                                      validator: validate_CreateTags_593116,
                                      base: "/", url: url_CreateTags_593117,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_593101 = ref object of OpenApiRestCall_592364
proc url_ListTagsForResource_593103(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListTagsForResource_593102(path: JsonNode; query: JsonNode;
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
  var valid_593104 = path.getOrDefault("resource-arn")
  valid_593104 = validateParameter(valid_593104, JString, required = true,
                                 default = nil)
  if valid_593104 != nil:
    section.add "resource-arn", valid_593104
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
  var valid_593105 = header.getOrDefault("X-Amz-Signature")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-Signature", valid_593105
  var valid_593106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "X-Amz-Content-Sha256", valid_593106
  var valid_593107 = header.getOrDefault("X-Amz-Date")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "X-Amz-Date", valid_593107
  var valid_593108 = header.getOrDefault("X-Amz-Credential")
  valid_593108 = validateParameter(valid_593108, JString, required = false,
                                 default = nil)
  if valid_593108 != nil:
    section.add "X-Amz-Credential", valid_593108
  var valid_593109 = header.getOrDefault("X-Amz-Security-Token")
  valid_593109 = validateParameter(valid_593109, JString, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "X-Amz-Security-Token", valid_593109
  var valid_593110 = header.getOrDefault("X-Amz-Algorithm")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = nil)
  if valid_593110 != nil:
    section.add "X-Amz-Algorithm", valid_593110
  var valid_593111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "X-Amz-SignedHeaders", valid_593111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593112: Call_ListTagsForResource_593101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces list of tags that have been created for a resource
  ## 
  let valid = call_593112.validator(path, query, header, formData, body)
  let scheme = call_593112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593112.url(scheme.get, call_593112.host, call_593112.base,
                         call_593112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593112, url, valid)

proc call*(call_593113: Call_ListTagsForResource_593101; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Produces list of tags that have been created for a resource
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  var path_593114 = newJObject()
  add(path_593114, "resource-arn", newJString(resourceArn))
  result = call_593113.call(path_593114, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_593101(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/tags/{resource-arn}",
    validator: validate_ListTagsForResource_593102, base: "/",
    url: url_ListTagsForResource_593103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_593145 = ref object of OpenApiRestCall_592364
proc url_UpdateChannel_593147(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateChannel_593146(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593148 = path.getOrDefault("channelId")
  valid_593148 = validateParameter(valid_593148, JString, required = true,
                                 default = nil)
  if valid_593148 != nil:
    section.add "channelId", valid_593148
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
  var valid_593149 = header.getOrDefault("X-Amz-Signature")
  valid_593149 = validateParameter(valid_593149, JString, required = false,
                                 default = nil)
  if valid_593149 != nil:
    section.add "X-Amz-Signature", valid_593149
  var valid_593150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593150 = validateParameter(valid_593150, JString, required = false,
                                 default = nil)
  if valid_593150 != nil:
    section.add "X-Amz-Content-Sha256", valid_593150
  var valid_593151 = header.getOrDefault("X-Amz-Date")
  valid_593151 = validateParameter(valid_593151, JString, required = false,
                                 default = nil)
  if valid_593151 != nil:
    section.add "X-Amz-Date", valid_593151
  var valid_593152 = header.getOrDefault("X-Amz-Credential")
  valid_593152 = validateParameter(valid_593152, JString, required = false,
                                 default = nil)
  if valid_593152 != nil:
    section.add "X-Amz-Credential", valid_593152
  var valid_593153 = header.getOrDefault("X-Amz-Security-Token")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "X-Amz-Security-Token", valid_593153
  var valid_593154 = header.getOrDefault("X-Amz-Algorithm")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "X-Amz-Algorithm", valid_593154
  var valid_593155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "X-Amz-SignedHeaders", valid_593155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593157: Call_UpdateChannel_593145; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a channel.
  ## 
  let valid = call_593157.validator(path, query, header, formData, body)
  let scheme = call_593157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593157.url(scheme.get, call_593157.host, call_593157.base,
                         call_593157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593157, url, valid)

proc call*(call_593158: Call_UpdateChannel_593145; channelId: string; body: JsonNode): Recallable =
  ## updateChannel
  ## Updates a channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_593159 = newJObject()
  var body_593160 = newJObject()
  add(path_593159, "channelId", newJString(channelId))
  if body != nil:
    body_593160 = body
  result = call_593158.call(path_593159, nil, nil, nil, body_593160)

var updateChannel* = Call_UpdateChannel_593145(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_UpdateChannel_593146,
    base: "/", url: url_UpdateChannel_593147, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_593131 = ref object of OpenApiRestCall_592364
proc url_DescribeChannel_593133(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeChannel_593132(path: JsonNode; query: JsonNode;
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
  var valid_593134 = path.getOrDefault("channelId")
  valid_593134 = validateParameter(valid_593134, JString, required = true,
                                 default = nil)
  if valid_593134 != nil:
    section.add "channelId", valid_593134
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
  var valid_593135 = header.getOrDefault("X-Amz-Signature")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "X-Amz-Signature", valid_593135
  var valid_593136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "X-Amz-Content-Sha256", valid_593136
  var valid_593137 = header.getOrDefault("X-Amz-Date")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-Date", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-Credential")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Credential", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-Security-Token")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-Security-Token", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-Algorithm")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-Algorithm", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-SignedHeaders", valid_593141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593142: Call_DescribeChannel_593131; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about a channel
  ## 
  let valid = call_593142.validator(path, query, header, formData, body)
  let scheme = call_593142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593142.url(scheme.get, call_593142.host, call_593142.base,
                         call_593142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593142, url, valid)

proc call*(call_593143: Call_DescribeChannel_593131; channelId: string): Recallable =
  ## describeChannel
  ## Gets details about a channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_593144 = newJObject()
  add(path_593144, "channelId", newJString(channelId))
  result = call_593143.call(path_593144, nil, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_593131(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_DescribeChannel_593132,
    base: "/", url: url_DescribeChannel_593133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_593161 = ref object of OpenApiRestCall_592364
proc url_DeleteChannel_593163(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteChannel_593162(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593164 = path.getOrDefault("channelId")
  valid_593164 = validateParameter(valid_593164, JString, required = true,
                                 default = nil)
  if valid_593164 != nil:
    section.add "channelId", valid_593164
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
  var valid_593165 = header.getOrDefault("X-Amz-Signature")
  valid_593165 = validateParameter(valid_593165, JString, required = false,
                                 default = nil)
  if valid_593165 != nil:
    section.add "X-Amz-Signature", valid_593165
  var valid_593166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593166 = validateParameter(valid_593166, JString, required = false,
                                 default = nil)
  if valid_593166 != nil:
    section.add "X-Amz-Content-Sha256", valid_593166
  var valid_593167 = header.getOrDefault("X-Amz-Date")
  valid_593167 = validateParameter(valid_593167, JString, required = false,
                                 default = nil)
  if valid_593167 != nil:
    section.add "X-Amz-Date", valid_593167
  var valid_593168 = header.getOrDefault("X-Amz-Credential")
  valid_593168 = validateParameter(valid_593168, JString, required = false,
                                 default = nil)
  if valid_593168 != nil:
    section.add "X-Amz-Credential", valid_593168
  var valid_593169 = header.getOrDefault("X-Amz-Security-Token")
  valid_593169 = validateParameter(valid_593169, JString, required = false,
                                 default = nil)
  if valid_593169 != nil:
    section.add "X-Amz-Security-Token", valid_593169
  var valid_593170 = header.getOrDefault("X-Amz-Algorithm")
  valid_593170 = validateParameter(valid_593170, JString, required = false,
                                 default = nil)
  if valid_593170 != nil:
    section.add "X-Amz-Algorithm", valid_593170
  var valid_593171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "X-Amz-SignedHeaders", valid_593171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593172: Call_DeleteChannel_593161; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts deletion of channel. The associated outputs are also deleted.
  ## 
  let valid = call_593172.validator(path, query, header, formData, body)
  let scheme = call_593172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593172.url(scheme.get, call_593172.host, call_593172.base,
                         call_593172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593172, url, valid)

proc call*(call_593173: Call_DeleteChannel_593161; channelId: string): Recallable =
  ## deleteChannel
  ## Starts deletion of channel. The associated outputs are also deleted.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_593174 = newJObject()
  add(path_593174, "channelId", newJString(channelId))
  result = call_593173.call(path_593174, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_593161(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_DeleteChannel_593162,
    base: "/", url: url_DeleteChannel_593163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInput_593189 = ref object of OpenApiRestCall_592364
proc url_UpdateInput_593191(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputId" in path, "`inputId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputs/"),
               (kind: VariableSegment, value: "inputId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateInput_593190(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593192 = path.getOrDefault("inputId")
  valid_593192 = validateParameter(valid_593192, JString, required = true,
                                 default = nil)
  if valid_593192 != nil:
    section.add "inputId", valid_593192
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
  var valid_593193 = header.getOrDefault("X-Amz-Signature")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "X-Amz-Signature", valid_593193
  var valid_593194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593194 = validateParameter(valid_593194, JString, required = false,
                                 default = nil)
  if valid_593194 != nil:
    section.add "X-Amz-Content-Sha256", valid_593194
  var valid_593195 = header.getOrDefault("X-Amz-Date")
  valid_593195 = validateParameter(valid_593195, JString, required = false,
                                 default = nil)
  if valid_593195 != nil:
    section.add "X-Amz-Date", valid_593195
  var valid_593196 = header.getOrDefault("X-Amz-Credential")
  valid_593196 = validateParameter(valid_593196, JString, required = false,
                                 default = nil)
  if valid_593196 != nil:
    section.add "X-Amz-Credential", valid_593196
  var valid_593197 = header.getOrDefault("X-Amz-Security-Token")
  valid_593197 = validateParameter(valid_593197, JString, required = false,
                                 default = nil)
  if valid_593197 != nil:
    section.add "X-Amz-Security-Token", valid_593197
  var valid_593198 = header.getOrDefault("X-Amz-Algorithm")
  valid_593198 = validateParameter(valid_593198, JString, required = false,
                                 default = nil)
  if valid_593198 != nil:
    section.add "X-Amz-Algorithm", valid_593198
  var valid_593199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593199 = validateParameter(valid_593199, JString, required = false,
                                 default = nil)
  if valid_593199 != nil:
    section.add "X-Amz-SignedHeaders", valid_593199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593201: Call_UpdateInput_593189; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an input.
  ## 
  let valid = call_593201.validator(path, query, header, formData, body)
  let scheme = call_593201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593201.url(scheme.get, call_593201.host, call_593201.base,
                         call_593201.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593201, url, valid)

proc call*(call_593202: Call_UpdateInput_593189; body: JsonNode; inputId: string): Recallable =
  ## updateInput
  ## Updates an input.
  ##   body: JObject (required)
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  var path_593203 = newJObject()
  var body_593204 = newJObject()
  if body != nil:
    body_593204 = body
  add(path_593203, "inputId", newJString(inputId))
  result = call_593202.call(path_593203, nil, nil, nil, body_593204)

var updateInput* = Call_UpdateInput_593189(name: "updateInput",
                                        meth: HttpMethod.HttpPut,
                                        host: "medialive.amazonaws.com",
                                        route: "/prod/inputs/{inputId}",
                                        validator: validate_UpdateInput_593190,
                                        base: "/", url: url_UpdateInput_593191,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInput_593175 = ref object of OpenApiRestCall_592364
proc url_DescribeInput_593177(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputId" in path, "`inputId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputs/"),
               (kind: VariableSegment, value: "inputId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeInput_593176(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593178 = path.getOrDefault("inputId")
  valid_593178 = validateParameter(valid_593178, JString, required = true,
                                 default = nil)
  if valid_593178 != nil:
    section.add "inputId", valid_593178
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
  var valid_593179 = header.getOrDefault("X-Amz-Signature")
  valid_593179 = validateParameter(valid_593179, JString, required = false,
                                 default = nil)
  if valid_593179 != nil:
    section.add "X-Amz-Signature", valid_593179
  var valid_593180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593180 = validateParameter(valid_593180, JString, required = false,
                                 default = nil)
  if valid_593180 != nil:
    section.add "X-Amz-Content-Sha256", valid_593180
  var valid_593181 = header.getOrDefault("X-Amz-Date")
  valid_593181 = validateParameter(valid_593181, JString, required = false,
                                 default = nil)
  if valid_593181 != nil:
    section.add "X-Amz-Date", valid_593181
  var valid_593182 = header.getOrDefault("X-Amz-Credential")
  valid_593182 = validateParameter(valid_593182, JString, required = false,
                                 default = nil)
  if valid_593182 != nil:
    section.add "X-Amz-Credential", valid_593182
  var valid_593183 = header.getOrDefault("X-Amz-Security-Token")
  valid_593183 = validateParameter(valid_593183, JString, required = false,
                                 default = nil)
  if valid_593183 != nil:
    section.add "X-Amz-Security-Token", valid_593183
  var valid_593184 = header.getOrDefault("X-Amz-Algorithm")
  valid_593184 = validateParameter(valid_593184, JString, required = false,
                                 default = nil)
  if valid_593184 != nil:
    section.add "X-Amz-Algorithm", valid_593184
  var valid_593185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "X-Amz-SignedHeaders", valid_593185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593186: Call_DescribeInput_593175; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces details about an input
  ## 
  let valid = call_593186.validator(path, query, header, formData, body)
  let scheme = call_593186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593186.url(scheme.get, call_593186.host, call_593186.base,
                         call_593186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593186, url, valid)

proc call*(call_593187: Call_DescribeInput_593175; inputId: string): Recallable =
  ## describeInput
  ## Produces details about an input
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  var path_593188 = newJObject()
  add(path_593188, "inputId", newJString(inputId))
  result = call_593187.call(path_593188, nil, nil, nil, nil)

var describeInput* = Call_DescribeInput_593175(name: "describeInput",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/inputs/{inputId}", validator: validate_DescribeInput_593176,
    base: "/", url: url_DescribeInput_593177, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInput_593205 = ref object of OpenApiRestCall_592364
proc url_DeleteInput_593207(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputId" in path, "`inputId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputs/"),
               (kind: VariableSegment, value: "inputId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteInput_593206(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593208 = path.getOrDefault("inputId")
  valid_593208 = validateParameter(valid_593208, JString, required = true,
                                 default = nil)
  if valid_593208 != nil:
    section.add "inputId", valid_593208
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
  var valid_593209 = header.getOrDefault("X-Amz-Signature")
  valid_593209 = validateParameter(valid_593209, JString, required = false,
                                 default = nil)
  if valid_593209 != nil:
    section.add "X-Amz-Signature", valid_593209
  var valid_593210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593210 = validateParameter(valid_593210, JString, required = false,
                                 default = nil)
  if valid_593210 != nil:
    section.add "X-Amz-Content-Sha256", valid_593210
  var valid_593211 = header.getOrDefault("X-Amz-Date")
  valid_593211 = validateParameter(valid_593211, JString, required = false,
                                 default = nil)
  if valid_593211 != nil:
    section.add "X-Amz-Date", valid_593211
  var valid_593212 = header.getOrDefault("X-Amz-Credential")
  valid_593212 = validateParameter(valid_593212, JString, required = false,
                                 default = nil)
  if valid_593212 != nil:
    section.add "X-Amz-Credential", valid_593212
  var valid_593213 = header.getOrDefault("X-Amz-Security-Token")
  valid_593213 = validateParameter(valid_593213, JString, required = false,
                                 default = nil)
  if valid_593213 != nil:
    section.add "X-Amz-Security-Token", valid_593213
  var valid_593214 = header.getOrDefault("X-Amz-Algorithm")
  valid_593214 = validateParameter(valid_593214, JString, required = false,
                                 default = nil)
  if valid_593214 != nil:
    section.add "X-Amz-Algorithm", valid_593214
  var valid_593215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593215 = validateParameter(valid_593215, JString, required = false,
                                 default = nil)
  if valid_593215 != nil:
    section.add "X-Amz-SignedHeaders", valid_593215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593216: Call_DeleteInput_593205; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the input end point
  ## 
  let valid = call_593216.validator(path, query, header, formData, body)
  let scheme = call_593216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593216.url(scheme.get, call_593216.host, call_593216.base,
                         call_593216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593216, url, valid)

proc call*(call_593217: Call_DeleteInput_593205; inputId: string): Recallable =
  ## deleteInput
  ## Deletes the input end point
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  var path_593218 = newJObject()
  add(path_593218, "inputId", newJString(inputId))
  result = call_593217.call(path_593218, nil, nil, nil, nil)

var deleteInput* = Call_DeleteInput_593205(name: "deleteInput",
                                        meth: HttpMethod.HttpDelete,
                                        host: "medialive.amazonaws.com",
                                        route: "/prod/inputs/{inputId}",
                                        validator: validate_DeleteInput_593206,
                                        base: "/", url: url_DeleteInput_593207,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInputSecurityGroup_593233 = ref object of OpenApiRestCall_592364
proc url_UpdateInputSecurityGroup_593235(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputSecurityGroupId" in path,
        "`inputSecurityGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputSecurityGroups/"),
               (kind: VariableSegment, value: "inputSecurityGroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateInputSecurityGroup_593234(path: JsonNode; query: JsonNode;
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
  var valid_593236 = path.getOrDefault("inputSecurityGroupId")
  valid_593236 = validateParameter(valid_593236, JString, required = true,
                                 default = nil)
  if valid_593236 != nil:
    section.add "inputSecurityGroupId", valid_593236
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
  var valid_593237 = header.getOrDefault("X-Amz-Signature")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "X-Amz-Signature", valid_593237
  var valid_593238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593238 = validateParameter(valid_593238, JString, required = false,
                                 default = nil)
  if valid_593238 != nil:
    section.add "X-Amz-Content-Sha256", valid_593238
  var valid_593239 = header.getOrDefault("X-Amz-Date")
  valid_593239 = validateParameter(valid_593239, JString, required = false,
                                 default = nil)
  if valid_593239 != nil:
    section.add "X-Amz-Date", valid_593239
  var valid_593240 = header.getOrDefault("X-Amz-Credential")
  valid_593240 = validateParameter(valid_593240, JString, required = false,
                                 default = nil)
  if valid_593240 != nil:
    section.add "X-Amz-Credential", valid_593240
  var valid_593241 = header.getOrDefault("X-Amz-Security-Token")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "X-Amz-Security-Token", valid_593241
  var valid_593242 = header.getOrDefault("X-Amz-Algorithm")
  valid_593242 = validateParameter(valid_593242, JString, required = false,
                                 default = nil)
  if valid_593242 != nil:
    section.add "X-Amz-Algorithm", valid_593242
  var valid_593243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593243 = validateParameter(valid_593243, JString, required = false,
                                 default = nil)
  if valid_593243 != nil:
    section.add "X-Amz-SignedHeaders", valid_593243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593245: Call_UpdateInputSecurityGroup_593233; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update an Input Security Group's Whilelists.
  ## 
  let valid = call_593245.validator(path, query, header, formData, body)
  let scheme = call_593245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593245.url(scheme.get, call_593245.host, call_593245.base,
                         call_593245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593245, url, valid)

proc call*(call_593246: Call_UpdateInputSecurityGroup_593233;
          inputSecurityGroupId: string; body: JsonNode): Recallable =
  ## updateInputSecurityGroup
  ## Update an Input Security Group's Whilelists.
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_593247 = newJObject()
  var body_593248 = newJObject()
  add(path_593247, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  if body != nil:
    body_593248 = body
  result = call_593246.call(path_593247, nil, nil, nil, body_593248)

var updateInputSecurityGroup* = Call_UpdateInputSecurityGroup_593233(
    name: "updateInputSecurityGroup", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_UpdateInputSecurityGroup_593234, base: "/",
    url: url_UpdateInputSecurityGroup_593235, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInputSecurityGroup_593219 = ref object of OpenApiRestCall_592364
proc url_DescribeInputSecurityGroup_593221(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputSecurityGroupId" in path,
        "`inputSecurityGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputSecurityGroups/"),
               (kind: VariableSegment, value: "inputSecurityGroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeInputSecurityGroup_593220(path: JsonNode; query: JsonNode;
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
  var valid_593222 = path.getOrDefault("inputSecurityGroupId")
  valid_593222 = validateParameter(valid_593222, JString, required = true,
                                 default = nil)
  if valid_593222 != nil:
    section.add "inputSecurityGroupId", valid_593222
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
  var valid_593223 = header.getOrDefault("X-Amz-Signature")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "X-Amz-Signature", valid_593223
  var valid_593224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593224 = validateParameter(valid_593224, JString, required = false,
                                 default = nil)
  if valid_593224 != nil:
    section.add "X-Amz-Content-Sha256", valid_593224
  var valid_593225 = header.getOrDefault("X-Amz-Date")
  valid_593225 = validateParameter(valid_593225, JString, required = false,
                                 default = nil)
  if valid_593225 != nil:
    section.add "X-Amz-Date", valid_593225
  var valid_593226 = header.getOrDefault("X-Amz-Credential")
  valid_593226 = validateParameter(valid_593226, JString, required = false,
                                 default = nil)
  if valid_593226 != nil:
    section.add "X-Amz-Credential", valid_593226
  var valid_593227 = header.getOrDefault("X-Amz-Security-Token")
  valid_593227 = validateParameter(valid_593227, JString, required = false,
                                 default = nil)
  if valid_593227 != nil:
    section.add "X-Amz-Security-Token", valid_593227
  var valid_593228 = header.getOrDefault("X-Amz-Algorithm")
  valid_593228 = validateParameter(valid_593228, JString, required = false,
                                 default = nil)
  if valid_593228 != nil:
    section.add "X-Amz-Algorithm", valid_593228
  var valid_593229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593229 = validateParameter(valid_593229, JString, required = false,
                                 default = nil)
  if valid_593229 != nil:
    section.add "X-Amz-SignedHeaders", valid_593229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593230: Call_DescribeInputSecurityGroup_593219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces a summary of an Input Security Group
  ## 
  let valid = call_593230.validator(path, query, header, formData, body)
  let scheme = call_593230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593230.url(scheme.get, call_593230.host, call_593230.base,
                         call_593230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593230, url, valid)

proc call*(call_593231: Call_DescribeInputSecurityGroup_593219;
          inputSecurityGroupId: string): Recallable =
  ## describeInputSecurityGroup
  ## Produces a summary of an Input Security Group
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  var path_593232 = newJObject()
  add(path_593232, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  result = call_593231.call(path_593232, nil, nil, nil, nil)

var describeInputSecurityGroup* = Call_DescribeInputSecurityGroup_593219(
    name: "describeInputSecurityGroup", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_DescribeInputSecurityGroup_593220, base: "/",
    url: url_DescribeInputSecurityGroup_593221,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInputSecurityGroup_593249 = ref object of OpenApiRestCall_592364
proc url_DeleteInputSecurityGroup_593251(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputSecurityGroupId" in path,
        "`inputSecurityGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputSecurityGroups/"),
               (kind: VariableSegment, value: "inputSecurityGroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteInputSecurityGroup_593250(path: JsonNode; query: JsonNode;
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
  var valid_593252 = path.getOrDefault("inputSecurityGroupId")
  valid_593252 = validateParameter(valid_593252, JString, required = true,
                                 default = nil)
  if valid_593252 != nil:
    section.add "inputSecurityGroupId", valid_593252
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
  var valid_593253 = header.getOrDefault("X-Amz-Signature")
  valid_593253 = validateParameter(valid_593253, JString, required = false,
                                 default = nil)
  if valid_593253 != nil:
    section.add "X-Amz-Signature", valid_593253
  var valid_593254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593254 = validateParameter(valid_593254, JString, required = false,
                                 default = nil)
  if valid_593254 != nil:
    section.add "X-Amz-Content-Sha256", valid_593254
  var valid_593255 = header.getOrDefault("X-Amz-Date")
  valid_593255 = validateParameter(valid_593255, JString, required = false,
                                 default = nil)
  if valid_593255 != nil:
    section.add "X-Amz-Date", valid_593255
  var valid_593256 = header.getOrDefault("X-Amz-Credential")
  valid_593256 = validateParameter(valid_593256, JString, required = false,
                                 default = nil)
  if valid_593256 != nil:
    section.add "X-Amz-Credential", valid_593256
  var valid_593257 = header.getOrDefault("X-Amz-Security-Token")
  valid_593257 = validateParameter(valid_593257, JString, required = false,
                                 default = nil)
  if valid_593257 != nil:
    section.add "X-Amz-Security-Token", valid_593257
  var valid_593258 = header.getOrDefault("X-Amz-Algorithm")
  valid_593258 = validateParameter(valid_593258, JString, required = false,
                                 default = nil)
  if valid_593258 != nil:
    section.add "X-Amz-Algorithm", valid_593258
  var valid_593259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593259 = validateParameter(valid_593259, JString, required = false,
                                 default = nil)
  if valid_593259 != nil:
    section.add "X-Amz-SignedHeaders", valid_593259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593260: Call_DeleteInputSecurityGroup_593249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Input Security Group
  ## 
  let valid = call_593260.validator(path, query, header, formData, body)
  let scheme = call_593260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593260.url(scheme.get, call_593260.host, call_593260.base,
                         call_593260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593260, url, valid)

proc call*(call_593261: Call_DeleteInputSecurityGroup_593249;
          inputSecurityGroupId: string): Recallable =
  ## deleteInputSecurityGroup
  ## Deletes an Input Security Group
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  var path_593262 = newJObject()
  add(path_593262, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  result = call_593261.call(path_593262, nil, nil, nil, nil)

var deleteInputSecurityGroup* = Call_DeleteInputSecurityGroup_593249(
    name: "deleteInputSecurityGroup", meth: HttpMethod.HttpDelete,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_DeleteInputSecurityGroup_593250, base: "/",
    url: url_DeleteInputSecurityGroup_593251, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateReservation_593277 = ref object of OpenApiRestCall_592364
proc url_UpdateReservation_593279(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "reservationId" in path, "`reservationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/reservations/"),
               (kind: VariableSegment, value: "reservationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateReservation_593278(path: JsonNode; query: JsonNode;
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
  var valid_593280 = path.getOrDefault("reservationId")
  valid_593280 = validateParameter(valid_593280, JString, required = true,
                                 default = nil)
  if valid_593280 != nil:
    section.add "reservationId", valid_593280
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
  var valid_593281 = header.getOrDefault("X-Amz-Signature")
  valid_593281 = validateParameter(valid_593281, JString, required = false,
                                 default = nil)
  if valid_593281 != nil:
    section.add "X-Amz-Signature", valid_593281
  var valid_593282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593282 = validateParameter(valid_593282, JString, required = false,
                                 default = nil)
  if valid_593282 != nil:
    section.add "X-Amz-Content-Sha256", valid_593282
  var valid_593283 = header.getOrDefault("X-Amz-Date")
  valid_593283 = validateParameter(valid_593283, JString, required = false,
                                 default = nil)
  if valid_593283 != nil:
    section.add "X-Amz-Date", valid_593283
  var valid_593284 = header.getOrDefault("X-Amz-Credential")
  valid_593284 = validateParameter(valid_593284, JString, required = false,
                                 default = nil)
  if valid_593284 != nil:
    section.add "X-Amz-Credential", valid_593284
  var valid_593285 = header.getOrDefault("X-Amz-Security-Token")
  valid_593285 = validateParameter(valid_593285, JString, required = false,
                                 default = nil)
  if valid_593285 != nil:
    section.add "X-Amz-Security-Token", valid_593285
  var valid_593286 = header.getOrDefault("X-Amz-Algorithm")
  valid_593286 = validateParameter(valid_593286, JString, required = false,
                                 default = nil)
  if valid_593286 != nil:
    section.add "X-Amz-Algorithm", valid_593286
  var valid_593287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593287 = validateParameter(valid_593287, JString, required = false,
                                 default = nil)
  if valid_593287 != nil:
    section.add "X-Amz-SignedHeaders", valid_593287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593289: Call_UpdateReservation_593277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update reservation.
  ## 
  let valid = call_593289.validator(path, query, header, formData, body)
  let scheme = call_593289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593289.url(scheme.get, call_593289.host, call_593289.base,
                         call_593289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593289, url, valid)

proc call*(call_593290: Call_UpdateReservation_593277; body: JsonNode;
          reservationId: string): Recallable =
  ## updateReservation
  ## Update reservation.
  ##   body: JObject (required)
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  var path_593291 = newJObject()
  var body_593292 = newJObject()
  if body != nil:
    body_593292 = body
  add(path_593291, "reservationId", newJString(reservationId))
  result = call_593290.call(path_593291, nil, nil, nil, body_593292)

var updateReservation* = Call_UpdateReservation_593277(name: "updateReservation",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/reservations/{reservationId}",
    validator: validate_UpdateReservation_593278, base: "/",
    url: url_UpdateReservation_593279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReservation_593263 = ref object of OpenApiRestCall_592364
proc url_DescribeReservation_593265(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "reservationId" in path, "`reservationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/reservations/"),
               (kind: VariableSegment, value: "reservationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeReservation_593264(path: JsonNode; query: JsonNode;
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
  var valid_593266 = path.getOrDefault("reservationId")
  valid_593266 = validateParameter(valid_593266, JString, required = true,
                                 default = nil)
  if valid_593266 != nil:
    section.add "reservationId", valid_593266
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
  var valid_593267 = header.getOrDefault("X-Amz-Signature")
  valid_593267 = validateParameter(valid_593267, JString, required = false,
                                 default = nil)
  if valid_593267 != nil:
    section.add "X-Amz-Signature", valid_593267
  var valid_593268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593268 = validateParameter(valid_593268, JString, required = false,
                                 default = nil)
  if valid_593268 != nil:
    section.add "X-Amz-Content-Sha256", valid_593268
  var valid_593269 = header.getOrDefault("X-Amz-Date")
  valid_593269 = validateParameter(valid_593269, JString, required = false,
                                 default = nil)
  if valid_593269 != nil:
    section.add "X-Amz-Date", valid_593269
  var valid_593270 = header.getOrDefault("X-Amz-Credential")
  valid_593270 = validateParameter(valid_593270, JString, required = false,
                                 default = nil)
  if valid_593270 != nil:
    section.add "X-Amz-Credential", valid_593270
  var valid_593271 = header.getOrDefault("X-Amz-Security-Token")
  valid_593271 = validateParameter(valid_593271, JString, required = false,
                                 default = nil)
  if valid_593271 != nil:
    section.add "X-Amz-Security-Token", valid_593271
  var valid_593272 = header.getOrDefault("X-Amz-Algorithm")
  valid_593272 = validateParameter(valid_593272, JString, required = false,
                                 default = nil)
  if valid_593272 != nil:
    section.add "X-Amz-Algorithm", valid_593272
  var valid_593273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "X-Amz-SignedHeaders", valid_593273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593274: Call_DescribeReservation_593263; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get details for a reservation.
  ## 
  let valid = call_593274.validator(path, query, header, formData, body)
  let scheme = call_593274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593274.url(scheme.get, call_593274.host, call_593274.base,
                         call_593274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593274, url, valid)

proc call*(call_593275: Call_DescribeReservation_593263; reservationId: string): Recallable =
  ## describeReservation
  ## Get details for a reservation.
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  var path_593276 = newJObject()
  add(path_593276, "reservationId", newJString(reservationId))
  result = call_593275.call(path_593276, nil, nil, nil, nil)

var describeReservation* = Call_DescribeReservation_593263(
    name: "describeReservation", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/reservations/{reservationId}",
    validator: validate_DescribeReservation_593264, base: "/",
    url: url_DescribeReservation_593265, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReservation_593293 = ref object of OpenApiRestCall_592364
proc url_DeleteReservation_593295(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "reservationId" in path, "`reservationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/reservations/"),
               (kind: VariableSegment, value: "reservationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteReservation_593294(path: JsonNode; query: JsonNode;
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
  var valid_593296 = path.getOrDefault("reservationId")
  valid_593296 = validateParameter(valid_593296, JString, required = true,
                                 default = nil)
  if valid_593296 != nil:
    section.add "reservationId", valid_593296
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
  var valid_593297 = header.getOrDefault("X-Amz-Signature")
  valid_593297 = validateParameter(valid_593297, JString, required = false,
                                 default = nil)
  if valid_593297 != nil:
    section.add "X-Amz-Signature", valid_593297
  var valid_593298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593298 = validateParameter(valid_593298, JString, required = false,
                                 default = nil)
  if valid_593298 != nil:
    section.add "X-Amz-Content-Sha256", valid_593298
  var valid_593299 = header.getOrDefault("X-Amz-Date")
  valid_593299 = validateParameter(valid_593299, JString, required = false,
                                 default = nil)
  if valid_593299 != nil:
    section.add "X-Amz-Date", valid_593299
  var valid_593300 = header.getOrDefault("X-Amz-Credential")
  valid_593300 = validateParameter(valid_593300, JString, required = false,
                                 default = nil)
  if valid_593300 != nil:
    section.add "X-Amz-Credential", valid_593300
  var valid_593301 = header.getOrDefault("X-Amz-Security-Token")
  valid_593301 = validateParameter(valid_593301, JString, required = false,
                                 default = nil)
  if valid_593301 != nil:
    section.add "X-Amz-Security-Token", valid_593301
  var valid_593302 = header.getOrDefault("X-Amz-Algorithm")
  valid_593302 = validateParameter(valid_593302, JString, required = false,
                                 default = nil)
  if valid_593302 != nil:
    section.add "X-Amz-Algorithm", valid_593302
  var valid_593303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593303 = validateParameter(valid_593303, JString, required = false,
                                 default = nil)
  if valid_593303 != nil:
    section.add "X-Amz-SignedHeaders", valid_593303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593304: Call_DeleteReservation_593293; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete an expired reservation.
  ## 
  let valid = call_593304.validator(path, query, header, formData, body)
  let scheme = call_593304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593304.url(scheme.get, call_593304.host, call_593304.base,
                         call_593304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593304, url, valid)

proc call*(call_593305: Call_DeleteReservation_593293; reservationId: string): Recallable =
  ## deleteReservation
  ## Delete an expired reservation.
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  var path_593306 = newJObject()
  add(path_593306, "reservationId", newJString(reservationId))
  result = call_593305.call(path_593306, nil, nil, nil, nil)

var deleteReservation* = Call_DeleteReservation_593293(name: "deleteReservation",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/reservations/{reservationId}",
    validator: validate_DeleteReservation_593294, base: "/",
    url: url_DeleteReservation_593295, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_593307 = ref object of OpenApiRestCall_592364
proc url_DeleteTags_593309(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/tags/"),
               (kind: VariableSegment, value: "resource-arn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteTags_593308(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593310 = path.getOrDefault("resource-arn")
  valid_593310 = validateParameter(valid_593310, JString, required = true,
                                 default = nil)
  if valid_593310 != nil:
    section.add "resource-arn", valid_593310
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : Placeholder documentation for __listOf__string
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_593311 = query.getOrDefault("tagKeys")
  valid_593311 = validateParameter(valid_593311, JArray, required = true, default = nil)
  if valid_593311 != nil:
    section.add "tagKeys", valid_593311
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
  var valid_593312 = header.getOrDefault("X-Amz-Signature")
  valid_593312 = validateParameter(valid_593312, JString, required = false,
                                 default = nil)
  if valid_593312 != nil:
    section.add "X-Amz-Signature", valid_593312
  var valid_593313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593313 = validateParameter(valid_593313, JString, required = false,
                                 default = nil)
  if valid_593313 != nil:
    section.add "X-Amz-Content-Sha256", valid_593313
  var valid_593314 = header.getOrDefault("X-Amz-Date")
  valid_593314 = validateParameter(valid_593314, JString, required = false,
                                 default = nil)
  if valid_593314 != nil:
    section.add "X-Amz-Date", valid_593314
  var valid_593315 = header.getOrDefault("X-Amz-Credential")
  valid_593315 = validateParameter(valid_593315, JString, required = false,
                                 default = nil)
  if valid_593315 != nil:
    section.add "X-Amz-Credential", valid_593315
  var valid_593316 = header.getOrDefault("X-Amz-Security-Token")
  valid_593316 = validateParameter(valid_593316, JString, required = false,
                                 default = nil)
  if valid_593316 != nil:
    section.add "X-Amz-Security-Token", valid_593316
  var valid_593317 = header.getOrDefault("X-Amz-Algorithm")
  valid_593317 = validateParameter(valid_593317, JString, required = false,
                                 default = nil)
  if valid_593317 != nil:
    section.add "X-Amz-Algorithm", valid_593317
  var valid_593318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593318 = validateParameter(valid_593318, JString, required = false,
                                 default = nil)
  if valid_593318 != nil:
    section.add "X-Amz-SignedHeaders", valid_593318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593319: Call_DeleteTags_593307; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags for a resource
  ## 
  let valid = call_593319.validator(path, query, header, formData, body)
  let scheme = call_593319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593319.url(scheme.get, call_593319.host, call_593319.base,
                         call_593319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593319, url, valid)

proc call*(call_593320: Call_DeleteTags_593307; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## deleteTags
  ## Removes tags for a resource
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  ##   tagKeys: JArray (required)
  ##          : Placeholder documentation for __listOf__string
  var path_593321 = newJObject()
  var query_593322 = newJObject()
  add(path_593321, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_593322.add "tagKeys", tagKeys
  result = call_593320.call(path_593321, query_593322, nil, nil, nil)

var deleteTags* = Call_DeleteTags_593307(name: "deleteTags",
                                      meth: HttpMethod.HttpDelete,
                                      host: "medialive.amazonaws.com", route: "/prod/tags/{resource-arn}#tagKeys",
                                      validator: validate_DeleteTags_593308,
                                      base: "/", url: url_DeleteTags_593309,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOffering_593323 = ref object of OpenApiRestCall_592364
proc url_DescribeOffering_593325(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "offeringId" in path, "`offeringId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/offerings/"),
               (kind: VariableSegment, value: "offeringId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeOffering_593324(path: JsonNode; query: JsonNode;
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
  var valid_593326 = path.getOrDefault("offeringId")
  valid_593326 = validateParameter(valid_593326, JString, required = true,
                                 default = nil)
  if valid_593326 != nil:
    section.add "offeringId", valid_593326
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
  var valid_593327 = header.getOrDefault("X-Amz-Signature")
  valid_593327 = validateParameter(valid_593327, JString, required = false,
                                 default = nil)
  if valid_593327 != nil:
    section.add "X-Amz-Signature", valid_593327
  var valid_593328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593328 = validateParameter(valid_593328, JString, required = false,
                                 default = nil)
  if valid_593328 != nil:
    section.add "X-Amz-Content-Sha256", valid_593328
  var valid_593329 = header.getOrDefault("X-Amz-Date")
  valid_593329 = validateParameter(valid_593329, JString, required = false,
                                 default = nil)
  if valid_593329 != nil:
    section.add "X-Amz-Date", valid_593329
  var valid_593330 = header.getOrDefault("X-Amz-Credential")
  valid_593330 = validateParameter(valid_593330, JString, required = false,
                                 default = nil)
  if valid_593330 != nil:
    section.add "X-Amz-Credential", valid_593330
  var valid_593331 = header.getOrDefault("X-Amz-Security-Token")
  valid_593331 = validateParameter(valid_593331, JString, required = false,
                                 default = nil)
  if valid_593331 != nil:
    section.add "X-Amz-Security-Token", valid_593331
  var valid_593332 = header.getOrDefault("X-Amz-Algorithm")
  valid_593332 = validateParameter(valid_593332, JString, required = false,
                                 default = nil)
  if valid_593332 != nil:
    section.add "X-Amz-Algorithm", valid_593332
  var valid_593333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593333 = validateParameter(valid_593333, JString, required = false,
                                 default = nil)
  if valid_593333 != nil:
    section.add "X-Amz-SignedHeaders", valid_593333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593334: Call_DescribeOffering_593323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get details for an offering.
  ## 
  let valid = call_593334.validator(path, query, header, formData, body)
  let scheme = call_593334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593334.url(scheme.get, call_593334.host, call_593334.base,
                         call_593334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593334, url, valid)

proc call*(call_593335: Call_DescribeOffering_593323; offeringId: string): Recallable =
  ## describeOffering
  ## Get details for an offering.
  ##   offeringId: string (required)
  ##             : Placeholder documentation for __string
  var path_593336 = newJObject()
  add(path_593336, "offeringId", newJString(offeringId))
  result = call_593335.call(path_593336, nil, nil, nil, nil)

var describeOffering* = Call_DescribeOffering_593323(name: "describeOffering",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/offerings/{offeringId}", validator: validate_DescribeOffering_593324,
    base: "/", url: url_DescribeOffering_593325,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferings_593337 = ref object of OpenApiRestCall_592364
proc url_ListOfferings_593339(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListOfferings_593338(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## List offerings available for purchase.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   specialFeature: JString
  ##                 : Placeholder documentation for __string
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   channelClass: JString
  ##               : Placeholder documentation for __string
  ##   NextToken: JString
  ##            : Pagination token
  ##   videoQuality: JString
  ##               : Placeholder documentation for __string
  ##   maximumFramerate: JString
  ##                   : Placeholder documentation for __string
  ##   maximumBitrate: JString
  ##                 : Placeholder documentation for __string
  ##   resourceType: JString
  ##               : Placeholder documentation for __string
  ##   channelConfiguration: JString
  ##                       : Placeholder documentation for __string
  ##   codec: JString
  ##        : Placeholder documentation for __string
  ##   resolution: JString
  ##             : Placeholder documentation for __string
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  section = newJObject()
  var valid_593340 = query.getOrDefault("specialFeature")
  valid_593340 = validateParameter(valid_593340, JString, required = false,
                                 default = nil)
  if valid_593340 != nil:
    section.add "specialFeature", valid_593340
  var valid_593341 = query.getOrDefault("nextToken")
  valid_593341 = validateParameter(valid_593341, JString, required = false,
                                 default = nil)
  if valid_593341 != nil:
    section.add "nextToken", valid_593341
  var valid_593342 = query.getOrDefault("MaxResults")
  valid_593342 = validateParameter(valid_593342, JString, required = false,
                                 default = nil)
  if valid_593342 != nil:
    section.add "MaxResults", valid_593342
  var valid_593343 = query.getOrDefault("channelClass")
  valid_593343 = validateParameter(valid_593343, JString, required = false,
                                 default = nil)
  if valid_593343 != nil:
    section.add "channelClass", valid_593343
  var valid_593344 = query.getOrDefault("NextToken")
  valid_593344 = validateParameter(valid_593344, JString, required = false,
                                 default = nil)
  if valid_593344 != nil:
    section.add "NextToken", valid_593344
  var valid_593345 = query.getOrDefault("videoQuality")
  valid_593345 = validateParameter(valid_593345, JString, required = false,
                                 default = nil)
  if valid_593345 != nil:
    section.add "videoQuality", valid_593345
  var valid_593346 = query.getOrDefault("maximumFramerate")
  valid_593346 = validateParameter(valid_593346, JString, required = false,
                                 default = nil)
  if valid_593346 != nil:
    section.add "maximumFramerate", valid_593346
  var valid_593347 = query.getOrDefault("maximumBitrate")
  valid_593347 = validateParameter(valid_593347, JString, required = false,
                                 default = nil)
  if valid_593347 != nil:
    section.add "maximumBitrate", valid_593347
  var valid_593348 = query.getOrDefault("resourceType")
  valid_593348 = validateParameter(valid_593348, JString, required = false,
                                 default = nil)
  if valid_593348 != nil:
    section.add "resourceType", valid_593348
  var valid_593349 = query.getOrDefault("channelConfiguration")
  valid_593349 = validateParameter(valid_593349, JString, required = false,
                                 default = nil)
  if valid_593349 != nil:
    section.add "channelConfiguration", valid_593349
  var valid_593350 = query.getOrDefault("codec")
  valid_593350 = validateParameter(valid_593350, JString, required = false,
                                 default = nil)
  if valid_593350 != nil:
    section.add "codec", valid_593350
  var valid_593351 = query.getOrDefault("resolution")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "resolution", valid_593351
  var valid_593352 = query.getOrDefault("maxResults")
  valid_593352 = validateParameter(valid_593352, JInt, required = false, default = nil)
  if valid_593352 != nil:
    section.add "maxResults", valid_593352
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
  var valid_593353 = header.getOrDefault("X-Amz-Signature")
  valid_593353 = validateParameter(valid_593353, JString, required = false,
                                 default = nil)
  if valid_593353 != nil:
    section.add "X-Amz-Signature", valid_593353
  var valid_593354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593354 = validateParameter(valid_593354, JString, required = false,
                                 default = nil)
  if valid_593354 != nil:
    section.add "X-Amz-Content-Sha256", valid_593354
  var valid_593355 = header.getOrDefault("X-Amz-Date")
  valid_593355 = validateParameter(valid_593355, JString, required = false,
                                 default = nil)
  if valid_593355 != nil:
    section.add "X-Amz-Date", valid_593355
  var valid_593356 = header.getOrDefault("X-Amz-Credential")
  valid_593356 = validateParameter(valid_593356, JString, required = false,
                                 default = nil)
  if valid_593356 != nil:
    section.add "X-Amz-Credential", valid_593356
  var valid_593357 = header.getOrDefault("X-Amz-Security-Token")
  valid_593357 = validateParameter(valid_593357, JString, required = false,
                                 default = nil)
  if valid_593357 != nil:
    section.add "X-Amz-Security-Token", valid_593357
  var valid_593358 = header.getOrDefault("X-Amz-Algorithm")
  valid_593358 = validateParameter(valid_593358, JString, required = false,
                                 default = nil)
  if valid_593358 != nil:
    section.add "X-Amz-Algorithm", valid_593358
  var valid_593359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593359 = validateParameter(valid_593359, JString, required = false,
                                 default = nil)
  if valid_593359 != nil:
    section.add "X-Amz-SignedHeaders", valid_593359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593360: Call_ListOfferings_593337; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List offerings available for purchase.
  ## 
  let valid = call_593360.validator(path, query, header, formData, body)
  let scheme = call_593360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593360.url(scheme.get, call_593360.host, call_593360.base,
                         call_593360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593360, url, valid)

proc call*(call_593361: Call_ListOfferings_593337; specialFeature: string = "";
          nextToken: string = ""; MaxResults: string = ""; channelClass: string = "";
          NextToken: string = ""; videoQuality: string = "";
          maximumFramerate: string = ""; maximumBitrate: string = "";
          resourceType: string = ""; channelConfiguration: string = "";
          codec: string = ""; resolution: string = ""; maxResults: int = 0): Recallable =
  ## listOfferings
  ## List offerings available for purchase.
  ##   specialFeature: string
  ##                 : Placeholder documentation for __string
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  ##   channelClass: string
  ##               : Placeholder documentation for __string
  ##   NextToken: string
  ##            : Pagination token
  ##   videoQuality: string
  ##               : Placeholder documentation for __string
  ##   maximumFramerate: string
  ##                   : Placeholder documentation for __string
  ##   maximumBitrate: string
  ##                 : Placeholder documentation for __string
  ##   resourceType: string
  ##               : Placeholder documentation for __string
  ##   channelConfiguration: string
  ##                       : Placeholder documentation for __string
  ##   codec: string
  ##        : Placeholder documentation for __string
  ##   resolution: string
  ##             : Placeholder documentation for __string
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  var query_593362 = newJObject()
  add(query_593362, "specialFeature", newJString(specialFeature))
  add(query_593362, "nextToken", newJString(nextToken))
  add(query_593362, "MaxResults", newJString(MaxResults))
  add(query_593362, "channelClass", newJString(channelClass))
  add(query_593362, "NextToken", newJString(NextToken))
  add(query_593362, "videoQuality", newJString(videoQuality))
  add(query_593362, "maximumFramerate", newJString(maximumFramerate))
  add(query_593362, "maximumBitrate", newJString(maximumBitrate))
  add(query_593362, "resourceType", newJString(resourceType))
  add(query_593362, "channelConfiguration", newJString(channelConfiguration))
  add(query_593362, "codec", newJString(codec))
  add(query_593362, "resolution", newJString(resolution))
  add(query_593362, "maxResults", newJInt(maxResults))
  result = call_593361.call(nil, query_593362, nil, nil, nil)

var listOfferings* = Call_ListOfferings_593337(name: "listOfferings",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/offerings", validator: validate_ListOfferings_593338, base: "/",
    url: url_ListOfferings_593339, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReservations_593363 = ref object of OpenApiRestCall_592364
proc url_ListReservations_593365(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListReservations_593364(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## List purchased reservations.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   specialFeature: JString
  ##                 : Placeholder documentation for __string
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   channelClass: JString
  ##               : Placeholder documentation for __string
  ##   NextToken: JString
  ##            : Pagination token
  ##   videoQuality: JString
  ##               : Placeholder documentation for __string
  ##   maximumFramerate: JString
  ##                   : Placeholder documentation for __string
  ##   maximumBitrate: JString
  ##                 : Placeholder documentation for __string
  ##   resourceType: JString
  ##               : Placeholder documentation for __string
  ##   codec: JString
  ##        : Placeholder documentation for __string
  ##   resolution: JString
  ##             : Placeholder documentation for __string
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  section = newJObject()
  var valid_593366 = query.getOrDefault("specialFeature")
  valid_593366 = validateParameter(valid_593366, JString, required = false,
                                 default = nil)
  if valid_593366 != nil:
    section.add "specialFeature", valid_593366
  var valid_593367 = query.getOrDefault("nextToken")
  valid_593367 = validateParameter(valid_593367, JString, required = false,
                                 default = nil)
  if valid_593367 != nil:
    section.add "nextToken", valid_593367
  var valid_593368 = query.getOrDefault("MaxResults")
  valid_593368 = validateParameter(valid_593368, JString, required = false,
                                 default = nil)
  if valid_593368 != nil:
    section.add "MaxResults", valid_593368
  var valid_593369 = query.getOrDefault("channelClass")
  valid_593369 = validateParameter(valid_593369, JString, required = false,
                                 default = nil)
  if valid_593369 != nil:
    section.add "channelClass", valid_593369
  var valid_593370 = query.getOrDefault("NextToken")
  valid_593370 = validateParameter(valid_593370, JString, required = false,
                                 default = nil)
  if valid_593370 != nil:
    section.add "NextToken", valid_593370
  var valid_593371 = query.getOrDefault("videoQuality")
  valid_593371 = validateParameter(valid_593371, JString, required = false,
                                 default = nil)
  if valid_593371 != nil:
    section.add "videoQuality", valid_593371
  var valid_593372 = query.getOrDefault("maximumFramerate")
  valid_593372 = validateParameter(valid_593372, JString, required = false,
                                 default = nil)
  if valid_593372 != nil:
    section.add "maximumFramerate", valid_593372
  var valid_593373 = query.getOrDefault("maximumBitrate")
  valid_593373 = validateParameter(valid_593373, JString, required = false,
                                 default = nil)
  if valid_593373 != nil:
    section.add "maximumBitrate", valid_593373
  var valid_593374 = query.getOrDefault("resourceType")
  valid_593374 = validateParameter(valid_593374, JString, required = false,
                                 default = nil)
  if valid_593374 != nil:
    section.add "resourceType", valid_593374
  var valid_593375 = query.getOrDefault("codec")
  valid_593375 = validateParameter(valid_593375, JString, required = false,
                                 default = nil)
  if valid_593375 != nil:
    section.add "codec", valid_593375
  var valid_593376 = query.getOrDefault("resolution")
  valid_593376 = validateParameter(valid_593376, JString, required = false,
                                 default = nil)
  if valid_593376 != nil:
    section.add "resolution", valid_593376
  var valid_593377 = query.getOrDefault("maxResults")
  valid_593377 = validateParameter(valid_593377, JInt, required = false, default = nil)
  if valid_593377 != nil:
    section.add "maxResults", valid_593377
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
  var valid_593378 = header.getOrDefault("X-Amz-Signature")
  valid_593378 = validateParameter(valid_593378, JString, required = false,
                                 default = nil)
  if valid_593378 != nil:
    section.add "X-Amz-Signature", valid_593378
  var valid_593379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593379 = validateParameter(valid_593379, JString, required = false,
                                 default = nil)
  if valid_593379 != nil:
    section.add "X-Amz-Content-Sha256", valid_593379
  var valid_593380 = header.getOrDefault("X-Amz-Date")
  valid_593380 = validateParameter(valid_593380, JString, required = false,
                                 default = nil)
  if valid_593380 != nil:
    section.add "X-Amz-Date", valid_593380
  var valid_593381 = header.getOrDefault("X-Amz-Credential")
  valid_593381 = validateParameter(valid_593381, JString, required = false,
                                 default = nil)
  if valid_593381 != nil:
    section.add "X-Amz-Credential", valid_593381
  var valid_593382 = header.getOrDefault("X-Amz-Security-Token")
  valid_593382 = validateParameter(valid_593382, JString, required = false,
                                 default = nil)
  if valid_593382 != nil:
    section.add "X-Amz-Security-Token", valid_593382
  var valid_593383 = header.getOrDefault("X-Amz-Algorithm")
  valid_593383 = validateParameter(valid_593383, JString, required = false,
                                 default = nil)
  if valid_593383 != nil:
    section.add "X-Amz-Algorithm", valid_593383
  var valid_593384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593384 = validateParameter(valid_593384, JString, required = false,
                                 default = nil)
  if valid_593384 != nil:
    section.add "X-Amz-SignedHeaders", valid_593384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593385: Call_ListReservations_593363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List purchased reservations.
  ## 
  let valid = call_593385.validator(path, query, header, formData, body)
  let scheme = call_593385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593385.url(scheme.get, call_593385.host, call_593385.base,
                         call_593385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593385, url, valid)

proc call*(call_593386: Call_ListReservations_593363; specialFeature: string = "";
          nextToken: string = ""; MaxResults: string = ""; channelClass: string = "";
          NextToken: string = ""; videoQuality: string = "";
          maximumFramerate: string = ""; maximumBitrate: string = "";
          resourceType: string = ""; codec: string = ""; resolution: string = "";
          maxResults: int = 0): Recallable =
  ## listReservations
  ## List purchased reservations.
  ##   specialFeature: string
  ##                 : Placeholder documentation for __string
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  ##   channelClass: string
  ##               : Placeholder documentation for __string
  ##   NextToken: string
  ##            : Pagination token
  ##   videoQuality: string
  ##               : Placeholder documentation for __string
  ##   maximumFramerate: string
  ##                   : Placeholder documentation for __string
  ##   maximumBitrate: string
  ##                 : Placeholder documentation for __string
  ##   resourceType: string
  ##               : Placeholder documentation for __string
  ##   codec: string
  ##        : Placeholder documentation for __string
  ##   resolution: string
  ##             : Placeholder documentation for __string
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  var query_593387 = newJObject()
  add(query_593387, "specialFeature", newJString(specialFeature))
  add(query_593387, "nextToken", newJString(nextToken))
  add(query_593387, "MaxResults", newJString(MaxResults))
  add(query_593387, "channelClass", newJString(channelClass))
  add(query_593387, "NextToken", newJString(NextToken))
  add(query_593387, "videoQuality", newJString(videoQuality))
  add(query_593387, "maximumFramerate", newJString(maximumFramerate))
  add(query_593387, "maximumBitrate", newJString(maximumBitrate))
  add(query_593387, "resourceType", newJString(resourceType))
  add(query_593387, "codec", newJString(codec))
  add(query_593387, "resolution", newJString(resolution))
  add(query_593387, "maxResults", newJInt(maxResults))
  result = call_593386.call(nil, query_593387, nil, nil, nil)

var listReservations* = Call_ListReservations_593363(name: "listReservations",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/reservations", validator: validate_ListReservations_593364,
    base: "/", url: url_ListReservations_593365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseOffering_593388 = ref object of OpenApiRestCall_592364
proc url_PurchaseOffering_593390(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "offeringId" in path, "`offeringId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/offerings/"),
               (kind: VariableSegment, value: "offeringId"),
               (kind: ConstantSegment, value: "/purchase")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PurchaseOffering_593389(path: JsonNode; query: JsonNode;
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
  var valid_593391 = path.getOrDefault("offeringId")
  valid_593391 = validateParameter(valid_593391, JString, required = true,
                                 default = nil)
  if valid_593391 != nil:
    section.add "offeringId", valid_593391
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
  var valid_593392 = header.getOrDefault("X-Amz-Signature")
  valid_593392 = validateParameter(valid_593392, JString, required = false,
                                 default = nil)
  if valid_593392 != nil:
    section.add "X-Amz-Signature", valid_593392
  var valid_593393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593393 = validateParameter(valid_593393, JString, required = false,
                                 default = nil)
  if valid_593393 != nil:
    section.add "X-Amz-Content-Sha256", valid_593393
  var valid_593394 = header.getOrDefault("X-Amz-Date")
  valid_593394 = validateParameter(valid_593394, JString, required = false,
                                 default = nil)
  if valid_593394 != nil:
    section.add "X-Amz-Date", valid_593394
  var valid_593395 = header.getOrDefault("X-Amz-Credential")
  valid_593395 = validateParameter(valid_593395, JString, required = false,
                                 default = nil)
  if valid_593395 != nil:
    section.add "X-Amz-Credential", valid_593395
  var valid_593396 = header.getOrDefault("X-Amz-Security-Token")
  valid_593396 = validateParameter(valid_593396, JString, required = false,
                                 default = nil)
  if valid_593396 != nil:
    section.add "X-Amz-Security-Token", valid_593396
  var valid_593397 = header.getOrDefault("X-Amz-Algorithm")
  valid_593397 = validateParameter(valid_593397, JString, required = false,
                                 default = nil)
  if valid_593397 != nil:
    section.add "X-Amz-Algorithm", valid_593397
  var valid_593398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593398 = validateParameter(valid_593398, JString, required = false,
                                 default = nil)
  if valid_593398 != nil:
    section.add "X-Amz-SignedHeaders", valid_593398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593400: Call_PurchaseOffering_593388; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Purchase an offering and create a reservation.
  ## 
  let valid = call_593400.validator(path, query, header, formData, body)
  let scheme = call_593400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593400.url(scheme.get, call_593400.host, call_593400.base,
                         call_593400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593400, url, valid)

proc call*(call_593401: Call_PurchaseOffering_593388; body: JsonNode;
          offeringId: string): Recallable =
  ## purchaseOffering
  ## Purchase an offering and create a reservation.
  ##   body: JObject (required)
  ##   offeringId: string (required)
  ##             : Placeholder documentation for __string
  var path_593402 = newJObject()
  var body_593403 = newJObject()
  if body != nil:
    body_593403 = body
  add(path_593402, "offeringId", newJString(offeringId))
  result = call_593401.call(path_593402, nil, nil, nil, body_593403)

var purchaseOffering* = Call_PurchaseOffering_593388(name: "purchaseOffering",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/offerings/{offeringId}/purchase",
    validator: validate_PurchaseOffering_593389, base: "/",
    url: url_PurchaseOffering_593390, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartChannel_593404 = ref object of OpenApiRestCall_592364
proc url_StartChannel_593406(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId"),
               (kind: ConstantSegment, value: "/start")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_StartChannel_593405(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593407 = path.getOrDefault("channelId")
  valid_593407 = validateParameter(valid_593407, JString, required = true,
                                 default = nil)
  if valid_593407 != nil:
    section.add "channelId", valid_593407
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
  var valid_593408 = header.getOrDefault("X-Amz-Signature")
  valid_593408 = validateParameter(valid_593408, JString, required = false,
                                 default = nil)
  if valid_593408 != nil:
    section.add "X-Amz-Signature", valid_593408
  var valid_593409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593409 = validateParameter(valid_593409, JString, required = false,
                                 default = nil)
  if valid_593409 != nil:
    section.add "X-Amz-Content-Sha256", valid_593409
  var valid_593410 = header.getOrDefault("X-Amz-Date")
  valid_593410 = validateParameter(valid_593410, JString, required = false,
                                 default = nil)
  if valid_593410 != nil:
    section.add "X-Amz-Date", valid_593410
  var valid_593411 = header.getOrDefault("X-Amz-Credential")
  valid_593411 = validateParameter(valid_593411, JString, required = false,
                                 default = nil)
  if valid_593411 != nil:
    section.add "X-Amz-Credential", valid_593411
  var valid_593412 = header.getOrDefault("X-Amz-Security-Token")
  valid_593412 = validateParameter(valid_593412, JString, required = false,
                                 default = nil)
  if valid_593412 != nil:
    section.add "X-Amz-Security-Token", valid_593412
  var valid_593413 = header.getOrDefault("X-Amz-Algorithm")
  valid_593413 = validateParameter(valid_593413, JString, required = false,
                                 default = nil)
  if valid_593413 != nil:
    section.add "X-Amz-Algorithm", valid_593413
  var valid_593414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593414 = validateParameter(valid_593414, JString, required = false,
                                 default = nil)
  if valid_593414 != nil:
    section.add "X-Amz-SignedHeaders", valid_593414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593415: Call_StartChannel_593404; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an existing channel
  ## 
  let valid = call_593415.validator(path, query, header, formData, body)
  let scheme = call_593415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593415.url(scheme.get, call_593415.host, call_593415.base,
                         call_593415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593415, url, valid)

proc call*(call_593416: Call_StartChannel_593404; channelId: string): Recallable =
  ## startChannel
  ## Starts an existing channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_593417 = newJObject()
  add(path_593417, "channelId", newJString(channelId))
  result = call_593416.call(path_593417, nil, nil, nil, nil)

var startChannel* = Call_StartChannel_593404(name: "startChannel",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/start", validator: validate_StartChannel_593405,
    base: "/", url: url_StartChannel_593406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopChannel_593418 = ref object of OpenApiRestCall_592364
proc url_StopChannel_593420(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId"),
               (kind: ConstantSegment, value: "/stop")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_StopChannel_593419(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593421 = path.getOrDefault("channelId")
  valid_593421 = validateParameter(valid_593421, JString, required = true,
                                 default = nil)
  if valid_593421 != nil:
    section.add "channelId", valid_593421
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
  var valid_593422 = header.getOrDefault("X-Amz-Signature")
  valid_593422 = validateParameter(valid_593422, JString, required = false,
                                 default = nil)
  if valid_593422 != nil:
    section.add "X-Amz-Signature", valid_593422
  var valid_593423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593423 = validateParameter(valid_593423, JString, required = false,
                                 default = nil)
  if valid_593423 != nil:
    section.add "X-Amz-Content-Sha256", valid_593423
  var valid_593424 = header.getOrDefault("X-Amz-Date")
  valid_593424 = validateParameter(valid_593424, JString, required = false,
                                 default = nil)
  if valid_593424 != nil:
    section.add "X-Amz-Date", valid_593424
  var valid_593425 = header.getOrDefault("X-Amz-Credential")
  valid_593425 = validateParameter(valid_593425, JString, required = false,
                                 default = nil)
  if valid_593425 != nil:
    section.add "X-Amz-Credential", valid_593425
  var valid_593426 = header.getOrDefault("X-Amz-Security-Token")
  valid_593426 = validateParameter(valid_593426, JString, required = false,
                                 default = nil)
  if valid_593426 != nil:
    section.add "X-Amz-Security-Token", valid_593426
  var valid_593427 = header.getOrDefault("X-Amz-Algorithm")
  valid_593427 = validateParameter(valid_593427, JString, required = false,
                                 default = nil)
  if valid_593427 != nil:
    section.add "X-Amz-Algorithm", valid_593427
  var valid_593428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593428 = validateParameter(valid_593428, JString, required = false,
                                 default = nil)
  if valid_593428 != nil:
    section.add "X-Amz-SignedHeaders", valid_593428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593429: Call_StopChannel_593418; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running channel
  ## 
  let valid = call_593429.validator(path, query, header, formData, body)
  let scheme = call_593429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593429.url(scheme.get, call_593429.host, call_593429.base,
                         call_593429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593429, url, valid)

proc call*(call_593430: Call_StopChannel_593418; channelId: string): Recallable =
  ## stopChannel
  ## Stops a running channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_593431 = newJObject()
  add(path_593431, "channelId", newJString(channelId))
  result = call_593430.call(path_593431, nil, nil, nil, nil)

var stopChannel* = Call_StopChannel_593418(name: "stopChannel",
                                        meth: HttpMethod.HttpPost,
                                        host: "medialive.amazonaws.com", route: "/prod/channels/{channelId}/stop",
                                        validator: validate_StopChannel_593419,
                                        base: "/", url: url_StopChannel_593420,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannelClass_593432 = ref object of OpenApiRestCall_592364
proc url_UpdateChannelClass_593434(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId"),
               (kind: ConstantSegment, value: "/channelClass")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateChannelClass_593433(path: JsonNode; query: JsonNode;
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
  var valid_593435 = path.getOrDefault("channelId")
  valid_593435 = validateParameter(valid_593435, JString, required = true,
                                 default = nil)
  if valid_593435 != nil:
    section.add "channelId", valid_593435
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
  var valid_593436 = header.getOrDefault("X-Amz-Signature")
  valid_593436 = validateParameter(valid_593436, JString, required = false,
                                 default = nil)
  if valid_593436 != nil:
    section.add "X-Amz-Signature", valid_593436
  var valid_593437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593437 = validateParameter(valid_593437, JString, required = false,
                                 default = nil)
  if valid_593437 != nil:
    section.add "X-Amz-Content-Sha256", valid_593437
  var valid_593438 = header.getOrDefault("X-Amz-Date")
  valid_593438 = validateParameter(valid_593438, JString, required = false,
                                 default = nil)
  if valid_593438 != nil:
    section.add "X-Amz-Date", valid_593438
  var valid_593439 = header.getOrDefault("X-Amz-Credential")
  valid_593439 = validateParameter(valid_593439, JString, required = false,
                                 default = nil)
  if valid_593439 != nil:
    section.add "X-Amz-Credential", valid_593439
  var valid_593440 = header.getOrDefault("X-Amz-Security-Token")
  valid_593440 = validateParameter(valid_593440, JString, required = false,
                                 default = nil)
  if valid_593440 != nil:
    section.add "X-Amz-Security-Token", valid_593440
  var valid_593441 = header.getOrDefault("X-Amz-Algorithm")
  valid_593441 = validateParameter(valid_593441, JString, required = false,
                                 default = nil)
  if valid_593441 != nil:
    section.add "X-Amz-Algorithm", valid_593441
  var valid_593442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593442 = validateParameter(valid_593442, JString, required = false,
                                 default = nil)
  if valid_593442 != nil:
    section.add "X-Amz-SignedHeaders", valid_593442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593444: Call_UpdateChannelClass_593432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the class of the channel.
  ## 
  let valid = call_593444.validator(path, query, header, formData, body)
  let scheme = call_593444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593444.url(scheme.get, call_593444.host, call_593444.base,
                         call_593444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593444, url, valid)

proc call*(call_593445: Call_UpdateChannelClass_593432; channelId: string;
          body: JsonNode): Recallable =
  ## updateChannelClass
  ## Changes the class of the channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_593446 = newJObject()
  var body_593447 = newJObject()
  add(path_593446, "channelId", newJString(channelId))
  if body != nil:
    body_593447 = body
  result = call_593445.call(path_593446, nil, nil, nil, body_593447)

var updateChannelClass* = Call_UpdateChannelClass_593432(
    name: "updateChannelClass", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/channelClass",
    validator: validate_UpdateChannelClass_593433, base: "/",
    url: url_UpdateChannelClass_593434, schemes: {Scheme.Https, Scheme.Http})
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
