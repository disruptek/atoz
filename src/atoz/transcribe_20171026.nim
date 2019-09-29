
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Transcribe Service
## version: 2017-10-26
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Operations and objects for transcribing speech to text.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/transcribe/
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

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "transcribe.ap-northeast-1.amazonaws.com", "ap-southeast-1": "transcribe.ap-southeast-1.amazonaws.com",
                           "us-west-2": "transcribe.us-west-2.amazonaws.com",
                           "eu-west-2": "transcribe.eu-west-2.amazonaws.com", "ap-northeast-3": "transcribe.ap-northeast-3.amazonaws.com", "eu-central-1": "transcribe.eu-central-1.amazonaws.com",
                           "us-east-2": "transcribe.us-east-2.amazonaws.com",
                           "us-east-1": "transcribe.us-east-1.amazonaws.com", "cn-northwest-1": "transcribe.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "transcribe.ap-south-1.amazonaws.com",
                           "eu-north-1": "transcribe.eu-north-1.amazonaws.com", "ap-northeast-2": "transcribe.ap-northeast-2.amazonaws.com",
                           "us-west-1": "transcribe.us-west-1.amazonaws.com", "us-gov-east-1": "transcribe.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "transcribe.eu-west-3.amazonaws.com", "cn-north-1": "transcribe.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "transcribe.sa-east-1.amazonaws.com",
                           "eu-west-1": "transcribe.eu-west-1.amazonaws.com", "us-gov-west-1": "transcribe.us-gov-west-1.amazonaws.com", "ap-southeast-2": "transcribe.ap-southeast-2.amazonaws.com", "ca-central-1": "transcribe.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "transcribe.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "transcribe.ap-southeast-1.amazonaws.com",
      "us-west-2": "transcribe.us-west-2.amazonaws.com",
      "eu-west-2": "transcribe.eu-west-2.amazonaws.com",
      "ap-northeast-3": "transcribe.ap-northeast-3.amazonaws.com",
      "eu-central-1": "transcribe.eu-central-1.amazonaws.com",
      "us-east-2": "transcribe.us-east-2.amazonaws.com",
      "us-east-1": "transcribe.us-east-1.amazonaws.com",
      "cn-northwest-1": "transcribe.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "transcribe.ap-south-1.amazonaws.com",
      "eu-north-1": "transcribe.eu-north-1.amazonaws.com",
      "ap-northeast-2": "transcribe.ap-northeast-2.amazonaws.com",
      "us-west-1": "transcribe.us-west-1.amazonaws.com",
      "us-gov-east-1": "transcribe.us-gov-east-1.amazonaws.com",
      "eu-west-3": "transcribe.eu-west-3.amazonaws.com",
      "cn-north-1": "transcribe.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "transcribe.sa-east-1.amazonaws.com",
      "eu-west-1": "transcribe.eu-west-1.amazonaws.com",
      "us-gov-west-1": "transcribe.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "transcribe.ap-southeast-2.amazonaws.com",
      "ca-central-1": "transcribe.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "transcribe"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateVocabulary_593774 = ref object of OpenApiRestCall_593437
proc url_CreateVocabulary_593776(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateVocabulary_593775(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a new custom vocabulary that you can use to change the way Amazon Transcribe handles transcription of an audio file. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_593888 = header.getOrDefault("X-Amz-Date")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Date", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-Security-Token")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Security-Token", valid_593889
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593903 = header.getOrDefault("X-Amz-Target")
  valid_593903 = validateParameter(valid_593903, JString, required = true, default = newJString(
      "Transcribe.CreateVocabulary"))
  if valid_593903 != nil:
    section.add "X-Amz-Target", valid_593903
  var valid_593904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Content-Sha256", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Algorithm")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Algorithm", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Signature")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Signature", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-SignedHeaders", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Credential")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Credential", valid_593908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593932: Call_CreateVocabulary_593774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new custom vocabulary that you can use to change the way Amazon Transcribe handles transcription of an audio file. 
  ## 
  let valid = call_593932.validator(path, query, header, formData, body)
  let scheme = call_593932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593932.url(scheme.get, call_593932.host, call_593932.base,
                         call_593932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593932, url, valid)

proc call*(call_594003: Call_CreateVocabulary_593774; body: JsonNode): Recallable =
  ## createVocabulary
  ## Creates a new custom vocabulary that you can use to change the way Amazon Transcribe handles transcription of an audio file. 
  ##   body: JObject (required)
  var body_594004 = newJObject()
  if body != nil:
    body_594004 = body
  result = call_594003.call(nil, nil, nil, nil, body_594004)

var createVocabulary* = Call_CreateVocabulary_593774(name: "createVocabulary",
    meth: HttpMethod.HttpPost, host: "transcribe.amazonaws.com",
    route: "/#X-Amz-Target=Transcribe.CreateVocabulary",
    validator: validate_CreateVocabulary_593775, base: "/",
    url: url_CreateVocabulary_593776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTranscriptionJob_594043 = ref object of OpenApiRestCall_593437
proc url_DeleteTranscriptionJob_594045(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTranscriptionJob_594044(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a previously submitted transcription job along with any other generated results such as the transcription, models, and so on.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594046 = header.getOrDefault("X-Amz-Date")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Date", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-Security-Token")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Security-Token", valid_594047
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594048 = header.getOrDefault("X-Amz-Target")
  valid_594048 = validateParameter(valid_594048, JString, required = true, default = newJString(
      "Transcribe.DeleteTranscriptionJob"))
  if valid_594048 != nil:
    section.add "X-Amz-Target", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Content-Sha256", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Algorithm")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Algorithm", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Signature")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Signature", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-SignedHeaders", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Credential")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Credential", valid_594053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594055: Call_DeleteTranscriptionJob_594043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously submitted transcription job along with any other generated results such as the transcription, models, and so on.
  ## 
  let valid = call_594055.validator(path, query, header, formData, body)
  let scheme = call_594055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594055.url(scheme.get, call_594055.host, call_594055.base,
                         call_594055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594055, url, valid)

proc call*(call_594056: Call_DeleteTranscriptionJob_594043; body: JsonNode): Recallable =
  ## deleteTranscriptionJob
  ## Deletes a previously submitted transcription job along with any other generated results such as the transcription, models, and so on.
  ##   body: JObject (required)
  var body_594057 = newJObject()
  if body != nil:
    body_594057 = body
  result = call_594056.call(nil, nil, nil, nil, body_594057)

var deleteTranscriptionJob* = Call_DeleteTranscriptionJob_594043(
    name: "deleteTranscriptionJob", meth: HttpMethod.HttpPost,
    host: "transcribe.amazonaws.com",
    route: "/#X-Amz-Target=Transcribe.DeleteTranscriptionJob",
    validator: validate_DeleteTranscriptionJob_594044, base: "/",
    url: url_DeleteTranscriptionJob_594045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVocabulary_594058 = ref object of OpenApiRestCall_593437
proc url_DeleteVocabulary_594060(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteVocabulary_594059(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes a vocabulary from Amazon Transcribe. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594061 = header.getOrDefault("X-Amz-Date")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Date", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Security-Token")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Security-Token", valid_594062
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594063 = header.getOrDefault("X-Amz-Target")
  valid_594063 = validateParameter(valid_594063, JString, required = true, default = newJString(
      "Transcribe.DeleteVocabulary"))
  if valid_594063 != nil:
    section.add "X-Amz-Target", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Content-Sha256", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Algorithm")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Algorithm", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Signature")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Signature", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-SignedHeaders", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Credential")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Credential", valid_594068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594070: Call_DeleteVocabulary_594058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a vocabulary from Amazon Transcribe. 
  ## 
  let valid = call_594070.validator(path, query, header, formData, body)
  let scheme = call_594070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594070.url(scheme.get, call_594070.host, call_594070.base,
                         call_594070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594070, url, valid)

proc call*(call_594071: Call_DeleteVocabulary_594058; body: JsonNode): Recallable =
  ## deleteVocabulary
  ## Deletes a vocabulary from Amazon Transcribe. 
  ##   body: JObject (required)
  var body_594072 = newJObject()
  if body != nil:
    body_594072 = body
  result = call_594071.call(nil, nil, nil, nil, body_594072)

var deleteVocabulary* = Call_DeleteVocabulary_594058(name: "deleteVocabulary",
    meth: HttpMethod.HttpPost, host: "transcribe.amazonaws.com",
    route: "/#X-Amz-Target=Transcribe.DeleteVocabulary",
    validator: validate_DeleteVocabulary_594059, base: "/",
    url: url_DeleteVocabulary_594060, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTranscriptionJob_594073 = ref object of OpenApiRestCall_593437
proc url_GetTranscriptionJob_594075(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTranscriptionJob_594074(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns information about a transcription job. To see the status of the job, check the <code>TranscriptionJobStatus</code> field. If the status is <code>COMPLETED</code>, the job is finished and you can find the results at the location specified in the <code>TranscriptionFileUri</code> field.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594076 = header.getOrDefault("X-Amz-Date")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Date", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Security-Token")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Security-Token", valid_594077
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594078 = header.getOrDefault("X-Amz-Target")
  valid_594078 = validateParameter(valid_594078, JString, required = true, default = newJString(
      "Transcribe.GetTranscriptionJob"))
  if valid_594078 != nil:
    section.add "X-Amz-Target", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Content-Sha256", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Algorithm")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Algorithm", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Signature")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Signature", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-SignedHeaders", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Credential")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Credential", valid_594083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594085: Call_GetTranscriptionJob_594073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a transcription job. To see the status of the job, check the <code>TranscriptionJobStatus</code> field. If the status is <code>COMPLETED</code>, the job is finished and you can find the results at the location specified in the <code>TranscriptionFileUri</code> field.
  ## 
  let valid = call_594085.validator(path, query, header, formData, body)
  let scheme = call_594085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594085.url(scheme.get, call_594085.host, call_594085.base,
                         call_594085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594085, url, valid)

proc call*(call_594086: Call_GetTranscriptionJob_594073; body: JsonNode): Recallable =
  ## getTranscriptionJob
  ## Returns information about a transcription job. To see the status of the job, check the <code>TranscriptionJobStatus</code> field. If the status is <code>COMPLETED</code>, the job is finished and you can find the results at the location specified in the <code>TranscriptionFileUri</code> field.
  ##   body: JObject (required)
  var body_594087 = newJObject()
  if body != nil:
    body_594087 = body
  result = call_594086.call(nil, nil, nil, nil, body_594087)

var getTranscriptionJob* = Call_GetTranscriptionJob_594073(
    name: "getTranscriptionJob", meth: HttpMethod.HttpPost,
    host: "transcribe.amazonaws.com",
    route: "/#X-Amz-Target=Transcribe.GetTranscriptionJob",
    validator: validate_GetTranscriptionJob_594074, base: "/",
    url: url_GetTranscriptionJob_594075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVocabulary_594088 = ref object of OpenApiRestCall_593437
proc url_GetVocabulary_594090(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetVocabulary_594089(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a vocabulary. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594091 = header.getOrDefault("X-Amz-Date")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Date", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Security-Token")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Security-Token", valid_594092
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594093 = header.getOrDefault("X-Amz-Target")
  valid_594093 = validateParameter(valid_594093, JString, required = true, default = newJString(
      "Transcribe.GetVocabulary"))
  if valid_594093 != nil:
    section.add "X-Amz-Target", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Content-Sha256", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Algorithm")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Algorithm", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Signature")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Signature", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-SignedHeaders", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Credential")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Credential", valid_594098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594100: Call_GetVocabulary_594088; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a vocabulary. 
  ## 
  let valid = call_594100.validator(path, query, header, formData, body)
  let scheme = call_594100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594100.url(scheme.get, call_594100.host, call_594100.base,
                         call_594100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594100, url, valid)

proc call*(call_594101: Call_GetVocabulary_594088; body: JsonNode): Recallable =
  ## getVocabulary
  ## Gets information about a vocabulary. 
  ##   body: JObject (required)
  var body_594102 = newJObject()
  if body != nil:
    body_594102 = body
  result = call_594101.call(nil, nil, nil, nil, body_594102)

var getVocabulary* = Call_GetVocabulary_594088(name: "getVocabulary",
    meth: HttpMethod.HttpPost, host: "transcribe.amazonaws.com",
    route: "/#X-Amz-Target=Transcribe.GetVocabulary",
    validator: validate_GetVocabulary_594089, base: "/", url: url_GetVocabulary_594090,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTranscriptionJobs_594103 = ref object of OpenApiRestCall_593437
proc url_ListTranscriptionJobs_594105(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTranscriptionJobs_594104(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists transcription jobs with the specified status.
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
  var valid_594106 = query.getOrDefault("NextToken")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "NextToken", valid_594106
  var valid_594107 = query.getOrDefault("MaxResults")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "MaxResults", valid_594107
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594108 = header.getOrDefault("X-Amz-Date")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "X-Amz-Date", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Security-Token")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Security-Token", valid_594109
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594110 = header.getOrDefault("X-Amz-Target")
  valid_594110 = validateParameter(valid_594110, JString, required = true, default = newJString(
      "Transcribe.ListTranscriptionJobs"))
  if valid_594110 != nil:
    section.add "X-Amz-Target", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Content-Sha256", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Algorithm")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Algorithm", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Signature")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Signature", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-SignedHeaders", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-Credential")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-Credential", valid_594115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594117: Call_ListTranscriptionJobs_594103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists transcription jobs with the specified status.
  ## 
  let valid = call_594117.validator(path, query, header, formData, body)
  let scheme = call_594117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594117.url(scheme.get, call_594117.host, call_594117.base,
                         call_594117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594117, url, valid)

proc call*(call_594118: Call_ListTranscriptionJobs_594103; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTranscriptionJobs
  ## Lists transcription jobs with the specified status.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594119 = newJObject()
  var body_594120 = newJObject()
  add(query_594119, "NextToken", newJString(NextToken))
  if body != nil:
    body_594120 = body
  add(query_594119, "MaxResults", newJString(MaxResults))
  result = call_594118.call(nil, query_594119, nil, nil, body_594120)

var listTranscriptionJobs* = Call_ListTranscriptionJobs_594103(
    name: "listTranscriptionJobs", meth: HttpMethod.HttpPost,
    host: "transcribe.amazonaws.com",
    route: "/#X-Amz-Target=Transcribe.ListTranscriptionJobs",
    validator: validate_ListTranscriptionJobs_594104, base: "/",
    url: url_ListTranscriptionJobs_594105, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVocabularies_594122 = ref object of OpenApiRestCall_593437
proc url_ListVocabularies_594124(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListVocabularies_594123(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of vocabularies that match the specified criteria. If no criteria are specified, returns the entire list of vocabularies.
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
  var valid_594125 = query.getOrDefault("NextToken")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "NextToken", valid_594125
  var valid_594126 = query.getOrDefault("MaxResults")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "MaxResults", valid_594126
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594127 = header.getOrDefault("X-Amz-Date")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Date", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Security-Token")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Security-Token", valid_594128
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594129 = header.getOrDefault("X-Amz-Target")
  valid_594129 = validateParameter(valid_594129, JString, required = true, default = newJString(
      "Transcribe.ListVocabularies"))
  if valid_594129 != nil:
    section.add "X-Amz-Target", valid_594129
  var valid_594130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-Content-Sha256", valid_594130
  var valid_594131 = header.getOrDefault("X-Amz-Algorithm")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Algorithm", valid_594131
  var valid_594132 = header.getOrDefault("X-Amz-Signature")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-Signature", valid_594132
  var valid_594133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-SignedHeaders", valid_594133
  var valid_594134 = header.getOrDefault("X-Amz-Credential")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "X-Amz-Credential", valid_594134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594136: Call_ListVocabularies_594122; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of vocabularies that match the specified criteria. If no criteria are specified, returns the entire list of vocabularies.
  ## 
  let valid = call_594136.validator(path, query, header, formData, body)
  let scheme = call_594136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594136.url(scheme.get, call_594136.host, call_594136.base,
                         call_594136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594136, url, valid)

proc call*(call_594137: Call_ListVocabularies_594122; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listVocabularies
  ## Returns a list of vocabularies that match the specified criteria. If no criteria are specified, returns the entire list of vocabularies.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594138 = newJObject()
  var body_594139 = newJObject()
  add(query_594138, "NextToken", newJString(NextToken))
  if body != nil:
    body_594139 = body
  add(query_594138, "MaxResults", newJString(MaxResults))
  result = call_594137.call(nil, query_594138, nil, nil, body_594139)

var listVocabularies* = Call_ListVocabularies_594122(name: "listVocabularies",
    meth: HttpMethod.HttpPost, host: "transcribe.amazonaws.com",
    route: "/#X-Amz-Target=Transcribe.ListVocabularies",
    validator: validate_ListVocabularies_594123, base: "/",
    url: url_ListVocabularies_594124, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTranscriptionJob_594140 = ref object of OpenApiRestCall_593437
proc url_StartTranscriptionJob_594142(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartTranscriptionJob_594141(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts an asynchronous job to transcribe speech to text. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594143 = header.getOrDefault("X-Amz-Date")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Date", valid_594143
  var valid_594144 = header.getOrDefault("X-Amz-Security-Token")
  valid_594144 = validateParameter(valid_594144, JString, required = false,
                                 default = nil)
  if valid_594144 != nil:
    section.add "X-Amz-Security-Token", valid_594144
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594145 = header.getOrDefault("X-Amz-Target")
  valid_594145 = validateParameter(valid_594145, JString, required = true, default = newJString(
      "Transcribe.StartTranscriptionJob"))
  if valid_594145 != nil:
    section.add "X-Amz-Target", valid_594145
  var valid_594146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "X-Amz-Content-Sha256", valid_594146
  var valid_594147 = header.getOrDefault("X-Amz-Algorithm")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-Algorithm", valid_594147
  var valid_594148 = header.getOrDefault("X-Amz-Signature")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-Signature", valid_594148
  var valid_594149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-SignedHeaders", valid_594149
  var valid_594150 = header.getOrDefault("X-Amz-Credential")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-Credential", valid_594150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594152: Call_StartTranscriptionJob_594140; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an asynchronous job to transcribe speech to text. 
  ## 
  let valid = call_594152.validator(path, query, header, formData, body)
  let scheme = call_594152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594152.url(scheme.get, call_594152.host, call_594152.base,
                         call_594152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594152, url, valid)

proc call*(call_594153: Call_StartTranscriptionJob_594140; body: JsonNode): Recallable =
  ## startTranscriptionJob
  ## Starts an asynchronous job to transcribe speech to text. 
  ##   body: JObject (required)
  var body_594154 = newJObject()
  if body != nil:
    body_594154 = body
  result = call_594153.call(nil, nil, nil, nil, body_594154)

var startTranscriptionJob* = Call_StartTranscriptionJob_594140(
    name: "startTranscriptionJob", meth: HttpMethod.HttpPost,
    host: "transcribe.amazonaws.com",
    route: "/#X-Amz-Target=Transcribe.StartTranscriptionJob",
    validator: validate_StartTranscriptionJob_594141, base: "/",
    url: url_StartTranscriptionJob_594142, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVocabulary_594155 = ref object of OpenApiRestCall_593437
proc url_UpdateVocabulary_594157(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateVocabulary_594156(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates an existing vocabulary with new values. The <code>UpdateVocabulary</code> operation overwrites all of the existing information with the values that you provide in the request. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594158 = header.getOrDefault("X-Amz-Date")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Date", valid_594158
  var valid_594159 = header.getOrDefault("X-Amz-Security-Token")
  valid_594159 = validateParameter(valid_594159, JString, required = false,
                                 default = nil)
  if valid_594159 != nil:
    section.add "X-Amz-Security-Token", valid_594159
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594160 = header.getOrDefault("X-Amz-Target")
  valid_594160 = validateParameter(valid_594160, JString, required = true, default = newJString(
      "Transcribe.UpdateVocabulary"))
  if valid_594160 != nil:
    section.add "X-Amz-Target", valid_594160
  var valid_594161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-Content-Sha256", valid_594161
  var valid_594162 = header.getOrDefault("X-Amz-Algorithm")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = nil)
  if valid_594162 != nil:
    section.add "X-Amz-Algorithm", valid_594162
  var valid_594163 = header.getOrDefault("X-Amz-Signature")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "X-Amz-Signature", valid_594163
  var valid_594164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = nil)
  if valid_594164 != nil:
    section.add "X-Amz-SignedHeaders", valid_594164
  var valid_594165 = header.getOrDefault("X-Amz-Credential")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Credential", valid_594165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594167: Call_UpdateVocabulary_594155; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing vocabulary with new values. The <code>UpdateVocabulary</code> operation overwrites all of the existing information with the values that you provide in the request. 
  ## 
  let valid = call_594167.validator(path, query, header, formData, body)
  let scheme = call_594167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594167.url(scheme.get, call_594167.host, call_594167.base,
                         call_594167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594167, url, valid)

proc call*(call_594168: Call_UpdateVocabulary_594155; body: JsonNode): Recallable =
  ## updateVocabulary
  ## Updates an existing vocabulary with new values. The <code>UpdateVocabulary</code> operation overwrites all of the existing information with the values that you provide in the request. 
  ##   body: JObject (required)
  var body_594169 = newJObject()
  if body != nil:
    body_594169 = body
  result = call_594168.call(nil, nil, nil, nil, body_594169)

var updateVocabulary* = Call_UpdateVocabulary_594155(name: "updateVocabulary",
    meth: HttpMethod.HttpPost, host: "transcribe.amazonaws.com",
    route: "/#X-Amz-Target=Transcribe.UpdateVocabulary",
    validator: validate_UpdateVocabulary_594156, base: "/",
    url: url_UpdateVocabulary_594157, schemes: {Scheme.Https, Scheme.Http})
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
