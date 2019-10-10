
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Lex Runtime Service
## version: 2016-11-28
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon Lex provides both build and runtime endpoints. Each endpoint provides a set of operations (API). Your conversational bot uses the runtime API to understand user utterances (user input text or voice). For example, suppose a user says "I want pizza", your bot sends this input to Amazon Lex using the runtime API. Amazon Lex recognizes that the user request is for the OrderPizza intent (one of the intents defined in the bot). Then Amazon Lex engages in user conversation on behalf of the bot to elicit required information (slot values, such as pizza size and crust type), and then performs fulfillment activity (that you configured when you created the bot). You use the build-time API to create and manage your Amazon Lex bot. For a list of build-time operations, see the build-time API, . 
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/lex/
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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "runtime.lex.ap-northeast-1.amazonaws.com", "ap-southeast-1": "runtime.lex.ap-southeast-1.amazonaws.com",
                           "us-west-2": "runtime.lex.us-west-2.amazonaws.com",
                           "eu-west-2": "runtime.lex.eu-west-2.amazonaws.com", "ap-northeast-3": "runtime.lex.ap-northeast-3.amazonaws.com", "eu-central-1": "runtime.lex.eu-central-1.amazonaws.com",
                           "us-east-2": "runtime.lex.us-east-2.amazonaws.com",
                           "us-east-1": "runtime.lex.us-east-1.amazonaws.com", "cn-northwest-1": "runtime.lex.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "runtime.lex.ap-south-1.amazonaws.com", "eu-north-1": "runtime.lex.eu-north-1.amazonaws.com", "ap-northeast-2": "runtime.lex.ap-northeast-2.amazonaws.com",
                           "us-west-1": "runtime.lex.us-west-1.amazonaws.com", "us-gov-east-1": "runtime.lex.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "runtime.lex.eu-west-3.amazonaws.com", "cn-north-1": "runtime.lex.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "runtime.lex.sa-east-1.amazonaws.com",
                           "eu-west-1": "runtime.lex.eu-west-1.amazonaws.com", "us-gov-west-1": "runtime.lex.us-gov-west-1.amazonaws.com", "ap-southeast-2": "runtime.lex.ap-southeast-2.amazonaws.com", "ca-central-1": "runtime.lex.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "runtime.lex.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "runtime.lex.ap-southeast-1.amazonaws.com",
      "us-west-2": "runtime.lex.us-west-2.amazonaws.com",
      "eu-west-2": "runtime.lex.eu-west-2.amazonaws.com",
      "ap-northeast-3": "runtime.lex.ap-northeast-3.amazonaws.com",
      "eu-central-1": "runtime.lex.eu-central-1.amazonaws.com",
      "us-east-2": "runtime.lex.us-east-2.amazonaws.com",
      "us-east-1": "runtime.lex.us-east-1.amazonaws.com",
      "cn-northwest-1": "runtime.lex.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "runtime.lex.ap-south-1.amazonaws.com",
      "eu-north-1": "runtime.lex.eu-north-1.amazonaws.com",
      "ap-northeast-2": "runtime.lex.ap-northeast-2.amazonaws.com",
      "us-west-1": "runtime.lex.us-west-1.amazonaws.com",
      "us-gov-east-1": "runtime.lex.us-gov-east-1.amazonaws.com",
      "eu-west-3": "runtime.lex.eu-west-3.amazonaws.com",
      "cn-north-1": "runtime.lex.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "runtime.lex.sa-east-1.amazonaws.com",
      "eu-west-1": "runtime.lex.eu-west-1.amazonaws.com",
      "us-gov-west-1": "runtime.lex.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "runtime.lex.ap-southeast-2.amazonaws.com",
      "ca-central-1": "runtime.lex.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "runtime.lex"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PutSession_603075 = ref object of OpenApiRestCall_602466
proc url_PutSession_603077(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "botName" in path, "`botName` is a required path parameter"
  assert "botAlias" in path, "`botAlias` is a required path parameter"
  assert "userId" in path, "`userId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bot/"),
               (kind: VariableSegment, value: "botName"),
               (kind: ConstantSegment, value: "/alias/"),
               (kind: VariableSegment, value: "botAlias"),
               (kind: ConstantSegment, value: "/user/"),
               (kind: VariableSegment, value: "userId"),
               (kind: ConstantSegment, value: "/session")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutSession_603076(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new session or modifies an existing session with an Amazon Lex bot. Use this operation to enable your application to set the state of the bot.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/how-session-api.html">Managing Sessions</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botName: JString (required)
  ##          : The name of the bot that contains the session data.
  ##   botAlias: JString (required)
  ##           : The alias in use for the bot that contains the session data.
  ##   userId: JString (required)
  ##         : The ID of the client application user. Amazon Lex uses this to identify a user's conversation with your bot. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botName` field"
  var valid_603078 = path.getOrDefault("botName")
  valid_603078 = validateParameter(valid_603078, JString, required = true,
                                 default = nil)
  if valid_603078 != nil:
    section.add "botName", valid_603078
  var valid_603079 = path.getOrDefault("botAlias")
  valid_603079 = validateParameter(valid_603079, JString, required = true,
                                 default = nil)
  if valid_603079 != nil:
    section.add "botAlias", valid_603079
  var valid_603080 = path.getOrDefault("userId")
  valid_603080 = validateParameter(valid_603080, JString, required = true,
                                 default = nil)
  if valid_603080 != nil:
    section.add "userId", valid_603080
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
  ##   Accept: JString
  ##         : <p>The message that Amazon Lex returns in the response can be either text or speech based depending on the value of this field.</p> <ul> <li> <p>If the value is <code>text/plain; charset=utf-8</code>, Amazon Lex returns text in the response.</p> </li> <li> <p>If the value begins with <code>audio/</code>, Amazon Lex returns speech in the response. Amazon Lex uses Amazon Polly to generate the speech in the configuration that you specify. For example, if you specify <code>audio/mpeg</code> as the value, Amazon Lex returns speech in the MPEG format.</p> </li> <li> <p>If the value is <code>audio/pcm</code>, the speech is returned as <code>audio/pcm</code> in 16-bit, little endian format.</p> </li> <li> <p>The following are the accepted values:</p> <ul> <li> <p> <code>audio/mpeg</code> </p> </li> <li> <p> <code>audio/ogg</code> </p> </li> <li> <p> <code>audio/pcm</code> </p> </li> <li> <p> <code>audio/*</code> (defaults to mpeg)</p> </li> <li> <p> <code>text/plain; charset=utf-8</code> </p> </li> </ul> </li> </ul>
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603081 = header.getOrDefault("X-Amz-Date")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Date", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Security-Token")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Security-Token", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Content-Sha256", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Algorithm")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Algorithm", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Signature")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Signature", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-SignedHeaders", valid_603086
  var valid_603087 = header.getOrDefault("Accept")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "Accept", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Credential")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Credential", valid_603088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603090: Call_PutSession_603075; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new session or modifies an existing session with an Amazon Lex bot. Use this operation to enable your application to set the state of the bot.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/how-session-api.html">Managing Sessions</a>.</p>
  ## 
  let valid = call_603090.validator(path, query, header, formData, body)
  let scheme = call_603090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603090.url(scheme.get, call_603090.host, call_603090.base,
                         call_603090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603090, url, valid)

proc call*(call_603091: Call_PutSession_603075; botName: string; body: JsonNode;
          botAlias: string; userId: string): Recallable =
  ## putSession
  ## <p>Creates a new session or modifies an existing session with an Amazon Lex bot. Use this operation to enable your application to set the state of the bot.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/how-session-api.html">Managing Sessions</a>.</p>
  ##   botName: string (required)
  ##          : The name of the bot that contains the session data.
  ##   body: JObject (required)
  ##   botAlias: string (required)
  ##           : The alias in use for the bot that contains the session data.
  ##   userId: string (required)
  ##         : The ID of the client application user. Amazon Lex uses this to identify a user's conversation with your bot. 
  var path_603092 = newJObject()
  var body_603093 = newJObject()
  add(path_603092, "botName", newJString(botName))
  if body != nil:
    body_603093 = body
  add(path_603092, "botAlias", newJString(botAlias))
  add(path_603092, "userId", newJString(userId))
  result = call_603091.call(path_603092, nil, nil, nil, body_603093)

var putSession* = Call_PutSession_603075(name: "putSession",
                                      meth: HttpMethod.HttpPost,
                                      host: "runtime.lex.amazonaws.com", route: "/bot/{botName}/alias/{botAlias}/user/{userId}/session",
                                      validator: validate_PutSession_603076,
                                      base: "/", url: url_PutSession_603077,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSession_602803 = ref object of OpenApiRestCall_602466
proc url_GetSession_602805(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "botName" in path, "`botName` is a required path parameter"
  assert "botAlias" in path, "`botAlias` is a required path parameter"
  assert "userId" in path, "`userId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bot/"),
               (kind: VariableSegment, value: "botName"),
               (kind: ConstantSegment, value: "/alias/"),
               (kind: VariableSegment, value: "botAlias"),
               (kind: ConstantSegment, value: "/user/"),
               (kind: VariableSegment, value: "userId"),
               (kind: ConstantSegment, value: "/session")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetSession_602804(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns session information for a specified bot, alias, and user ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botName: JString (required)
  ##          : The name of the bot that contains the session data.
  ##   botAlias: JString (required)
  ##           : The alias in use for the bot that contains the session data.
  ##   userId: JString (required)
  ##         : The ID of the client application user. Amazon Lex uses this to identify a user's conversation with your bot. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botName` field"
  var valid_602931 = path.getOrDefault("botName")
  valid_602931 = validateParameter(valid_602931, JString, required = true,
                                 default = nil)
  if valid_602931 != nil:
    section.add "botName", valid_602931
  var valid_602932 = path.getOrDefault("botAlias")
  valid_602932 = validateParameter(valid_602932, JString, required = true,
                                 default = nil)
  if valid_602932 != nil:
    section.add "botAlias", valid_602932
  var valid_602933 = path.getOrDefault("userId")
  valid_602933 = validateParameter(valid_602933, JString, required = true,
                                 default = nil)
  if valid_602933 != nil:
    section.add "userId", valid_602933
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
  var valid_602934 = header.getOrDefault("X-Amz-Date")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Date", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Security-Token")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Security-Token", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-Content-Sha256", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Algorithm")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Algorithm", valid_602937
  var valid_602938 = header.getOrDefault("X-Amz-Signature")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-Signature", valid_602938
  var valid_602939 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602939 = validateParameter(valid_602939, JString, required = false,
                                 default = nil)
  if valid_602939 != nil:
    section.add "X-Amz-SignedHeaders", valid_602939
  var valid_602940 = header.getOrDefault("X-Amz-Credential")
  valid_602940 = validateParameter(valid_602940, JString, required = false,
                                 default = nil)
  if valid_602940 != nil:
    section.add "X-Amz-Credential", valid_602940
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602963: Call_GetSession_602803; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns session information for a specified bot, alias, and user ID.
  ## 
  let valid = call_602963.validator(path, query, header, formData, body)
  let scheme = call_602963.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602963.url(scheme.get, call_602963.host, call_602963.base,
                         call_602963.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602963, url, valid)

proc call*(call_603034: Call_GetSession_602803; botName: string; botAlias: string;
          userId: string): Recallable =
  ## getSession
  ## Returns session information for a specified bot, alias, and user ID.
  ##   botName: string (required)
  ##          : The name of the bot that contains the session data.
  ##   botAlias: string (required)
  ##           : The alias in use for the bot that contains the session data.
  ##   userId: string (required)
  ##         : The ID of the client application user. Amazon Lex uses this to identify a user's conversation with your bot. 
  var path_603035 = newJObject()
  add(path_603035, "botName", newJString(botName))
  add(path_603035, "botAlias", newJString(botAlias))
  add(path_603035, "userId", newJString(userId))
  result = call_603034.call(path_603035, nil, nil, nil, nil)

var getSession* = Call_GetSession_602803(name: "getSession",
                                      meth: HttpMethod.HttpGet,
                                      host: "runtime.lex.amazonaws.com", route: "/bot/{botName}/alias/{botAlias}/user/{userId}/session",
                                      validator: validate_GetSession_602804,
                                      base: "/", url: url_GetSession_602805,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSession_603094 = ref object of OpenApiRestCall_602466
proc url_DeleteSession_603096(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "botName" in path, "`botName` is a required path parameter"
  assert "botAlias" in path, "`botAlias` is a required path parameter"
  assert "userId" in path, "`userId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bot/"),
               (kind: VariableSegment, value: "botName"),
               (kind: ConstantSegment, value: "/alias/"),
               (kind: VariableSegment, value: "botAlias"),
               (kind: ConstantSegment, value: "/user/"),
               (kind: VariableSegment, value: "userId"),
               (kind: ConstantSegment, value: "/session")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteSession_603095(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes session information for a specified bot, alias, and user ID. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botName: JString (required)
  ##          : The name of the bot that contains the session data.
  ##   botAlias: JString (required)
  ##           : The alias in use for the bot that contains the session data.
  ##   userId: JString (required)
  ##         : The identifier of the user associated with the session data.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botName` field"
  var valid_603097 = path.getOrDefault("botName")
  valid_603097 = validateParameter(valid_603097, JString, required = true,
                                 default = nil)
  if valid_603097 != nil:
    section.add "botName", valid_603097
  var valid_603098 = path.getOrDefault("botAlias")
  valid_603098 = validateParameter(valid_603098, JString, required = true,
                                 default = nil)
  if valid_603098 != nil:
    section.add "botAlias", valid_603098
  var valid_603099 = path.getOrDefault("userId")
  valid_603099 = validateParameter(valid_603099, JString, required = true,
                                 default = nil)
  if valid_603099 != nil:
    section.add "userId", valid_603099
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
  var valid_603100 = header.getOrDefault("X-Amz-Date")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Date", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-Security-Token")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Security-Token", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Content-Sha256", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Algorithm")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Algorithm", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Signature")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Signature", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-SignedHeaders", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Credential")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Credential", valid_603106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603107: Call_DeleteSession_603094; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes session information for a specified bot, alias, and user ID. 
  ## 
  let valid = call_603107.validator(path, query, header, formData, body)
  let scheme = call_603107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603107.url(scheme.get, call_603107.host, call_603107.base,
                         call_603107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603107, url, valid)

proc call*(call_603108: Call_DeleteSession_603094; botName: string; botAlias: string;
          userId: string): Recallable =
  ## deleteSession
  ## Removes session information for a specified bot, alias, and user ID. 
  ##   botName: string (required)
  ##          : The name of the bot that contains the session data.
  ##   botAlias: string (required)
  ##           : The alias in use for the bot that contains the session data.
  ##   userId: string (required)
  ##         : The identifier of the user associated with the session data.
  var path_603109 = newJObject()
  add(path_603109, "botName", newJString(botName))
  add(path_603109, "botAlias", newJString(botAlias))
  add(path_603109, "userId", newJString(userId))
  result = call_603108.call(path_603109, nil, nil, nil, nil)

var deleteSession* = Call_DeleteSession_603094(name: "deleteSession",
    meth: HttpMethod.HttpDelete, host: "runtime.lex.amazonaws.com",
    route: "/bot/{botName}/alias/{botAlias}/user/{userId}/session",
    validator: validate_DeleteSession_603095, base: "/", url: url_DeleteSession_603096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostContent_603110 = ref object of OpenApiRestCall_602466
proc url_PostContent_603112(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "botName" in path, "`botName` is a required path parameter"
  assert "botAlias" in path, "`botAlias` is a required path parameter"
  assert "userId" in path, "`userId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bot/"),
               (kind: VariableSegment, value: "botName"),
               (kind: ConstantSegment, value: "/alias/"),
               (kind: VariableSegment, value: "botAlias"),
               (kind: ConstantSegment, value: "/user/"),
               (kind: VariableSegment, value: "userId"),
               (kind: ConstantSegment, value: "/content#Content-Type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PostContent_603111(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Sends user input (text or speech) to Amazon Lex. Clients use this API to send text and audio requests to Amazon Lex at runtime. Amazon Lex interprets the user input using the machine learning model that it built for the bot. </p> <p>The <code>PostContent</code> operation supports audio input at 8kHz and 16kHz. You can use 8kHz audio to achieve higher speech recognition accuracy in telephone audio applications. </p> <p> In response, Amazon Lex returns the next message to convey to the user. Consider the following example messages: </p> <ul> <li> <p> For a user input "I would like a pizza," Amazon Lex might return a response with a message eliciting slot data (for example, <code>PizzaSize</code>): "What size pizza would you like?". </p> </li> <li> <p> After the user provides all of the pizza order information, Amazon Lex might return a response with a message to get user confirmation: "Order the pizza?". </p> </li> <li> <p> After the user replies "Yes" to the confirmation prompt, Amazon Lex might return a conclusion statement: "Thank you, your cheese pizza has been ordered.". </p> </li> </ul> <p> Not all Amazon Lex messages require a response from the user. For example, conclusion statements do not require a response. Some messages require only a yes or no response. In addition to the <code>message</code>, Amazon Lex provides additional context about the message in the response that you can use to enhance client behavior, such as displaying the appropriate client user interface. Consider the following examples: </p> <ul> <li> <p> If the message is to elicit slot data, Amazon Lex returns the following context information: </p> <ul> <li> <p> <code>x-amz-lex-dialog-state</code> header set to <code>ElicitSlot</code> </p> </li> <li> <p> <code>x-amz-lex-intent-name</code> header set to the intent name in the current context </p> </li> <li> <p> <code>x-amz-lex-slot-to-elicit</code> header set to the slot name for which the <code>message</code> is eliciting information </p> </li> <li> <p> <code>x-amz-lex-slots</code> header set to a map of slots configured for the intent with their current values </p> </li> </ul> </li> <li> <p> If the message is a confirmation prompt, the <code>x-amz-lex-dialog-state</code> header is set to <code>Confirmation</code> and the <code>x-amz-lex-slot-to-elicit</code> header is omitted. </p> </li> <li> <p> If the message is a clarification prompt configured for the intent, indicating that the user intent is not understood, the <code>x-amz-dialog-state</code> header is set to <code>ElicitIntent</code> and the <code>x-amz-slot-to-elicit</code> header is omitted. </p> </li> </ul> <p> In addition, Amazon Lex also returns your application-specific <code>sessionAttributes</code>. For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html">Managing Conversation Context</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botName: JString (required)
  ##          : Name of the Amazon Lex bot.
  ##   botAlias: JString (required)
  ##           : Alias of the Amazon Lex bot.
  ##   userId: JString (required)
  ##         : <p>The ID of the client application user. Amazon Lex uses this to identify a user's conversation with your bot. At runtime, each request must contain the <code>userID</code> field.</p> <p>To decide the user ID to use for your application, consider the following factors.</p> <ul> <li> <p>The <code>userID</code> field must not contain any personally identifiable information of the user, for example, name, personal identification numbers, or other end user personal information.</p> </li> <li> <p>If you want a user to start a conversation on one device and continue on another device, use a user-specific identifier.</p> </li> <li> <p>If you want the same user to be able to have two independent conversations on two different devices, choose a device-specific identifier.</p> </li> <li> <p>A user can't have two independent conversations with two different versions of the same bot. For example, a user can't have a conversation with the PROD and BETA versions of the same bot. If you anticipate that a user will need to have conversation with two different versions, for example, while testing, include the bot alias in the user ID to separate the two conversations.</p> </li> </ul>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botName` field"
  var valid_603113 = path.getOrDefault("botName")
  valid_603113 = validateParameter(valid_603113, JString, required = true,
                                 default = nil)
  if valid_603113 != nil:
    section.add "botName", valid_603113
  var valid_603114 = path.getOrDefault("botAlias")
  valid_603114 = validateParameter(valid_603114, JString, required = true,
                                 default = nil)
  if valid_603114 != nil:
    section.add "botAlias", valid_603114
  var valid_603115 = path.getOrDefault("userId")
  valid_603115 = validateParameter(valid_603115, JString, required = true,
                                 default = nil)
  if valid_603115 != nil:
    section.add "userId", valid_603115
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-lex-session-attributes: JString
  ##                               : <p>You pass this value as the <code>x-amz-lex-session-attributes</code> HTTP header.</p> <p>Application-specific information passed between Amazon Lex and a client application. The value must be a JSON serialized and base64 encoded map with string keys and values. The total size of the <code>sessionAttributes</code> and <code>requestAttributes</code> headers is limited to 12 KB.</p> <p>For more information, see <a 
  ## href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html#context-mgmt-session-attribs">Setting Session Attributes</a>.</p>
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-lex-request-attributes: JString
  ##                               : <p>You pass this value as the <code>x-amz-lex-request-attributes</code> HTTP header.</p> <p>Request-specific information passed between Amazon Lex and a client application. The value must be a JSON serialized and base64 encoded map with string keys and values. The total size of the <code>requestAttributes</code> and <code>sessionAttributes</code> headers is limited to 12 KB.</p> <p>The namespace <code>x-amz-lex:</code> is reserved for special attributes. Don't create any request attributes with the prefix <code>x-amz-lex:</code>.</p> <p>For more information, see <a 
  ## href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html#context-mgmt-request-attribs">Setting Request Attributes</a>.</p>
  ##   Content-Type: JString (required)
  ##               : <p> You pass this value as the <code>Content-Type</code> HTTP header. </p> <p> Indicates the audio format or text. The header value must start with one of the following prefixes: </p> <ul> <li> <p>PCM format, audio data must be in little-endian byte order.</p> <ul> <li> <p>audio/l16; rate=16000; channels=1</p> </li> <li> <p>audio/x-l16; sample-rate=16000; channel-count=1</p> </li> <li> <p>audio/lpcm; sample-rate=8000; sample-size-bits=16; channel-count=1; is-big-endian=false </p> </li> </ul> </li> <li> <p>Opus format</p> <ul> <li> <p>audio/x-cbr-opus-with-preamble; preamble-size=0; bit-rate=256000; frame-size-milliseconds=4</p> </li> </ul> </li> <li> <p>Text format</p> <ul> <li> <p>text/plain; charset=utf-8</p> </li> </ul> </li> </ul>
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   Accept: JString
  ##         : <p> You pass this value as the <code>Accept</code> HTTP header. </p> <p> The message Amazon Lex returns in the response can be either text or speech based on the <code>Accept</code> HTTP header value in the request. </p> <ul> <li> <p> If the value is <code>text/plain; charset=utf-8</code>, Amazon Lex returns text in the response. </p> </li> <li> <p> If the value begins with <code>audio/</code>, Amazon Lex returns speech in the response. Amazon Lex uses Amazon Polly to generate the speech (using the configuration you specified in the <code>Accept</code> header). For example, if you specify <code>audio/mpeg</code> as the value, Amazon Lex returns speech in the MPEG format.</p> </li> <li> <p>If the value is <code>audio/pcm</code>, the speech returned is <code>audio/pcm</code> in 16-bit, little endian format. </p> </li> <li> <p>The following are the accepted values:</p> <ul> <li> <p>audio/mpeg</p> </li> <li> <p>audio/ogg</p> </li> <li> <p>audio/pcm</p> </li> <li> <p>text/plain; charset=utf-8</p> </li> <li> <p>audio/* (defaults to mpeg)</p> </li> </ul> </li> </ul>
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603116 = header.getOrDefault("X-Amz-Date")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Date", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Security-Token")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Security-Token", valid_603117
  var valid_603118 = header.getOrDefault("x-amz-lex-session-attributes")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "x-amz-lex-session-attributes", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Content-Sha256", valid_603119
  var valid_603120 = header.getOrDefault("x-amz-lex-request-attributes")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "x-amz-lex-request-attributes", valid_603120
  assert header != nil,
        "header argument is necessary due to required `Content-Type` field"
  var valid_603121 = header.getOrDefault("Content-Type")
  valid_603121 = validateParameter(valid_603121, JString, required = true,
                                 default = nil)
  if valid_603121 != nil:
    section.add "Content-Type", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Algorithm")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Algorithm", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Signature")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Signature", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-SignedHeaders", valid_603124
  var valid_603125 = header.getOrDefault("Accept")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "Accept", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-Credential")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Credential", valid_603126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603128: Call_PostContent_603110; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Sends user input (text or speech) to Amazon Lex. Clients use this API to send text and audio requests to Amazon Lex at runtime. Amazon Lex interprets the user input using the machine learning model that it built for the bot. </p> <p>The <code>PostContent</code> operation supports audio input at 8kHz and 16kHz. You can use 8kHz audio to achieve higher speech recognition accuracy in telephone audio applications. </p> <p> In response, Amazon Lex returns the next message to convey to the user. Consider the following example messages: </p> <ul> <li> <p> For a user input "I would like a pizza," Amazon Lex might return a response with a message eliciting slot data (for example, <code>PizzaSize</code>): "What size pizza would you like?". </p> </li> <li> <p> After the user provides all of the pizza order information, Amazon Lex might return a response with a message to get user confirmation: "Order the pizza?". </p> </li> <li> <p> After the user replies "Yes" to the confirmation prompt, Amazon Lex might return a conclusion statement: "Thank you, your cheese pizza has been ordered.". </p> </li> </ul> <p> Not all Amazon Lex messages require a response from the user. For example, conclusion statements do not require a response. Some messages require only a yes or no response. In addition to the <code>message</code>, Amazon Lex provides additional context about the message in the response that you can use to enhance client behavior, such as displaying the appropriate client user interface. Consider the following examples: </p> <ul> <li> <p> If the message is to elicit slot data, Amazon Lex returns the following context information: </p> <ul> <li> <p> <code>x-amz-lex-dialog-state</code> header set to <code>ElicitSlot</code> </p> </li> <li> <p> <code>x-amz-lex-intent-name</code> header set to the intent name in the current context </p> </li> <li> <p> <code>x-amz-lex-slot-to-elicit</code> header set to the slot name for which the <code>message</code> is eliciting information </p> </li> <li> <p> <code>x-amz-lex-slots</code> header set to a map of slots configured for the intent with their current values </p> </li> </ul> </li> <li> <p> If the message is a confirmation prompt, the <code>x-amz-lex-dialog-state</code> header is set to <code>Confirmation</code> and the <code>x-amz-lex-slot-to-elicit</code> header is omitted. </p> </li> <li> <p> If the message is a clarification prompt configured for the intent, indicating that the user intent is not understood, the <code>x-amz-dialog-state</code> header is set to <code>ElicitIntent</code> and the <code>x-amz-slot-to-elicit</code> header is omitted. </p> </li> </ul> <p> In addition, Amazon Lex also returns your application-specific <code>sessionAttributes</code>. For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html">Managing Conversation Context</a>. </p>
  ## 
  let valid = call_603128.validator(path, query, header, formData, body)
  let scheme = call_603128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603128.url(scheme.get, call_603128.host, call_603128.base,
                         call_603128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603128, url, valid)

proc call*(call_603129: Call_PostContent_603110; botName: string; body: JsonNode;
          botAlias: string; userId: string): Recallable =
  ## postContent
  ## <p> Sends user input (text or speech) to Amazon Lex. Clients use this API to send text and audio requests to Amazon Lex at runtime. Amazon Lex interprets the user input using the machine learning model that it built for the bot. </p> <p>The <code>PostContent</code> operation supports audio input at 8kHz and 16kHz. You can use 8kHz audio to achieve higher speech recognition accuracy in telephone audio applications. </p> <p> In response, Amazon Lex returns the next message to convey to the user. Consider the following example messages: </p> <ul> <li> <p> For a user input "I would like a pizza," Amazon Lex might return a response with a message eliciting slot data (for example, <code>PizzaSize</code>): "What size pizza would you like?". </p> </li> <li> <p> After the user provides all of the pizza order information, Amazon Lex might return a response with a message to get user confirmation: "Order the pizza?". </p> </li> <li> <p> After the user replies "Yes" to the confirmation prompt, Amazon Lex might return a conclusion statement: "Thank you, your cheese pizza has been ordered.". </p> </li> </ul> <p> Not all Amazon Lex messages require a response from the user. For example, conclusion statements do not require a response. Some messages require only a yes or no response. In addition to the <code>message</code>, Amazon Lex provides additional context about the message in the response that you can use to enhance client behavior, such as displaying the appropriate client user interface. Consider the following examples: </p> <ul> <li> <p> If the message is to elicit slot data, Amazon Lex returns the following context information: </p> <ul> <li> <p> <code>x-amz-lex-dialog-state</code> header set to <code>ElicitSlot</code> </p> </li> <li> <p> <code>x-amz-lex-intent-name</code> header set to the intent name in the current context </p> </li> <li> <p> <code>x-amz-lex-slot-to-elicit</code> header set to the slot name for which the <code>message</code> is eliciting information </p> </li> <li> <p> <code>x-amz-lex-slots</code> header set to a map of slots configured for the intent with their current values </p> </li> </ul> </li> <li> <p> If the message is a confirmation prompt, the <code>x-amz-lex-dialog-state</code> header is set to <code>Confirmation</code> and the <code>x-amz-lex-slot-to-elicit</code> header is omitted. </p> </li> <li> <p> If the message is a clarification prompt configured for the intent, indicating that the user intent is not understood, the <code>x-amz-dialog-state</code> header is set to <code>ElicitIntent</code> and the <code>x-amz-slot-to-elicit</code> header is omitted. </p> </li> </ul> <p> In addition, Amazon Lex also returns your application-specific <code>sessionAttributes</code>. For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html">Managing Conversation Context</a>. </p>
  ##   botName: string (required)
  ##          : Name of the Amazon Lex bot.
  ##   body: JObject (required)
  ##   botAlias: string (required)
  ##           : Alias of the Amazon Lex bot.
  ##   userId: string (required)
  ##         : <p>The ID of the client application user. Amazon Lex uses this to identify a user's conversation with your bot. At runtime, each request must contain the <code>userID</code> field.</p> <p>To decide the user ID to use for your application, consider the following factors.</p> <ul> <li> <p>The <code>userID</code> field must not contain any personally identifiable information of the user, for example, name, personal identification numbers, or other end user personal information.</p> </li> <li> <p>If you want a user to start a conversation on one device and continue on another device, use a user-specific identifier.</p> </li> <li> <p>If you want the same user to be able to have two independent conversations on two different devices, choose a device-specific identifier.</p> </li> <li> <p>A user can't have two independent conversations with two different versions of the same bot. For example, a user can't have a conversation with the PROD and BETA versions of the same bot. If you anticipate that a user will need to have conversation with two different versions, for example, while testing, include the bot alias in the user ID to separate the two conversations.</p> </li> </ul>
  var path_603130 = newJObject()
  var body_603131 = newJObject()
  add(path_603130, "botName", newJString(botName))
  if body != nil:
    body_603131 = body
  add(path_603130, "botAlias", newJString(botAlias))
  add(path_603130, "userId", newJString(userId))
  result = call_603129.call(path_603130, nil, nil, nil, body_603131)

var postContent* = Call_PostContent_603110(name: "postContent",
                                        meth: HttpMethod.HttpPost,
                                        host: "runtime.lex.amazonaws.com", route: "/bot/{botName}/alias/{botAlias}/user/{userId}/content#Content-Type",
                                        validator: validate_PostContent_603111,
                                        base: "/", url: url_PostContent_603112,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostText_603132 = ref object of OpenApiRestCall_602466
proc url_PostText_603134(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "botName" in path, "`botName` is a required path parameter"
  assert "botAlias" in path, "`botAlias` is a required path parameter"
  assert "userId" in path, "`userId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bot/"),
               (kind: VariableSegment, value: "botName"),
               (kind: ConstantSegment, value: "/alias/"),
               (kind: VariableSegment, value: "botAlias"),
               (kind: ConstantSegment, value: "/user/"),
               (kind: VariableSegment, value: "userId"),
               (kind: ConstantSegment, value: "/text")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PostText_603133(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sends user input (text or SSML) to Amazon Lex. Client applications can use this API to send requests to Amazon Lex at runtime. Amazon Lex then interprets the user input using the machine learning model it built for the bot. </p> <p> In response, Amazon Lex returns the next <code>message</code> to convey to the user an optional <code>responseCard</code> to display. Consider the following example messages: </p> <ul> <li> <p> For a user input "I would like a pizza", Amazon Lex might return a response with a message eliciting slot data (for example, PizzaSize): "What size pizza would you like?" </p> </li> <li> <p> After the user provides all of the pizza order information, Amazon Lex might return a response with a message to obtain user confirmation "Proceed with the pizza order?". </p> </li> <li> <p> After the user replies to a confirmation prompt with a "yes", Amazon Lex might return a conclusion statement: "Thank you, your cheese pizza has been ordered.". </p> </li> </ul> <p> Not all Amazon Lex messages require a user response. For example, a conclusion statement does not require a response. Some messages require only a "yes" or "no" user response. In addition to the <code>message</code>, Amazon Lex provides additional context about the message in the response that you might use to enhance client behavior, for example, to display the appropriate client user interface. These are the <code>slotToElicit</code>, <code>dialogState</code>, <code>intentName</code>, and <code>slots</code> fields in the response. Consider the following examples: </p> <ul> <li> <p>If the message is to elicit slot data, Amazon Lex returns the following context information:</p> <ul> <li> <p> <code>dialogState</code> set to ElicitSlot </p> </li> <li> <p> <code>intentName</code> set to the intent name in the current context </p> </li> <li> <p> <code>slotToElicit</code> set to the slot name for which the <code>message</code> is eliciting information </p> </li> <li> <p> <code>slots</code> set to a map of slots, configured for the intent, with currently known values </p> </li> </ul> </li> <li> <p> If the message is a confirmation prompt, the <code>dialogState</code> is set to ConfirmIntent and <code>SlotToElicit</code> is set to null. </p> </li> <li> <p>If the message is a clarification prompt (configured for the intent) that indicates that user intent is not understood, the <code>dialogState</code> is set to ElicitIntent and <code>slotToElicit</code> is set to null. </p> </li> </ul> <p> In addition, Amazon Lex also returns your application-specific <code>sessionAttributes</code>. For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html">Managing Conversation Context</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botName: JString (required)
  ##          : The name of the Amazon Lex bot.
  ##   botAlias: JString (required)
  ##           : The alias of the Amazon Lex bot.
  ##   userId: JString (required)
  ##         : <p>The ID of the client application user. Amazon Lex uses this to identify a user's conversation with your bot. At runtime, each request must contain the <code>userID</code> field.</p> <p>To decide the user ID to use for your application, consider the following factors.</p> <ul> <li> <p>The <code>userID</code> field must not contain any personally identifiable information of the user, for example, name, personal identification numbers, or other end user personal information.</p> </li> <li> <p>If you want a user to start a conversation on one device and continue on another device, use a user-specific identifier.</p> </li> <li> <p>If you want the same user to be able to have two independent conversations on two different devices, choose a device-specific identifier.</p> </li> <li> <p>A user can't have two independent conversations with two different versions of the same bot. For example, a user can't have a conversation with the PROD and BETA versions of the same bot. If you anticipate that a user will need to have conversation with two different versions, for example, while testing, include the bot alias in the user ID to separate the two conversations.</p> </li> </ul>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botName` field"
  var valid_603135 = path.getOrDefault("botName")
  valid_603135 = validateParameter(valid_603135, JString, required = true,
                                 default = nil)
  if valid_603135 != nil:
    section.add "botName", valid_603135
  var valid_603136 = path.getOrDefault("botAlias")
  valid_603136 = validateParameter(valid_603136, JString, required = true,
                                 default = nil)
  if valid_603136 != nil:
    section.add "botAlias", valid_603136
  var valid_603137 = path.getOrDefault("userId")
  valid_603137 = validateParameter(valid_603137, JString, required = true,
                                 default = nil)
  if valid_603137 != nil:
    section.add "userId", valid_603137
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
  var valid_603138 = header.getOrDefault("X-Amz-Date")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Date", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Security-Token")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Security-Token", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Content-Sha256", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Algorithm")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Algorithm", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Signature")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Signature", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-SignedHeaders", valid_603143
  var valid_603144 = header.getOrDefault("X-Amz-Credential")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-Credential", valid_603144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603146: Call_PostText_603132; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends user input (text or SSML) to Amazon Lex. Client applications can use this API to send requests to Amazon Lex at runtime. Amazon Lex then interprets the user input using the machine learning model it built for the bot. </p> <p> In response, Amazon Lex returns the next <code>message</code> to convey to the user an optional <code>responseCard</code> to display. Consider the following example messages: </p> <ul> <li> <p> For a user input "I would like a pizza", Amazon Lex might return a response with a message eliciting slot data (for example, PizzaSize): "What size pizza would you like?" </p> </li> <li> <p> After the user provides all of the pizza order information, Amazon Lex might return a response with a message to obtain user confirmation "Proceed with the pizza order?". </p> </li> <li> <p> After the user replies to a confirmation prompt with a "yes", Amazon Lex might return a conclusion statement: "Thank you, your cheese pizza has been ordered.". </p> </li> </ul> <p> Not all Amazon Lex messages require a user response. For example, a conclusion statement does not require a response. Some messages require only a "yes" or "no" user response. In addition to the <code>message</code>, Amazon Lex provides additional context about the message in the response that you might use to enhance client behavior, for example, to display the appropriate client user interface. These are the <code>slotToElicit</code>, <code>dialogState</code>, <code>intentName</code>, and <code>slots</code> fields in the response. Consider the following examples: </p> <ul> <li> <p>If the message is to elicit slot data, Amazon Lex returns the following context information:</p> <ul> <li> <p> <code>dialogState</code> set to ElicitSlot </p> </li> <li> <p> <code>intentName</code> set to the intent name in the current context </p> </li> <li> <p> <code>slotToElicit</code> set to the slot name for which the <code>message</code> is eliciting information </p> </li> <li> <p> <code>slots</code> set to a map of slots, configured for the intent, with currently known values </p> </li> </ul> </li> <li> <p> If the message is a confirmation prompt, the <code>dialogState</code> is set to ConfirmIntent and <code>SlotToElicit</code> is set to null. </p> </li> <li> <p>If the message is a clarification prompt (configured for the intent) that indicates that user intent is not understood, the <code>dialogState</code> is set to ElicitIntent and <code>slotToElicit</code> is set to null. </p> </li> </ul> <p> In addition, Amazon Lex also returns your application-specific <code>sessionAttributes</code>. For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html">Managing Conversation Context</a>. </p>
  ## 
  let valid = call_603146.validator(path, query, header, formData, body)
  let scheme = call_603146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603146.url(scheme.get, call_603146.host, call_603146.base,
                         call_603146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603146, url, valid)

proc call*(call_603147: Call_PostText_603132; botName: string; body: JsonNode;
          botAlias: string; userId: string): Recallable =
  ## postText
  ## <p>Sends user input (text or SSML) to Amazon Lex. Client applications can use this API to send requests to Amazon Lex at runtime. Amazon Lex then interprets the user input using the machine learning model it built for the bot. </p> <p> In response, Amazon Lex returns the next <code>message</code> to convey to the user an optional <code>responseCard</code> to display. Consider the following example messages: </p> <ul> <li> <p> For a user input "I would like a pizza", Amazon Lex might return a response with a message eliciting slot data (for example, PizzaSize): "What size pizza would you like?" </p> </li> <li> <p> After the user provides all of the pizza order information, Amazon Lex might return a response with a message to obtain user confirmation "Proceed with the pizza order?". </p> </li> <li> <p> After the user replies to a confirmation prompt with a "yes", Amazon Lex might return a conclusion statement: "Thank you, your cheese pizza has been ordered.". </p> </li> </ul> <p> Not all Amazon Lex messages require a user response. For example, a conclusion statement does not require a response. Some messages require only a "yes" or "no" user response. In addition to the <code>message</code>, Amazon Lex provides additional context about the message in the response that you might use to enhance client behavior, for example, to display the appropriate client user interface. These are the <code>slotToElicit</code>, <code>dialogState</code>, <code>intentName</code>, and <code>slots</code> fields in the response. Consider the following examples: </p> <ul> <li> <p>If the message is to elicit slot data, Amazon Lex returns the following context information:</p> <ul> <li> <p> <code>dialogState</code> set to ElicitSlot </p> </li> <li> <p> <code>intentName</code> set to the intent name in the current context </p> </li> <li> <p> <code>slotToElicit</code> set to the slot name for which the <code>message</code> is eliciting information </p> </li> <li> <p> <code>slots</code> set to a map of slots, configured for the intent, with currently known values </p> </li> </ul> </li> <li> <p> If the message is a confirmation prompt, the <code>dialogState</code> is set to ConfirmIntent and <code>SlotToElicit</code> is set to null. </p> </li> <li> <p>If the message is a clarification prompt (configured for the intent) that indicates that user intent is not understood, the <code>dialogState</code> is set to ElicitIntent and <code>slotToElicit</code> is set to null. </p> </li> </ul> <p> In addition, Amazon Lex also returns your application-specific <code>sessionAttributes</code>. For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html">Managing Conversation Context</a>. </p>
  ##   botName: string (required)
  ##          : The name of the Amazon Lex bot.
  ##   body: JObject (required)
  ##   botAlias: string (required)
  ##           : The alias of the Amazon Lex bot.
  ##   userId: string (required)
  ##         : <p>The ID of the client application user. Amazon Lex uses this to identify a user's conversation with your bot. At runtime, each request must contain the <code>userID</code> field.</p> <p>To decide the user ID to use for your application, consider the following factors.</p> <ul> <li> <p>The <code>userID</code> field must not contain any personally identifiable information of the user, for example, name, personal identification numbers, or other end user personal information.</p> </li> <li> <p>If you want a user to start a conversation on one device and continue on another device, use a user-specific identifier.</p> </li> <li> <p>If you want the same user to be able to have two independent conversations on two different devices, choose a device-specific identifier.</p> </li> <li> <p>A user can't have two independent conversations with two different versions of the same bot. For example, a user can't have a conversation with the PROD and BETA versions of the same bot. If you anticipate that a user will need to have conversation with two different versions, for example, while testing, include the bot alias in the user ID to separate the two conversations.</p> </li> </ul>
  var path_603148 = newJObject()
  var body_603149 = newJObject()
  add(path_603148, "botName", newJString(botName))
  if body != nil:
    body_603149 = body
  add(path_603148, "botAlias", newJString(botAlias))
  add(path_603148, "userId", newJString(userId))
  result = call_603147.call(path_603148, nil, nil, nil, body_603149)

var postText* = Call_PostText_603132(name: "postText", meth: HttpMethod.HttpPost,
                                  host: "runtime.lex.amazonaws.com", route: "/bot/{botName}/alias/{botAlias}/user/{userId}/text",
                                  validator: validate_PostText_603133, base: "/",
                                  url: url_PostText_603134,
                                  schemes: {Scheme.Https, Scheme.Http})
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
