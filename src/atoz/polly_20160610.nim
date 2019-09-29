
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_593438 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593438](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593438): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PutLexicon_594045 = ref object of OpenApiRestCall_593438
proc url_PutLexicon_594047(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LexiconName" in path, "`LexiconName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/lexicons/"),
               (kind: VariableSegment, value: "LexiconName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutLexicon_594046(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594048 = path.getOrDefault("LexiconName")
  valid_594048 = validateParameter(valid_594048, JString, required = true,
                                 default = nil)
  if valid_594048 != nil:
    section.add "LexiconName", valid_594048
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
  var valid_594049 = header.getOrDefault("X-Amz-Date")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Date", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Security-Token")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Security-Token", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Content-Sha256", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-Algorithm")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-Algorithm", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Signature")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Signature", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-SignedHeaders", valid_594054
  var valid_594055 = header.getOrDefault("X-Amz-Credential")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Credential", valid_594055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594057: Call_PutLexicon_594045; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stores a pronunciation lexicon in an AWS Region. If a lexicon with the same name already exists in the region, it is overwritten by the new lexicon. Lexicon operations have eventual consistency, therefore, it might take some time before the lexicon is available to the SynthesizeSpeech operation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.</p>
  ## 
  let valid = call_594057.validator(path, query, header, formData, body)
  let scheme = call_594057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594057.url(scheme.get, call_594057.host, call_594057.base,
                         call_594057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594057, url, valid)

proc call*(call_594058: Call_PutLexicon_594045; LexiconName: string; body: JsonNode): Recallable =
  ## putLexicon
  ## <p>Stores a pronunciation lexicon in an AWS Region. If a lexicon with the same name already exists in the region, it is overwritten by the new lexicon. Lexicon operations have eventual consistency, therefore, it might take some time before the lexicon is available to the SynthesizeSpeech operation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.</p>
  ##   LexiconName: string (required)
  ##              : Name of the lexicon. The name must follow the regular express format [0-9A-Za-z]{1,20}. That is, the name is a case-sensitive alphanumeric string up to 20 characters long. 
  ##   body: JObject (required)
  var path_594059 = newJObject()
  var body_594060 = newJObject()
  add(path_594059, "LexiconName", newJString(LexiconName))
  if body != nil:
    body_594060 = body
  result = call_594058.call(path_594059, nil, nil, nil, body_594060)

var putLexicon* = Call_PutLexicon_594045(name: "putLexicon",
                                      meth: HttpMethod.HttpPut,
                                      host: "polly.amazonaws.com",
                                      route: "/v1/lexicons/{LexiconName}",
                                      validator: validate_PutLexicon_594046,
                                      base: "/", url: url_PutLexicon_594047,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLexicon_593775 = ref object of OpenApiRestCall_593438
proc url_GetLexicon_593777(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LexiconName" in path, "`LexiconName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/lexicons/"),
               (kind: VariableSegment, value: "LexiconName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetLexicon_593776(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593903 = path.getOrDefault("LexiconName")
  valid_593903 = validateParameter(valid_593903, JString, required = true,
                                 default = nil)
  if valid_593903 != nil:
    section.add "LexiconName", valid_593903
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
  var valid_593904 = header.getOrDefault("X-Amz-Date")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Date", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Security-Token")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Security-Token", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Content-Sha256", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-Algorithm")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-Algorithm", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Signature")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Signature", valid_593908
  var valid_593909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593909 = validateParameter(valid_593909, JString, required = false,
                                 default = nil)
  if valid_593909 != nil:
    section.add "X-Amz-SignedHeaders", valid_593909
  var valid_593910 = header.getOrDefault("X-Amz-Credential")
  valid_593910 = validateParameter(valid_593910, JString, required = false,
                                 default = nil)
  if valid_593910 != nil:
    section.add "X-Amz-Credential", valid_593910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593933: Call_GetLexicon_593775; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the content of the specified pronunciation lexicon stored in an AWS Region. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.
  ## 
  let valid = call_593933.validator(path, query, header, formData, body)
  let scheme = call_593933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593933.url(scheme.get, call_593933.host, call_593933.base,
                         call_593933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593933, url, valid)

proc call*(call_594004: Call_GetLexicon_593775; LexiconName: string): Recallable =
  ## getLexicon
  ## Returns the content of the specified pronunciation lexicon stored in an AWS Region. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.
  ##   LexiconName: string (required)
  ##              : Name of the lexicon.
  var path_594005 = newJObject()
  add(path_594005, "LexiconName", newJString(LexiconName))
  result = call_594004.call(path_594005, nil, nil, nil, nil)

var getLexicon* = Call_GetLexicon_593775(name: "getLexicon",
                                      meth: HttpMethod.HttpGet,
                                      host: "polly.amazonaws.com",
                                      route: "/v1/lexicons/{LexiconName}",
                                      validator: validate_GetLexicon_593776,
                                      base: "/", url: url_GetLexicon_593777,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLexicon_594061 = ref object of OpenApiRestCall_593438
proc url_DeleteLexicon_594063(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LexiconName" in path, "`LexiconName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/lexicons/"),
               (kind: VariableSegment, value: "LexiconName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteLexicon_594062(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594064 = path.getOrDefault("LexiconName")
  valid_594064 = validateParameter(valid_594064, JString, required = true,
                                 default = nil)
  if valid_594064 != nil:
    section.add "LexiconName", valid_594064
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
  var valid_594065 = header.getOrDefault("X-Amz-Date")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Date", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Security-Token")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Security-Token", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-Content-Sha256", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Algorithm")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Algorithm", valid_594068
  var valid_594069 = header.getOrDefault("X-Amz-Signature")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-Signature", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-SignedHeaders", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-Credential")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Credential", valid_594071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594072: Call_DeleteLexicon_594061; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified pronunciation lexicon stored in an AWS Region. A lexicon which has been deleted is not available for speech synthesis, nor is it possible to retrieve it using either the <code>GetLexicon</code> or <code>ListLexicon</code> APIs.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.</p>
  ## 
  let valid = call_594072.validator(path, query, header, formData, body)
  let scheme = call_594072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594072.url(scheme.get, call_594072.host, call_594072.base,
                         call_594072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594072, url, valid)

proc call*(call_594073: Call_DeleteLexicon_594061; LexiconName: string): Recallable =
  ## deleteLexicon
  ## <p>Deletes the specified pronunciation lexicon stored in an AWS Region. A lexicon which has been deleted is not available for speech synthesis, nor is it possible to retrieve it using either the <code>GetLexicon</code> or <code>ListLexicon</code> APIs.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.</p>
  ##   LexiconName: string (required)
  ##              : The name of the lexicon to delete. Must be an existing lexicon in the region.
  var path_594074 = newJObject()
  add(path_594074, "LexiconName", newJString(LexiconName))
  result = call_594073.call(path_594074, nil, nil, nil, nil)

var deleteLexicon* = Call_DeleteLexicon_594061(name: "deleteLexicon",
    meth: HttpMethod.HttpDelete, host: "polly.amazonaws.com",
    route: "/v1/lexicons/{LexiconName}", validator: validate_DeleteLexicon_594062,
    base: "/", url: url_DeleteLexicon_594063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVoices_594075 = ref object of OpenApiRestCall_593438
proc url_DescribeVoices_594077(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeVoices_594076(path: JsonNode; query: JsonNode;
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
  var valid_594091 = query.getOrDefault("Engine")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = newJString("standard"))
  if valid_594091 != nil:
    section.add "Engine", valid_594091
  var valid_594092 = query.getOrDefault("LanguageCode")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = newJString("arb"))
  if valid_594092 != nil:
    section.add "LanguageCode", valid_594092
  var valid_594093 = query.getOrDefault("NextToken")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "NextToken", valid_594093
  var valid_594094 = query.getOrDefault("IncludeAdditionalLanguageCodes")
  valid_594094 = validateParameter(valid_594094, JBool, required = false, default = nil)
  if valid_594094 != nil:
    section.add "IncludeAdditionalLanguageCodes", valid_594094
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
  var valid_594095 = header.getOrDefault("X-Amz-Date")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Date", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Security-Token")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Security-Token", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Content-Sha256", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Algorithm")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Algorithm", valid_594098
  var valid_594099 = header.getOrDefault("X-Amz-Signature")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "X-Amz-Signature", valid_594099
  var valid_594100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "X-Amz-SignedHeaders", valid_594100
  var valid_594101 = header.getOrDefault("X-Amz-Credential")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "X-Amz-Credential", valid_594101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594102: Call_DescribeVoices_594075; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the list of voices that are available for use when requesting speech synthesis. Each voice speaks a specified language, is either male or female, and is identified by an ID, which is the ASCII version of the voice name. </p> <p>When synthesizing speech ( <code>SynthesizeSpeech</code> ), you provide the voice ID for the voice you want from the list of voices returned by <code>DescribeVoices</code>.</p> <p>For example, you want your news reader application to read news in a specific language, but giving a user the option to choose the voice. Using the <code>DescribeVoices</code> operation you can provide the user with a list of available voices to select from.</p> <p> You can optionally specify a language code to filter the available voices. For example, if you specify <code>en-US</code>, the operation returns a list of all available US English voices. </p> <p>This operation requires permissions to perform the <code>polly:DescribeVoices</code> action.</p>
  ## 
  let valid = call_594102.validator(path, query, header, formData, body)
  let scheme = call_594102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594102.url(scheme.get, call_594102.host, call_594102.base,
                         call_594102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594102, url, valid)

proc call*(call_594103: Call_DescribeVoices_594075; Engine: string = "standard";
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
  var query_594104 = newJObject()
  add(query_594104, "Engine", newJString(Engine))
  add(query_594104, "LanguageCode", newJString(LanguageCode))
  add(query_594104, "NextToken", newJString(NextToken))
  add(query_594104, "IncludeAdditionalLanguageCodes",
      newJBool(IncludeAdditionalLanguageCodes))
  result = call_594103.call(nil, query_594104, nil, nil, nil)

var describeVoices* = Call_DescribeVoices_594075(name: "describeVoices",
    meth: HttpMethod.HttpGet, host: "polly.amazonaws.com", route: "/v1/voices",
    validator: validate_DescribeVoices_594076, base: "/", url: url_DescribeVoices_594077,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSpeechSynthesisTask_594105 = ref object of OpenApiRestCall_593438
proc url_GetSpeechSynthesisTask_594107(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "TaskId" in path, "`TaskId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/synthesisTasks/"),
               (kind: VariableSegment, value: "TaskId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetSpeechSynthesisTask_594106(path: JsonNode; query: JsonNode;
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
  var valid_594108 = path.getOrDefault("TaskId")
  valid_594108 = validateParameter(valid_594108, JString, required = true,
                                 default = nil)
  if valid_594108 != nil:
    section.add "TaskId", valid_594108
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
  var valid_594109 = header.getOrDefault("X-Amz-Date")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Date", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Security-Token")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Security-Token", valid_594110
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
  if body != nil:
    result.add "body", body

proc call*(call_594116: Call_GetSpeechSynthesisTask_594105; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specific SpeechSynthesisTask object based on its TaskID. This object contains information about the given speech synthesis task, including the status of the task, and a link to the S3 bucket containing the output of the task.
  ## 
  let valid = call_594116.validator(path, query, header, formData, body)
  let scheme = call_594116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594116.url(scheme.get, call_594116.host, call_594116.base,
                         call_594116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594116, url, valid)

proc call*(call_594117: Call_GetSpeechSynthesisTask_594105; TaskId: string): Recallable =
  ## getSpeechSynthesisTask
  ## Retrieves a specific SpeechSynthesisTask object based on its TaskID. This object contains information about the given speech synthesis task, including the status of the task, and a link to the S3 bucket containing the output of the task.
  ##   TaskId: string (required)
  ##         : The Amazon Polly generated identifier for a speech synthesis task.
  var path_594118 = newJObject()
  add(path_594118, "TaskId", newJString(TaskId))
  result = call_594117.call(path_594118, nil, nil, nil, nil)

var getSpeechSynthesisTask* = Call_GetSpeechSynthesisTask_594105(
    name: "getSpeechSynthesisTask", meth: HttpMethod.HttpGet,
    host: "polly.amazonaws.com", route: "/v1/synthesisTasks/{TaskId}",
    validator: validate_GetSpeechSynthesisTask_594106, base: "/",
    url: url_GetSpeechSynthesisTask_594107, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLexicons_594119 = ref object of OpenApiRestCall_593438
proc url_ListLexicons_594121(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLexicons_594120(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594122 = query.getOrDefault("NextToken")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "NextToken", valid_594122
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
  var valid_594123 = header.getOrDefault("X-Amz-Date")
  valid_594123 = validateParameter(valid_594123, JString, required = false,
                                 default = nil)
  if valid_594123 != nil:
    section.add "X-Amz-Date", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Security-Token")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Security-Token", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Content-Sha256", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Algorithm")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Algorithm", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-Signature")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Signature", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-SignedHeaders", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Credential")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Credential", valid_594129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594130: Call_ListLexicons_594119; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of pronunciation lexicons stored in an AWS Region. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.
  ## 
  let valid = call_594130.validator(path, query, header, formData, body)
  let scheme = call_594130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594130.url(scheme.get, call_594130.host, call_594130.base,
                         call_594130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594130, url, valid)

proc call*(call_594131: Call_ListLexicons_594119; NextToken: string = ""): Recallable =
  ## listLexicons
  ## Returns a list of pronunciation lexicons stored in an AWS Region. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.
  ##   NextToken: string
  ##            : An opaque pagination token returned from previous <code>ListLexicons</code> operation. If present, indicates where to continue the list of lexicons.
  var query_594132 = newJObject()
  add(query_594132, "NextToken", newJString(NextToken))
  result = call_594131.call(nil, query_594132, nil, nil, nil)

var listLexicons* = Call_ListLexicons_594119(name: "listLexicons",
    meth: HttpMethod.HttpGet, host: "polly.amazonaws.com", route: "/v1/lexicons",
    validator: validate_ListLexicons_594120, base: "/", url: url_ListLexicons_594121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSpeechSynthesisTask_594149 = ref object of OpenApiRestCall_593438
proc url_StartSpeechSynthesisTask_594151(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartSpeechSynthesisTask_594150(path: JsonNode; query: JsonNode;
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
  var valid_594152 = header.getOrDefault("X-Amz-Date")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Date", valid_594152
  var valid_594153 = header.getOrDefault("X-Amz-Security-Token")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "X-Amz-Security-Token", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Content-Sha256", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Algorithm")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Algorithm", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-Signature")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Signature", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-SignedHeaders", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Credential")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Credential", valid_594158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594160: Call_StartSpeechSynthesisTask_594149; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows the creation of an asynchronous synthesis task, by starting a new <code>SpeechSynthesisTask</code>. This operation requires all the standard information needed for speech synthesis, plus the name of an Amazon S3 bucket for the service to store the output of the synthesis task and two optional parameters (OutputS3KeyPrefix and SnsTopicArn). Once the synthesis task is created, this operation will return a SpeechSynthesisTask object, which will include an identifier of this task as well as the current status.
  ## 
  let valid = call_594160.validator(path, query, header, formData, body)
  let scheme = call_594160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594160.url(scheme.get, call_594160.host, call_594160.base,
                         call_594160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594160, url, valid)

proc call*(call_594161: Call_StartSpeechSynthesisTask_594149; body: JsonNode): Recallable =
  ## startSpeechSynthesisTask
  ## Allows the creation of an asynchronous synthesis task, by starting a new <code>SpeechSynthesisTask</code>. This operation requires all the standard information needed for speech synthesis, plus the name of an Amazon S3 bucket for the service to store the output of the synthesis task and two optional parameters (OutputS3KeyPrefix and SnsTopicArn). Once the synthesis task is created, this operation will return a SpeechSynthesisTask object, which will include an identifier of this task as well as the current status.
  ##   body: JObject (required)
  var body_594162 = newJObject()
  if body != nil:
    body_594162 = body
  result = call_594161.call(nil, nil, nil, nil, body_594162)

var startSpeechSynthesisTask* = Call_StartSpeechSynthesisTask_594149(
    name: "startSpeechSynthesisTask", meth: HttpMethod.HttpPost,
    host: "polly.amazonaws.com", route: "/v1/synthesisTasks",
    validator: validate_StartSpeechSynthesisTask_594150, base: "/",
    url: url_StartSpeechSynthesisTask_594151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSpeechSynthesisTasks_594133 = ref object of OpenApiRestCall_593438
proc url_ListSpeechSynthesisTasks_594135(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSpeechSynthesisTasks_594134(path: JsonNode; query: JsonNode;
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
  var valid_594136 = query.getOrDefault("Status")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = newJString("scheduled"))
  if valid_594136 != nil:
    section.add "Status", valid_594136
  var valid_594137 = query.getOrDefault("NextToken")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "NextToken", valid_594137
  var valid_594138 = query.getOrDefault("MaxResults")
  valid_594138 = validateParameter(valid_594138, JInt, required = false, default = nil)
  if valid_594138 != nil:
    section.add "MaxResults", valid_594138
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
  var valid_594139 = header.getOrDefault("X-Amz-Date")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Date", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Security-Token")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Security-Token", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-Content-Sha256", valid_594141
  var valid_594142 = header.getOrDefault("X-Amz-Algorithm")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-Algorithm", valid_594142
  var valid_594143 = header.getOrDefault("X-Amz-Signature")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Signature", valid_594143
  var valid_594144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594144 = validateParameter(valid_594144, JString, required = false,
                                 default = nil)
  if valid_594144 != nil:
    section.add "X-Amz-SignedHeaders", valid_594144
  var valid_594145 = header.getOrDefault("X-Amz-Credential")
  valid_594145 = validateParameter(valid_594145, JString, required = false,
                                 default = nil)
  if valid_594145 != nil:
    section.add "X-Amz-Credential", valid_594145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594146: Call_ListSpeechSynthesisTasks_594133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of SpeechSynthesisTask objects ordered by their creation date. This operation can filter the tasks by their status, for example, allowing users to list only tasks that are completed.
  ## 
  let valid = call_594146.validator(path, query, header, formData, body)
  let scheme = call_594146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594146.url(scheme.get, call_594146.host, call_594146.base,
                         call_594146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594146, url, valid)

proc call*(call_594147: Call_ListSpeechSynthesisTasks_594133;
          Status: string = "scheduled"; NextToken: string = ""; MaxResults: int = 0): Recallable =
  ## listSpeechSynthesisTasks
  ## Returns a list of SpeechSynthesisTask objects ordered by their creation date. This operation can filter the tasks by their status, for example, allowing users to list only tasks that are completed.
  ##   Status: string
  ##         : Status of the speech synthesis tasks returned in a List operation
  ##   NextToken: string
  ##            : The pagination token to use in the next request to continue the listing of speech synthesis tasks. 
  ##   MaxResults: int
  ##             : Maximum number of speech synthesis tasks returned in a List operation.
  var query_594148 = newJObject()
  add(query_594148, "Status", newJString(Status))
  add(query_594148, "NextToken", newJString(NextToken))
  add(query_594148, "MaxResults", newJInt(MaxResults))
  result = call_594147.call(nil, query_594148, nil, nil, nil)

var listSpeechSynthesisTasks* = Call_ListSpeechSynthesisTasks_594133(
    name: "listSpeechSynthesisTasks", meth: HttpMethod.HttpGet,
    host: "polly.amazonaws.com", route: "/v1/synthesisTasks",
    validator: validate_ListSpeechSynthesisTasks_594134, base: "/",
    url: url_ListSpeechSynthesisTasks_594135, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SynthesizeSpeech_594163 = ref object of OpenApiRestCall_593438
proc url_SynthesizeSpeech_594165(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SynthesizeSpeech_594164(path: JsonNode; query: JsonNode;
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
  var valid_594166 = header.getOrDefault("X-Amz-Date")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Date", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Security-Token")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Security-Token", valid_594167
  var valid_594168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "X-Amz-Content-Sha256", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Algorithm")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Algorithm", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Signature")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Signature", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-SignedHeaders", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-Credential")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-Credential", valid_594172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594174: Call_SynthesizeSpeech_594163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Synthesizes UTF-8 input, plain text or SSML, to a stream of bytes. SSML input must be valid, well-formed SSML. Some alphabets might not be available with all the voices (for example, Cyrillic might not be read at all by English voices) unless phoneme mapping is used. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/how-text-to-speech-works.html">How it Works</a>.
  ## 
  let valid = call_594174.validator(path, query, header, formData, body)
  let scheme = call_594174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594174.url(scheme.get, call_594174.host, call_594174.base,
                         call_594174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594174, url, valid)

proc call*(call_594175: Call_SynthesizeSpeech_594163; body: JsonNode): Recallable =
  ## synthesizeSpeech
  ## Synthesizes UTF-8 input, plain text or SSML, to a stream of bytes. SSML input must be valid, well-formed SSML. Some alphabets might not be available with all the voices (for example, Cyrillic might not be read at all by English voices) unless phoneme mapping is used. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/how-text-to-speech-works.html">How it Works</a>.
  ##   body: JObject (required)
  var body_594176 = newJObject()
  if body != nil:
    body_594176 = body
  result = call_594175.call(nil, nil, nil, nil, body_594176)

var synthesizeSpeech* = Call_SynthesizeSpeech_594163(name: "synthesizeSpeech",
    meth: HttpMethod.HttpPost, host: "polly.amazonaws.com", route: "/v1/speech",
    validator: validate_SynthesizeSpeech_594164, base: "/",
    url: url_SynthesizeSpeech_594165, schemes: {Scheme.Https, Scheme.Http})
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
