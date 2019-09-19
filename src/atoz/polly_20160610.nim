
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Polly
## version: 2016-06-10
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Amazon Polly is a web service that makes it easy to synthesize speech from text.</p> <p>The Amazon Polly service provides API operations for synthesizing high-quality speech from plain text and Speech Synthesis Markup Language (SSML), along with managing pronunciations lexicons that enable you to get the best results for your application domain.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/polly/
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

  OpenApiRestCall_600427 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600427](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600427): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "polly.ap-northeast-1.amazonaws.com", "ap-southeast-1": "polly.ap-southeast-1.amazonaws.com",
                           "us-west-2": "polly.us-west-2.amazonaws.com",
                           "eu-west-2": "polly.eu-west-2.amazonaws.com", "ap-northeast-3": "polly.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "polly.eu-central-1.amazonaws.com",
                           "us-east-2": "polly.us-east-2.amazonaws.com",
                           "us-east-1": "polly.us-east-1.amazonaws.com", "cn-northwest-1": "polly.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "polly.ap-south-1.amazonaws.com",
                           "eu-north-1": "polly.eu-north-1.amazonaws.com", "ap-northeast-2": "polly.ap-northeast-2.amazonaws.com",
                           "us-west-1": "polly.us-west-1.amazonaws.com", "us-gov-east-1": "polly.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "polly.eu-west-3.amazonaws.com",
                           "cn-north-1": "polly.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "polly.sa-east-1.amazonaws.com",
                           "eu-west-1": "polly.eu-west-1.amazonaws.com", "us-gov-west-1": "polly.us-gov-west-1.amazonaws.com", "ap-southeast-2": "polly.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "polly.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "polly.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "polly.ap-southeast-1.amazonaws.com",
      "us-west-2": "polly.us-west-2.amazonaws.com",
      "eu-west-2": "polly.eu-west-2.amazonaws.com",
      "ap-northeast-3": "polly.ap-northeast-3.amazonaws.com",
      "eu-central-1": "polly.eu-central-1.amazonaws.com",
      "us-east-2": "polly.us-east-2.amazonaws.com",
      "us-east-1": "polly.us-east-1.amazonaws.com",
      "cn-northwest-1": "polly.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "polly.ap-south-1.amazonaws.com",
      "eu-north-1": "polly.eu-north-1.amazonaws.com",
      "ap-northeast-2": "polly.ap-northeast-2.amazonaws.com",
      "us-west-1": "polly.us-west-1.amazonaws.com",
      "us-gov-east-1": "polly.us-gov-east-1.amazonaws.com",
      "eu-west-3": "polly.eu-west-3.amazonaws.com",
      "cn-north-1": "polly.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "polly.sa-east-1.amazonaws.com",
      "eu-west-1": "polly.eu-west-1.amazonaws.com",
      "us-gov-west-1": "polly.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "polly.ap-southeast-2.amazonaws.com",
      "ca-central-1": "polly.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "polly"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_PutLexicon_601039 = ref object of OpenApiRestCall_600427
proc url_PutLexicon_601041(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "LexiconName" in path, "`LexiconName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/lexicons/"),
               (kind: VariableSegment, value: "LexiconName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutLexicon_601040(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Stores a pronunciation lexicon in an AWS Region. If a lexicon with the same name already exists in the region, it is overwritten by the new lexicon. Lexicon operations have eventual consistency, therefore, it might take some time before the lexicon is available to the SynthesizeSpeech operation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LexiconName: JString (required)
  ##              : Name of the lexicon. The name must follow the regular express format [0-9A-Za-z]{1,20}. That is, the name is a case-sensitive alphanumeric string up to 20 characters long. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `LexiconName` field"
  var valid_601042 = path.getOrDefault("LexiconName")
  valid_601042 = validateParameter(valid_601042, JString, required = true,
                                 default = nil)
  if valid_601042 != nil:
    section.add "LexiconName", valid_601042
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
  var valid_601043 = header.getOrDefault("X-Amz-Date")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Date", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Security-Token")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Security-Token", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Content-Sha256", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Algorithm")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Algorithm", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Signature")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Signature", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-SignedHeaders", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-Credential")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-Credential", valid_601049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601051: Call_PutLexicon_601039; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stores a pronunciation lexicon in an AWS Region. If a lexicon with the same name already exists in the region, it is overwritten by the new lexicon. Lexicon operations have eventual consistency, therefore, it might take some time before the lexicon is available to the SynthesizeSpeech operation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.</p>
  ## 
  let valid = call_601051.validator(path, query, header, formData, body)
  let scheme = call_601051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601051.url(scheme.get, call_601051.host, call_601051.base,
                         call_601051.route, valid.getOrDefault("path"))
  result = hook(call_601051, url, valid)

proc call*(call_601052: Call_PutLexicon_601039; LexiconName: string; body: JsonNode): Recallable =
  ## putLexicon
  ## <p>Stores a pronunciation lexicon in an AWS Region. If a lexicon with the same name already exists in the region, it is overwritten by the new lexicon. Lexicon operations have eventual consistency, therefore, it might take some time before the lexicon is available to the SynthesizeSpeech operation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.</p>
  ##   LexiconName: string (required)
  ##              : Name of the lexicon. The name must follow the regular express format [0-9A-Za-z]{1,20}. That is, the name is a case-sensitive alphanumeric string up to 20 characters long. 
  ##   body: JObject (required)
  var path_601053 = newJObject()
  var body_601054 = newJObject()
  add(path_601053, "LexiconName", newJString(LexiconName))
  if body != nil:
    body_601054 = body
  result = call_601052.call(path_601053, nil, nil, nil, body_601054)

var putLexicon* = Call_PutLexicon_601039(name: "putLexicon",
                                      meth: HttpMethod.HttpPut,
                                      host: "polly.amazonaws.com",
                                      route: "/v1/lexicons/{LexiconName}",
                                      validator: validate_PutLexicon_601040,
                                      base: "/", url: url_PutLexicon_601041,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLexicon_600769 = ref object of OpenApiRestCall_600427
proc url_GetLexicon_600771(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "LexiconName" in path, "`LexiconName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/lexicons/"),
               (kind: VariableSegment, value: "LexiconName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetLexicon_600770(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the content of the specified pronunciation lexicon stored in an AWS Region. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LexiconName: JString (required)
  ##              : Name of the lexicon.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `LexiconName` field"
  var valid_600897 = path.getOrDefault("LexiconName")
  valid_600897 = validateParameter(valid_600897, JString, required = true,
                                 default = nil)
  if valid_600897 != nil:
    section.add "LexiconName", valid_600897
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
  var valid_600898 = header.getOrDefault("X-Amz-Date")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Date", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Security-Token")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Security-Token", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Content-Sha256", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-Algorithm")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-Algorithm", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Signature")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Signature", valid_600902
  var valid_600903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "X-Amz-SignedHeaders", valid_600903
  var valid_600904 = header.getOrDefault("X-Amz-Credential")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-Credential", valid_600904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600927: Call_GetLexicon_600769; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the content of the specified pronunciation lexicon stored in an AWS Region. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.
  ## 
  let valid = call_600927.validator(path, query, header, formData, body)
  let scheme = call_600927.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600927.url(scheme.get, call_600927.host, call_600927.base,
                         call_600927.route, valid.getOrDefault("path"))
  result = hook(call_600927, url, valid)

proc call*(call_600998: Call_GetLexicon_600769; LexiconName: string): Recallable =
  ## getLexicon
  ## Returns the content of the specified pronunciation lexicon stored in an AWS Region. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.
  ##   LexiconName: string (required)
  ##              : Name of the lexicon.
  var path_600999 = newJObject()
  add(path_600999, "LexiconName", newJString(LexiconName))
  result = call_600998.call(path_600999, nil, nil, nil, nil)

var getLexicon* = Call_GetLexicon_600769(name: "getLexicon",
                                      meth: HttpMethod.HttpGet,
                                      host: "polly.amazonaws.com",
                                      route: "/v1/lexicons/{LexiconName}",
                                      validator: validate_GetLexicon_600770,
                                      base: "/", url: url_GetLexicon_600771,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLexicon_601055 = ref object of OpenApiRestCall_600427
proc url_DeleteLexicon_601057(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "LexiconName" in path, "`LexiconName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/lexicons/"),
               (kind: VariableSegment, value: "LexiconName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteLexicon_601056(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified pronunciation lexicon stored in an AWS Region. A lexicon which has been deleted is not available for speech synthesis, nor is it possible to retrieve it using either the <code>GetLexicon</code> or <code>ListLexicon</code> APIs.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LexiconName: JString (required)
  ##              : The name of the lexicon to delete. Must be an existing lexicon in the region.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `LexiconName` field"
  var valid_601058 = path.getOrDefault("LexiconName")
  valid_601058 = validateParameter(valid_601058, JString, required = true,
                                 default = nil)
  if valid_601058 != nil:
    section.add "LexiconName", valid_601058
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
  var valid_601059 = header.getOrDefault("X-Amz-Date")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Date", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Security-Token")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Security-Token", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Content-Sha256", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Algorithm")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Algorithm", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-Signature")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Signature", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-SignedHeaders", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Credential")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Credential", valid_601065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601066: Call_DeleteLexicon_601055; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified pronunciation lexicon stored in an AWS Region. A lexicon which has been deleted is not available for speech synthesis, nor is it possible to retrieve it using either the <code>GetLexicon</code> or <code>ListLexicon</code> APIs.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.</p>
  ## 
  let valid = call_601066.validator(path, query, header, formData, body)
  let scheme = call_601066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601066.url(scheme.get, call_601066.host, call_601066.base,
                         call_601066.route, valid.getOrDefault("path"))
  result = hook(call_601066, url, valid)

proc call*(call_601067: Call_DeleteLexicon_601055; LexiconName: string): Recallable =
  ## deleteLexicon
  ## <p>Deletes the specified pronunciation lexicon stored in an AWS Region. A lexicon which has been deleted is not available for speech synthesis, nor is it possible to retrieve it using either the <code>GetLexicon</code> or <code>ListLexicon</code> APIs.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.</p>
  ##   LexiconName: string (required)
  ##              : The name of the lexicon to delete. Must be an existing lexicon in the region.
  var path_601068 = newJObject()
  add(path_601068, "LexiconName", newJString(LexiconName))
  result = call_601067.call(path_601068, nil, nil, nil, nil)

var deleteLexicon* = Call_DeleteLexicon_601055(name: "deleteLexicon",
    meth: HttpMethod.HttpDelete, host: "polly.amazonaws.com",
    route: "/v1/lexicons/{LexiconName}", validator: validate_DeleteLexicon_601056,
    base: "/", url: url_DeleteLexicon_601057, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVoices_601069 = ref object of OpenApiRestCall_600427
proc url_DescribeVoices_601071(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeVoices_601070(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns the list of voices that are available for use when requesting speech synthesis. Each voice speaks a specified language, is either male or female, and is identified by an ID, which is the ASCII version of the voice name. </p> <p>When synthesizing speech ( <code>SynthesizeSpeech</code> ), you provide the voice ID for the voice you want from the list of voices returned by <code>DescribeVoices</code>.</p> <p>For example, you want your news reader application to read news in a specific language, but giving a user the option to choose the voice. Using the <code>DescribeVoices</code> operation you can provide the user with a list of available voices to select from.</p> <p> You can optionally specify a language code to filter the available voices. For example, if you specify <code>en-US</code>, the operation returns a list of all available US English voices. </p> <p>This operation requires permissions to perform the <code>polly:DescribeVoices</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString
  ##         : Specifies the engine (<code>standard</code> or <code>neural</code>) used by Amazon Polly when processing input text for speech synthesis. 
  ##   LanguageCode: JString
  ##               :  The language identification tag (ISO 639 code for the language name-ISO 3166 country code) for filtering the list of voices returned. If you don't specify this optional parameter, all available voices are returned. 
  ##   NextToken: JString
  ##            : An opaque pagination token returned from the previous <code>DescribeVoices</code> operation. If present, this indicates where to continue the listing.
  ##   IncludeAdditionalLanguageCodes: JBool
  ##                                 : Boolean value indicating whether to return any bilingual voices that use the specified language as an additional language. For instance, if you request all languages that use US English (es-US), and there is an Italian voice that speaks both Italian (it-IT) and US English, that voice will be included if you specify <code>yes</code> but not if you specify <code>no</code>.
  section = newJObject()
  var valid_601085 = query.getOrDefault("Engine")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = newJString("standard"))
  if valid_601085 != nil:
    section.add "Engine", valid_601085
  var valid_601086 = query.getOrDefault("LanguageCode")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = newJString("arb"))
  if valid_601086 != nil:
    section.add "LanguageCode", valid_601086
  var valid_601087 = query.getOrDefault("NextToken")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "NextToken", valid_601087
  var valid_601088 = query.getOrDefault("IncludeAdditionalLanguageCodes")
  valid_601088 = validateParameter(valid_601088, JBool, required = false, default = nil)
  if valid_601088 != nil:
    section.add "IncludeAdditionalLanguageCodes", valid_601088
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
  var valid_601089 = header.getOrDefault("X-Amz-Date")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Date", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Security-Token")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Security-Token", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Content-Sha256", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Algorithm")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Algorithm", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-Signature")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Signature", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-SignedHeaders", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Credential")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Credential", valid_601095
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601096: Call_DescribeVoices_601069; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the list of voices that are available for use when requesting speech synthesis. Each voice speaks a specified language, is either male or female, and is identified by an ID, which is the ASCII version of the voice name. </p> <p>When synthesizing speech ( <code>SynthesizeSpeech</code> ), you provide the voice ID for the voice you want from the list of voices returned by <code>DescribeVoices</code>.</p> <p>For example, you want your news reader application to read news in a specific language, but giving a user the option to choose the voice. Using the <code>DescribeVoices</code> operation you can provide the user with a list of available voices to select from.</p> <p> You can optionally specify a language code to filter the available voices. For example, if you specify <code>en-US</code>, the operation returns a list of all available US English voices. </p> <p>This operation requires permissions to perform the <code>polly:DescribeVoices</code> action.</p>
  ## 
  let valid = call_601096.validator(path, query, header, formData, body)
  let scheme = call_601096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601096.url(scheme.get, call_601096.host, call_601096.base,
                         call_601096.route, valid.getOrDefault("path"))
  result = hook(call_601096, url, valid)

proc call*(call_601097: Call_DescribeVoices_601069; Engine: string = "standard";
          LanguageCode: string = "arb"; NextToken: string = "";
          IncludeAdditionalLanguageCodes: bool = false): Recallable =
  ## describeVoices
  ## <p>Returns the list of voices that are available for use when requesting speech synthesis. Each voice speaks a specified language, is either male or female, and is identified by an ID, which is the ASCII version of the voice name. </p> <p>When synthesizing speech ( <code>SynthesizeSpeech</code> ), you provide the voice ID for the voice you want from the list of voices returned by <code>DescribeVoices</code>.</p> <p>For example, you want your news reader application to read news in a specific language, but giving a user the option to choose the voice. Using the <code>DescribeVoices</code> operation you can provide the user with a list of available voices to select from.</p> <p> You can optionally specify a language code to filter the available voices. For example, if you specify <code>en-US</code>, the operation returns a list of all available US English voices. </p> <p>This operation requires permissions to perform the <code>polly:DescribeVoices</code> action.</p>
  ##   Engine: string
  ##         : Specifies the engine (<code>standard</code> or <code>neural</code>) used by Amazon Polly when processing input text for speech synthesis. 
  ##   LanguageCode: string
  ##               :  The language identification tag (ISO 639 code for the language name-ISO 3166 country code) for filtering the list of voices returned. If you don't specify this optional parameter, all available voices are returned. 
  ##   NextToken: string
  ##            : An opaque pagination token returned from the previous <code>DescribeVoices</code> operation. If present, this indicates where to continue the listing.
  ##   IncludeAdditionalLanguageCodes: bool
  ##                                 : Boolean value indicating whether to return any bilingual voices that use the specified language as an additional language. For instance, if you request all languages that use US English (es-US), and there is an Italian voice that speaks both Italian (it-IT) and US English, that voice will be included if you specify <code>yes</code> but not if you specify <code>no</code>.
  var query_601098 = newJObject()
  add(query_601098, "Engine", newJString(Engine))
  add(query_601098, "LanguageCode", newJString(LanguageCode))
  add(query_601098, "NextToken", newJString(NextToken))
  add(query_601098, "IncludeAdditionalLanguageCodes",
      newJBool(IncludeAdditionalLanguageCodes))
  result = call_601097.call(nil, query_601098, nil, nil, nil)

var describeVoices* = Call_DescribeVoices_601069(name: "describeVoices",
    meth: HttpMethod.HttpGet, host: "polly.amazonaws.com", route: "/v1/voices",
    validator: validate_DescribeVoices_601070, base: "/", url: url_DescribeVoices_601071,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSpeechSynthesisTask_601099 = ref object of OpenApiRestCall_600427
proc url_GetSpeechSynthesisTask_601101(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "TaskId" in path, "`TaskId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/synthesisTasks/"),
               (kind: VariableSegment, value: "TaskId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetSpeechSynthesisTask_601100(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a specific SpeechSynthesisTask object based on its TaskID. This object contains information about the given speech synthesis task, including the status of the task, and a link to the S3 bucket containing the output of the task.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   TaskId: JString (required)
  ##         : The Amazon Polly generated identifier for a speech synthesis task.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `TaskId` field"
  var valid_601102 = path.getOrDefault("TaskId")
  valid_601102 = validateParameter(valid_601102, JString, required = true,
                                 default = nil)
  if valid_601102 != nil:
    section.add "TaskId", valid_601102
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
  if body != nil:
    result.add "body", body

proc call*(call_601110: Call_GetSpeechSynthesisTask_601099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specific SpeechSynthesisTask object based on its TaskID. This object contains information about the given speech synthesis task, including the status of the task, and a link to the S3 bucket containing the output of the task.
  ## 
  let valid = call_601110.validator(path, query, header, formData, body)
  let scheme = call_601110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601110.url(scheme.get, call_601110.host, call_601110.base,
                         call_601110.route, valid.getOrDefault("path"))
  result = hook(call_601110, url, valid)

proc call*(call_601111: Call_GetSpeechSynthesisTask_601099; TaskId: string): Recallable =
  ## getSpeechSynthesisTask
  ## Retrieves a specific SpeechSynthesisTask object based on its TaskID. This object contains information about the given speech synthesis task, including the status of the task, and a link to the S3 bucket containing the output of the task.
  ##   TaskId: string (required)
  ##         : The Amazon Polly generated identifier for a speech synthesis task.
  var path_601112 = newJObject()
  add(path_601112, "TaskId", newJString(TaskId))
  result = call_601111.call(path_601112, nil, nil, nil, nil)

var getSpeechSynthesisTask* = Call_GetSpeechSynthesisTask_601099(
    name: "getSpeechSynthesisTask", meth: HttpMethod.HttpGet,
    host: "polly.amazonaws.com", route: "/v1/synthesisTasks/{TaskId}",
    validator: validate_GetSpeechSynthesisTask_601100, base: "/",
    url: url_GetSpeechSynthesisTask_601101, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLexicons_601113 = ref object of OpenApiRestCall_600427
proc url_ListLexicons_601115(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListLexicons_601114(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of pronunciation lexicons stored in an AWS Region. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : An opaque pagination token returned from previous <code>ListLexicons</code> operation. If present, indicates where to continue the list of lexicons.
  section = newJObject()
  var valid_601116 = query.getOrDefault("NextToken")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "NextToken", valid_601116
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
  var valid_601117 = header.getOrDefault("X-Amz-Date")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "X-Amz-Date", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Security-Token")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Security-Token", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Content-Sha256", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Algorithm")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Algorithm", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-Signature")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Signature", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-SignedHeaders", valid_601122
  var valid_601123 = header.getOrDefault("X-Amz-Credential")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-Credential", valid_601123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601124: Call_ListLexicons_601113; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of pronunciation lexicons stored in an AWS Region. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.
  ## 
  let valid = call_601124.validator(path, query, header, formData, body)
  let scheme = call_601124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601124.url(scheme.get, call_601124.host, call_601124.base,
                         call_601124.route, valid.getOrDefault("path"))
  result = hook(call_601124, url, valid)

proc call*(call_601125: Call_ListLexicons_601113; NextToken: string = ""): Recallable =
  ## listLexicons
  ## Returns a list of pronunciation lexicons stored in an AWS Region. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.
  ##   NextToken: string
  ##            : An opaque pagination token returned from previous <code>ListLexicons</code> operation. If present, indicates where to continue the list of lexicons.
  var query_601126 = newJObject()
  add(query_601126, "NextToken", newJString(NextToken))
  result = call_601125.call(nil, query_601126, nil, nil, nil)

var listLexicons* = Call_ListLexicons_601113(name: "listLexicons",
    meth: HttpMethod.HttpGet, host: "polly.amazonaws.com", route: "/v1/lexicons",
    validator: validate_ListLexicons_601114, base: "/", url: url_ListLexicons_601115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSpeechSynthesisTask_601143 = ref object of OpenApiRestCall_600427
proc url_StartSpeechSynthesisTask_601145(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartSpeechSynthesisTask_601144(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows the creation of an asynchronous synthesis task, by starting a new <code>SpeechSynthesisTask</code>. This operation requires all the standard information needed for speech synthesis, plus the name of an Amazon S3 bucket for the service to store the output of the synthesis task and two optional parameters (OutputS3KeyPrefix and SnsTopicArn). Once the synthesis task is created, this operation will return a SpeechSynthesisTask object, which will include an identifier of this task as well as the current status.
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
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601146 = header.getOrDefault("X-Amz-Date")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Date", valid_601146
  var valid_601147 = header.getOrDefault("X-Amz-Security-Token")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Security-Token", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Content-Sha256", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Algorithm")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Algorithm", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Signature")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Signature", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-SignedHeaders", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Credential")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Credential", valid_601152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601154: Call_StartSpeechSynthesisTask_601143; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows the creation of an asynchronous synthesis task, by starting a new <code>SpeechSynthesisTask</code>. This operation requires all the standard information needed for speech synthesis, plus the name of an Amazon S3 bucket for the service to store the output of the synthesis task and two optional parameters (OutputS3KeyPrefix and SnsTopicArn). Once the synthesis task is created, this operation will return a SpeechSynthesisTask object, which will include an identifier of this task as well as the current status.
  ## 
  let valid = call_601154.validator(path, query, header, formData, body)
  let scheme = call_601154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601154.url(scheme.get, call_601154.host, call_601154.base,
                         call_601154.route, valid.getOrDefault("path"))
  result = hook(call_601154, url, valid)

proc call*(call_601155: Call_StartSpeechSynthesisTask_601143; body: JsonNode): Recallable =
  ## startSpeechSynthesisTask
  ## Allows the creation of an asynchronous synthesis task, by starting a new <code>SpeechSynthesisTask</code>. This operation requires all the standard information needed for speech synthesis, plus the name of an Amazon S3 bucket for the service to store the output of the synthesis task and two optional parameters (OutputS3KeyPrefix and SnsTopicArn). Once the synthesis task is created, this operation will return a SpeechSynthesisTask object, which will include an identifier of this task as well as the current status.
  ##   body: JObject (required)
  var body_601156 = newJObject()
  if body != nil:
    body_601156 = body
  result = call_601155.call(nil, nil, nil, nil, body_601156)

var startSpeechSynthesisTask* = Call_StartSpeechSynthesisTask_601143(
    name: "startSpeechSynthesisTask", meth: HttpMethod.HttpPost,
    host: "polly.amazonaws.com", route: "/v1/synthesisTasks",
    validator: validate_StartSpeechSynthesisTask_601144, base: "/",
    url: url_StartSpeechSynthesisTask_601145, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSpeechSynthesisTasks_601127 = ref object of OpenApiRestCall_600427
proc url_ListSpeechSynthesisTasks_601129(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListSpeechSynthesisTasks_601128(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of SpeechSynthesisTask objects ordered by their creation date. This operation can filter the tasks by their status, for example, allowing users to list only tasks that are completed.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Status: JString
  ##         : Status of the speech synthesis tasks returned in a List operation
  ##   NextToken: JString
  ##            : The pagination token to use in the next request to continue the listing of speech synthesis tasks. 
  ##   MaxResults: JInt
  ##             : Maximum number of speech synthesis tasks returned in a List operation.
  section = newJObject()
  var valid_601130 = query.getOrDefault("Status")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = newJString("scheduled"))
  if valid_601130 != nil:
    section.add "Status", valid_601130
  var valid_601131 = query.getOrDefault("NextToken")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "NextToken", valid_601131
  var valid_601132 = query.getOrDefault("MaxResults")
  valid_601132 = validateParameter(valid_601132, JInt, required = false, default = nil)
  if valid_601132 != nil:
    section.add "MaxResults", valid_601132
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
  var valid_601133 = header.getOrDefault("X-Amz-Date")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Date", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Security-Token")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Security-Token", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Content-Sha256", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-Algorithm")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Algorithm", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Signature")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Signature", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-SignedHeaders", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Credential")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Credential", valid_601139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601140: Call_ListSpeechSynthesisTasks_601127; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of SpeechSynthesisTask objects ordered by their creation date. This operation can filter the tasks by their status, for example, allowing users to list only tasks that are completed.
  ## 
  let valid = call_601140.validator(path, query, header, formData, body)
  let scheme = call_601140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601140.url(scheme.get, call_601140.host, call_601140.base,
                         call_601140.route, valid.getOrDefault("path"))
  result = hook(call_601140, url, valid)

proc call*(call_601141: Call_ListSpeechSynthesisTasks_601127;
          Status: string = "scheduled"; NextToken: string = ""; MaxResults: int = 0): Recallable =
  ## listSpeechSynthesisTasks
  ## Returns a list of SpeechSynthesisTask objects ordered by their creation date. This operation can filter the tasks by their status, for example, allowing users to list only tasks that are completed.
  ##   Status: string
  ##         : Status of the speech synthesis tasks returned in a List operation
  ##   NextToken: string
  ##            : The pagination token to use in the next request to continue the listing of speech synthesis tasks. 
  ##   MaxResults: int
  ##             : Maximum number of speech synthesis tasks returned in a List operation.
  var query_601142 = newJObject()
  add(query_601142, "Status", newJString(Status))
  add(query_601142, "NextToken", newJString(NextToken))
  add(query_601142, "MaxResults", newJInt(MaxResults))
  result = call_601141.call(nil, query_601142, nil, nil, nil)

var listSpeechSynthesisTasks* = Call_ListSpeechSynthesisTasks_601127(
    name: "listSpeechSynthesisTasks", meth: HttpMethod.HttpGet,
    host: "polly.amazonaws.com", route: "/v1/synthesisTasks",
    validator: validate_ListSpeechSynthesisTasks_601128, base: "/",
    url: url_ListSpeechSynthesisTasks_601129, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SynthesizeSpeech_601157 = ref object of OpenApiRestCall_600427
proc url_SynthesizeSpeech_601159(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SynthesizeSpeech_601158(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Synthesizes UTF-8 input, plain text or SSML, to a stream of bytes. SSML input must be valid, well-formed SSML. Some alphabets might not be available with all the voices (for example, Cyrillic might not be read at all by English voices) unless phoneme mapping is used. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/how-text-to-speech-works.html">How it Works</a>.
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
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601160 = header.getOrDefault("X-Amz-Date")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Date", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Security-Token")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Security-Token", valid_601161
  var valid_601162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "X-Amz-Content-Sha256", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Algorithm")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Algorithm", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Signature")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Signature", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-SignedHeaders", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-Credential")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Credential", valid_601166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601168: Call_SynthesizeSpeech_601157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Synthesizes UTF-8 input, plain text or SSML, to a stream of bytes. SSML input must be valid, well-formed SSML. Some alphabets might not be available with all the voices (for example, Cyrillic might not be read at all by English voices) unless phoneme mapping is used. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/how-text-to-speech-works.html">How it Works</a>.
  ## 
  let valid = call_601168.validator(path, query, header, formData, body)
  let scheme = call_601168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601168.url(scheme.get, call_601168.host, call_601168.base,
                         call_601168.route, valid.getOrDefault("path"))
  result = hook(call_601168, url, valid)

proc call*(call_601169: Call_SynthesizeSpeech_601157; body: JsonNode): Recallable =
  ## synthesizeSpeech
  ## Synthesizes UTF-8 input, plain text or SSML, to a stream of bytes. SSML input must be valid, well-formed SSML. Some alphabets might not be available with all the voices (for example, Cyrillic might not be read at all by English voices) unless phoneme mapping is used. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/how-text-to-speech-works.html">How it Works</a>.
  ##   body: JObject (required)
  var body_601170 = newJObject()
  if body != nil:
    body_601170 = body
  result = call_601169.call(nil, nil, nil, nil, body_601170)

var synthesizeSpeech* = Call_SynthesizeSpeech_601157(name: "synthesizeSpeech",
    meth: HttpMethod.HttpPost, host: "polly.amazonaws.com", route: "/v1/speech",
    validator: validate_SynthesizeSpeech_601158, base: "/",
    url: url_SynthesizeSpeech_601159, schemes: {Scheme.Https, Scheme.Http})
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
