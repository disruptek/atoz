
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

  OpenApiRestCall_599359 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599359](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599359): Option[Scheme] {.used.} =
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
  Call_CreateParticipantConnection_599696 = ref object of OpenApiRestCall_599359
proc url_CreateParticipantConnection_599698(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateParticipantConnection_599697(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Bearer: JString (required)
  ##               : Participant Token as obtained from <a 
  ## href="https://docs.aws.amazon.com/connect/latest/APIReference/API_StartChatContactResponse.html">StartChatContact</a> API response.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599810 = header.getOrDefault("X-Amz-Date")
  valid_599810 = validateParameter(valid_599810, JString, required = false,
                                 default = nil)
  if valid_599810 != nil:
    section.add "X-Amz-Date", valid_599810
  var valid_599811 = header.getOrDefault("X-Amz-Security-Token")
  valid_599811 = validateParameter(valid_599811, JString, required = false,
                                 default = nil)
  if valid_599811 != nil:
    section.add "X-Amz-Security-Token", valid_599811
  var valid_599812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599812 = validateParameter(valid_599812, JString, required = false,
                                 default = nil)
  if valid_599812 != nil:
    section.add "X-Amz-Content-Sha256", valid_599812
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Bearer` field"
  var valid_599813 = header.getOrDefault("X-Amz-Bearer")
  valid_599813 = validateParameter(valid_599813, JString, required = true,
                                 default = nil)
  if valid_599813 != nil:
    section.add "X-Amz-Bearer", valid_599813
  var valid_599814 = header.getOrDefault("X-Amz-Algorithm")
  valid_599814 = validateParameter(valid_599814, JString, required = false,
                                 default = nil)
  if valid_599814 != nil:
    section.add "X-Amz-Algorithm", valid_599814
  var valid_599815 = header.getOrDefault("X-Amz-Signature")
  valid_599815 = validateParameter(valid_599815, JString, required = false,
                                 default = nil)
  if valid_599815 != nil:
    section.add "X-Amz-Signature", valid_599815
  var valid_599816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599816 = validateParameter(valid_599816, JString, required = false,
                                 default = nil)
  if valid_599816 != nil:
    section.add "X-Amz-SignedHeaders", valid_599816
  var valid_599817 = header.getOrDefault("X-Amz-Credential")
  valid_599817 = validateParameter(valid_599817, JString, required = false,
                                 default = nil)
  if valid_599817 != nil:
    section.add "X-Amz-Credential", valid_599817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599841: Call_CreateParticipantConnection_599696; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates the participant's connection. Note that ParticipantToken is used for invoking this API instead of ConnectionToken.</p> <p>The participant token is valid for the lifetime of the participant – until the they are part of a contact.</p> <p>The response URL for <code>WEBSOCKET</code> Type has a connect expiry timeout of 100s. Clients must manually connect to the returned websocket URL and subscribe to the desired topic. </p> <p>For chat, you need to publish the following on the established websocket connection:</p> <p> <code>{"topic":"aws/subscribe","content":{"topics":["aws/chat"]}}</code> </p> <p>Upon websocket URL expiry, as specified in the response ConnectionExpiry parameter, clients need to call this API again to obtain a new websocket URL and perform the same steps as before.</p>
  ## 
  let valid = call_599841.validator(path, query, header, formData, body)
  let scheme = call_599841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599841.url(scheme.get, call_599841.host, call_599841.base,
                         call_599841.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599841, url, valid)

proc call*(call_599912: Call_CreateParticipantConnection_599696; body: JsonNode): Recallable =
  ## createParticipantConnection
  ## <p>Creates the participant's connection. Note that ParticipantToken is used for invoking this API instead of ConnectionToken.</p> <p>The participant token is valid for the lifetime of the participant – until the they are part of a contact.</p> <p>The response URL for <code>WEBSOCKET</code> Type has a connect expiry timeout of 100s. Clients must manually connect to the returned websocket URL and subscribe to the desired topic. </p> <p>For chat, you need to publish the following on the established websocket connection:</p> <p> <code>{"topic":"aws/subscribe","content":{"topics":["aws/chat"]}}</code> </p> <p>Upon websocket URL expiry, as specified in the response ConnectionExpiry parameter, clients need to call this API again to obtain a new websocket URL and perform the same steps as before.</p>
  ##   body: JObject (required)
  var body_599913 = newJObject()
  if body != nil:
    body_599913 = body
  result = call_599912.call(nil, nil, nil, nil, body_599913)

var createParticipantConnection* = Call_CreateParticipantConnection_599696(
    name: "createParticipantConnection", meth: HttpMethod.HttpPost,
    host: "participant.connect.amazonaws.com",
    route: "/participant/connection#X-Amz-Bearer",
    validator: validate_CreateParticipantConnection_599697, base: "/",
    url: url_CreateParticipantConnection_599698,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisconnectParticipant_599952 = ref object of OpenApiRestCall_599359
proc url_DisconnectParticipant_599954(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisconnectParticipant_599953(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Bearer: JString (required)
  ##               : The authentication token associated with the participant's connection.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599955 = header.getOrDefault("X-Amz-Date")
  valid_599955 = validateParameter(valid_599955, JString, required = false,
                                 default = nil)
  if valid_599955 != nil:
    section.add "X-Amz-Date", valid_599955
  var valid_599956 = header.getOrDefault("X-Amz-Security-Token")
  valid_599956 = validateParameter(valid_599956, JString, required = false,
                                 default = nil)
  if valid_599956 != nil:
    section.add "X-Amz-Security-Token", valid_599956
  var valid_599957 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599957 = validateParameter(valid_599957, JString, required = false,
                                 default = nil)
  if valid_599957 != nil:
    section.add "X-Amz-Content-Sha256", valid_599957
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Bearer` field"
  var valid_599958 = header.getOrDefault("X-Amz-Bearer")
  valid_599958 = validateParameter(valid_599958, JString, required = true,
                                 default = nil)
  if valid_599958 != nil:
    section.add "X-Amz-Bearer", valid_599958
  var valid_599959 = header.getOrDefault("X-Amz-Algorithm")
  valid_599959 = validateParameter(valid_599959, JString, required = false,
                                 default = nil)
  if valid_599959 != nil:
    section.add "X-Amz-Algorithm", valid_599959
  var valid_599960 = header.getOrDefault("X-Amz-Signature")
  valid_599960 = validateParameter(valid_599960, JString, required = false,
                                 default = nil)
  if valid_599960 != nil:
    section.add "X-Amz-Signature", valid_599960
  var valid_599961 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599961 = validateParameter(valid_599961, JString, required = false,
                                 default = nil)
  if valid_599961 != nil:
    section.add "X-Amz-SignedHeaders", valid_599961
  var valid_599962 = header.getOrDefault("X-Amz-Credential")
  valid_599962 = validateParameter(valid_599962, JString, required = false,
                                 default = nil)
  if valid_599962 != nil:
    section.add "X-Amz-Credential", valid_599962
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599964: Call_DisconnectParticipant_599952; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disconnects a participant. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ## 
  let valid = call_599964.validator(path, query, header, formData, body)
  let scheme = call_599964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599964.url(scheme.get, call_599964.host, call_599964.base,
                         call_599964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599964, url, valid)

proc call*(call_599965: Call_DisconnectParticipant_599952; body: JsonNode): Recallable =
  ## disconnectParticipant
  ## Disconnects a participant. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ##   body: JObject (required)
  var body_599966 = newJObject()
  if body != nil:
    body_599966 = body
  result = call_599965.call(nil, nil, nil, nil, body_599966)

var disconnectParticipant* = Call_DisconnectParticipant_599952(
    name: "disconnectParticipant", meth: HttpMethod.HttpPost,
    host: "participant.connect.amazonaws.com",
    route: "/participant/disconnect#X-Amz-Bearer",
    validator: validate_DisconnectParticipant_599953, base: "/",
    url: url_DisconnectParticipant_599954, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTranscript_599967 = ref object of OpenApiRestCall_599359
proc url_GetTranscript_599969(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTranscript_599968(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a transcript of the session. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_599970 = query.getOrDefault("NextToken")
  valid_599970 = validateParameter(valid_599970, JString, required = false,
                                 default = nil)
  if valid_599970 != nil:
    section.add "NextToken", valid_599970
  var valid_599971 = query.getOrDefault("MaxResults")
  valid_599971 = validateParameter(valid_599971, JString, required = false,
                                 default = nil)
  if valid_599971 != nil:
    section.add "MaxResults", valid_599971
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Bearer: JString (required)
  ##               : The authentication token associated with the participant's connection.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599972 = header.getOrDefault("X-Amz-Date")
  valid_599972 = validateParameter(valid_599972, JString, required = false,
                                 default = nil)
  if valid_599972 != nil:
    section.add "X-Amz-Date", valid_599972
  var valid_599973 = header.getOrDefault("X-Amz-Security-Token")
  valid_599973 = validateParameter(valid_599973, JString, required = false,
                                 default = nil)
  if valid_599973 != nil:
    section.add "X-Amz-Security-Token", valid_599973
  var valid_599974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599974 = validateParameter(valid_599974, JString, required = false,
                                 default = nil)
  if valid_599974 != nil:
    section.add "X-Amz-Content-Sha256", valid_599974
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Bearer` field"
  var valid_599975 = header.getOrDefault("X-Amz-Bearer")
  valid_599975 = validateParameter(valid_599975, JString, required = true,
                                 default = nil)
  if valid_599975 != nil:
    section.add "X-Amz-Bearer", valid_599975
  var valid_599976 = header.getOrDefault("X-Amz-Algorithm")
  valid_599976 = validateParameter(valid_599976, JString, required = false,
                                 default = nil)
  if valid_599976 != nil:
    section.add "X-Amz-Algorithm", valid_599976
  var valid_599977 = header.getOrDefault("X-Amz-Signature")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "X-Amz-Signature", valid_599977
  var valid_599978 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-SignedHeaders", valid_599978
  var valid_599979 = header.getOrDefault("X-Amz-Credential")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "X-Amz-Credential", valid_599979
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599981: Call_GetTranscript_599967; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a transcript of the session. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ## 
  let valid = call_599981.validator(path, query, header, formData, body)
  let scheme = call_599981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599981.url(scheme.get, call_599981.host, call_599981.base,
                         call_599981.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599981, url, valid)

proc call*(call_599982: Call_GetTranscript_599967; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getTranscript
  ## Retrieves a transcript of the session. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_599983 = newJObject()
  var body_599984 = newJObject()
  add(query_599983, "NextToken", newJString(NextToken))
  if body != nil:
    body_599984 = body
  add(query_599983, "MaxResults", newJString(MaxResults))
  result = call_599982.call(nil, query_599983, nil, nil, body_599984)

var getTranscript* = Call_GetTranscript_599967(name: "getTranscript",
    meth: HttpMethod.HttpPost, host: "participant.connect.amazonaws.com",
    route: "/participant/transcript#X-Amz-Bearer",
    validator: validate_GetTranscript_599968, base: "/", url: url_GetTranscript_599969,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendEvent_599986 = ref object of OpenApiRestCall_599359
proc url_SendEvent_599988(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendEvent_599987(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Bearer: JString (required)
  ##               : The authentication token associated with the participant's connection.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599989 = header.getOrDefault("X-Amz-Date")
  valid_599989 = validateParameter(valid_599989, JString, required = false,
                                 default = nil)
  if valid_599989 != nil:
    section.add "X-Amz-Date", valid_599989
  var valid_599990 = header.getOrDefault("X-Amz-Security-Token")
  valid_599990 = validateParameter(valid_599990, JString, required = false,
                                 default = nil)
  if valid_599990 != nil:
    section.add "X-Amz-Security-Token", valid_599990
  var valid_599991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599991 = validateParameter(valid_599991, JString, required = false,
                                 default = nil)
  if valid_599991 != nil:
    section.add "X-Amz-Content-Sha256", valid_599991
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Bearer` field"
  var valid_599992 = header.getOrDefault("X-Amz-Bearer")
  valid_599992 = validateParameter(valid_599992, JString, required = true,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Bearer", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Algorithm")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Algorithm", valid_599993
  var valid_599994 = header.getOrDefault("X-Amz-Signature")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "X-Amz-Signature", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-SignedHeaders", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Credential")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Credential", valid_599996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599998: Call_SendEvent_599986; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends an event. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ## 
  let valid = call_599998.validator(path, query, header, formData, body)
  let scheme = call_599998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599998.url(scheme.get, call_599998.host, call_599998.base,
                         call_599998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599998, url, valid)

proc call*(call_599999: Call_SendEvent_599986; body: JsonNode): Recallable =
  ## sendEvent
  ## Sends an event. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ##   body: JObject (required)
  var body_600000 = newJObject()
  if body != nil:
    body_600000 = body
  result = call_599999.call(nil, nil, nil, nil, body_600000)

var sendEvent* = Call_SendEvent_599986(name: "sendEvent", meth: HttpMethod.HttpPost,
                                    host: "participant.connect.amazonaws.com",
                                    route: "/participant/event#X-Amz-Bearer",
                                    validator: validate_SendEvent_599987,
                                    base: "/", url: url_SendEvent_599988,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendMessage_600001 = ref object of OpenApiRestCall_599359
proc url_SendMessage_600003(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendMessage_600002(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Bearer: JString (required)
  ##               : The authentication token associated with the connection.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600004 = header.getOrDefault("X-Amz-Date")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-Date", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-Security-Token")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Security-Token", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-Content-Sha256", valid_600006
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Bearer` field"
  var valid_600007 = header.getOrDefault("X-Amz-Bearer")
  valid_600007 = validateParameter(valid_600007, JString, required = true,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Bearer", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Algorithm")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Algorithm", valid_600008
  var valid_600009 = header.getOrDefault("X-Amz-Signature")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-Signature", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-SignedHeaders", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Credential")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Credential", valid_600011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600013: Call_SendMessage_600001; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends a message. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ## 
  let valid = call_600013.validator(path, query, header, formData, body)
  let scheme = call_600013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600013.url(scheme.get, call_600013.host, call_600013.base,
                         call_600013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600013, url, valid)

proc call*(call_600014: Call_SendMessage_600001; body: JsonNode): Recallable =
  ## sendMessage
  ## Sends a message. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ##   body: JObject (required)
  var body_600015 = newJObject()
  if body != nil:
    body_600015 = body
  result = call_600014.call(nil, nil, nil, nil, body_600015)

var sendMessage* = Call_SendMessage_600001(name: "sendMessage",
                                        meth: HttpMethod.HttpPost, host: "participant.connect.amazonaws.com", route: "/participant/message#X-Amz-Bearer",
                                        validator: validate_SendMessage_600002,
                                        base: "/", url: url_SendMessage_600003,
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
