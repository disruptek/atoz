
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
  Call_PutSession_601727 = ref object of OpenApiRestCall_601389
proc url_PutSession_601729(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutSession_601728(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new session or modifies an existing session with an Amazon Lex bot. Use this operation to enable your application to set the state of the bot.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/how-session-api.html">Managing Sessions</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botName: JString (required)
  ##          : The name of the bot that contains the session data.
  ##   userId: JString (required)
  ##         : The ID of the client application user. Amazon Lex uses this to identify a user's conversation with your bot. 
  ##   botAlias: JString (required)
  ##           : The alias in use for the bot that contains the session data.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botName` field"
  var valid_601855 = path.getOrDefault("botName")
  valid_601855 = validateParameter(valid_601855, JString, required = true,
                                 default = nil)
  if valid_601855 != nil:
    section.add "botName", valid_601855
  var valid_601856 = path.getOrDefault("userId")
  valid_601856 = validateParameter(valid_601856, JString, required = true,
                                 default = nil)
  if valid_601856 != nil:
    section.add "userId", valid_601856
  var valid_601857 = path.getOrDefault("botAlias")
  valid_601857 = validateParameter(valid_601857, JString, required = true,
                                 default = nil)
  if valid_601857 != nil:
    section.add "botAlias", valid_601857
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
  ##   Accept: JString
  ##         : <p>The message that Amazon Lex returns in the response can be either text or speech based depending on the value of this field.</p> <ul> <li> <p>If the value is <code>text/plain; charset=utf-8</code>, Amazon Lex returns text in the response.</p> </li> <li> <p>If the value begins with <code>audio/</code>, Amazon Lex returns speech in the response. Amazon Lex uses Amazon Polly to generate the speech in the configuration that you specify. For example, if you specify <code>audio/mpeg</code> as the value, Amazon Lex returns speech in the MPEG format.</p> </li> <li> <p>If the value is <code>audio/pcm</code>, the speech is returned as <code>audio/pcm</code> in 16-bit, little endian format.</p> </li> <li> <p>The following are the accepted values:</p> <ul> <li> <p> <code>audio/mpeg</code> </p> </li> <li> <p> <code>audio/ogg</code> </p> </li> <li> <p> <code>audio/pcm</code> </p> </li> <li> <p> <code>audio/*</code> (defaults to mpeg)</p> </li> <li> <p> <code>text/plain; charset=utf-8</code> </p> </li> </ul> </li> </ul>
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601858 = header.getOrDefault("X-Amz-Signature")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Signature", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Content-Sha256", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Date")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Date", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Credential")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Credential", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-Security-Token")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-Security-Token", valid_601862
  var valid_601863 = header.getOrDefault("X-Amz-Algorithm")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-Algorithm", valid_601863
  var valid_601864 = header.getOrDefault("Accept")
  valid_601864 = validateParameter(valid_601864, JString, required = false,
                                 default = nil)
  if valid_601864 != nil:
    section.add "Accept", valid_601864
  var valid_601865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601865 = validateParameter(valid_601865, JString, required = false,
                                 default = nil)
  if valid_601865 != nil:
    section.add "X-Amz-SignedHeaders", valid_601865
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601889: Call_PutSession_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new session or modifies an existing session with an Amazon Lex bot. Use this operation to enable your application to set the state of the bot.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/how-session-api.html">Managing Sessions</a>.</p>
  ## 
  let valid = call_601889.validator(path, query, header, formData, body)
  let scheme = call_601889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601889.url(scheme.get, call_601889.host, call_601889.base,
                         call_601889.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601889, url, valid)

proc call*(call_601960: Call_PutSession_601727; botName: string; userId: string;
          botAlias: string; body: JsonNode): Recallable =
  ## putSession
  ## <p>Creates a new session or modifies an existing session with an Amazon Lex bot. Use this operation to enable your application to set the state of the bot.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/how-session-api.html">Managing Sessions</a>.</p>
  ##   botName: string (required)
  ##          : The name of the bot that contains the session data.
  ##   userId: string (required)
  ##         : The ID of the client application user. Amazon Lex uses this to identify a user's conversation with your bot. 
  ##   botAlias: string (required)
  ##           : The alias in use for the bot that contains the session data.
  ##   body: JObject (required)
  var path_601961 = newJObject()
  var body_601963 = newJObject()
  add(path_601961, "botName", newJString(botName))
  add(path_601961, "userId", newJString(userId))
  add(path_601961, "botAlias", newJString(botAlias))
  if body != nil:
    body_601963 = body
  result = call_601960.call(path_601961, nil, nil, nil, body_601963)

var putSession* = Call_PutSession_601727(name: "putSession",
                                      meth: HttpMethod.HttpPost,
                                      host: "runtime.lex.amazonaws.com", route: "/bot/{botName}/alias/{botAlias}/user/{userId}/session",
                                      validator: validate_PutSession_601728,
                                      base: "/", url: url_PutSession_601729,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSession_602002 = ref object of OpenApiRestCall_601389
proc url_DeleteSession_602004(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSession_602003(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes session information for a specified bot, alias, and user ID. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botName: JString (required)
  ##          : The name of the bot that contains the session data.
  ##   userId: JString (required)
  ##         : The identifier of the user associated with the session data.
  ##   botAlias: JString (required)
  ##           : The alias in use for the bot that contains the session data.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botName` field"
  var valid_602005 = path.getOrDefault("botName")
  valid_602005 = validateParameter(valid_602005, JString, required = true,
                                 default = nil)
  if valid_602005 != nil:
    section.add "botName", valid_602005
  var valid_602006 = path.getOrDefault("userId")
  valid_602006 = validateParameter(valid_602006, JString, required = true,
                                 default = nil)
  if valid_602006 != nil:
    section.add "userId", valid_602006
  var valid_602007 = path.getOrDefault("botAlias")
  valid_602007 = validateParameter(valid_602007, JString, required = true,
                                 default = nil)
  if valid_602007 != nil:
    section.add "botAlias", valid_602007
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
  var valid_602008 = header.getOrDefault("X-Amz-Signature")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Signature", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Content-Sha256", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Date")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Date", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-Credential")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-Credential", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-Security-Token")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-Security-Token", valid_602012
  var valid_602013 = header.getOrDefault("X-Amz-Algorithm")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "X-Amz-Algorithm", valid_602013
  var valid_602014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602014 = validateParameter(valid_602014, JString, required = false,
                                 default = nil)
  if valid_602014 != nil:
    section.add "X-Amz-SignedHeaders", valid_602014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602015: Call_DeleteSession_602002; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes session information for a specified bot, alias, and user ID. 
  ## 
  let valid = call_602015.validator(path, query, header, formData, body)
  let scheme = call_602015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602015.url(scheme.get, call_602015.host, call_602015.base,
                         call_602015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602015, url, valid)

proc call*(call_602016: Call_DeleteSession_602002; botName: string; userId: string;
          botAlias: string): Recallable =
  ## deleteSession
  ## Removes session information for a specified bot, alias, and user ID. 
  ##   botName: string (required)
  ##          : The name of the bot that contains the session data.
  ##   userId: string (required)
  ##         : The identifier of the user associated with the session data.
  ##   botAlias: string (required)
  ##           : The alias in use for the bot that contains the session data.
  var path_602017 = newJObject()
  add(path_602017, "botName", newJString(botName))
  add(path_602017, "userId", newJString(userId))
  add(path_602017, "botAlias", newJString(botAlias))
  result = call_602016.call(path_602017, nil, nil, nil, nil)

var deleteSession* = Call_DeleteSession_602002(name: "deleteSession",
    meth: HttpMethod.HttpDelete, host: "runtime.lex.amazonaws.com",
    route: "/bot/{botName}/alias/{botAlias}/user/{userId}/session",
    validator: validate_DeleteSession_602003, base: "/", url: url_DeleteSession_602004,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSession_602018 = ref object of OpenApiRestCall_601389
proc url_GetSession_602020(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSession_602019(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns session information for a specified bot, alias, and user ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botName: JString (required)
  ##          : The name of the bot that contains the session data.
  ##   userId: JString (required)
  ##         : The ID of the client application user. Amazon Lex uses this to identify a user's conversation with your bot. 
  ##   botAlias: JString (required)
  ##           : The alias in use for the bot that contains the session data.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botName` field"
  var valid_602021 = path.getOrDefault("botName")
  valid_602021 = validateParameter(valid_602021, JString, required = true,
                                 default = nil)
  if valid_602021 != nil:
    section.add "botName", valid_602021
  var valid_602022 = path.getOrDefault("userId")
  valid_602022 = validateParameter(valid_602022, JString, required = true,
                                 default = nil)
  if valid_602022 != nil:
    section.add "userId", valid_602022
  var valid_602023 = path.getOrDefault("botAlias")
  valid_602023 = validateParameter(valid_602023, JString, required = true,
                                 default = nil)
  if valid_602023 != nil:
    section.add "botAlias", valid_602023
  result.add "path", section
  ## parameters in `query` object:
  ##   checkpointLabelFilter: JString
  ##                        : <p>A string used to filter the intents returned in the <code>recentIntentSummaryView</code> structure. </p> <p>When you specify a filter, only intents with their <code>checkpointLabel</code> field set to that string are returned.</p>
  section = newJObject()
  var valid_602024 = query.getOrDefault("checkpointLabelFilter")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "checkpointLabelFilter", valid_602024
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
  var valid_602025 = header.getOrDefault("X-Amz-Signature")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Signature", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Content-Sha256", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Date")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Date", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Credential")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Credential", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-Security-Token")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Security-Token", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Algorithm")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Algorithm", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-SignedHeaders", valid_602031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602032: Call_GetSession_602018; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns session information for a specified bot, alias, and user ID.
  ## 
  let valid = call_602032.validator(path, query, header, formData, body)
  let scheme = call_602032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602032.url(scheme.get, call_602032.host, call_602032.base,
                         call_602032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602032, url, valid)

proc call*(call_602033: Call_GetSession_602018; botName: string; userId: string;
          botAlias: string; checkpointLabelFilter: string = ""): Recallable =
  ## getSession
  ## Returns session information for a specified bot, alias, and user ID.
  ##   botName: string (required)
  ##          : The name of the bot that contains the session data.
  ##   checkpointLabelFilter: string
  ##                        : <p>A string used to filter the intents returned in the <code>recentIntentSummaryView</code> structure. </p> <p>When you specify a filter, only intents with their <code>checkpointLabel</code> field set to that string are returned.</p>
  ##   userId: string (required)
  ##         : The ID of the client application user. Amazon Lex uses this to identify a user's conversation with your bot. 
  ##   botAlias: string (required)
  ##           : The alias in use for the bot that contains the session data.
  var path_602034 = newJObject()
  var query_602035 = newJObject()
  add(path_602034, "botName", newJString(botName))
  add(query_602035, "checkpointLabelFilter", newJString(checkpointLabelFilter))
  add(path_602034, "userId", newJString(userId))
  add(path_602034, "botAlias", newJString(botAlias))
  result = call_602033.call(path_602034, query_602035, nil, nil, nil)

var getSession* = Call_GetSession_602018(name: "getSession",
                                      meth: HttpMethod.HttpGet,
                                      host: "runtime.lex.amazonaws.com", route: "/bot/{botName}/alias/{botAlias}/user/{userId}/session/",
                                      validator: validate_GetSession_602019,
                                      base: "/", url: url_GetSession_602020,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostContent_602036 = ref object of OpenApiRestCall_601389
proc url_PostContent_602038(protocol: Scheme; host: string; base: string;
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

proc validate_PostContent_602037(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Sends user input (text or speech) to Amazon Lex. Clients use this API to send text and audio requests to Amazon Lex at runtime. Amazon Lex interprets the user input using the machine learning model that it built for the bot. </p> <p>The <code>PostContent</code> operation supports audio input at 8kHz and 16kHz. You can use 8kHz audio to achieve higher speech recognition accuracy in telephone audio applications. </p> <p> In response, Amazon Lex returns the next message to convey to the user. Consider the following example messages: </p> <ul> <li> <p> For a user input "I would like a pizza," Amazon Lex might return a response with a message eliciting slot data (for example, <code>PizzaSize</code>): "What size pizza would you like?". </p> </li> <li> <p> After the user provides all of the pizza order information, Amazon Lex might return a response with a message to get user confirmation: "Order the pizza?". </p> </li> <li> <p> After the user replies "Yes" to the confirmation prompt, Amazon Lex might return a conclusion statement: "Thank you, your cheese pizza has been ordered.". </p> </li> </ul> <p> Not all Amazon Lex messages require a response from the user. For example, conclusion statements do not require a response. Some messages require only a yes or no response. In addition to the <code>message</code>, Amazon Lex provides additional context about the message in the response that you can use to enhance client behavior, such as displaying the appropriate client user interface. Consider the following examples: </p> <ul> <li> <p> If the message is to elicit slot data, Amazon Lex returns the following context information: </p> <ul> <li> <p> <code>x-amz-lex-dialog-state</code> header set to <code>ElicitSlot</code> </p> </li> <li> <p> <code>x-amz-lex-intent-name</code> header set to the intent name in the current context </p> </li> <li> <p> <code>x-amz-lex-slot-to-elicit</code> header set to the slot name for which the <code>message</code> is eliciting information </p> </li> <li> <p> <code>x-amz-lex-slots</code> header set to a map of slots configured for the intent with their current values </p> </li> </ul> </li> <li> <p> If the message is a confirmation prompt, the <code>x-amz-lex-dialog-state</code> header is set to <code>Confirmation</code> and the <code>x-amz-lex-slot-to-elicit</code> header is omitted. </p> </li> <li> <p> If the message is a clarification prompt configured for the intent, indicating that the user intent is not understood, the <code>x-amz-dialog-state</code> header is set to <code>ElicitIntent</code> and the <code>x-amz-slot-to-elicit</code> header is omitted. </p> </li> </ul> <p> In addition, Amazon Lex also returns your application-specific <code>sessionAttributes</code>. For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html">Managing Conversation Context</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botName: JString (required)
  ##          : Name of the Amazon Lex bot.
  ##   userId: JString (required)
  ##         : <p>The ID of the client application user. Amazon Lex uses this to identify a user's conversation with your bot. At runtime, each request must contain the <code>userID</code> field.</p> <p>To decide the user ID to use for your application, consider the following factors.</p> <ul> <li> <p>The <code>userID</code> field must not contain any personally identifiable information of the user, for example, name, personal identification numbers, or other end user personal information.</p> </li> <li> <p>If you want a user to start a conversation on one device and continue on another device, use a user-specific identifier.</p> </li> <li> <p>If you want the same user to be able to have two independent conversations on two different devices, choose a device-specific identifier.</p> </li> <li> <p>A user can't have two independent conversations with two different versions of the same bot. For example, a user can't have a conversation with the PROD and BETA versions of the same bot. If you anticipate that a user will need to have conversation with two different versions, for example, while testing, include the bot alias in the user ID to separate the two conversations.</p> </li> </ul>
  ##   botAlias: JString (required)
  ##           : Alias of the Amazon Lex bot.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botName` field"
  var valid_602039 = path.getOrDefault("botName")
  valid_602039 = validateParameter(valid_602039, JString, required = true,
                                 default = nil)
  if valid_602039 != nil:
    section.add "botName", valid_602039
  var valid_602040 = path.getOrDefault("userId")
  valid_602040 = validateParameter(valid_602040, JString, required = true,
                                 default = nil)
  if valid_602040 != nil:
    section.add "userId", valid_602040
  var valid_602041 = path.getOrDefault("botAlias")
  valid_602041 = validateParameter(valid_602041, JString, required = true,
                                 default = nil)
  if valid_602041 != nil:
    section.add "botAlias", valid_602041
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-lex-session-attributes: JString
  ##                               : <p>You pass this value as the <code>x-amz-lex-session-attributes</code> HTTP header.</p> <p>Application-specific information passed between Amazon Lex and a client application. The value must be a JSON serialized and base64 encoded map with string keys and values. The total size of the <code>sessionAttributes</code> and <code>requestAttributes</code> headers is limited to 12 KB.</p> <p>For more information, see <a 
  ## href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html#context-mgmt-session-attribs">Setting Session Attributes</a>.</p>
  ##   x-amz-lex-request-attributes: JString
  ##                               : <p>You pass this value as the <code>x-amz-lex-request-attributes</code> HTTP header.</p> <p>Request-specific information passed between Amazon Lex and a client application. The value must be a JSON serialized and base64 encoded map with string keys and values. The total size of the <code>requestAttributes</code> and <code>sessionAttributes</code> headers is limited to 12 KB.</p> <p>The namespace <code>x-amz-lex:</code> is reserved for special attributes. Don't create any request attributes with the prefix <code>x-amz-lex:</code>.</p> <p>For more information, see <a 
  ## href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html#context-mgmt-request-attribs">Setting Request Attributes</a>.</p>
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   Content-Type: JString (required)
  ##               : <p> You pass this value as the <code>Content-Type</code> HTTP header. </p> <p> Indicates the audio format or text. The header value must start with one of the following prefixes: </p> <ul> <li> <p>PCM format, audio data must be in little-endian byte order.</p> <ul> <li> <p>audio/l16; rate=16000; channels=1</p> </li> <li> <p>audio/x-l16; sample-rate=16000; channel-count=1</p> </li> <li> <p>audio/lpcm; sample-rate=8000; sample-size-bits=16; channel-count=1; is-big-endian=false </p> </li> </ul> </li> <li> <p>Opus format</p> <ul> <li> <p>audio/x-cbr-opus-with-preamble; preamble-size=0; bit-rate=256000; frame-size-milliseconds=4</p> </li> </ul> </li> <li> <p>Text format</p> <ul> <li> <p>text/plain; charset=utf-8</p> </li> </ul> </li> </ul>
  ##   X-Amz-Algorithm: JString
  ##   Accept: JString
  ##         : <p> You pass this value as the <code>Accept</code> HTTP header. </p> <p> The message Amazon Lex returns in the response can be either text or speech based on the <code>Accept</code> HTTP header value in the request. </p> <ul> <li> <p> If the value is <code>text/plain; charset=utf-8</code>, Amazon Lex returns text in the response. </p> </li> <li> <p> If the value begins with <code>audio/</code>, Amazon Lex returns speech in the response. Amazon Lex uses Amazon Polly to generate the speech (using the configuration you specified in the <code>Accept</code> header). For example, if you specify <code>audio/mpeg</code> as the value, Amazon Lex returns speech in the MPEG format.</p> </li> <li> <p>If the value is <code>audio/pcm</code>, the speech returned is <code>audio/pcm</code> in 16-bit, little endian format. </p> </li> <li> <p>The following are the accepted values:</p> <ul> <li> <p>audio/mpeg</p> </li> <li> <p>audio/ogg</p> </li> <li> <p>audio/pcm</p> </li> <li> <p>text/plain; charset=utf-8</p> </li> <li> <p>audio/* (defaults to mpeg)</p> </li> </ul> </li> </ul>
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602042 = header.getOrDefault("x-amz-lex-session-attributes")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "x-amz-lex-session-attributes", valid_602042
  var valid_602043 = header.getOrDefault("x-amz-lex-request-attributes")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "x-amz-lex-request-attributes", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-Signature")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Signature", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Content-Sha256", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Date")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Date", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Credential")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Credential", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Security-Token")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Security-Token", valid_602048
  assert header != nil,
        "header argument is necessary due to required `Content-Type` field"
  var valid_602049 = header.getOrDefault("Content-Type")
  valid_602049 = validateParameter(valid_602049, JString, required = true,
                                 default = nil)
  if valid_602049 != nil:
    section.add "Content-Type", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Algorithm")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Algorithm", valid_602050
  var valid_602051 = header.getOrDefault("Accept")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "Accept", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-SignedHeaders", valid_602052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602054: Call_PostContent_602036; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Sends user input (text or speech) to Amazon Lex. Clients use this API to send text and audio requests to Amazon Lex at runtime. Amazon Lex interprets the user input using the machine learning model that it built for the bot. </p> <p>The <code>PostContent</code> operation supports audio input at 8kHz and 16kHz. You can use 8kHz audio to achieve higher speech recognition accuracy in telephone audio applications. </p> <p> In response, Amazon Lex returns the next message to convey to the user. Consider the following example messages: </p> <ul> <li> <p> For a user input "I would like a pizza," Amazon Lex might return a response with a message eliciting slot data (for example, <code>PizzaSize</code>): "What size pizza would you like?". </p> </li> <li> <p> After the user provides all of the pizza order information, Amazon Lex might return a response with a message to get user confirmation: "Order the pizza?". </p> </li> <li> <p> After the user replies "Yes" to the confirmation prompt, Amazon Lex might return a conclusion statement: "Thank you, your cheese pizza has been ordered.". </p> </li> </ul> <p> Not all Amazon Lex messages require a response from the user. For example, conclusion statements do not require a response. Some messages require only a yes or no response. In addition to the <code>message</code>, Amazon Lex provides additional context about the message in the response that you can use to enhance client behavior, such as displaying the appropriate client user interface. Consider the following examples: </p> <ul> <li> <p> If the message is to elicit slot data, Amazon Lex returns the following context information: </p> <ul> <li> <p> <code>x-amz-lex-dialog-state</code> header set to <code>ElicitSlot</code> </p> </li> <li> <p> <code>x-amz-lex-intent-name</code> header set to the intent name in the current context </p> </li> <li> <p> <code>x-amz-lex-slot-to-elicit</code> header set to the slot name for which the <code>message</code> is eliciting information </p> </li> <li> <p> <code>x-amz-lex-slots</code> header set to a map of slots configured for the intent with their current values </p> </li> </ul> </li> <li> <p> If the message is a confirmation prompt, the <code>x-amz-lex-dialog-state</code> header is set to <code>Confirmation</code> and the <code>x-amz-lex-slot-to-elicit</code> header is omitted. </p> </li> <li> <p> If the message is a clarification prompt configured for the intent, indicating that the user intent is not understood, the <code>x-amz-dialog-state</code> header is set to <code>ElicitIntent</code> and the <code>x-amz-slot-to-elicit</code> header is omitted. </p> </li> </ul> <p> In addition, Amazon Lex also returns your application-specific <code>sessionAttributes</code>. For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html">Managing Conversation Context</a>. </p>
  ## 
  let valid = call_602054.validator(path, query, header, formData, body)
  let scheme = call_602054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602054.url(scheme.get, call_602054.host, call_602054.base,
                         call_602054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602054, url, valid)

proc call*(call_602055: Call_PostContent_602036; botName: string; userId: string;
          botAlias: string; body: JsonNode): Recallable =
  ## postContent
  ## <p> Sends user input (text or speech) to Amazon Lex. Clients use this API to send text and audio requests to Amazon Lex at runtime. Amazon Lex interprets the user input using the machine learning model that it built for the bot. </p> <p>The <code>PostContent</code> operation supports audio input at 8kHz and 16kHz. You can use 8kHz audio to achieve higher speech recognition accuracy in telephone audio applications. </p> <p> In response, Amazon Lex returns the next message to convey to the user. Consider the following example messages: </p> <ul> <li> <p> For a user input "I would like a pizza," Amazon Lex might return a response with a message eliciting slot data (for example, <code>PizzaSize</code>): "What size pizza would you like?". </p> </li> <li> <p> After the user provides all of the pizza order information, Amazon Lex might return a response with a message to get user confirmation: "Order the pizza?". </p> </li> <li> <p> After the user replies "Yes" to the confirmation prompt, Amazon Lex might return a conclusion statement: "Thank you, your cheese pizza has been ordered.". </p> </li> </ul> <p> Not all Amazon Lex messages require a response from the user. For example, conclusion statements do not require a response. Some messages require only a yes or no response. In addition to the <code>message</code>, Amazon Lex provides additional context about the message in the response that you can use to enhance client behavior, such as displaying the appropriate client user interface. Consider the following examples: </p> <ul> <li> <p> If the message is to elicit slot data, Amazon Lex returns the following context information: </p> <ul> <li> <p> <code>x-amz-lex-dialog-state</code> header set to <code>ElicitSlot</code> </p> </li> <li> <p> <code>x-amz-lex-intent-name</code> header set to the intent name in the current context </p> </li> <li> <p> <code>x-amz-lex-slot-to-elicit</code> header set to the slot name for which the <code>message</code> is eliciting information </p> </li> <li> <p> <code>x-amz-lex-slots</code> header set to a map of slots configured for the intent with their current values </p> </li> </ul> </li> <li> <p> If the message is a confirmation prompt, the <code>x-amz-lex-dialog-state</code> header is set to <code>Confirmation</code> and the <code>x-amz-lex-slot-to-elicit</code> header is omitted. </p> </li> <li> <p> If the message is a clarification prompt configured for the intent, indicating that the user intent is not understood, the <code>x-amz-dialog-state</code> header is set to <code>ElicitIntent</code> and the <code>x-amz-slot-to-elicit</code> header is omitted. </p> </li> </ul> <p> In addition, Amazon Lex also returns your application-specific <code>sessionAttributes</code>. For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html">Managing Conversation Context</a>. </p>
  ##   botName: string (required)
  ##          : Name of the Amazon Lex bot.
  ##   userId: string (required)
  ##         : <p>The ID of the client application user. Amazon Lex uses this to identify a user's conversation with your bot. At runtime, each request must contain the <code>userID</code> field.</p> <p>To decide the user ID to use for your application, consider the following factors.</p> <ul> <li> <p>The <code>userID</code> field must not contain any personally identifiable information of the user, for example, name, personal identification numbers, or other end user personal information.</p> </li> <li> <p>If you want a user to start a conversation on one device and continue on another device, use a user-specific identifier.</p> </li> <li> <p>If you want the same user to be able to have two independent conversations on two different devices, choose a device-specific identifier.</p> </li> <li> <p>A user can't have two independent conversations with two different versions of the same bot. For example, a user can't have a conversation with the PROD and BETA versions of the same bot. If you anticipate that a user will need to have conversation with two different versions, for example, while testing, include the bot alias in the user ID to separate the two conversations.</p> </li> </ul>
  ##   botAlias: string (required)
  ##           : Alias of the Amazon Lex bot.
  ##   body: JObject (required)
  var path_602056 = newJObject()
  var body_602057 = newJObject()
  add(path_602056, "botName", newJString(botName))
  add(path_602056, "userId", newJString(userId))
  add(path_602056, "botAlias", newJString(botAlias))
  if body != nil:
    body_602057 = body
  result = call_602055.call(path_602056, nil, nil, nil, body_602057)

var postContent* = Call_PostContent_602036(name: "postContent",
                                        meth: HttpMethod.HttpPost,
                                        host: "runtime.lex.amazonaws.com", route: "/bot/{botName}/alias/{botAlias}/user/{userId}/content#Content-Type",
                                        validator: validate_PostContent_602037,
                                        base: "/", url: url_PostContent_602038,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostText_602058 = ref object of OpenApiRestCall_601389
proc url_PostText_602060(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PostText_602059(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sends user input to Amazon Lex. Client applications can use this API to send requests to Amazon Lex at runtime. Amazon Lex then interprets the user input using the machine learning model it built for the bot. </p> <p> In response, Amazon Lex returns the next <code>message</code> to convey to the user an optional <code>responseCard</code> to display. Consider the following example messages: </p> <ul> <li> <p> For a user input "I would like a pizza", Amazon Lex might return a response with a message eliciting slot data (for example, PizzaSize): "What size pizza would you like?" </p> </li> <li> <p> After the user provides all of the pizza order information, Amazon Lex might return a response with a message to obtain user confirmation "Proceed with the pizza order?". </p> </li> <li> <p> After the user replies to a confirmation prompt with a "yes", Amazon Lex might return a conclusion statement: "Thank you, your cheese pizza has been ordered.". </p> </li> </ul> <p> Not all Amazon Lex messages require a user response. For example, a conclusion statement does not require a response. Some messages require only a "yes" or "no" user response. In addition to the <code>message</code>, Amazon Lex provides additional context about the message in the response that you might use to enhance client behavior, for example, to display the appropriate client user interface. These are the <code>slotToElicit</code>, <code>dialogState</code>, <code>intentName</code>, and <code>slots</code> fields in the response. Consider the following examples: </p> <ul> <li> <p>If the message is to elicit slot data, Amazon Lex returns the following context information:</p> <ul> <li> <p> <code>dialogState</code> set to ElicitSlot </p> </li> <li> <p> <code>intentName</code> set to the intent name in the current context </p> </li> <li> <p> <code>slotToElicit</code> set to the slot name for which the <code>message</code> is eliciting information </p> </li> <li> <p> <code>slots</code> set to a map of slots, configured for the intent, with currently known values </p> </li> </ul> </li> <li> <p> If the message is a confirmation prompt, the <code>dialogState</code> is set to ConfirmIntent and <code>SlotToElicit</code> is set to null. </p> </li> <li> <p>If the message is a clarification prompt (configured for the intent) that indicates that user intent is not understood, the <code>dialogState</code> is set to ElicitIntent and <code>slotToElicit</code> is set to null. </p> </li> </ul> <p> In addition, Amazon Lex also returns your application-specific <code>sessionAttributes</code>. For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html">Managing Conversation Context</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botName: JString (required)
  ##          : The name of the Amazon Lex bot.
  ##   userId: JString (required)
  ##         : <p>The ID of the client application user. Amazon Lex uses this to identify a user's conversation with your bot. At runtime, each request must contain the <code>userID</code> field.</p> <p>To decide the user ID to use for your application, consider the following factors.</p> <ul> <li> <p>The <code>userID</code> field must not contain any personally identifiable information of the user, for example, name, personal identification numbers, or other end user personal information.</p> </li> <li> <p>If you want a user to start a conversation on one device and continue on another device, use a user-specific identifier.</p> </li> <li> <p>If you want the same user to be able to have two independent conversations on two different devices, choose a device-specific identifier.</p> </li> <li> <p>A user can't have two independent conversations with two different versions of the same bot. For example, a user can't have a conversation with the PROD and BETA versions of the same bot. If you anticipate that a user will need to have conversation with two different versions, for example, while testing, include the bot alias in the user ID to separate the two conversations.</p> </li> </ul>
  ##   botAlias: JString (required)
  ##           : The alias of the Amazon Lex bot.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botName` field"
  var valid_602061 = path.getOrDefault("botName")
  valid_602061 = validateParameter(valid_602061, JString, required = true,
                                 default = nil)
  if valid_602061 != nil:
    section.add "botName", valid_602061
  var valid_602062 = path.getOrDefault("userId")
  valid_602062 = validateParameter(valid_602062, JString, required = true,
                                 default = nil)
  if valid_602062 != nil:
    section.add "userId", valid_602062
  var valid_602063 = path.getOrDefault("botAlias")
  valid_602063 = validateParameter(valid_602063, JString, required = true,
                                 default = nil)
  if valid_602063 != nil:
    section.add "botAlias", valid_602063
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
  var valid_602064 = header.getOrDefault("X-Amz-Signature")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Signature", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Content-Sha256", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-Date")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Date", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-Credential")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-Credential", valid_602067
  var valid_602068 = header.getOrDefault("X-Amz-Security-Token")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Security-Token", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-Algorithm")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-Algorithm", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-SignedHeaders", valid_602070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602072: Call_PostText_602058; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends user input to Amazon Lex. Client applications can use this API to send requests to Amazon Lex at runtime. Amazon Lex then interprets the user input using the machine learning model it built for the bot. </p> <p> In response, Amazon Lex returns the next <code>message</code> to convey to the user an optional <code>responseCard</code> to display. Consider the following example messages: </p> <ul> <li> <p> For a user input "I would like a pizza", Amazon Lex might return a response with a message eliciting slot data (for example, PizzaSize): "What size pizza would you like?" </p> </li> <li> <p> After the user provides all of the pizza order information, Amazon Lex might return a response with a message to obtain user confirmation "Proceed with the pizza order?". </p> </li> <li> <p> After the user replies to a confirmation prompt with a "yes", Amazon Lex might return a conclusion statement: "Thank you, your cheese pizza has been ordered.". </p> </li> </ul> <p> Not all Amazon Lex messages require a user response. For example, a conclusion statement does not require a response. Some messages require only a "yes" or "no" user response. In addition to the <code>message</code>, Amazon Lex provides additional context about the message in the response that you might use to enhance client behavior, for example, to display the appropriate client user interface. These are the <code>slotToElicit</code>, <code>dialogState</code>, <code>intentName</code>, and <code>slots</code> fields in the response. Consider the following examples: </p> <ul> <li> <p>If the message is to elicit slot data, Amazon Lex returns the following context information:</p> <ul> <li> <p> <code>dialogState</code> set to ElicitSlot </p> </li> <li> <p> <code>intentName</code> set to the intent name in the current context </p> </li> <li> <p> <code>slotToElicit</code> set to the slot name for which the <code>message</code> is eliciting information </p> </li> <li> <p> <code>slots</code> set to a map of slots, configured for the intent, with currently known values </p> </li> </ul> </li> <li> <p> If the message is a confirmation prompt, the <code>dialogState</code> is set to ConfirmIntent and <code>SlotToElicit</code> is set to null. </p> </li> <li> <p>If the message is a clarification prompt (configured for the intent) that indicates that user intent is not understood, the <code>dialogState</code> is set to ElicitIntent and <code>slotToElicit</code> is set to null. </p> </li> </ul> <p> In addition, Amazon Lex also returns your application-specific <code>sessionAttributes</code>. For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html">Managing Conversation Context</a>. </p>
  ## 
  let valid = call_602072.validator(path, query, header, formData, body)
  let scheme = call_602072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602072.url(scheme.get, call_602072.host, call_602072.base,
                         call_602072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602072, url, valid)

proc call*(call_602073: Call_PostText_602058; botName: string; userId: string;
          botAlias: string; body: JsonNode): Recallable =
  ## postText
  ## <p>Sends user input to Amazon Lex. Client applications can use this API to send requests to Amazon Lex at runtime. Amazon Lex then interprets the user input using the machine learning model it built for the bot. </p> <p> In response, Amazon Lex returns the next <code>message</code> to convey to the user an optional <code>responseCard</code> to display. Consider the following example messages: </p> <ul> <li> <p> For a user input "I would like a pizza", Amazon Lex might return a response with a message eliciting slot data (for example, PizzaSize): "What size pizza would you like?" </p> </li> <li> <p> After the user provides all of the pizza order information, Amazon Lex might return a response with a message to obtain user confirmation "Proceed with the pizza order?". </p> </li> <li> <p> After the user replies to a confirmation prompt with a "yes", Amazon Lex might return a conclusion statement: "Thank you, your cheese pizza has been ordered.". </p> </li> </ul> <p> Not all Amazon Lex messages require a user response. For example, a conclusion statement does not require a response. Some messages require only a "yes" or "no" user response. In addition to the <code>message</code>, Amazon Lex provides additional context about the message in the response that you might use to enhance client behavior, for example, to display the appropriate client user interface. These are the <code>slotToElicit</code>, <code>dialogState</code>, <code>intentName</code>, and <code>slots</code> fields in the response. Consider the following examples: </p> <ul> <li> <p>If the message is to elicit slot data, Amazon Lex returns the following context information:</p> <ul> <li> <p> <code>dialogState</code> set to ElicitSlot </p> </li> <li> <p> <code>intentName</code> set to the intent name in the current context </p> </li> <li> <p> <code>slotToElicit</code> set to the slot name for which the <code>message</code> is eliciting information </p> </li> <li> <p> <code>slots</code> set to a map of slots, configured for the intent, with currently known values </p> </li> </ul> </li> <li> <p> If the message is a confirmation prompt, the <code>dialogState</code> is set to ConfirmIntent and <code>SlotToElicit</code> is set to null. </p> </li> <li> <p>If the message is a clarification prompt (configured for the intent) that indicates that user intent is not understood, the <code>dialogState</code> is set to ElicitIntent and <code>slotToElicit</code> is set to null. </p> </li> </ul> <p> In addition, Amazon Lex also returns your application-specific <code>sessionAttributes</code>. For more information, see <a href="https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html">Managing Conversation Context</a>. </p>
  ##   botName: string (required)
  ##          : The name of the Amazon Lex bot.
  ##   userId: string (required)
  ##         : <p>The ID of the client application user. Amazon Lex uses this to identify a user's conversation with your bot. At runtime, each request must contain the <code>userID</code> field.</p> <p>To decide the user ID to use for your application, consider the following factors.</p> <ul> <li> <p>The <code>userID</code> field must not contain any personally identifiable information of the user, for example, name, personal identification numbers, or other end user personal information.</p> </li> <li> <p>If you want a user to start a conversation on one device and continue on another device, use a user-specific identifier.</p> </li> <li> <p>If you want the same user to be able to have two independent conversations on two different devices, choose a device-specific identifier.</p> </li> <li> <p>A user can't have two independent conversations with two different versions of the same bot. For example, a user can't have a conversation with the PROD and BETA versions of the same bot. If you anticipate that a user will need to have conversation with two different versions, for example, while testing, include the bot alias in the user ID to separate the two conversations.</p> </li> </ul>
  ##   botAlias: string (required)
  ##           : The alias of the Amazon Lex bot.
  ##   body: JObject (required)
  var path_602074 = newJObject()
  var body_602075 = newJObject()
  add(path_602074, "botName", newJString(botName))
  add(path_602074, "userId", newJString(userId))
  add(path_602074, "botAlias", newJString(botAlias))
  if body != nil:
    body_602075 = body
  result = call_602073.call(path_602074, nil, nil, nil, body_602075)

var postText* = Call_PostText_602058(name: "postText", meth: HttpMethod.HttpPost,
                                  host: "runtime.lex.amazonaws.com", route: "/bot/{botName}/alias/{botAlias}/user/{userId}/text",
                                  validator: validate_PostText_602059, base: "/",
                                  url: url_PostText_602060,
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
