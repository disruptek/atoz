
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PutSession_599705 = ref object of OpenApiRestCall_599368
proc url_PutSession_599707(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutSession_599706(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599833 = path.getOrDefault("botName")
  valid_599833 = validateParameter(valid_599833, JString, required = true,
                                 default = nil)
  if valid_599833 != nil:
    section.add "botName", valid_599833
  var valid_599834 = path.getOrDefault("botAlias")
  valid_599834 = validateParameter(valid_599834, JString, required = true,
                                 default = nil)
  if valid_599834 != nil:
    section.add "botAlias", valid_599834
  var valid_599835 = path.getOrDefault("userId")
  valid_599835 = validateParameter(valid_599835, JString, required = true,
                                 default = nil)
  if valid_599835 != nil:
    section.add "userId", valid_599835
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
  var valid_599836 = header.getOrDefault("X-Amz-Date")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Date", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Security-Token")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Security-Token", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Content-Sha256", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Algorithm")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Algorithm", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-Signature")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-Signature", valid_599840
  var valid_599841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599841 = validateParameter(valid_599841, JString, required = false,
                                 default = nil)
  if valid_599841 != nil:
    section.add "X-Amz-SignedHeaders", valid_599841
  var valid_599842 = header.getOrDefault("Accept")
  valid_599842 = validateParameter(valid_599842, JString, required = false,
                                 default = nil)
  if valid_599842 != nil:
    section.add "Accept", valid_599842
  var valid_599843 = header.getOrDefault("X-Amz-Credential")
  valid_599843 = validateParameter(valid_599843, JString, required = false,
                                 default = nil)
  if valid_599843 != nil:
    section.add "X-Amz-Credential", valid_599843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599867: Call_PutSession_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new session or modifies an existing session with an Amazon Lex bot. Use this operation to enable your application to set the state of the bot.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/how-session-api.html">Managing Sessions</a>.</p>
  ## 
  let valid = call_599867.validator(path, query, header, formData, body)
  let scheme = call_599867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599867.url(scheme.get, call_599867.host, call_599867.base,
                         call_599867.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599867, url, valid)

proc call*(call_599938: Call_PutSession_599705; botName: string; body: JsonNode;
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
  var path_599939 = newJObject()
  var body_599941 = newJObject()
  add(path_599939, "botName", newJString(botName))
  if body != nil:
    body_599941 = body
  add(path_599939, "botAlias", newJString(botAlias))
  add(path_599939, "userId", newJString(userId))
  result = call_599938.call(path_599939, nil, nil, nil, body_599941)

var putSession* = Call_PutSession_599705(name: "putSession",
                                      meth: HttpMethod.HttpPost,
                                      host: "runtime.lex.amazonaws.com", route: "/bot/{botName}/alias/{botAlias}/user/{userId}/session",
                                      validator: validate_PutSession_599706,
                                      base: "/", url: url_PutSession_599707,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSession_599980 = ref object of OpenApiRestCall_599368
proc url_DeleteSession_599982(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSession_599981(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599983 = path.getOrDefault("botName")
  valid_599983 = validateParameter(valid_599983, JString, required = true,
                                 default = nil)
  if valid_599983 != nil:
    section.add "botName", valid_599983
  var valid_599984 = path.getOrDefault("botAlias")
  valid_599984 = validateParameter(valid_599984, JString, required = true,
                                 default = nil)
  if valid_599984 != nil:
    section.add "botAlias", valid_599984
  var valid_599985 = path.getOrDefault("userId")
  valid_599985 = validateParameter(valid_599985, JString, required = true,
                                 default = nil)
  if valid_599985 != nil:
    section.add "userId", valid_599985
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
  var valid_599986 = header.getOrDefault("X-Amz-Date")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-Date", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-Security-Token")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Security-Token", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-Content-Sha256", valid_599988
  var valid_599989 = header.getOrDefault("X-Amz-Algorithm")
  valid_599989 = validateParameter(valid_599989, JString, required = false,
                                 default = nil)
  if valid_599989 != nil:
    section.add "X-Amz-Algorithm", valid_599989
  var valid_599990 = header.getOrDefault("X-Amz-Signature")
  valid_599990 = validateParameter(valid_599990, JString, required = false,
                                 default = nil)
  if valid_599990 != nil:
    section.add "X-Amz-Signature", valid_599990
  var valid_599991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599991 = validateParameter(valid_599991, JString, required = false,
                                 default = nil)
  if valid_599991 != nil:
    section.add "X-Amz-SignedHeaders", valid_599991
  var valid_599992 = header.getOrDefault("X-Amz-Credential")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Credential", valid_599992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599993: Call_DeleteSession_599980; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes session information for a specified bot, alias, and user ID. 
  ## 
  let valid = call_599993.validator(path, query, header, formData, body)
  let scheme = call_599993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599993.url(scheme.get, call_599993.host, call_599993.base,
                         call_599993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599993, url, valid)

proc call*(call_599994: Call_DeleteSession_599980; botName: string; botAlias: string;
          userId: string): Recallable =
  ## deleteSession
  ## Removes session information for a specified bot, alias, and user ID. 
  ##   botName: string (required)
  ##          : The name of the bot that contains the session data.
  ##   botAlias: string (required)
  ##           : The alias in use for the bot that contains the session data.
  ##   userId: string (required)
  ##         : The identifier of the user associated with the session data.
  var path_599995 = newJObject()
  add(path_599995, "botName", newJString(botName))
  add(path_599995, "botAlias", newJString(botAlias))
  add(path_599995, "userId", newJString(userId))
  result = call_599994.call(path_599995, nil, nil, nil, nil)

var deleteSession* = Call_DeleteSession_599980(name: "deleteSession",
    meth: HttpMethod.HttpDelete, host: "runtime.lex.amazonaws.com",
    route: "/bot/{botName}/alias/{botAlias}/user/{userId}/session",
    validator: validate_DeleteSession_599981, base: "/", url: url_DeleteSession_599982,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSession_599996 = ref object of OpenApiRestCall_599368
proc url_GetSession_599998(protocol: Scheme; host: string; base: string; route: string;
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
               (kind: ConstantSegment, value: "/session/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSession_599997(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599999 = path.getOrDefault("botName")
  valid_599999 = validateParameter(valid_599999, JString, required = true,
                                 default = nil)
  if valid_599999 != nil:
    section.add "botName", valid_599999
  var valid_600000 = path.getOrDefault("botAlias")
  valid_600000 = validateParameter(valid_600000, JString, required = true,
                                 default = nil)
  if valid_600000 != nil:
    section.add "botAlias", valid_600000
  var valid_600001 = path.getOrDefault("userId")
  valid_600001 = validateParameter(valid_600001, JString, required = true,
                                 default = nil)
  if valid_600001 != nil:
    section.add "userId", valid_600001
  result.add "path", section
  ## parameters in `query` object:
  ##   checkpointLabelFilter: JString
  ##                        : <p>A string used to filter the intents returned in the <code>recentIntentSummaryView</code> structure. </p> <p>When you specify a filter, only intents with their <code>checkpointLabel</code> field set to that string are returned.</p>
  section = newJObject()
  var valid_600002 = query.getOrDefault("checkpointLabelFilter")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "checkpointLabelFilter", valid_600002
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
  var valid_600003 = header.getOrDefault("X-Amz-Date")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-Date", valid_600003
  var valid_600004 = header.getOrDefault("X-Amz-Security-Token")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-Security-Token", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Content-Sha256", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-Algorithm")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-Algorithm", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-Signature")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Signature", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-SignedHeaders", valid_600008
  var valid_600009 = header.getOrDefault("X-Amz-Credential")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-Credential", valid_600009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600010: Call_GetSession_599996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns session information for a specified bot, alias, and user ID.
  ## 
  let valid = call_600010.validator(path, query, header, formData, body)
  let scheme = call_600010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600010.url(scheme.get, call_600010.host, call_600010.base,
                         call_600010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600010, url, valid)

proc call*(call_600011: Call_GetSession_599996; botName: string; botAlias: string;
          userId: string; checkpointLabelFilter: string = ""): Recallable =
  ## getSession
  ## Returns session information for a specified bot, alias, and user ID.
  ##   botName: string (required)
  ##          : The name of the bot that contains the session data.
  ##   checkpointLabelFilter: string
  ##                        : <p>A string used to filter the intents returned in the <code>recentIntentSummaryView</code> structure. </p> <p>When you specify a filter, only intents with their <code>checkpointLabel</code> field set to that string are returned.</p>
  ##   botAlias: string (required)
  ##           : The alias in use for the bot that contains the session data.
  ##   userId: string (required)
  ##         : The ID of the client application user. Amazon Lex uses this to identify a user's conversation with your bot. 
  var path_600012 = newJObject()
  var query_600013 = newJObject()
  add(path_600012, "botName", newJString(botName))
  add(query_600013, "checkpointLabelFilter", newJString(checkpointLabelFilter))
  add(path_600012, "botAlias", newJString(botAlias))
  add(path_600012, "userId", newJString(userId))
  result = call_600011.call(path_600012, query_600013, nil, nil, nil)

var getSession* = Call_GetSession_599996(name: "getSession",
                                      meth: HttpMethod.HttpGet,
                                      host: "runtime.lex.amazonaws.com", route: "/bot/{botName}/alias/{botAlias}/user/{userId}/session/",
                                      validator: validate_GetSession_599997,
                                      base: "/", url: url_GetSession_599998,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostContent_600014 = ref object of OpenApiRestCall_599368
proc url_PostContent_600016(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostContent_600015(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600017 = path.getOrDefault("botName")
  valid_600017 = validateParameter(valid_600017, JString, required = true,
                                 default = nil)
  if valid_600017 != nil:
    section.add "botName", valid_600017
  var valid_600018 = path.getOrDefault("botAlias")
  valid_600018 = validateParameter(valid_600018, JString, required = true,
                                 default = nil)
  if valid_600018 != nil:
    section.add "botAlias", valid_600018
  var valid_600019 = path.getOrDefault("userId")
  valid_600019 = validateParameter(valid_600019, JString, required = true,
                                 default = nil)
  if valid_600019 != nil:
    section.add "userId", valid_600019
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
  var valid_600020 = header.getOrDefault("X-Amz-Date")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Date", valid_600020
  var valid_600021 = header.getOrDefault("X-Amz-Security-Token")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-Security-Token", valid_600021
  var valid_600022 = header.getOrDefault("x-amz-lex-session-attributes")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "x-amz-lex-session-attributes", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Content-Sha256", valid_600023
  var valid_600024 = header.getOrDefault("x-amz-lex-request-attributes")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "x-amz-lex-request-attributes", valid_600024
  assert header != nil,
        "header argument is necessary due to required `Content-Type` field"
  var valid_600025 = header.getOrDefault("Content-Type")
  valid_600025 = validateParameter(valid_600025, JString, required = true,
                                 default = nil)
  if valid_600025 != nil:
    section.add "Content-Type", valid_600025
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
  var valid_600029 = header.getOrDefault("Accept")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "Accept", valid_600029
  var valid_600030 = header.getOrDefault("X-Amz-Credential")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "X-Amz-Credential", valid_600030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600032: Call_PostContent_600014; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Sends user input (text or speech) to Amazon Lex. Clients use this API to send text and audio requests to Amazon Lex at runtime. Amazon Lex interprets the user input using the machine learning model that it built for the bot. </p> <p>The <code>PostContent</code> operation supports audio input at 8kHz and 16kHz. You can use 8kHz audio to achieve higher speech recognition accuracy in telephone audio applications. </p> <p> In response, Amazon Lex returns the next message to convey to the user. Consider the following example messages: </p> <ul> <li> <p> For a user input "I would like a pizza," Amazon Lex might return a response with a message eliciting slot data (for example, <code>PizzaSize</code>): "What size pizza would you like?". </p> </li> <li> <p> After the user provides all of the pizza order information, Amazon Lex might return a response with a message to get user confirmation: "Order the pizza?". </p> </li> <li> <p> After the user replies "Yes" to the confirmation prompt, Amazon Lex might return a conclusion statement: "Thank you, your cheese pizza has been ordered.". </p> </li> </ul> <p> Not all Amazon Lex messages require a response from the user. For example, conclusion statements do not require a response. Some messages require only a yes or no response. In addition to the <code>message</code>, Amazon Lex provides additional context about the message in the response that you can use to enhance client behavior, such as displaying the appropriate client user interface. Consider the following examples: </p> <ul> <li> <p> If the message is to elicit slot data, Amazon Lex returns the following context information: </p> <ul> <li> <p> <code>x-amz-lex-dialog-state</code> header set to <code>ElicitSlot</code> </p> </li> <li> <p> <code>x-amz-lex-intent-name</code> header set to the intent name in the current context </p> </li> <li> <p> <code>x-amz-lex-slot-to-elicit</code> header set to the slot name for which the <code>message</code> is eliciting information </p> </li> <li> <p> <code>x-amz-lex-slots</code> header set to a map of slots configured for the intent with their current values </p> </li> </ul> </li> <li> <p> If the message is a confirmation prompt, the <code>x-amz-lex-dialog-state</code> header is set to <code>Confirmation</code> and the <code>x-amz-lex-slot-to-elicit</code> header is omitted. </p> </li> <li> <p> If the message is a clarification prompt configured for the intent, indicating that the user intent is not understood, the <code>x-amz-dialog-state</code> header is set to <code>ElicitIntent</code> and the <code>x-amz-slot-to-elicit</code> header is omitted. </p> </li> </ul> <p> In addition, Amazon Lex also returns your application-specific <code>sessionAttributes</code>. For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html">Managing Conversation Context</a>. </p>
  ## 
  let valid = call_600032.validator(path, query, header, formData, body)
  let scheme = call_600032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600032.url(scheme.get, call_600032.host, call_600032.base,
                         call_600032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600032, url, valid)

proc call*(call_600033: Call_PostContent_600014; botName: string; body: JsonNode;
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
  var path_600034 = newJObject()
  var body_600035 = newJObject()
  add(path_600034, "botName", newJString(botName))
  if body != nil:
    body_600035 = body
  add(path_600034, "botAlias", newJString(botAlias))
  add(path_600034, "userId", newJString(userId))
  result = call_600033.call(path_600034, nil, nil, nil, body_600035)

var postContent* = Call_PostContent_600014(name: "postContent",
                                        meth: HttpMethod.HttpPost,
                                        host: "runtime.lex.amazonaws.com", route: "/bot/{botName}/alias/{botAlias}/user/{userId}/content#Content-Type",
                                        validator: validate_PostContent_600015,
                                        base: "/", url: url_PostContent_600016,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostText_600036 = ref object of OpenApiRestCall_599368
proc url_PostText_600038(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostText_600037(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sends user input to Amazon Lex. Client applications can use this API to send requests to Amazon Lex at runtime. Amazon Lex then interprets the user input using the machine learning model it built for the bot. </p> <p> In response, Amazon Lex returns the next <code>message</code> to convey to the user an optional <code>responseCard</code> to display. Consider the following example messages: </p> <ul> <li> <p> For a user input "I would like a pizza", Amazon Lex might return a response with a message eliciting slot data (for example, PizzaSize): "What size pizza would you like?" </p> </li> <li> <p> After the user provides all of the pizza order information, Amazon Lex might return a response with a message to obtain user confirmation "Proceed with the pizza order?". </p> </li> <li> <p> After the user replies to a confirmation prompt with a "yes", Amazon Lex might return a conclusion statement: "Thank you, your cheese pizza has been ordered.". </p> </li> </ul> <p> Not all Amazon Lex messages require a user response. For example, a conclusion statement does not require a response. Some messages require only a "yes" or "no" user response. In addition to the <code>message</code>, Amazon Lex provides additional context about the message in the response that you might use to enhance client behavior, for example, to display the appropriate client user interface. These are the <code>slotToElicit</code>, <code>dialogState</code>, <code>intentName</code>, and <code>slots</code> fields in the response. Consider the following examples: </p> <ul> <li> <p>If the message is to elicit slot data, Amazon Lex returns the following context information:</p> <ul> <li> <p> <code>dialogState</code> set to ElicitSlot </p> </li> <li> <p> <code>intentName</code> set to the intent name in the current context </p> </li> <li> <p> <code>slotToElicit</code> set to the slot name for which the <code>message</code> is eliciting information </p> </li> <li> <p> <code>slots</code> set to a map of slots, configured for the intent, with currently known values </p> </li> </ul> </li> <li> <p> If the message is a confirmation prompt, the <code>dialogState</code> is set to ConfirmIntent and <code>SlotToElicit</code> is set to null. </p> </li> <li> <p>If the message is a clarification prompt (configured for the intent) that indicates that user intent is not understood, the <code>dialogState</code> is set to ElicitIntent and <code>slotToElicit</code> is set to null. </p> </li> </ul> <p> In addition, Amazon Lex also returns your application-specific <code>sessionAttributes</code>. For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html">Managing Conversation Context</a>. </p>
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
  var valid_600039 = path.getOrDefault("botName")
  valid_600039 = validateParameter(valid_600039, JString, required = true,
                                 default = nil)
  if valid_600039 != nil:
    section.add "botName", valid_600039
  var valid_600040 = path.getOrDefault("botAlias")
  valid_600040 = validateParameter(valid_600040, JString, required = true,
                                 default = nil)
  if valid_600040 != nil:
    section.add "botAlias", valid_600040
  var valid_600041 = path.getOrDefault("userId")
  valid_600041 = validateParameter(valid_600041, JString, required = true,
                                 default = nil)
  if valid_600041 != nil:
    section.add "userId", valid_600041
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
  var valid_600042 = header.getOrDefault("X-Amz-Date")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Date", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Security-Token")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Security-Token", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Content-Sha256", valid_600044
  var valid_600045 = header.getOrDefault("X-Amz-Algorithm")
  valid_600045 = validateParameter(valid_600045, JString, required = false,
                                 default = nil)
  if valid_600045 != nil:
    section.add "X-Amz-Algorithm", valid_600045
  var valid_600046 = header.getOrDefault("X-Amz-Signature")
  valid_600046 = validateParameter(valid_600046, JString, required = false,
                                 default = nil)
  if valid_600046 != nil:
    section.add "X-Amz-Signature", valid_600046
  var valid_600047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600047 = validateParameter(valid_600047, JString, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "X-Amz-SignedHeaders", valid_600047
  var valid_600048 = header.getOrDefault("X-Amz-Credential")
  valid_600048 = validateParameter(valid_600048, JString, required = false,
                                 default = nil)
  if valid_600048 != nil:
    section.add "X-Amz-Credential", valid_600048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600050: Call_PostText_600036; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends user input to Amazon Lex. Client applications can use this API to send requests to Amazon Lex at runtime. Amazon Lex then interprets the user input using the machine learning model it built for the bot. </p> <p> In response, Amazon Lex returns the next <code>message</code> to convey to the user an optional <code>responseCard</code> to display. Consider the following example messages: </p> <ul> <li> <p> For a user input "I would like a pizza", Amazon Lex might return a response with a message eliciting slot data (for example, PizzaSize): "What size pizza would you like?" </p> </li> <li> <p> After the user provides all of the pizza order information, Amazon Lex might return a response with a message to obtain user confirmation "Proceed with the pizza order?". </p> </li> <li> <p> After the user replies to a confirmation prompt with a "yes", Amazon Lex might return a conclusion statement: "Thank you, your cheese pizza has been ordered.". </p> </li> </ul> <p> Not all Amazon Lex messages require a user response. For example, a conclusion statement does not require a response. Some messages require only a "yes" or "no" user response. In addition to the <code>message</code>, Amazon Lex provides additional context about the message in the response that you might use to enhance client behavior, for example, to display the appropriate client user interface. These are the <code>slotToElicit</code>, <code>dialogState</code>, <code>intentName</code>, and <code>slots</code> fields in the response. Consider the following examples: </p> <ul> <li> <p>If the message is to elicit slot data, Amazon Lex returns the following context information:</p> <ul> <li> <p> <code>dialogState</code> set to ElicitSlot </p> </li> <li> <p> <code>intentName</code> set to the intent name in the current context </p> </li> <li> <p> <code>slotToElicit</code> set to the slot name for which the <code>message</code> is eliciting information </p> </li> <li> <p> <code>slots</code> set to a map of slots, configured for the intent, with currently known values </p> </li> </ul> </li> <li> <p> If the message is a confirmation prompt, the <code>dialogState</code> is set to ConfirmIntent and <code>SlotToElicit</code> is set to null. </p> </li> <li> <p>If the message is a clarification prompt (configured for the intent) that indicates that user intent is not understood, the <code>dialogState</code> is set to ElicitIntent and <code>slotToElicit</code> is set to null. </p> </li> </ul> <p> In addition, Amazon Lex also returns your application-specific <code>sessionAttributes</code>. For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html">Managing Conversation Context</a>. </p>
  ## 
  let valid = call_600050.validator(path, query, header, formData, body)
  let scheme = call_600050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600050.url(scheme.get, call_600050.host, call_600050.base,
                         call_600050.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600050, url, valid)

proc call*(call_600051: Call_PostText_600036; botName: string; body: JsonNode;
          botAlias: string; userId: string): Recallable =
  ## postText
  ## <p>Sends user input to Amazon Lex. Client applications can use this API to send requests to Amazon Lex at runtime. Amazon Lex then interprets the user input using the machine learning model it built for the bot. </p> <p> In response, Amazon Lex returns the next <code>message</code> to convey to the user an optional <code>responseCard</code> to display. Consider the following example messages: </p> <ul> <li> <p> For a user input "I would like a pizza", Amazon Lex might return a response with a message eliciting slot data (for example, PizzaSize): "What size pizza would you like?" </p> </li> <li> <p> After the user provides all of the pizza order information, Amazon Lex might return a response with a message to obtain user confirmation "Proceed with the pizza order?". </p> </li> <li> <p> After the user replies to a confirmation prompt with a "yes", Amazon Lex might return a conclusion statement: "Thank you, your cheese pizza has been ordered.". </p> </li> </ul> <p> Not all Amazon Lex messages require a user response. For example, a conclusion statement does not require a response. Some messages require only a "yes" or "no" user response. In addition to the <code>message</code>, Amazon Lex provides additional context about the message in the response that you might use to enhance client behavior, for example, to display the appropriate client user interface. These are the <code>slotToElicit</code>, <code>dialogState</code>, <code>intentName</code>, and <code>slots</code> fields in the response. Consider the following examples: </p> <ul> <li> <p>If the message is to elicit slot data, Amazon Lex returns the following context information:</p> <ul> <li> <p> <code>dialogState</code> set to ElicitSlot </p> </li> <li> <p> <code>intentName</code> set to the intent name in the current context </p> </li> <li> <p> <code>slotToElicit</code> set to the slot name for which the <code>message</code> is eliciting information </p> </li> <li> <p> <code>slots</code> set to a map of slots, configured for the intent, with currently known values </p> </li> </ul> </li> <li> <p> If the message is a confirmation prompt, the <code>dialogState</code> is set to ConfirmIntent and <code>SlotToElicit</code> is set to null. </p> </li> <li> <p>If the message is a clarification prompt (configured for the intent) that indicates that user intent is not understood, the <code>dialogState</code> is set to ElicitIntent and <code>slotToElicit</code> is set to null. </p> </li> </ul> <p> In addition, Amazon Lex also returns your application-specific <code>sessionAttributes</code>. For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html">Managing Conversation Context</a>. </p>
  ##   botName: string (required)
  ##          : The name of the Amazon Lex bot.
  ##   body: JObject (required)
  ##   botAlias: string (required)
  ##           : The alias of the Amazon Lex bot.
  ##   userId: string (required)
  ##         : <p>The ID of the client application user. Amazon Lex uses this to identify a user's conversation with your bot. At runtime, each request must contain the <code>userID</code> field.</p> <p>To decide the user ID to use for your application, consider the following factors.</p> <ul> <li> <p>The <code>userID</code> field must not contain any personally identifiable information of the user, for example, name, personal identification numbers, or other end user personal information.</p> </li> <li> <p>If you want a user to start a conversation on one device and continue on another device, use a user-specific identifier.</p> </li> <li> <p>If you want the same user to be able to have two independent conversations on two different devices, choose a device-specific identifier.</p> </li> <li> <p>A user can't have two independent conversations with two different versions of the same bot. For example, a user can't have a conversation with the PROD and BETA versions of the same bot. If you anticipate that a user will need to have conversation with two different versions, for example, while testing, include the bot alias in the user ID to separate the two conversations.</p> </li> </ul>
  var path_600052 = newJObject()
  var body_600053 = newJObject()
  add(path_600052, "botName", newJString(botName))
  if body != nil:
    body_600053 = body
  add(path_600052, "botAlias", newJString(botAlias))
  add(path_600052, "userId", newJString(userId))
  result = call_600051.call(path_600052, nil, nil, nil, body_600053)

var postText* = Call_PostText_600036(name: "postText", meth: HttpMethod.HttpPost,
                                  host: "runtime.lex.amazonaws.com", route: "/bot/{botName}/alias/{botAlias}/user/{userId}/text",
                                  validator: validate_PostText_600037, base: "/",
                                  url: url_PostText_600038,
                                  schemes: {Scheme.Https, Scheme.Http})
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
