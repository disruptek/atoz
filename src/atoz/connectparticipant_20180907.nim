
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

  OpenApiRestCall_610649 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610649](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610649): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
  Call_CreateParticipantConnection_610987 = ref object of OpenApiRestCall_610649
proc url_CreateParticipantConnection_610989(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateParticipantConnection_610988(path: JsonNode; query: JsonNode;
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
  var valid_611101 = header.getOrDefault("X-Amz-Bearer")
  valid_611101 = validateParameter(valid_611101, JString, required = true,
                                 default = nil)
  if valid_611101 != nil:
    section.add "X-Amz-Bearer", valid_611101
  var valid_611102 = header.getOrDefault("X-Amz-Signature")
  valid_611102 = validateParameter(valid_611102, JString, required = false,
                                 default = nil)
  if valid_611102 != nil:
    section.add "X-Amz-Signature", valid_611102
  var valid_611103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611103 = validateParameter(valid_611103, JString, required = false,
                                 default = nil)
  if valid_611103 != nil:
    section.add "X-Amz-Content-Sha256", valid_611103
  var valid_611104 = header.getOrDefault("X-Amz-Date")
  valid_611104 = validateParameter(valid_611104, JString, required = false,
                                 default = nil)
  if valid_611104 != nil:
    section.add "X-Amz-Date", valid_611104
  var valid_611105 = header.getOrDefault("X-Amz-Credential")
  valid_611105 = validateParameter(valid_611105, JString, required = false,
                                 default = nil)
  if valid_611105 != nil:
    section.add "X-Amz-Credential", valid_611105
  var valid_611106 = header.getOrDefault("X-Amz-Security-Token")
  valid_611106 = validateParameter(valid_611106, JString, required = false,
                                 default = nil)
  if valid_611106 != nil:
    section.add "X-Amz-Security-Token", valid_611106
  var valid_611107 = header.getOrDefault("X-Amz-Algorithm")
  valid_611107 = validateParameter(valid_611107, JString, required = false,
                                 default = nil)
  if valid_611107 != nil:
    section.add "X-Amz-Algorithm", valid_611107
  var valid_611108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611108 = validateParameter(valid_611108, JString, required = false,
                                 default = nil)
  if valid_611108 != nil:
    section.add "X-Amz-SignedHeaders", valid_611108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611132: Call_CreateParticipantConnection_610987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates the participant's connection. Note that ParticipantToken is used for invoking this API instead of ConnectionToken.</p> <p>The participant token is valid for the lifetime of the participant – until the they are part of a contact.</p> <p>The response URL for <code>WEBSOCKET</code> Type has a connect expiry timeout of 100s. Clients must manually connect to the returned websocket URL and subscribe to the desired topic. </p> <p>For chat, you need to publish the following on the established websocket connection:</p> <p> <code>{"topic":"aws/subscribe","content":{"topics":["aws/chat"]}}</code> </p> <p>Upon websocket URL expiry, as specified in the response ConnectionExpiry parameter, clients need to call this API again to obtain a new websocket URL and perform the same steps as before.</p>
  ## 
  let valid = call_611132.validator(path, query, header, formData, body)
  let scheme = call_611132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611132.url(scheme.get, call_611132.host, call_611132.base,
                         call_611132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611132, url, valid)

proc call*(call_611203: Call_CreateParticipantConnection_610987; body: JsonNode): Recallable =
  ## createParticipantConnection
  ## <p>Creates the participant's connection. Note that ParticipantToken is used for invoking this API instead of ConnectionToken.</p> <p>The participant token is valid for the lifetime of the participant – until the they are part of a contact.</p> <p>The response URL for <code>WEBSOCKET</code> Type has a connect expiry timeout of 100s. Clients must manually connect to the returned websocket URL and subscribe to the desired topic. </p> <p>For chat, you need to publish the following on the established websocket connection:</p> <p> <code>{"topic":"aws/subscribe","content":{"topics":["aws/chat"]}}</code> </p> <p>Upon websocket URL expiry, as specified in the response ConnectionExpiry parameter, clients need to call this API again to obtain a new websocket URL and perform the same steps as before.</p>
  ##   body: JObject (required)
  var body_611204 = newJObject()
  if body != nil:
    body_611204 = body
  result = call_611203.call(nil, nil, nil, nil, body_611204)

var createParticipantConnection* = Call_CreateParticipantConnection_610987(
    name: "createParticipantConnection", meth: HttpMethod.HttpPost,
    host: "participant.connect.amazonaws.com",
    route: "/participant/connection#X-Amz-Bearer",
    validator: validate_CreateParticipantConnection_610988, base: "/",
    url: url_CreateParticipantConnection_610989,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisconnectParticipant_611243 = ref object of OpenApiRestCall_610649
proc url_DisconnectParticipant_611245(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisconnectParticipant_611244(path: JsonNode; query: JsonNode;
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
  var valid_611246 = header.getOrDefault("X-Amz-Bearer")
  valid_611246 = validateParameter(valid_611246, JString, required = true,
                                 default = nil)
  if valid_611246 != nil:
    section.add "X-Amz-Bearer", valid_611246
  var valid_611247 = header.getOrDefault("X-Amz-Signature")
  valid_611247 = validateParameter(valid_611247, JString, required = false,
                                 default = nil)
  if valid_611247 != nil:
    section.add "X-Amz-Signature", valid_611247
  var valid_611248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611248 = validateParameter(valid_611248, JString, required = false,
                                 default = nil)
  if valid_611248 != nil:
    section.add "X-Amz-Content-Sha256", valid_611248
  var valid_611249 = header.getOrDefault("X-Amz-Date")
  valid_611249 = validateParameter(valid_611249, JString, required = false,
                                 default = nil)
  if valid_611249 != nil:
    section.add "X-Amz-Date", valid_611249
  var valid_611250 = header.getOrDefault("X-Amz-Credential")
  valid_611250 = validateParameter(valid_611250, JString, required = false,
                                 default = nil)
  if valid_611250 != nil:
    section.add "X-Amz-Credential", valid_611250
  var valid_611251 = header.getOrDefault("X-Amz-Security-Token")
  valid_611251 = validateParameter(valid_611251, JString, required = false,
                                 default = nil)
  if valid_611251 != nil:
    section.add "X-Amz-Security-Token", valid_611251
  var valid_611252 = header.getOrDefault("X-Amz-Algorithm")
  valid_611252 = validateParameter(valid_611252, JString, required = false,
                                 default = nil)
  if valid_611252 != nil:
    section.add "X-Amz-Algorithm", valid_611252
  var valid_611253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611253 = validateParameter(valid_611253, JString, required = false,
                                 default = nil)
  if valid_611253 != nil:
    section.add "X-Amz-SignedHeaders", valid_611253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611255: Call_DisconnectParticipant_611243; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disconnects a participant. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ## 
  let valid = call_611255.validator(path, query, header, formData, body)
  let scheme = call_611255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611255.url(scheme.get, call_611255.host, call_611255.base,
                         call_611255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611255, url, valid)

proc call*(call_611256: Call_DisconnectParticipant_611243; body: JsonNode): Recallable =
  ## disconnectParticipant
  ## Disconnects a participant. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ##   body: JObject (required)
  var body_611257 = newJObject()
  if body != nil:
    body_611257 = body
  result = call_611256.call(nil, nil, nil, nil, body_611257)

var disconnectParticipant* = Call_DisconnectParticipant_611243(
    name: "disconnectParticipant", meth: HttpMethod.HttpPost,
    host: "participant.connect.amazonaws.com",
    route: "/participant/disconnect#X-Amz-Bearer",
    validator: validate_DisconnectParticipant_611244, base: "/",
    url: url_DisconnectParticipant_611245, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTranscript_611258 = ref object of OpenApiRestCall_610649
proc url_GetTranscript_611260(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTranscript_611259(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611261 = query.getOrDefault("MaxResults")
  valid_611261 = validateParameter(valid_611261, JString, required = false,
                                 default = nil)
  if valid_611261 != nil:
    section.add "MaxResults", valid_611261
  var valid_611262 = query.getOrDefault("NextToken")
  valid_611262 = validateParameter(valid_611262, JString, required = false,
                                 default = nil)
  if valid_611262 != nil:
    section.add "NextToken", valid_611262
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
  var valid_611263 = header.getOrDefault("X-Amz-Bearer")
  valid_611263 = validateParameter(valid_611263, JString, required = true,
                                 default = nil)
  if valid_611263 != nil:
    section.add "X-Amz-Bearer", valid_611263
  var valid_611264 = header.getOrDefault("X-Amz-Signature")
  valid_611264 = validateParameter(valid_611264, JString, required = false,
                                 default = nil)
  if valid_611264 != nil:
    section.add "X-Amz-Signature", valid_611264
  var valid_611265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611265 = validateParameter(valid_611265, JString, required = false,
                                 default = nil)
  if valid_611265 != nil:
    section.add "X-Amz-Content-Sha256", valid_611265
  var valid_611266 = header.getOrDefault("X-Amz-Date")
  valid_611266 = validateParameter(valid_611266, JString, required = false,
                                 default = nil)
  if valid_611266 != nil:
    section.add "X-Amz-Date", valid_611266
  var valid_611267 = header.getOrDefault("X-Amz-Credential")
  valid_611267 = validateParameter(valid_611267, JString, required = false,
                                 default = nil)
  if valid_611267 != nil:
    section.add "X-Amz-Credential", valid_611267
  var valid_611268 = header.getOrDefault("X-Amz-Security-Token")
  valid_611268 = validateParameter(valid_611268, JString, required = false,
                                 default = nil)
  if valid_611268 != nil:
    section.add "X-Amz-Security-Token", valid_611268
  var valid_611269 = header.getOrDefault("X-Amz-Algorithm")
  valid_611269 = validateParameter(valid_611269, JString, required = false,
                                 default = nil)
  if valid_611269 != nil:
    section.add "X-Amz-Algorithm", valid_611269
  var valid_611270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-SignedHeaders", valid_611270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611272: Call_GetTranscript_611258; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a transcript of the session. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ## 
  let valid = call_611272.validator(path, query, header, formData, body)
  let scheme = call_611272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611272.url(scheme.get, call_611272.host, call_611272.base,
                         call_611272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611272, url, valid)

proc call*(call_611273: Call_GetTranscript_611258; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTranscript
  ## Retrieves a transcript of the session. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611274 = newJObject()
  var body_611275 = newJObject()
  add(query_611274, "MaxResults", newJString(MaxResults))
  add(query_611274, "NextToken", newJString(NextToken))
  if body != nil:
    body_611275 = body
  result = call_611273.call(nil, query_611274, nil, nil, body_611275)

var getTranscript* = Call_GetTranscript_611258(name: "getTranscript",
    meth: HttpMethod.HttpPost, host: "participant.connect.amazonaws.com",
    route: "/participant/transcript#X-Amz-Bearer",
    validator: validate_GetTranscript_611259, base: "/", url: url_GetTranscript_611260,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendEvent_611277 = ref object of OpenApiRestCall_610649
proc url_SendEvent_611279(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendEvent_611278(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611280 = header.getOrDefault("X-Amz-Bearer")
  valid_611280 = validateParameter(valid_611280, JString, required = true,
                                 default = nil)
  if valid_611280 != nil:
    section.add "X-Amz-Bearer", valid_611280
  var valid_611281 = header.getOrDefault("X-Amz-Signature")
  valid_611281 = validateParameter(valid_611281, JString, required = false,
                                 default = nil)
  if valid_611281 != nil:
    section.add "X-Amz-Signature", valid_611281
  var valid_611282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611282 = validateParameter(valid_611282, JString, required = false,
                                 default = nil)
  if valid_611282 != nil:
    section.add "X-Amz-Content-Sha256", valid_611282
  var valid_611283 = header.getOrDefault("X-Amz-Date")
  valid_611283 = validateParameter(valid_611283, JString, required = false,
                                 default = nil)
  if valid_611283 != nil:
    section.add "X-Amz-Date", valid_611283
  var valid_611284 = header.getOrDefault("X-Amz-Credential")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-Credential", valid_611284
  var valid_611285 = header.getOrDefault("X-Amz-Security-Token")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Security-Token", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Algorithm")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Algorithm", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-SignedHeaders", valid_611287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611289: Call_SendEvent_611277; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends an event. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ## 
  let valid = call_611289.validator(path, query, header, formData, body)
  let scheme = call_611289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611289.url(scheme.get, call_611289.host, call_611289.base,
                         call_611289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611289, url, valid)

proc call*(call_611290: Call_SendEvent_611277; body: JsonNode): Recallable =
  ## sendEvent
  ## Sends an event. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ##   body: JObject (required)
  var body_611291 = newJObject()
  if body != nil:
    body_611291 = body
  result = call_611290.call(nil, nil, nil, nil, body_611291)

var sendEvent* = Call_SendEvent_611277(name: "sendEvent", meth: HttpMethod.HttpPost,
                                    host: "participant.connect.amazonaws.com",
                                    route: "/participant/event#X-Amz-Bearer",
                                    validator: validate_SendEvent_611278,
                                    base: "/", url: url_SendEvent_611279,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendMessage_611292 = ref object of OpenApiRestCall_610649
proc url_SendMessage_611294(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendMessage_611293(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611295 = header.getOrDefault("X-Amz-Bearer")
  valid_611295 = validateParameter(valid_611295, JString, required = true,
                                 default = nil)
  if valid_611295 != nil:
    section.add "X-Amz-Bearer", valid_611295
  var valid_611296 = header.getOrDefault("X-Amz-Signature")
  valid_611296 = validateParameter(valid_611296, JString, required = false,
                                 default = nil)
  if valid_611296 != nil:
    section.add "X-Amz-Signature", valid_611296
  var valid_611297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611297 = validateParameter(valid_611297, JString, required = false,
                                 default = nil)
  if valid_611297 != nil:
    section.add "X-Amz-Content-Sha256", valid_611297
  var valid_611298 = header.getOrDefault("X-Amz-Date")
  valid_611298 = validateParameter(valid_611298, JString, required = false,
                                 default = nil)
  if valid_611298 != nil:
    section.add "X-Amz-Date", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Credential")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Credential", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Security-Token")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Security-Token", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Algorithm")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Algorithm", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-SignedHeaders", valid_611302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611304: Call_SendMessage_611292; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends a message. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ## 
  let valid = call_611304.validator(path, query, header, formData, body)
  let scheme = call_611304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611304.url(scheme.get, call_611304.host, call_611304.base,
                         call_611304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611304, url, valid)

proc call*(call_611305: Call_SendMessage_611292; body: JsonNode): Recallable =
  ## sendMessage
  ## Sends a message. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ##   body: JObject (required)
  var body_611306 = newJObject()
  if body != nil:
    body_611306 = body
  result = call_611305.call(nil, nil, nil, nil, body_611306)

var sendMessage* = Call_SendMessage_611292(name: "sendMessage",
                                        meth: HttpMethod.HttpPost, host: "participant.connect.amazonaws.com", route: "/participant/message#X-Amz-Bearer",
                                        validator: validate_SendMessage_611293,
                                        base: "/", url: url_SendMessage_611294,
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
