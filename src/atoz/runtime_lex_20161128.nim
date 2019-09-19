
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_PutSession_601040 = ref object of OpenApiRestCall_600426
proc url_PutSession_601042(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutSession_601041(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601043 = path.getOrDefault("botName")
  valid_601043 = validateParameter(valid_601043, JString, required = true,
                                 default = nil)
  if valid_601043 != nil:
    section.add "botName", valid_601043
  var valid_601044 = path.getOrDefault("botAlias")
  valid_601044 = validateParameter(valid_601044, JString, required = true,
                                 default = nil)
  if valid_601044 != nil:
    section.add "botAlias", valid_601044
  var valid_601045 = path.getOrDefault("userId")
  valid_601045 = validateParameter(valid_601045, JString, required = true,
                                 default = nil)
  if valid_601045 != nil:
    section.add "userId", valid_601045
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
  var valid_601046 = header.getOrDefault("X-Amz-Date")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Date", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Security-Token")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Security-Token", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Content-Sha256", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-Algorithm")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-Algorithm", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Signature")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Signature", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-SignedHeaders", valid_601051
  var valid_601052 = header.getOrDefault("Accept")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "Accept", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-Credential")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Credential", valid_601053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601055: Call_PutSession_601040; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new session or modifies an existing session with an Amazon Lex bot. Use this operation to enable your application to set the state of the bot.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/how-session-api.html">Managing Sessions</a>.</p>
  ## 
  let valid = call_601055.validator(path, query, header, formData, body)
  let scheme = call_601055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601055.url(scheme.get, call_601055.host, call_601055.base,
                         call_601055.route, valid.getOrDefault("path"))
  result = hook(call_601055, url, valid)

proc call*(call_601056: Call_PutSession_601040; botName: string; body: JsonNode;
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
  var path_601057 = newJObject()
  var body_601058 = newJObject()
  add(path_601057, "botName", newJString(botName))
  if body != nil:
    body_601058 = body
  add(path_601057, "botAlias", newJString(botAlias))
  add(path_601057, "userId", newJString(userId))
  result = call_601056.call(path_601057, nil, nil, nil, body_601058)

var putSession* = Call_PutSession_601040(name: "putSession",
                                      meth: HttpMethod.HttpPost,
                                      host: "runtime.lex.amazonaws.com", route: "/bot/{botName}/alias/{botAlias}/user/{userId}/session",
                                      validator: validate_PutSession_601041,
                                      base: "/", url: url_PutSession_601042,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSession_600768 = ref object of OpenApiRestCall_600426
proc url_GetSession_600770(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetSession_600769(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600896 = path.getOrDefault("botName")
  valid_600896 = validateParameter(valid_600896, JString, required = true,
                                 default = nil)
  if valid_600896 != nil:
    section.add "botName", valid_600896
  var valid_600897 = path.getOrDefault("botAlias")
  valid_600897 = validateParameter(valid_600897, JString, required = true,
                                 default = nil)
  if valid_600897 != nil:
    section.add "botAlias", valid_600897
  var valid_600898 = path.getOrDefault("userId")
  valid_600898 = validateParameter(valid_600898, JString, required = true,
                                 default = nil)
  if valid_600898 != nil:
    section.add "userId", valid_600898
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
  var valid_600899 = header.getOrDefault("X-Amz-Date")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Date", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Security-Token")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Security-Token", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-Content-Sha256", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Algorithm")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Algorithm", valid_600902
  var valid_600903 = header.getOrDefault("X-Amz-Signature")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "X-Amz-Signature", valid_600903
  var valid_600904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-SignedHeaders", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-Credential")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Credential", valid_600905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600928: Call_GetSession_600768; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns session information for a specified bot, alias, and user ID.
  ## 
  let valid = call_600928.validator(path, query, header, formData, body)
  let scheme = call_600928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600928.url(scheme.get, call_600928.host, call_600928.base,
                         call_600928.route, valid.getOrDefault("path"))
  result = hook(call_600928, url, valid)

proc call*(call_600999: Call_GetSession_600768; botName: string; botAlias: string;
          userId: string): Recallable =
  ## getSession
  ## Returns session information for a specified bot, alias, and user ID.
  ##   botName: string (required)
  ##          : The name of the bot that contains the session data.
  ##   botAlias: string (required)
  ##           : The alias in use for the bot that contains the session data.
  ##   userId: string (required)
  ##         : The ID of the client application user. Amazon Lex uses this to identify a user's conversation with your bot. 
  var path_601000 = newJObject()
  add(path_601000, "botName", newJString(botName))
  add(path_601000, "botAlias", newJString(botAlias))
  add(path_601000, "userId", newJString(userId))
  result = call_600999.call(path_601000, nil, nil, nil, nil)

var getSession* = Call_GetSession_600768(name: "getSession",
                                      meth: HttpMethod.HttpGet,
                                      host: "runtime.lex.amazonaws.com", route: "/bot/{botName}/alias/{botAlias}/user/{userId}/session",
                                      validator: validate_GetSession_600769,
                                      base: "/", url: url_GetSession_600770,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSession_601059 = ref object of OpenApiRestCall_600426
proc url_DeleteSession_601061(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteSession_601060(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601062 = path.getOrDefault("botName")
  valid_601062 = validateParameter(valid_601062, JString, required = true,
                                 default = nil)
  if valid_601062 != nil:
    section.add "botName", valid_601062
  var valid_601063 = path.getOrDefault("botAlias")
  valid_601063 = validateParameter(valid_601063, JString, required = true,
                                 default = nil)
  if valid_601063 != nil:
    section.add "botAlias", valid_601063
  var valid_601064 = path.getOrDefault("userId")
  valid_601064 = validateParameter(valid_601064, JString, required = true,
                                 default = nil)
  if valid_601064 != nil:
    section.add "userId", valid_601064
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
  var valid_601065 = header.getOrDefault("X-Amz-Date")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Date", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-Security-Token")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Security-Token", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Content-Sha256", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-Algorithm")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Algorithm", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-Signature")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Signature", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-SignedHeaders", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Credential")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Credential", valid_601071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601072: Call_DeleteSession_601059; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes session information for a specified bot, alias, and user ID. 
  ## 
  let valid = call_601072.validator(path, query, header, formData, body)
  let scheme = call_601072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601072.url(scheme.get, call_601072.host, call_601072.base,
                         call_601072.route, valid.getOrDefault("path"))
  result = hook(call_601072, url, valid)

proc call*(call_601073: Call_DeleteSession_601059; botName: string; botAlias: string;
          userId: string): Recallable =
  ## deleteSession
  ## Removes session information for a specified bot, alias, and user ID. 
  ##   botName: string (required)
  ##          : The name of the bot that contains the session data.
  ##   botAlias: string (required)
  ##           : The alias in use for the bot that contains the session data.
  ##   userId: string (required)
  ##         : The identifier of the user associated with the session data.
  var path_601074 = newJObject()
  add(path_601074, "botName", newJString(botName))
  add(path_601074, "botAlias", newJString(botAlias))
  add(path_601074, "userId", newJString(userId))
  result = call_601073.call(path_601074, nil, nil, nil, nil)

var deleteSession* = Call_DeleteSession_601059(name: "deleteSession",
    meth: HttpMethod.HttpDelete, host: "runtime.lex.amazonaws.com",
    route: "/bot/{botName}/alias/{botAlias}/user/{userId}/session",
    validator: validate_DeleteSession_601060, base: "/", url: url_DeleteSession_601061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostContent_601075 = ref object of OpenApiRestCall_600426
proc url_PostContent_601077(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PostContent_601076(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601078 = path.getOrDefault("botName")
  valid_601078 = validateParameter(valid_601078, JString, required = true,
                                 default = nil)
  if valid_601078 != nil:
    section.add "botName", valid_601078
  var valid_601079 = path.getOrDefault("botAlias")
  valid_601079 = validateParameter(valid_601079, JString, required = true,
                                 default = nil)
  if valid_601079 != nil:
    section.add "botAlias", valid_601079
  var valid_601080 = path.getOrDefault("userId")
  valid_601080 = validateParameter(valid_601080, JString, required = true,
                                 default = nil)
  if valid_601080 != nil:
    section.add "userId", valid_601080
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
  var valid_601081 = header.getOrDefault("X-Amz-Date")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Date", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-Security-Token")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Security-Token", valid_601082
  var valid_601083 = header.getOrDefault("x-amz-lex-session-attributes")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "x-amz-lex-session-attributes", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Content-Sha256", valid_601084
  var valid_601085 = header.getOrDefault("x-amz-lex-request-attributes")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "x-amz-lex-request-attributes", valid_601085
  assert header != nil,
        "header argument is necessary due to required `Content-Type` field"
  var valid_601086 = header.getOrDefault("Content-Type")
  valid_601086 = validateParameter(valid_601086, JString, required = true,
                                 default = nil)
  if valid_601086 != nil:
    section.add "Content-Type", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-Algorithm")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Algorithm", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Signature")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Signature", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-SignedHeaders", valid_601089
  var valid_601090 = header.getOrDefault("Accept")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "Accept", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Credential")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Credential", valid_601091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601093: Call_PostContent_601075; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Sends user input (text or speech) to Amazon Lex. Clients use this API to send text and audio requests to Amazon Lex at runtime. Amazon Lex interprets the user input using the machine learning model that it built for the bot. </p> <p>The <code>PostContent</code> operation supports audio input at 8kHz and 16kHz. You can use 8kHz audio to achieve higher speech recognition accuracy in telephone audio applications. </p> <p> In response, Amazon Lex returns the next message to convey to the user. Consider the following example messages: </p> <ul> <li> <p> For a user input "I would like a pizza," Amazon Lex might return a response with a message eliciting slot data (for example, <code>PizzaSize</code>): "What size pizza would you like?". </p> </li> <li> <p> After the user provides all of the pizza order information, Amazon Lex might return a response with a message to get user confirmation: "Order the pizza?". </p> </li> <li> <p> After the user replies "Yes" to the confirmation prompt, Amazon Lex might return a conclusion statement: "Thank you, your cheese pizza has been ordered.". </p> </li> </ul> <p> Not all Amazon Lex messages require a response from the user. For example, conclusion statements do not require a response. Some messages require only a yes or no response. In addition to the <code>message</code>, Amazon Lex provides additional context about the message in the response that you can use to enhance client behavior, such as displaying the appropriate client user interface. Consider the following examples: </p> <ul> <li> <p> If the message is to elicit slot data, Amazon Lex returns the following context information: </p> <ul> <li> <p> <code>x-amz-lex-dialog-state</code> header set to <code>ElicitSlot</code> </p> </li> <li> <p> <code>x-amz-lex-intent-name</code> header set to the intent name in the current context </p> </li> <li> <p> <code>x-amz-lex-slot-to-elicit</code> header set to the slot name for which the <code>message</code> is eliciting information </p> </li> <li> <p> <code>x-amz-lex-slots</code> header set to a map of slots configured for the intent with their current values </p> </li> </ul> </li> <li> <p> If the message is a confirmation prompt, the <code>x-amz-lex-dialog-state</code> header is set to <code>Confirmation</code> and the <code>x-amz-lex-slot-to-elicit</code> header is omitted. </p> </li> <li> <p> If the message is a clarification prompt configured for the intent, indicating that the user intent is not understood, the <code>x-amz-dialog-state</code> header is set to <code>ElicitIntent</code> and the <code>x-amz-slot-to-elicit</code> header is omitted. </p> </li> </ul> <p> In addition, Amazon Lex also returns your application-specific <code>sessionAttributes</code>. For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html">Managing Conversation Context</a>. </p>
  ## 
  let valid = call_601093.validator(path, query, header, formData, body)
  let scheme = call_601093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601093.url(scheme.get, call_601093.host, call_601093.base,
                         call_601093.route, valid.getOrDefault("path"))
  result = hook(call_601093, url, valid)

proc call*(call_601094: Call_PostContent_601075; botName: string; body: JsonNode;
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
  var path_601095 = newJObject()
  var body_601096 = newJObject()
  add(path_601095, "botName", newJString(botName))
  if body != nil:
    body_601096 = body
  add(path_601095, "botAlias", newJString(botAlias))
  add(path_601095, "userId", newJString(userId))
  result = call_601094.call(path_601095, nil, nil, nil, body_601096)

var postContent* = Call_PostContent_601075(name: "postContent",
                                        meth: HttpMethod.HttpPost,
                                        host: "runtime.lex.amazonaws.com", route: "/bot/{botName}/alias/{botAlias}/user/{userId}/content#Content-Type",
                                        validator: validate_PostContent_601076,
                                        base: "/", url: url_PostContent_601077,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostText_601097 = ref object of OpenApiRestCall_600426
proc url_PostText_601099(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PostText_601098(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601100 = path.getOrDefault("botName")
  valid_601100 = validateParameter(valid_601100, JString, required = true,
                                 default = nil)
  if valid_601100 != nil:
    section.add "botName", valid_601100
  var valid_601101 = path.getOrDefault("botAlias")
  valid_601101 = validateParameter(valid_601101, JString, required = true,
                                 default = nil)
  if valid_601101 != nil:
    section.add "botAlias", valid_601101
  var valid_601102 = path.getOrDefault("userId")
  valid_601102 = validateParameter(valid_601102, JString, required = true,
                                 default = nil)
  if valid_601102 != nil:
    section.add "userId", valid_601102
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
  var valid_601103 = header.getOrDefault("X-Amz-Date")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Date", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Security-Token")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Security-Token", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Content-Sha256", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Algorithm")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Algorithm", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Signature")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Signature", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-SignedHeaders", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Credential")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Credential", valid_601109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601111: Call_PostText_601097; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends user input (text or SSML) to Amazon Lex. Client applications can use this API to send requests to Amazon Lex at runtime. Amazon Lex then interprets the user input using the machine learning model it built for the bot. </p> <p> In response, Amazon Lex returns the next <code>message</code> to convey to the user an optional <code>responseCard</code> to display. Consider the following example messages: </p> <ul> <li> <p> For a user input "I would like a pizza", Amazon Lex might return a response with a message eliciting slot data (for example, PizzaSize): "What size pizza would you like?" </p> </li> <li> <p> After the user provides all of the pizza order information, Amazon Lex might return a response with a message to obtain user confirmation "Proceed with the pizza order?". </p> </li> <li> <p> After the user replies to a confirmation prompt with a "yes", Amazon Lex might return a conclusion statement: "Thank you, your cheese pizza has been ordered.". </p> </li> </ul> <p> Not all Amazon Lex messages require a user response. For example, a conclusion statement does not require a response. Some messages require only a "yes" or "no" user response. In addition to the <code>message</code>, Amazon Lex provides additional context about the message in the response that you might use to enhance client behavior, for example, to display the appropriate client user interface. These are the <code>slotToElicit</code>, <code>dialogState</code>, <code>intentName</code>, and <code>slots</code> fields in the response. Consider the following examples: </p> <ul> <li> <p>If the message is to elicit slot data, Amazon Lex returns the following context information:</p> <ul> <li> <p> <code>dialogState</code> set to ElicitSlot </p> </li> <li> <p> <code>intentName</code> set to the intent name in the current context </p> </li> <li> <p> <code>slotToElicit</code> set to the slot name for which the <code>message</code> is eliciting information </p> </li> <li> <p> <code>slots</code> set to a map of slots, configured for the intent, with currently known values </p> </li> </ul> </li> <li> <p> If the message is a confirmation prompt, the <code>dialogState</code> is set to ConfirmIntent and <code>SlotToElicit</code> is set to null. </p> </li> <li> <p>If the message is a clarification prompt (configured for the intent) that indicates that user intent is not understood, the <code>dialogState</code> is set to ElicitIntent and <code>slotToElicit</code> is set to null. </p> </li> </ul> <p> In addition, Amazon Lex also returns your application-specific <code>sessionAttributes</code>. For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html">Managing Conversation Context</a>. </p>
  ## 
  let valid = call_601111.validator(path, query, header, formData, body)
  let scheme = call_601111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601111.url(scheme.get, call_601111.host, call_601111.base,
                         call_601111.route, valid.getOrDefault("path"))
  result = hook(call_601111, url, valid)

proc call*(call_601112: Call_PostText_601097; botName: string; body: JsonNode;
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
  var path_601113 = newJObject()
  var body_601114 = newJObject()
  add(path_601113, "botName", newJString(botName))
  if body != nil:
    body_601114 = body
  add(path_601113, "botAlias", newJString(botAlias))
  add(path_601113, "userId", newJString(userId))
  result = call_601112.call(path_601113, nil, nil, nil, body_601114)

var postText* = Call_PostText_601097(name: "postText", meth: HttpMethod.HttpPost,
                                  host: "runtime.lex.amazonaws.com", route: "/bot/{botName}/alias/{botAlias}/user/{userId}/text",
                                  validator: validate_PostText_601098, base: "/",
                                  url: url_PostText_601099,
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
