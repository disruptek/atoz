
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateVocabulary_772933 = ref object of OpenApiRestCall_772597
proc url_CreateVocabulary_772935(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateVocabulary_772934(path: JsonNode; query: JsonNode;
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
  var valid_773047 = header.getOrDefault("X-Amz-Date")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "X-Amz-Date", valid_773047
  var valid_773048 = header.getOrDefault("X-Amz-Security-Token")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "X-Amz-Security-Token", valid_773048
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773062 = header.getOrDefault("X-Amz-Target")
  valid_773062 = validateParameter(valid_773062, JString, required = true, default = newJString(
      "Transcribe.CreateVocabulary"))
  if valid_773062 != nil:
    section.add "X-Amz-Target", valid_773062
  var valid_773063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773063 = validateParameter(valid_773063, JString, required = false,
                                 default = nil)
  if valid_773063 != nil:
    section.add "X-Amz-Content-Sha256", valid_773063
  var valid_773064 = header.getOrDefault("X-Amz-Algorithm")
  valid_773064 = validateParameter(valid_773064, JString, required = false,
                                 default = nil)
  if valid_773064 != nil:
    section.add "X-Amz-Algorithm", valid_773064
  var valid_773065 = header.getOrDefault("X-Amz-Signature")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Signature", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-SignedHeaders", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-Credential")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-Credential", valid_773067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773091: Call_CreateVocabulary_772933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new custom vocabulary that you can use to change the way Amazon Transcribe handles transcription of an audio file. 
  ## 
  let valid = call_773091.validator(path, query, header, formData, body)
  let scheme = call_773091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773091.url(scheme.get, call_773091.host, call_773091.base,
                         call_773091.route, valid.getOrDefault("path"))
  result = hook(call_773091, url, valid)

proc call*(call_773162: Call_CreateVocabulary_772933; body: JsonNode): Recallable =
  ## createVocabulary
  ## Creates a new custom vocabulary that you can use to change the way Amazon Transcribe handles transcription of an audio file. 
  ##   body: JObject (required)
  var body_773163 = newJObject()
  if body != nil:
    body_773163 = body
  result = call_773162.call(nil, nil, nil, nil, body_773163)

var createVocabulary* = Call_CreateVocabulary_772933(name: "createVocabulary",
    meth: HttpMethod.HttpPost, host: "transcribe.amazonaws.com",
    route: "/#X-Amz-Target=Transcribe.CreateVocabulary",
    validator: validate_CreateVocabulary_772934, base: "/",
    url: url_CreateVocabulary_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTranscriptionJob_773202 = ref object of OpenApiRestCall_772597
proc url_DeleteTranscriptionJob_773204(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteTranscriptionJob_773203(path: JsonNode; query: JsonNode;
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
  var valid_773205 = header.getOrDefault("X-Amz-Date")
  valid_773205 = validateParameter(valid_773205, JString, required = false,
                                 default = nil)
  if valid_773205 != nil:
    section.add "X-Amz-Date", valid_773205
  var valid_773206 = header.getOrDefault("X-Amz-Security-Token")
  valid_773206 = validateParameter(valid_773206, JString, required = false,
                                 default = nil)
  if valid_773206 != nil:
    section.add "X-Amz-Security-Token", valid_773206
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773207 = header.getOrDefault("X-Amz-Target")
  valid_773207 = validateParameter(valid_773207, JString, required = true, default = newJString(
      "Transcribe.DeleteTranscriptionJob"))
  if valid_773207 != nil:
    section.add "X-Amz-Target", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Content-Sha256", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Algorithm")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Algorithm", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-Signature")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Signature", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-SignedHeaders", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Credential")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Credential", valid_773212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773214: Call_DeleteTranscriptionJob_773202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously submitted transcription job along with any other generated results such as the transcription, models, and so on.
  ## 
  let valid = call_773214.validator(path, query, header, formData, body)
  let scheme = call_773214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773214.url(scheme.get, call_773214.host, call_773214.base,
                         call_773214.route, valid.getOrDefault("path"))
  result = hook(call_773214, url, valid)

proc call*(call_773215: Call_DeleteTranscriptionJob_773202; body: JsonNode): Recallable =
  ## deleteTranscriptionJob
  ## Deletes a previously submitted transcription job along with any other generated results such as the transcription, models, and so on.
  ##   body: JObject (required)
  var body_773216 = newJObject()
  if body != nil:
    body_773216 = body
  result = call_773215.call(nil, nil, nil, nil, body_773216)

var deleteTranscriptionJob* = Call_DeleteTranscriptionJob_773202(
    name: "deleteTranscriptionJob", meth: HttpMethod.HttpPost,
    host: "transcribe.amazonaws.com",
    route: "/#X-Amz-Target=Transcribe.DeleteTranscriptionJob",
    validator: validate_DeleteTranscriptionJob_773203, base: "/",
    url: url_DeleteTranscriptionJob_773204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVocabulary_773217 = ref object of OpenApiRestCall_772597
proc url_DeleteVocabulary_773219(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteVocabulary_773218(path: JsonNode; query: JsonNode;
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
  var valid_773220 = header.getOrDefault("X-Amz-Date")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "X-Amz-Date", valid_773220
  var valid_773221 = header.getOrDefault("X-Amz-Security-Token")
  valid_773221 = validateParameter(valid_773221, JString, required = false,
                                 default = nil)
  if valid_773221 != nil:
    section.add "X-Amz-Security-Token", valid_773221
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773222 = header.getOrDefault("X-Amz-Target")
  valid_773222 = validateParameter(valid_773222, JString, required = true, default = newJString(
      "Transcribe.DeleteVocabulary"))
  if valid_773222 != nil:
    section.add "X-Amz-Target", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Content-Sha256", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Algorithm")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Algorithm", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-Signature")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Signature", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-SignedHeaders", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Credential")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Credential", valid_773227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773229: Call_DeleteVocabulary_773217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a vocabulary from Amazon Transcribe. 
  ## 
  let valid = call_773229.validator(path, query, header, formData, body)
  let scheme = call_773229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773229.url(scheme.get, call_773229.host, call_773229.base,
                         call_773229.route, valid.getOrDefault("path"))
  result = hook(call_773229, url, valid)

proc call*(call_773230: Call_DeleteVocabulary_773217; body: JsonNode): Recallable =
  ## deleteVocabulary
  ## Deletes a vocabulary from Amazon Transcribe. 
  ##   body: JObject (required)
  var body_773231 = newJObject()
  if body != nil:
    body_773231 = body
  result = call_773230.call(nil, nil, nil, nil, body_773231)

var deleteVocabulary* = Call_DeleteVocabulary_773217(name: "deleteVocabulary",
    meth: HttpMethod.HttpPost, host: "transcribe.amazonaws.com",
    route: "/#X-Amz-Target=Transcribe.DeleteVocabulary",
    validator: validate_DeleteVocabulary_773218, base: "/",
    url: url_DeleteVocabulary_773219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTranscriptionJob_773232 = ref object of OpenApiRestCall_772597
proc url_GetTranscriptionJob_773234(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTranscriptionJob_773233(path: JsonNode; query: JsonNode;
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
  var valid_773235 = header.getOrDefault("X-Amz-Date")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Date", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-Security-Token")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Security-Token", valid_773236
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773237 = header.getOrDefault("X-Amz-Target")
  valid_773237 = validateParameter(valid_773237, JString, required = true, default = newJString(
      "Transcribe.GetTranscriptionJob"))
  if valid_773237 != nil:
    section.add "X-Amz-Target", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-Content-Sha256", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Algorithm")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Algorithm", valid_773239
  var valid_773240 = header.getOrDefault("X-Amz-Signature")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-Signature", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-SignedHeaders", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-Credential")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-Credential", valid_773242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773244: Call_GetTranscriptionJob_773232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a transcription job. To see the status of the job, check the <code>TranscriptionJobStatus</code> field. If the status is <code>COMPLETED</code>, the job is finished and you can find the results at the location specified in the <code>TranscriptionFileUri</code> field.
  ## 
  let valid = call_773244.validator(path, query, header, formData, body)
  let scheme = call_773244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773244.url(scheme.get, call_773244.host, call_773244.base,
                         call_773244.route, valid.getOrDefault("path"))
  result = hook(call_773244, url, valid)

proc call*(call_773245: Call_GetTranscriptionJob_773232; body: JsonNode): Recallable =
  ## getTranscriptionJob
  ## Returns information about a transcription job. To see the status of the job, check the <code>TranscriptionJobStatus</code> field. If the status is <code>COMPLETED</code>, the job is finished and you can find the results at the location specified in the <code>TranscriptionFileUri</code> field.
  ##   body: JObject (required)
  var body_773246 = newJObject()
  if body != nil:
    body_773246 = body
  result = call_773245.call(nil, nil, nil, nil, body_773246)

var getTranscriptionJob* = Call_GetTranscriptionJob_773232(
    name: "getTranscriptionJob", meth: HttpMethod.HttpPost,
    host: "transcribe.amazonaws.com",
    route: "/#X-Amz-Target=Transcribe.GetTranscriptionJob",
    validator: validate_GetTranscriptionJob_773233, base: "/",
    url: url_GetTranscriptionJob_773234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVocabulary_773247 = ref object of OpenApiRestCall_772597
proc url_GetVocabulary_773249(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetVocabulary_773248(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773250 = header.getOrDefault("X-Amz-Date")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Date", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Security-Token")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Security-Token", valid_773251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773252 = header.getOrDefault("X-Amz-Target")
  valid_773252 = validateParameter(valid_773252, JString, required = true, default = newJString(
      "Transcribe.GetVocabulary"))
  if valid_773252 != nil:
    section.add "X-Amz-Target", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Content-Sha256", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Algorithm")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Algorithm", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-Signature")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-Signature", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-SignedHeaders", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-Credential")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-Credential", valid_773257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773259: Call_GetVocabulary_773247; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a vocabulary. 
  ## 
  let valid = call_773259.validator(path, query, header, formData, body)
  let scheme = call_773259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773259.url(scheme.get, call_773259.host, call_773259.base,
                         call_773259.route, valid.getOrDefault("path"))
  result = hook(call_773259, url, valid)

proc call*(call_773260: Call_GetVocabulary_773247; body: JsonNode): Recallable =
  ## getVocabulary
  ## Gets information about a vocabulary. 
  ##   body: JObject (required)
  var body_773261 = newJObject()
  if body != nil:
    body_773261 = body
  result = call_773260.call(nil, nil, nil, nil, body_773261)

var getVocabulary* = Call_GetVocabulary_773247(name: "getVocabulary",
    meth: HttpMethod.HttpPost, host: "transcribe.amazonaws.com",
    route: "/#X-Amz-Target=Transcribe.GetVocabulary",
    validator: validate_GetVocabulary_773248, base: "/", url: url_GetVocabulary_773249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTranscriptionJobs_773262 = ref object of OpenApiRestCall_772597
proc url_ListTranscriptionJobs_773264(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTranscriptionJobs_773263(path: JsonNode; query: JsonNode;
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
  var valid_773265 = query.getOrDefault("NextToken")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "NextToken", valid_773265
  var valid_773266 = query.getOrDefault("MaxResults")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "MaxResults", valid_773266
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
  var valid_773267 = header.getOrDefault("X-Amz-Date")
  valid_773267 = validateParameter(valid_773267, JString, required = false,
                                 default = nil)
  if valid_773267 != nil:
    section.add "X-Amz-Date", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-Security-Token")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Security-Token", valid_773268
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773269 = header.getOrDefault("X-Amz-Target")
  valid_773269 = validateParameter(valid_773269, JString, required = true, default = newJString(
      "Transcribe.ListTranscriptionJobs"))
  if valid_773269 != nil:
    section.add "X-Amz-Target", valid_773269
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

proc call*(call_773276: Call_ListTranscriptionJobs_773262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists transcription jobs with the specified status.
  ## 
  let valid = call_773276.validator(path, query, header, formData, body)
  let scheme = call_773276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773276.url(scheme.get, call_773276.host, call_773276.base,
                         call_773276.route, valid.getOrDefault("path"))
  result = hook(call_773276, url, valid)

proc call*(call_773277: Call_ListTranscriptionJobs_773262; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTranscriptionJobs
  ## Lists transcription jobs with the specified status.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773278 = newJObject()
  var body_773279 = newJObject()
  add(query_773278, "NextToken", newJString(NextToken))
  if body != nil:
    body_773279 = body
  add(query_773278, "MaxResults", newJString(MaxResults))
  result = call_773277.call(nil, query_773278, nil, nil, body_773279)

var listTranscriptionJobs* = Call_ListTranscriptionJobs_773262(
    name: "listTranscriptionJobs", meth: HttpMethod.HttpPost,
    host: "transcribe.amazonaws.com",
    route: "/#X-Amz-Target=Transcribe.ListTranscriptionJobs",
    validator: validate_ListTranscriptionJobs_773263, base: "/",
    url: url_ListTranscriptionJobs_773264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVocabularies_773281 = ref object of OpenApiRestCall_772597
proc url_ListVocabularies_773283(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListVocabularies_773282(path: JsonNode; query: JsonNode;
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
  var valid_773284 = query.getOrDefault("NextToken")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "NextToken", valid_773284
  var valid_773285 = query.getOrDefault("MaxResults")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "MaxResults", valid_773285
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
  var valid_773286 = header.getOrDefault("X-Amz-Date")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-Date", valid_773286
  var valid_773287 = header.getOrDefault("X-Amz-Security-Token")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-Security-Token", valid_773287
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773288 = header.getOrDefault("X-Amz-Target")
  valid_773288 = validateParameter(valid_773288, JString, required = true, default = newJString(
      "Transcribe.ListVocabularies"))
  if valid_773288 != nil:
    section.add "X-Amz-Target", valid_773288
  var valid_773289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773289 = validateParameter(valid_773289, JString, required = false,
                                 default = nil)
  if valid_773289 != nil:
    section.add "X-Amz-Content-Sha256", valid_773289
  var valid_773290 = header.getOrDefault("X-Amz-Algorithm")
  valid_773290 = validateParameter(valid_773290, JString, required = false,
                                 default = nil)
  if valid_773290 != nil:
    section.add "X-Amz-Algorithm", valid_773290
  var valid_773291 = header.getOrDefault("X-Amz-Signature")
  valid_773291 = validateParameter(valid_773291, JString, required = false,
                                 default = nil)
  if valid_773291 != nil:
    section.add "X-Amz-Signature", valid_773291
  var valid_773292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773292 = validateParameter(valid_773292, JString, required = false,
                                 default = nil)
  if valid_773292 != nil:
    section.add "X-Amz-SignedHeaders", valid_773292
  var valid_773293 = header.getOrDefault("X-Amz-Credential")
  valid_773293 = validateParameter(valid_773293, JString, required = false,
                                 default = nil)
  if valid_773293 != nil:
    section.add "X-Amz-Credential", valid_773293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773295: Call_ListVocabularies_773281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of vocabularies that match the specified criteria. If no criteria are specified, returns the entire list of vocabularies.
  ## 
  let valid = call_773295.validator(path, query, header, formData, body)
  let scheme = call_773295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773295.url(scheme.get, call_773295.host, call_773295.base,
                         call_773295.route, valid.getOrDefault("path"))
  result = hook(call_773295, url, valid)

proc call*(call_773296: Call_ListVocabularies_773281; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listVocabularies
  ## Returns a list of vocabularies that match the specified criteria. If no criteria are specified, returns the entire list of vocabularies.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773297 = newJObject()
  var body_773298 = newJObject()
  add(query_773297, "NextToken", newJString(NextToken))
  if body != nil:
    body_773298 = body
  add(query_773297, "MaxResults", newJString(MaxResults))
  result = call_773296.call(nil, query_773297, nil, nil, body_773298)

var listVocabularies* = Call_ListVocabularies_773281(name: "listVocabularies",
    meth: HttpMethod.HttpPost, host: "transcribe.amazonaws.com",
    route: "/#X-Amz-Target=Transcribe.ListVocabularies",
    validator: validate_ListVocabularies_773282, base: "/",
    url: url_ListVocabularies_773283, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTranscriptionJob_773299 = ref object of OpenApiRestCall_772597
proc url_StartTranscriptionJob_773301(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartTranscriptionJob_773300(path: JsonNode; query: JsonNode;
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
  var valid_773302 = header.getOrDefault("X-Amz-Date")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-Date", valid_773302
  var valid_773303 = header.getOrDefault("X-Amz-Security-Token")
  valid_773303 = validateParameter(valid_773303, JString, required = false,
                                 default = nil)
  if valid_773303 != nil:
    section.add "X-Amz-Security-Token", valid_773303
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773304 = header.getOrDefault("X-Amz-Target")
  valid_773304 = validateParameter(valid_773304, JString, required = true, default = newJString(
      "Transcribe.StartTranscriptionJob"))
  if valid_773304 != nil:
    section.add "X-Amz-Target", valid_773304
  var valid_773305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773305 = validateParameter(valid_773305, JString, required = false,
                                 default = nil)
  if valid_773305 != nil:
    section.add "X-Amz-Content-Sha256", valid_773305
  var valid_773306 = header.getOrDefault("X-Amz-Algorithm")
  valid_773306 = validateParameter(valid_773306, JString, required = false,
                                 default = nil)
  if valid_773306 != nil:
    section.add "X-Amz-Algorithm", valid_773306
  var valid_773307 = header.getOrDefault("X-Amz-Signature")
  valid_773307 = validateParameter(valid_773307, JString, required = false,
                                 default = nil)
  if valid_773307 != nil:
    section.add "X-Amz-Signature", valid_773307
  var valid_773308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773308 = validateParameter(valid_773308, JString, required = false,
                                 default = nil)
  if valid_773308 != nil:
    section.add "X-Amz-SignedHeaders", valid_773308
  var valid_773309 = header.getOrDefault("X-Amz-Credential")
  valid_773309 = validateParameter(valid_773309, JString, required = false,
                                 default = nil)
  if valid_773309 != nil:
    section.add "X-Amz-Credential", valid_773309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773311: Call_StartTranscriptionJob_773299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an asynchronous job to transcribe speech to text. 
  ## 
  let valid = call_773311.validator(path, query, header, formData, body)
  let scheme = call_773311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773311.url(scheme.get, call_773311.host, call_773311.base,
                         call_773311.route, valid.getOrDefault("path"))
  result = hook(call_773311, url, valid)

proc call*(call_773312: Call_StartTranscriptionJob_773299; body: JsonNode): Recallable =
  ## startTranscriptionJob
  ## Starts an asynchronous job to transcribe speech to text. 
  ##   body: JObject (required)
  var body_773313 = newJObject()
  if body != nil:
    body_773313 = body
  result = call_773312.call(nil, nil, nil, nil, body_773313)

var startTranscriptionJob* = Call_StartTranscriptionJob_773299(
    name: "startTranscriptionJob", meth: HttpMethod.HttpPost,
    host: "transcribe.amazonaws.com",
    route: "/#X-Amz-Target=Transcribe.StartTranscriptionJob",
    validator: validate_StartTranscriptionJob_773300, base: "/",
    url: url_StartTranscriptionJob_773301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVocabulary_773314 = ref object of OpenApiRestCall_772597
proc url_UpdateVocabulary_773316(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateVocabulary_773315(path: JsonNode; query: JsonNode;
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
  var valid_773317 = header.getOrDefault("X-Amz-Date")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "X-Amz-Date", valid_773317
  var valid_773318 = header.getOrDefault("X-Amz-Security-Token")
  valid_773318 = validateParameter(valid_773318, JString, required = false,
                                 default = nil)
  if valid_773318 != nil:
    section.add "X-Amz-Security-Token", valid_773318
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773319 = header.getOrDefault("X-Amz-Target")
  valid_773319 = validateParameter(valid_773319, JString, required = true, default = newJString(
      "Transcribe.UpdateVocabulary"))
  if valid_773319 != nil:
    section.add "X-Amz-Target", valid_773319
  var valid_773320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773320 = validateParameter(valid_773320, JString, required = false,
                                 default = nil)
  if valid_773320 != nil:
    section.add "X-Amz-Content-Sha256", valid_773320
  var valid_773321 = header.getOrDefault("X-Amz-Algorithm")
  valid_773321 = validateParameter(valid_773321, JString, required = false,
                                 default = nil)
  if valid_773321 != nil:
    section.add "X-Amz-Algorithm", valid_773321
  var valid_773322 = header.getOrDefault("X-Amz-Signature")
  valid_773322 = validateParameter(valid_773322, JString, required = false,
                                 default = nil)
  if valid_773322 != nil:
    section.add "X-Amz-Signature", valid_773322
  var valid_773323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773323 = validateParameter(valid_773323, JString, required = false,
                                 default = nil)
  if valid_773323 != nil:
    section.add "X-Amz-SignedHeaders", valid_773323
  var valid_773324 = header.getOrDefault("X-Amz-Credential")
  valid_773324 = validateParameter(valid_773324, JString, required = false,
                                 default = nil)
  if valid_773324 != nil:
    section.add "X-Amz-Credential", valid_773324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773326: Call_UpdateVocabulary_773314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing vocabulary with new values. The <code>UpdateVocabulary</code> operation overwrites all of the existing information with the values that you provide in the request. 
  ## 
  let valid = call_773326.validator(path, query, header, formData, body)
  let scheme = call_773326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773326.url(scheme.get, call_773326.host, call_773326.base,
                         call_773326.route, valid.getOrDefault("path"))
  result = hook(call_773326, url, valid)

proc call*(call_773327: Call_UpdateVocabulary_773314; body: JsonNode): Recallable =
  ## updateVocabulary
  ## Updates an existing vocabulary with new values. The <code>UpdateVocabulary</code> operation overwrites all of the existing information with the values that you provide in the request. 
  ##   body: JObject (required)
  var body_773328 = newJObject()
  if body != nil:
    body_773328 = body
  result = call_773327.call(nil, nil, nil, nil, body_773328)

var updateVocabulary* = Call_UpdateVocabulary_773314(name: "updateVocabulary",
    meth: HttpMethod.HttpPost, host: "transcribe.amazonaws.com",
    route: "/#X-Amz-Target=Transcribe.UpdateVocabulary",
    validator: validate_UpdateVocabulary_773315, base: "/",
    url: url_UpdateVocabulary_773316, schemes: {Scheme.Https, Scheme.Http})
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
