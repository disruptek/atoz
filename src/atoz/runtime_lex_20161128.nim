
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
  Call_PutSession_773205 = ref object of OpenApiRestCall_772597
proc url_PutSession_773207(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutSession_773206(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773208 = path.getOrDefault("botName")
  valid_773208 = validateParameter(valid_773208, JString, required = true,
                                 default = nil)
  if valid_773208 != nil:
    section.add "botName", valid_773208
  var valid_773209 = path.getOrDefault("botAlias")
  valid_773209 = validateParameter(valid_773209, JString, required = true,
                                 default = nil)
  if valid_773209 != nil:
    section.add "botAlias", valid_773209
  var valid_773210 = path.getOrDefault("userId")
  valid_773210 = validateParameter(valid_773210, JString, required = true,
                                 default = nil)
  if valid_773210 != nil:
    section.add "userId", valid_773210
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
  var valid_773211 = header.getOrDefault("X-Amz-Date")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-Date", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Security-Token")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Security-Token", valid_773212
  var valid_773213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773213 = validateParameter(valid_773213, JString, required = false,
                                 default = nil)
  if valid_773213 != nil:
    section.add "X-Amz-Content-Sha256", valid_773213
  var valid_773214 = header.getOrDefault("X-Amz-Algorithm")
  valid_773214 = validateParameter(valid_773214, JString, required = false,
                                 default = nil)
  if valid_773214 != nil:
    section.add "X-Amz-Algorithm", valid_773214
  var valid_773215 = header.getOrDefault("X-Amz-Signature")
  valid_773215 = validateParameter(valid_773215, JString, required = false,
                                 default = nil)
  if valid_773215 != nil:
    section.add "X-Amz-Signature", valid_773215
  var valid_773216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773216 = validateParameter(valid_773216, JString, required = false,
                                 default = nil)
  if valid_773216 != nil:
    section.add "X-Amz-SignedHeaders", valid_773216
  var valid_773217 = header.getOrDefault("Accept")
  valid_773217 = validateParameter(valid_773217, JString, required = false,
                                 default = nil)
  if valid_773217 != nil:
    section.add "Accept", valid_773217
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

proc call*(call_773220: Call_PutSession_773205; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new session or modifies an existing session with an Amazon Lex bot. Use this operation to enable your application to set the state of the bot.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/how-session-api.html">Managing Sessions</a>.</p>
  ## 
  let valid = call_773220.validator(path, query, header, formData, body)
  let scheme = call_773220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773220.url(scheme.get, call_773220.host, call_773220.base,
                         call_773220.route, valid.getOrDefault("path"))
  result = hook(call_773220, url, valid)

proc call*(call_773221: Call_PutSession_773205; botName: string; body: JsonNode;
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
  var path_773222 = newJObject()
  var body_773223 = newJObject()
  add(path_773222, "botName", newJString(botName))
  if body != nil:
    body_773223 = body
  add(path_773222, "botAlias", newJString(botAlias))
  add(path_773222, "userId", newJString(userId))
  result = call_773221.call(path_773222, nil, nil, nil, body_773223)

var putSession* = Call_PutSession_773205(name: "putSession",
                                      meth: HttpMethod.HttpPost,
                                      host: "runtime.lex.amazonaws.com", route: "/bot/{botName}/alias/{botAlias}/user/{userId}/session",
                                      validator: validate_PutSession_773206,
                                      base: "/", url: url_PutSession_773207,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSession_772933 = ref object of OpenApiRestCall_772597
proc url_GetSession_772935(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSession_772934(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773061 = path.getOrDefault("botName")
  valid_773061 = validateParameter(valid_773061, JString, required = true,
                                 default = nil)
  if valid_773061 != nil:
    section.add "botName", valid_773061
  var valid_773062 = path.getOrDefault("botAlias")
  valid_773062 = validateParameter(valid_773062, JString, required = true,
                                 default = nil)
  if valid_773062 != nil:
    section.add "botAlias", valid_773062
  var valid_773063 = path.getOrDefault("userId")
  valid_773063 = validateParameter(valid_773063, JString, required = true,
                                 default = nil)
  if valid_773063 != nil:
    section.add "userId", valid_773063
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
  var valid_773064 = header.getOrDefault("X-Amz-Date")
  valid_773064 = validateParameter(valid_773064, JString, required = false,
                                 default = nil)
  if valid_773064 != nil:
    section.add "X-Amz-Date", valid_773064
  var valid_773065 = header.getOrDefault("X-Amz-Security-Token")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Security-Token", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-Content-Sha256", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-Algorithm")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-Algorithm", valid_773067
  var valid_773068 = header.getOrDefault("X-Amz-Signature")
  valid_773068 = validateParameter(valid_773068, JString, required = false,
                                 default = nil)
  if valid_773068 != nil:
    section.add "X-Amz-Signature", valid_773068
  var valid_773069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773069 = validateParameter(valid_773069, JString, required = false,
                                 default = nil)
  if valid_773069 != nil:
    section.add "X-Amz-SignedHeaders", valid_773069
  var valid_773070 = header.getOrDefault("X-Amz-Credential")
  valid_773070 = validateParameter(valid_773070, JString, required = false,
                                 default = nil)
  if valid_773070 != nil:
    section.add "X-Amz-Credential", valid_773070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773093: Call_GetSession_772933; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns session information for a specified bot, alias, and user ID.
  ## 
  let valid = call_773093.validator(path, query, header, formData, body)
  let scheme = call_773093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773093.url(scheme.get, call_773093.host, call_773093.base,
                         call_773093.route, valid.getOrDefault("path"))
  result = hook(call_773093, url, valid)

proc call*(call_773164: Call_GetSession_772933; botName: string; botAlias: string;
          userId: string): Recallable =
  ## getSession
  ## Returns session information for a specified bot, alias, and user ID.
  ##   botName: string (required)
  ##          : The name of the bot that contains the session data.
  ##   botAlias: string (required)
  ##           : The alias in use for the bot that contains the session data.
  ##   userId: string (required)
  ##         : The ID of the client application user. Amazon Lex uses this to identify a user's conversation with your bot. 
  var path_773165 = newJObject()
  add(path_773165, "botName", newJString(botName))
  add(path_773165, "botAlias", newJString(botAlias))
  add(path_773165, "userId", newJString(userId))
  result = call_773164.call(path_773165, nil, nil, nil, nil)

var getSession* = Call_GetSession_772933(name: "getSession",
                                      meth: HttpMethod.HttpGet,
                                      host: "runtime.lex.amazonaws.com", route: "/bot/{botName}/alias/{botAlias}/user/{userId}/session",
                                      validator: validate_GetSession_772934,
                                      base: "/", url: url_GetSession_772935,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSession_773224 = ref object of OpenApiRestCall_772597
proc url_DeleteSession_773226(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSession_773225(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773227 = path.getOrDefault("botName")
  valid_773227 = validateParameter(valid_773227, JString, required = true,
                                 default = nil)
  if valid_773227 != nil:
    section.add "botName", valid_773227
  var valid_773228 = path.getOrDefault("botAlias")
  valid_773228 = validateParameter(valid_773228, JString, required = true,
                                 default = nil)
  if valid_773228 != nil:
    section.add "botAlias", valid_773228
  var valid_773229 = path.getOrDefault("userId")
  valid_773229 = validateParameter(valid_773229, JString, required = true,
                                 default = nil)
  if valid_773229 != nil:
    section.add "userId", valid_773229
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
  var valid_773230 = header.getOrDefault("X-Amz-Date")
  valid_773230 = validateParameter(valid_773230, JString, required = false,
                                 default = nil)
  if valid_773230 != nil:
    section.add "X-Amz-Date", valid_773230
  var valid_773231 = header.getOrDefault("X-Amz-Security-Token")
  valid_773231 = validateParameter(valid_773231, JString, required = false,
                                 default = nil)
  if valid_773231 != nil:
    section.add "X-Amz-Security-Token", valid_773231
  var valid_773232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773232 = validateParameter(valid_773232, JString, required = false,
                                 default = nil)
  if valid_773232 != nil:
    section.add "X-Amz-Content-Sha256", valid_773232
  var valid_773233 = header.getOrDefault("X-Amz-Algorithm")
  valid_773233 = validateParameter(valid_773233, JString, required = false,
                                 default = nil)
  if valid_773233 != nil:
    section.add "X-Amz-Algorithm", valid_773233
  var valid_773234 = header.getOrDefault("X-Amz-Signature")
  valid_773234 = validateParameter(valid_773234, JString, required = false,
                                 default = nil)
  if valid_773234 != nil:
    section.add "X-Amz-Signature", valid_773234
  var valid_773235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-SignedHeaders", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-Credential")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Credential", valid_773236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773237: Call_DeleteSession_773224; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes session information for a specified bot, alias, and user ID. 
  ## 
  let valid = call_773237.validator(path, query, header, formData, body)
  let scheme = call_773237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773237.url(scheme.get, call_773237.host, call_773237.base,
                         call_773237.route, valid.getOrDefault("path"))
  result = hook(call_773237, url, valid)

proc call*(call_773238: Call_DeleteSession_773224; botName: string; botAlias: string;
          userId: string): Recallable =
  ## deleteSession
  ## Removes session information for a specified bot, alias, and user ID. 
  ##   botName: string (required)
  ##          : The name of the bot that contains the session data.
  ##   botAlias: string (required)
  ##           : The alias in use for the bot that contains the session data.
  ##   userId: string (required)
  ##         : The identifier of the user associated with the session data.
  var path_773239 = newJObject()
  add(path_773239, "botName", newJString(botName))
  add(path_773239, "botAlias", newJString(botAlias))
  add(path_773239, "userId", newJString(userId))
  result = call_773238.call(path_773239, nil, nil, nil, nil)

var deleteSession* = Call_DeleteSession_773224(name: "deleteSession",
    meth: HttpMethod.HttpDelete, host: "runtime.lex.amazonaws.com",
    route: "/bot/{botName}/alias/{botAlias}/user/{userId}/session",
    validator: validate_DeleteSession_773225, base: "/", url: url_DeleteSession_773226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostContent_773240 = ref object of OpenApiRestCall_772597
proc url_PostContent_773242(protocol: Scheme; host: string; base: string;
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

proc validate_PostContent_773241(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773243 = path.getOrDefault("botName")
  valid_773243 = validateParameter(valid_773243, JString, required = true,
                                 default = nil)
  if valid_773243 != nil:
    section.add "botName", valid_773243
  var valid_773244 = path.getOrDefault("botAlias")
  valid_773244 = validateParameter(valid_773244, JString, required = true,
                                 default = nil)
  if valid_773244 != nil:
    section.add "botAlias", valid_773244
  var valid_773245 = path.getOrDefault("userId")
  valid_773245 = validateParameter(valid_773245, JString, required = true,
                                 default = nil)
  if valid_773245 != nil:
    section.add "userId", valid_773245
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
  var valid_773246 = header.getOrDefault("X-Amz-Date")
  valid_773246 = validateParameter(valid_773246, JString, required = false,
                                 default = nil)
  if valid_773246 != nil:
    section.add "X-Amz-Date", valid_773246
  var valid_773247 = header.getOrDefault("X-Amz-Security-Token")
  valid_773247 = validateParameter(valid_773247, JString, required = false,
                                 default = nil)
  if valid_773247 != nil:
    section.add "X-Amz-Security-Token", valid_773247
  var valid_773248 = header.getOrDefault("x-amz-lex-session-attributes")
  valid_773248 = validateParameter(valid_773248, JString, required = false,
                                 default = nil)
  if valid_773248 != nil:
    section.add "x-amz-lex-session-attributes", valid_773248
  var valid_773249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773249 = validateParameter(valid_773249, JString, required = false,
                                 default = nil)
  if valid_773249 != nil:
    section.add "X-Amz-Content-Sha256", valid_773249
  var valid_773250 = header.getOrDefault("x-amz-lex-request-attributes")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "x-amz-lex-request-attributes", valid_773250
  assert header != nil,
        "header argument is necessary due to required `Content-Type` field"
  var valid_773251 = header.getOrDefault("Content-Type")
  valid_773251 = validateParameter(valid_773251, JString, required = true,
                                 default = nil)
  if valid_773251 != nil:
    section.add "Content-Type", valid_773251
  var valid_773252 = header.getOrDefault("X-Amz-Algorithm")
  valid_773252 = validateParameter(valid_773252, JString, required = false,
                                 default = nil)
  if valid_773252 != nil:
    section.add "X-Amz-Algorithm", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Signature")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Signature", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-SignedHeaders", valid_773254
  var valid_773255 = header.getOrDefault("Accept")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "Accept", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-Credential")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-Credential", valid_773256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773258: Call_PostContent_773240; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Sends user input (text or speech) to Amazon Lex. Clients use this API to send text and audio requests to Amazon Lex at runtime. Amazon Lex interprets the user input using the machine learning model that it built for the bot. </p> <p>The <code>PostContent</code> operation supports audio input at 8kHz and 16kHz. You can use 8kHz audio to achieve higher speech recognition accuracy in telephone audio applications. </p> <p> In response, Amazon Lex returns the next message to convey to the user. Consider the following example messages: </p> <ul> <li> <p> For a user input "I would like a pizza," Amazon Lex might return a response with a message eliciting slot data (for example, <code>PizzaSize</code>): "What size pizza would you like?". </p> </li> <li> <p> After the user provides all of the pizza order information, Amazon Lex might return a response with a message to get user confirmation: "Order the pizza?". </p> </li> <li> <p> After the user replies "Yes" to the confirmation prompt, Amazon Lex might return a conclusion statement: "Thank you, your cheese pizza has been ordered.". </p> </li> </ul> <p> Not all Amazon Lex messages require a response from the user. For example, conclusion statements do not require a response. Some messages require only a yes or no response. In addition to the <code>message</code>, Amazon Lex provides additional context about the message in the response that you can use to enhance client behavior, such as displaying the appropriate client user interface. Consider the following examples: </p> <ul> <li> <p> If the message is to elicit slot data, Amazon Lex returns the following context information: </p> <ul> <li> <p> <code>x-amz-lex-dialog-state</code> header set to <code>ElicitSlot</code> </p> </li> <li> <p> <code>x-amz-lex-intent-name</code> header set to the intent name in the current context </p> </li> <li> <p> <code>x-amz-lex-slot-to-elicit</code> header set to the slot name for which the <code>message</code> is eliciting information </p> </li> <li> <p> <code>x-amz-lex-slots</code> header set to a map of slots configured for the intent with their current values </p> </li> </ul> </li> <li> <p> If the message is a confirmation prompt, the <code>x-amz-lex-dialog-state</code> header is set to <code>Confirmation</code> and the <code>x-amz-lex-slot-to-elicit</code> header is omitted. </p> </li> <li> <p> If the message is a clarification prompt configured for the intent, indicating that the user intent is not understood, the <code>x-amz-dialog-state</code> header is set to <code>ElicitIntent</code> and the <code>x-amz-slot-to-elicit</code> header is omitted. </p> </li> </ul> <p> In addition, Amazon Lex also returns your application-specific <code>sessionAttributes</code>. For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html">Managing Conversation Context</a>. </p>
  ## 
  let valid = call_773258.validator(path, query, header, formData, body)
  let scheme = call_773258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773258.url(scheme.get, call_773258.host, call_773258.base,
                         call_773258.route, valid.getOrDefault("path"))
  result = hook(call_773258, url, valid)

proc call*(call_773259: Call_PostContent_773240; botName: string; body: JsonNode;
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
  var path_773260 = newJObject()
  var body_773261 = newJObject()
  add(path_773260, "botName", newJString(botName))
  if body != nil:
    body_773261 = body
  add(path_773260, "botAlias", newJString(botAlias))
  add(path_773260, "userId", newJString(userId))
  result = call_773259.call(path_773260, nil, nil, nil, body_773261)

var postContent* = Call_PostContent_773240(name: "postContent",
                                        meth: HttpMethod.HttpPost,
                                        host: "runtime.lex.amazonaws.com", route: "/bot/{botName}/alias/{botAlias}/user/{userId}/content#Content-Type",
                                        validator: validate_PostContent_773241,
                                        base: "/", url: url_PostContent_773242,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostText_773262 = ref object of OpenApiRestCall_772597
proc url_PostText_773264(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PostText_773263(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773265 = path.getOrDefault("botName")
  valid_773265 = validateParameter(valid_773265, JString, required = true,
                                 default = nil)
  if valid_773265 != nil:
    section.add "botName", valid_773265
  var valid_773266 = path.getOrDefault("botAlias")
  valid_773266 = validateParameter(valid_773266, JString, required = true,
                                 default = nil)
  if valid_773266 != nil:
    section.add "botAlias", valid_773266
  var valid_773267 = path.getOrDefault("userId")
  valid_773267 = validateParameter(valid_773267, JString, required = true,
                                 default = nil)
  if valid_773267 != nil:
    section.add "userId", valid_773267
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
  var valid_773268 = header.getOrDefault("X-Amz-Date")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Date", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Security-Token")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Security-Token", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Content-Sha256", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-Algorithm")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-Algorithm", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-Signature")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-Signature", valid_773272
  var valid_773273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773273 = validateParameter(valid_773273, JString, required = false,
                                 default = nil)
  if valid_773273 != nil:
    section.add "X-Amz-SignedHeaders", valid_773273
  var valid_773274 = header.getOrDefault("X-Amz-Credential")
  valid_773274 = validateParameter(valid_773274, JString, required = false,
                                 default = nil)
  if valid_773274 != nil:
    section.add "X-Amz-Credential", valid_773274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773276: Call_PostText_773262; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends user input (text or SSML) to Amazon Lex. Client applications can use this API to send requests to Amazon Lex at runtime. Amazon Lex then interprets the user input using the machine learning model it built for the bot. </p> <p> In response, Amazon Lex returns the next <code>message</code> to convey to the user an optional <code>responseCard</code> to display. Consider the following example messages: </p> <ul> <li> <p> For a user input "I would like a pizza", Amazon Lex might return a response with a message eliciting slot data (for example, PizzaSize): "What size pizza would you like?" </p> </li> <li> <p> After the user provides all of the pizza order information, Amazon Lex might return a response with a message to obtain user confirmation "Proceed with the pizza order?". </p> </li> <li> <p> After the user replies to a confirmation prompt with a "yes", Amazon Lex might return a conclusion statement: "Thank you, your cheese pizza has been ordered.". </p> </li> </ul> <p> Not all Amazon Lex messages require a user response. For example, a conclusion statement does not require a response. Some messages require only a "yes" or "no" user response. In addition to the <code>message</code>, Amazon Lex provides additional context about the message in the response that you might use to enhance client behavior, for example, to display the appropriate client user interface. These are the <code>slotToElicit</code>, <code>dialogState</code>, <code>intentName</code>, and <code>slots</code> fields in the response. Consider the following examples: </p> <ul> <li> <p>If the message is to elicit slot data, Amazon Lex returns the following context information:</p> <ul> <li> <p> <code>dialogState</code> set to ElicitSlot </p> </li> <li> <p> <code>intentName</code> set to the intent name in the current context </p> </li> <li> <p> <code>slotToElicit</code> set to the slot name for which the <code>message</code> is eliciting information </p> </li> <li> <p> <code>slots</code> set to a map of slots, configured for the intent, with currently known values </p> </li> </ul> </li> <li> <p> If the message is a confirmation prompt, the <code>dialogState</code> is set to ConfirmIntent and <code>SlotToElicit</code> is set to null. </p> </li> <li> <p>If the message is a clarification prompt (configured for the intent) that indicates that user intent is not understood, the <code>dialogState</code> is set to ElicitIntent and <code>slotToElicit</code> is set to null. </p> </li> </ul> <p> In addition, Amazon Lex also returns your application-specific <code>sessionAttributes</code>. For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html">Managing Conversation Context</a>. </p>
  ## 
  let valid = call_773276.validator(path, query, header, formData, body)
  let scheme = call_773276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773276.url(scheme.get, call_773276.host, call_773276.base,
                         call_773276.route, valid.getOrDefault("path"))
  result = hook(call_773276, url, valid)

proc call*(call_773277: Call_PostText_773262; botName: string; body: JsonNode;
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
  var path_773278 = newJObject()
  var body_773279 = newJObject()
  add(path_773278, "botName", newJString(botName))
  if body != nil:
    body_773279 = body
  add(path_773278, "botAlias", newJString(botAlias))
  add(path_773278, "userId", newJString(userId))
  result = call_773277.call(path_773278, nil, nil, nil, body_773279)

var postText* = Call_PostText_773262(name: "postText", meth: HttpMethod.HttpPost,
                                  host: "runtime.lex.amazonaws.com", route: "/bot/{botName}/alias/{botAlias}/user/{userId}/text",
                                  validator: validate_PostText_773263, base: "/",
                                  url: url_PostText_773264,
                                  schemes: {Scheme.Https, Scheme.Http})
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
