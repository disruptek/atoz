
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Connect Participant Service
## version: 2018-09-07
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Amazon Connect is a cloud-based contact center solution that makes it easy to set up and manage a customer contact center and provide reliable customer engagement at any scale.</p> <p>Amazon Connect enables customer contacts through voice or chat.</p> <p>The APIs described here are used by chat participants, such as agents and customers.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/connect/
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

  OpenApiRestCall_612649 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612649](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612649): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "participant.connect.ap-northeast-1.amazonaws.com", "ap-southeast-1": "participant.connect.ap-southeast-1.amazonaws.com", "us-west-2": "participant.connect.us-west-2.amazonaws.com", "eu-west-2": "participant.connect.eu-west-2.amazonaws.com", "ap-northeast-3": "participant.connect.ap-northeast-3.amazonaws.com", "eu-central-1": "participant.connect.eu-central-1.amazonaws.com", "us-east-2": "participant.connect.us-east-2.amazonaws.com", "us-east-1": "participant.connect.us-east-1.amazonaws.com", "cn-northwest-1": "participant.connect.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "participant.connect.ap-south-1.amazonaws.com", "eu-north-1": "participant.connect.eu-north-1.amazonaws.com", "ap-northeast-2": "participant.connect.ap-northeast-2.amazonaws.com", "us-west-1": "participant.connect.us-west-1.amazonaws.com", "us-gov-east-1": "participant.connect.us-gov-east-1.amazonaws.com", "eu-west-3": "participant.connect.eu-west-3.amazonaws.com", "cn-north-1": "participant.connect.cn-north-1.amazonaws.com.cn", "sa-east-1": "participant.connect.sa-east-1.amazonaws.com", "eu-west-1": "participant.connect.eu-west-1.amazonaws.com", "us-gov-west-1": "participant.connect.us-gov-west-1.amazonaws.com", "ap-southeast-2": "participant.connect.ap-southeast-2.amazonaws.com", "ca-central-1": "participant.connect.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "participant.connect.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "participant.connect.ap-southeast-1.amazonaws.com",
      "us-west-2": "participant.connect.us-west-2.amazonaws.com",
      "eu-west-2": "participant.connect.eu-west-2.amazonaws.com",
      "ap-northeast-3": "participant.connect.ap-northeast-3.amazonaws.com",
      "eu-central-1": "participant.connect.eu-central-1.amazonaws.com",
      "us-east-2": "participant.connect.us-east-2.amazonaws.com",
      "us-east-1": "participant.connect.us-east-1.amazonaws.com",
      "cn-northwest-1": "participant.connect.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "participant.connect.ap-south-1.amazonaws.com",
      "eu-north-1": "participant.connect.eu-north-1.amazonaws.com",
      "ap-northeast-2": "participant.connect.ap-northeast-2.amazonaws.com",
      "us-west-1": "participant.connect.us-west-1.amazonaws.com",
      "us-gov-east-1": "participant.connect.us-gov-east-1.amazonaws.com",
      "eu-west-3": "participant.connect.eu-west-3.amazonaws.com",
      "cn-north-1": "participant.connect.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "participant.connect.sa-east-1.amazonaws.com",
      "eu-west-1": "participant.connect.eu-west-1.amazonaws.com",
      "us-gov-west-1": "participant.connect.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "participant.connect.ap-southeast-2.amazonaws.com",
      "ca-central-1": "participant.connect.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "connectparticipant"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateParticipantConnection_612987 = ref object of OpenApiRestCall_612649
proc url_CreateParticipantConnection_612989(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateParticipantConnection_612988(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates the participant's connection. Note that ParticipantToken is used for invoking this API instead of ConnectionToken.</p> <p>The participant token is valid for the lifetime of the participant – until the they are part of a contact.</p> <p>The response URL for <code>WEBSOCKET</code> Type has a connect expiry timeout of 100s. Clients must manually connect to the returned websocket URL and subscribe to the desired topic. </p> <p>For chat, you need to publish the following on the established websocket connection:</p> <p> <code>{"topic":"aws/subscribe","content":{"topics":["aws/chat"]}}</code> </p> <p>Upon websocket URL expiry, as specified in the response ConnectionExpiry parameter, clients need to call this API again to obtain a new websocket URL and perform the same steps as before.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Bearer: JString (required)
  ##               : Participant Token as obtained from <a 
  ## href="https://docs.aws.amazon.com/connect/latest/APIReference/API_StartChatContactResponse.html">StartChatContact</a> API response.
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Bearer` field"
  var valid_613101 = header.getOrDefault("X-Amz-Bearer")
  valid_613101 = validateParameter(valid_613101, JString, required = true,
                                 default = nil)
  if valid_613101 != nil:
    section.add "X-Amz-Bearer", valid_613101
  var valid_613102 = header.getOrDefault("X-Amz-Signature")
  valid_613102 = validateParameter(valid_613102, JString, required = false,
                                 default = nil)
  if valid_613102 != nil:
    section.add "X-Amz-Signature", valid_613102
  var valid_613103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613103 = validateParameter(valid_613103, JString, required = false,
                                 default = nil)
  if valid_613103 != nil:
    section.add "X-Amz-Content-Sha256", valid_613103
  var valid_613104 = header.getOrDefault("X-Amz-Date")
  valid_613104 = validateParameter(valid_613104, JString, required = false,
                                 default = nil)
  if valid_613104 != nil:
    section.add "X-Amz-Date", valid_613104
  var valid_613105 = header.getOrDefault("X-Amz-Credential")
  valid_613105 = validateParameter(valid_613105, JString, required = false,
                                 default = nil)
  if valid_613105 != nil:
    section.add "X-Amz-Credential", valid_613105
  var valid_613106 = header.getOrDefault("X-Amz-Security-Token")
  valid_613106 = validateParameter(valid_613106, JString, required = false,
                                 default = nil)
  if valid_613106 != nil:
    section.add "X-Amz-Security-Token", valid_613106
  var valid_613107 = header.getOrDefault("X-Amz-Algorithm")
  valid_613107 = validateParameter(valid_613107, JString, required = false,
                                 default = nil)
  if valid_613107 != nil:
    section.add "X-Amz-Algorithm", valid_613107
  var valid_613108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613108 = validateParameter(valid_613108, JString, required = false,
                                 default = nil)
  if valid_613108 != nil:
    section.add "X-Amz-SignedHeaders", valid_613108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613132: Call_CreateParticipantConnection_612987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates the participant's connection. Note that ParticipantToken is used for invoking this API instead of ConnectionToken.</p> <p>The participant token is valid for the lifetime of the participant – until the they are part of a contact.</p> <p>The response URL for <code>WEBSOCKET</code> Type has a connect expiry timeout of 100s. Clients must manually connect to the returned websocket URL and subscribe to the desired topic. </p> <p>For chat, you need to publish the following on the established websocket connection:</p> <p> <code>{"topic":"aws/subscribe","content":{"topics":["aws/chat"]}}</code> </p> <p>Upon websocket URL expiry, as specified in the response ConnectionExpiry parameter, clients need to call this API again to obtain a new websocket URL and perform the same steps as before.</p>
  ## 
  let valid = call_613132.validator(path, query, header, formData, body)
  let scheme = call_613132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613132.url(scheme.get, call_613132.host, call_613132.base,
                         call_613132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613132, url, valid)

proc call*(call_613203: Call_CreateParticipantConnection_612987; body: JsonNode): Recallable =
  ## createParticipantConnection
  ## <p>Creates the participant's connection. Note that ParticipantToken is used for invoking this API instead of ConnectionToken.</p> <p>The participant token is valid for the lifetime of the participant – until the they are part of a contact.</p> <p>The response URL for <code>WEBSOCKET</code> Type has a connect expiry timeout of 100s. Clients must manually connect to the returned websocket URL and subscribe to the desired topic. </p> <p>For chat, you need to publish the following on the established websocket connection:</p> <p> <code>{"topic":"aws/subscribe","content":{"topics":["aws/chat"]}}</code> </p> <p>Upon websocket URL expiry, as specified in the response ConnectionExpiry parameter, clients need to call this API again to obtain a new websocket URL and perform the same steps as before.</p>
  ##   body: JObject (required)
  var body_613204 = newJObject()
  if body != nil:
    body_613204 = body
  result = call_613203.call(nil, nil, nil, nil, body_613204)

var createParticipantConnection* = Call_CreateParticipantConnection_612987(
    name: "createParticipantConnection", meth: HttpMethod.HttpPost,
    host: "participant.connect.amazonaws.com",
    route: "/participant/connection#X-Amz-Bearer",
    validator: validate_CreateParticipantConnection_612988, base: "/",
    url: url_CreateParticipantConnection_612989,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisconnectParticipant_613243 = ref object of OpenApiRestCall_612649
proc url_DisconnectParticipant_613245(protocol: Scheme; host: string; base: string;
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

proc validate_DisconnectParticipant_613244(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disconnects a participant. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Bearer: JString (required)
  ##               : The authentication token associated with the participant's connection.
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Bearer` field"
  var valid_613246 = header.getOrDefault("X-Amz-Bearer")
  valid_613246 = validateParameter(valid_613246, JString, required = true,
                                 default = nil)
  if valid_613246 != nil:
    section.add "X-Amz-Bearer", valid_613246
  var valid_613247 = header.getOrDefault("X-Amz-Signature")
  valid_613247 = validateParameter(valid_613247, JString, required = false,
                                 default = nil)
  if valid_613247 != nil:
    section.add "X-Amz-Signature", valid_613247
  var valid_613248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613248 = validateParameter(valid_613248, JString, required = false,
                                 default = nil)
  if valid_613248 != nil:
    section.add "X-Amz-Content-Sha256", valid_613248
  var valid_613249 = header.getOrDefault("X-Amz-Date")
  valid_613249 = validateParameter(valid_613249, JString, required = false,
                                 default = nil)
  if valid_613249 != nil:
    section.add "X-Amz-Date", valid_613249
  var valid_613250 = header.getOrDefault("X-Amz-Credential")
  valid_613250 = validateParameter(valid_613250, JString, required = false,
                                 default = nil)
  if valid_613250 != nil:
    section.add "X-Amz-Credential", valid_613250
  var valid_613251 = header.getOrDefault("X-Amz-Security-Token")
  valid_613251 = validateParameter(valid_613251, JString, required = false,
                                 default = nil)
  if valid_613251 != nil:
    section.add "X-Amz-Security-Token", valid_613251
  var valid_613252 = header.getOrDefault("X-Amz-Algorithm")
  valid_613252 = validateParameter(valid_613252, JString, required = false,
                                 default = nil)
  if valid_613252 != nil:
    section.add "X-Amz-Algorithm", valid_613252
  var valid_613253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613253 = validateParameter(valid_613253, JString, required = false,
                                 default = nil)
  if valid_613253 != nil:
    section.add "X-Amz-SignedHeaders", valid_613253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613255: Call_DisconnectParticipant_613243; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disconnects a participant. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ## 
  let valid = call_613255.validator(path, query, header, formData, body)
  let scheme = call_613255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613255.url(scheme.get, call_613255.host, call_613255.base,
                         call_613255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613255, url, valid)

proc call*(call_613256: Call_DisconnectParticipant_613243; body: JsonNode): Recallable =
  ## disconnectParticipant
  ## Disconnects a participant. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ##   body: JObject (required)
  var body_613257 = newJObject()
  if body != nil:
    body_613257 = body
  result = call_613256.call(nil, nil, nil, nil, body_613257)

var disconnectParticipant* = Call_DisconnectParticipant_613243(
    name: "disconnectParticipant", meth: HttpMethod.HttpPost,
    host: "participant.connect.amazonaws.com",
    route: "/participant/disconnect#X-Amz-Bearer",
    validator: validate_DisconnectParticipant_613244, base: "/",
    url: url_DisconnectParticipant_613245, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTranscript_613258 = ref object of OpenApiRestCall_612649
proc url_GetTranscript_613260(protocol: Scheme; host: string; base: string;
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

proc validate_GetTranscript_613259(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a transcript of the session. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613261 = query.getOrDefault("MaxResults")
  valid_613261 = validateParameter(valid_613261, JString, required = false,
                                 default = nil)
  if valid_613261 != nil:
    section.add "MaxResults", valid_613261
  var valid_613262 = query.getOrDefault("NextToken")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "NextToken", valid_613262
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Bearer: JString (required)
  ##               : The authentication token associated with the participant's connection.
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Bearer` field"
  var valid_613263 = header.getOrDefault("X-Amz-Bearer")
  valid_613263 = validateParameter(valid_613263, JString, required = true,
                                 default = nil)
  if valid_613263 != nil:
    section.add "X-Amz-Bearer", valid_613263
  var valid_613264 = header.getOrDefault("X-Amz-Signature")
  valid_613264 = validateParameter(valid_613264, JString, required = false,
                                 default = nil)
  if valid_613264 != nil:
    section.add "X-Amz-Signature", valid_613264
  var valid_613265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613265 = validateParameter(valid_613265, JString, required = false,
                                 default = nil)
  if valid_613265 != nil:
    section.add "X-Amz-Content-Sha256", valid_613265
  var valid_613266 = header.getOrDefault("X-Amz-Date")
  valid_613266 = validateParameter(valid_613266, JString, required = false,
                                 default = nil)
  if valid_613266 != nil:
    section.add "X-Amz-Date", valid_613266
  var valid_613267 = header.getOrDefault("X-Amz-Credential")
  valid_613267 = validateParameter(valid_613267, JString, required = false,
                                 default = nil)
  if valid_613267 != nil:
    section.add "X-Amz-Credential", valid_613267
  var valid_613268 = header.getOrDefault("X-Amz-Security-Token")
  valid_613268 = validateParameter(valid_613268, JString, required = false,
                                 default = nil)
  if valid_613268 != nil:
    section.add "X-Amz-Security-Token", valid_613268
  var valid_613269 = header.getOrDefault("X-Amz-Algorithm")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "X-Amz-Algorithm", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-SignedHeaders", valid_613270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613272: Call_GetTranscript_613258; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a transcript of the session. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ## 
  let valid = call_613272.validator(path, query, header, formData, body)
  let scheme = call_613272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613272.url(scheme.get, call_613272.host, call_613272.base,
                         call_613272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613272, url, valid)

proc call*(call_613273: Call_GetTranscript_613258; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTranscript
  ## Retrieves a transcript of the session. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613274 = newJObject()
  var body_613275 = newJObject()
  add(query_613274, "MaxResults", newJString(MaxResults))
  add(query_613274, "NextToken", newJString(NextToken))
  if body != nil:
    body_613275 = body
  result = call_613273.call(nil, query_613274, nil, nil, body_613275)

var getTranscript* = Call_GetTranscript_613258(name: "getTranscript",
    meth: HttpMethod.HttpPost, host: "participant.connect.amazonaws.com",
    route: "/participant/transcript#X-Amz-Bearer",
    validator: validate_GetTranscript_613259, base: "/", url: url_GetTranscript_613260,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendEvent_613277 = ref object of OpenApiRestCall_612649
proc url_SendEvent_613279(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_SendEvent_613278(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Sends an event. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Bearer: JString (required)
  ##               : The authentication token associated with the participant's connection.
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Bearer` field"
  var valid_613280 = header.getOrDefault("X-Amz-Bearer")
  valid_613280 = validateParameter(valid_613280, JString, required = true,
                                 default = nil)
  if valid_613280 != nil:
    section.add "X-Amz-Bearer", valid_613280
  var valid_613281 = header.getOrDefault("X-Amz-Signature")
  valid_613281 = validateParameter(valid_613281, JString, required = false,
                                 default = nil)
  if valid_613281 != nil:
    section.add "X-Amz-Signature", valid_613281
  var valid_613282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613282 = validateParameter(valid_613282, JString, required = false,
                                 default = nil)
  if valid_613282 != nil:
    section.add "X-Amz-Content-Sha256", valid_613282
  var valid_613283 = header.getOrDefault("X-Amz-Date")
  valid_613283 = validateParameter(valid_613283, JString, required = false,
                                 default = nil)
  if valid_613283 != nil:
    section.add "X-Amz-Date", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Credential")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Credential", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Security-Token")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Security-Token", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Algorithm")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Algorithm", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-SignedHeaders", valid_613287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613289: Call_SendEvent_613277; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends an event. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ## 
  let valid = call_613289.validator(path, query, header, formData, body)
  let scheme = call_613289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613289.url(scheme.get, call_613289.host, call_613289.base,
                         call_613289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613289, url, valid)

proc call*(call_613290: Call_SendEvent_613277; body: JsonNode): Recallable =
  ## sendEvent
  ## Sends an event. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ##   body: JObject (required)
  var body_613291 = newJObject()
  if body != nil:
    body_613291 = body
  result = call_613290.call(nil, nil, nil, nil, body_613291)

var sendEvent* = Call_SendEvent_613277(name: "sendEvent", meth: HttpMethod.HttpPost,
                                    host: "participant.connect.amazonaws.com",
                                    route: "/participant/event#X-Amz-Bearer",
                                    validator: validate_SendEvent_613278,
                                    base: "/", url: url_SendEvent_613279,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendMessage_613292 = ref object of OpenApiRestCall_612649
proc url_SendMessage_613294(protocol: Scheme; host: string; base: string;
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

proc validate_SendMessage_613293(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Sends a message. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Bearer: JString (required)
  ##               : The authentication token associated with the connection.
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Bearer` field"
  var valid_613295 = header.getOrDefault("X-Amz-Bearer")
  valid_613295 = validateParameter(valid_613295, JString, required = true,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Bearer", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-Signature")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-Signature", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-Content-Sha256", valid_613297
  var valid_613298 = header.getOrDefault("X-Amz-Date")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-Date", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Credential")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Credential", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Security-Token")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Security-Token", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Algorithm")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Algorithm", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-SignedHeaders", valid_613302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613304: Call_SendMessage_613292; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends a message. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ## 
  let valid = call_613304.validator(path, query, header, formData, body)
  let scheme = call_613304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613304.url(scheme.get, call_613304.host, call_613304.base,
                         call_613304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613304, url, valid)

proc call*(call_613305: Call_SendMessage_613292; body: JsonNode): Recallable =
  ## sendMessage
  ## Sends a message. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ##   body: JObject (required)
  var body_613306 = newJObject()
  if body != nil:
    body_613306 = body
  result = call_613305.call(nil, nil, nil, nil, body_613306)

var sendMessage* = Call_SendMessage_613292(name: "sendMessage",
                                        meth: HttpMethod.HttpPost, host: "participant.connect.amazonaws.com", route: "/participant/message#X-Amz-Bearer",
                                        validator: validate_SendMessage_613293,
                                        base: "/", url: url_SendMessage_613294,
                                        schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
