
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

  OpenApiRestCall_592365 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592365](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592365): Option[Scheme] {.used.} =
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
  Call_PutLexicon_592974 = ref object of OpenApiRestCall_592365
proc url_PutLexicon_592976(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutLexicon_592975(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592977 = path.getOrDefault("LexiconName")
  valid_592977 = validateParameter(valid_592977, JString, required = true,
                                 default = nil)
  if valid_592977 != nil:
    section.add "LexiconName", valid_592977
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
  var valid_592978 = header.getOrDefault("X-Amz-Signature")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Signature", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Content-Sha256", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Date")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Date", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Credential")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Credential", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-Security-Token")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Security-Token", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-Algorithm")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Algorithm", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-SignedHeaders", valid_592984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592986: Call_PutLexicon_592974; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stores a pronunciation lexicon in an AWS Region. If a lexicon with the same name already exists in the region, it is overwritten by the new lexicon. Lexicon operations have eventual consistency, therefore, it might take some time before the lexicon is available to the SynthesizeSpeech operation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.</p>
  ## 
  let valid = call_592986.validator(path, query, header, formData, body)
  let scheme = call_592986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592986.url(scheme.get, call_592986.host, call_592986.base,
                         call_592986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592986, url, valid)

proc call*(call_592987: Call_PutLexicon_592974; LexiconName: string; body: JsonNode): Recallable =
  ## putLexicon
  ## <p>Stores a pronunciation lexicon in an AWS Region. If a lexicon with the same name already exists in the region, it is overwritten by the new lexicon. Lexicon operations have eventual consistency, therefore, it might take some time before the lexicon is available to the SynthesizeSpeech operation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.</p>
  ##   LexiconName: string (required)
  ##              : Name of the lexicon. The name must follow the regular express format [0-9A-Za-z]{1,20}. That is, the name is a case-sensitive alphanumeric string up to 20 characters long. 
  ##   body: JObject (required)
  var path_592988 = newJObject()
  var body_592989 = newJObject()
  add(path_592988, "LexiconName", newJString(LexiconName))
  if body != nil:
    body_592989 = body
  result = call_592987.call(path_592988, nil, nil, nil, body_592989)

var putLexicon* = Call_PutLexicon_592974(name: "putLexicon",
                                      meth: HttpMethod.HttpPut,
                                      host: "polly.amazonaws.com",
                                      route: "/v1/lexicons/{LexiconName}",
                                      validator: validate_PutLexicon_592975,
                                      base: "/", url: url_PutLexicon_592976,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLexicon_592704 = ref object of OpenApiRestCall_592365
proc url_GetLexicon_592706(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetLexicon_592705(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592832 = path.getOrDefault("LexiconName")
  valid_592832 = validateParameter(valid_592832, JString, required = true,
                                 default = nil)
  if valid_592832 != nil:
    section.add "LexiconName", valid_592832
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
  var valid_592833 = header.getOrDefault("X-Amz-Signature")
  valid_592833 = validateParameter(valid_592833, JString, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "X-Amz-Signature", valid_592833
  var valid_592834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Content-Sha256", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Date")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Date", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Credential")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Credential", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-Security-Token")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-Security-Token", valid_592837
  var valid_592838 = header.getOrDefault("X-Amz-Algorithm")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "X-Amz-Algorithm", valid_592838
  var valid_592839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592839 = validateParameter(valid_592839, JString, required = false,
                                 default = nil)
  if valid_592839 != nil:
    section.add "X-Amz-SignedHeaders", valid_592839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592862: Call_GetLexicon_592704; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the content of the specified pronunciation lexicon stored in an AWS Region. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.
  ## 
  let valid = call_592862.validator(path, query, header, formData, body)
  let scheme = call_592862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592862.url(scheme.get, call_592862.host, call_592862.base,
                         call_592862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592862, url, valid)

proc call*(call_592933: Call_GetLexicon_592704; LexiconName: string): Recallable =
  ## getLexicon
  ## Returns the content of the specified pronunciation lexicon stored in an AWS Region. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.
  ##   LexiconName: string (required)
  ##              : Name of the lexicon.
  var path_592934 = newJObject()
  add(path_592934, "LexiconName", newJString(LexiconName))
  result = call_592933.call(path_592934, nil, nil, nil, nil)

var getLexicon* = Call_GetLexicon_592704(name: "getLexicon",
                                      meth: HttpMethod.HttpGet,
                                      host: "polly.amazonaws.com",
                                      route: "/v1/lexicons/{LexiconName}",
                                      validator: validate_GetLexicon_592705,
                                      base: "/", url: url_GetLexicon_592706,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLexicon_592990 = ref object of OpenApiRestCall_592365
proc url_DeleteLexicon_592992(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteLexicon_592991(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592993 = path.getOrDefault("LexiconName")
  valid_592993 = validateParameter(valid_592993, JString, required = true,
                                 default = nil)
  if valid_592993 != nil:
    section.add "LexiconName", valid_592993
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
  var valid_592994 = header.getOrDefault("X-Amz-Signature")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Signature", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Content-Sha256", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Date")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Date", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-Credential")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-Credential", valid_592997
  var valid_592998 = header.getOrDefault("X-Amz-Security-Token")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-Security-Token", valid_592998
  var valid_592999 = header.getOrDefault("X-Amz-Algorithm")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Algorithm", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-SignedHeaders", valid_593000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593001: Call_DeleteLexicon_592990; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified pronunciation lexicon stored in an AWS Region. A lexicon which has been deleted is not available for speech synthesis, nor is it possible to retrieve it using either the <code>GetLexicon</code> or <code>ListLexicon</code> APIs.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.</p>
  ## 
  let valid = call_593001.validator(path, query, header, formData, body)
  let scheme = call_593001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593001.url(scheme.get, call_593001.host, call_593001.base,
                         call_593001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593001, url, valid)

proc call*(call_593002: Call_DeleteLexicon_592990; LexiconName: string): Recallable =
  ## deleteLexicon
  ## <p>Deletes the specified pronunciation lexicon stored in an AWS Region. A lexicon which has been deleted is not available for speech synthesis, nor is it possible to retrieve it using either the <code>GetLexicon</code> or <code>ListLexicon</code> APIs.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.</p>
  ##   LexiconName: string (required)
  ##              : The name of the lexicon to delete. Must be an existing lexicon in the region.
  var path_593003 = newJObject()
  add(path_593003, "LexiconName", newJString(LexiconName))
  result = call_593002.call(path_593003, nil, nil, nil, nil)

var deleteLexicon* = Call_DeleteLexicon_592990(name: "deleteLexicon",
    meth: HttpMethod.HttpDelete, host: "polly.amazonaws.com",
    route: "/v1/lexicons/{LexiconName}", validator: validate_DeleteLexicon_592991,
    base: "/", url: url_DeleteLexicon_592992, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVoices_593004 = ref object of OpenApiRestCall_592365
proc url_DescribeVoices_593006(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeVoices_593005(path: JsonNode; query: JsonNode;
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
  ##   NextToken: JString
  ##            : An opaque pagination token returned from the previous <code>DescribeVoices</code> operation. If present, this indicates where to continue the listing.
  ##   LanguageCode: JString
  ##               :  The language identification tag (ISO 639 code for the language name-ISO 3166 country code) for filtering the list of voices returned. If you don't specify this optional parameter, all available voices are returned. 
  ##   IncludeAdditionalLanguageCodes: JBool
  ##                                 : Boolean value indicating whether to return any bilingual voices that use the specified language as an additional language. For instance, if you request all languages that use US English (es-US), and there is an Italian voice that speaks both Italian (it-IT) and US English, that voice will be included if you specify <code>yes</code> but not if you specify <code>no</code>.
  section = newJObject()
  var valid_593020 = query.getOrDefault("Engine")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = newJString("standard"))
  if valid_593020 != nil:
    section.add "Engine", valid_593020
  var valid_593021 = query.getOrDefault("NextToken")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "NextToken", valid_593021
  var valid_593022 = query.getOrDefault("LanguageCode")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = newJString("arb"))
  if valid_593022 != nil:
    section.add "LanguageCode", valid_593022
  var valid_593023 = query.getOrDefault("IncludeAdditionalLanguageCodes")
  valid_593023 = validateParameter(valid_593023, JBool, required = false, default = nil)
  if valid_593023 != nil:
    section.add "IncludeAdditionalLanguageCodes", valid_593023
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
  var valid_593024 = header.getOrDefault("X-Amz-Signature")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Signature", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Content-Sha256", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Date")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Date", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-Credential")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-Credential", valid_593027
  var valid_593028 = header.getOrDefault("X-Amz-Security-Token")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "X-Amz-Security-Token", valid_593028
  var valid_593029 = header.getOrDefault("X-Amz-Algorithm")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "X-Amz-Algorithm", valid_593029
  var valid_593030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "X-Amz-SignedHeaders", valid_593030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593031: Call_DescribeVoices_593004; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the list of voices that are available for use when requesting speech synthesis. Each voice speaks a specified language, is either male or female, and is identified by an ID, which is the ASCII version of the voice name. </p> <p>When synthesizing speech ( <code>SynthesizeSpeech</code> ), you provide the voice ID for the voice you want from the list of voices returned by <code>DescribeVoices</code>.</p> <p>For example, you want your news reader application to read news in a specific language, but giving a user the option to choose the voice. Using the <code>DescribeVoices</code> operation you can provide the user with a list of available voices to select from.</p> <p> You can optionally specify a language code to filter the available voices. For example, if you specify <code>en-US</code>, the operation returns a list of all available US English voices. </p> <p>This operation requires permissions to perform the <code>polly:DescribeVoices</code> action.</p>
  ## 
  let valid = call_593031.validator(path, query, header, formData, body)
  let scheme = call_593031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593031.url(scheme.get, call_593031.host, call_593031.base,
                         call_593031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593031, url, valid)

proc call*(call_593032: Call_DescribeVoices_593004; Engine: string = "standard";
          NextToken: string = ""; LanguageCode: string = "arb";
          IncludeAdditionalLanguageCodes: bool = false): Recallable =
  ## describeVoices
  ## <p>Returns the list of voices that are available for use when requesting speech synthesis. Each voice speaks a specified language, is either male or female, and is identified by an ID, which is the ASCII version of the voice name. </p> <p>When synthesizing speech ( <code>SynthesizeSpeech</code> ), you provide the voice ID for the voice you want from the list of voices returned by <code>DescribeVoices</code>.</p> <p>For example, you want your news reader application to read news in a specific language, but giving a user the option to choose the voice. Using the <code>DescribeVoices</code> operation you can provide the user with a list of available voices to select from.</p> <p> You can optionally specify a language code to filter the available voices. For example, if you specify <code>en-US</code>, the operation returns a list of all available US English voices. </p> <p>This operation requires permissions to perform the <code>polly:DescribeVoices</code> action.</p>
  ##   Engine: string
  ##         : Specifies the engine (<code>standard</code> or <code>neural</code>) used by Amazon Polly when processing input text for speech synthesis. 
  ##   NextToken: string
  ##            : An opaque pagination token returned from the previous <code>DescribeVoices</code> operation. If present, this indicates where to continue the listing.
  ##   LanguageCode: string
  ##               :  The language identification tag (ISO 639 code for the language name-ISO 3166 country code) for filtering the list of voices returned. If you don't specify this optional parameter, all available voices are returned. 
  ##   IncludeAdditionalLanguageCodes: bool
  ##                                 : Boolean value indicating whether to return any bilingual voices that use the specified language as an additional language. For instance, if you request all languages that use US English (es-US), and there is an Italian voice that speaks both Italian (it-IT) and US English, that voice will be included if you specify <code>yes</code> but not if you specify <code>no</code>.
  var query_593033 = newJObject()
  add(query_593033, "Engine", newJString(Engine))
  add(query_593033, "NextToken", newJString(NextToken))
  add(query_593033, "LanguageCode", newJString(LanguageCode))
  add(query_593033, "IncludeAdditionalLanguageCodes",
      newJBool(IncludeAdditionalLanguageCodes))
  result = call_593032.call(nil, query_593033, nil, nil, nil)

var describeVoices* = Call_DescribeVoices_593004(name: "describeVoices",
    meth: HttpMethod.HttpGet, host: "polly.amazonaws.com", route: "/v1/voices",
    validator: validate_DescribeVoices_593005, base: "/", url: url_DescribeVoices_593006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSpeechSynthesisTask_593034 = ref object of OpenApiRestCall_592365
proc url_GetSpeechSynthesisTask_593036(protocol: Scheme; host: string; base: string;
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

proc validate_GetSpeechSynthesisTask_593035(path: JsonNode; query: JsonNode;
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
  var valid_593037 = path.getOrDefault("TaskId")
  valid_593037 = validateParameter(valid_593037, JString, required = true,
                                 default = nil)
  if valid_593037 != nil:
    section.add "TaskId", valid_593037
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
  var valid_593038 = header.getOrDefault("X-Amz-Signature")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Signature", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Content-Sha256", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Date")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Date", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Credential")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Credential", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-Security-Token")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-Security-Token", valid_593042
  var valid_593043 = header.getOrDefault("X-Amz-Algorithm")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "X-Amz-Algorithm", valid_593043
  var valid_593044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "X-Amz-SignedHeaders", valid_593044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593045: Call_GetSpeechSynthesisTask_593034; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specific SpeechSynthesisTask object based on its TaskID. This object contains information about the given speech synthesis task, including the status of the task, and a link to the S3 bucket containing the output of the task.
  ## 
  let valid = call_593045.validator(path, query, header, formData, body)
  let scheme = call_593045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593045.url(scheme.get, call_593045.host, call_593045.base,
                         call_593045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593045, url, valid)

proc call*(call_593046: Call_GetSpeechSynthesisTask_593034; TaskId: string): Recallable =
  ## getSpeechSynthesisTask
  ## Retrieves a specific SpeechSynthesisTask object based on its TaskID. This object contains information about the given speech synthesis task, including the status of the task, and a link to the S3 bucket containing the output of the task.
  ##   TaskId: string (required)
  ##         : The Amazon Polly generated identifier for a speech synthesis task.
  var path_593047 = newJObject()
  add(path_593047, "TaskId", newJString(TaskId))
  result = call_593046.call(path_593047, nil, nil, nil, nil)

var getSpeechSynthesisTask* = Call_GetSpeechSynthesisTask_593034(
    name: "getSpeechSynthesisTask", meth: HttpMethod.HttpGet,
    host: "polly.amazonaws.com", route: "/v1/synthesisTasks/{TaskId}",
    validator: validate_GetSpeechSynthesisTask_593035, base: "/",
    url: url_GetSpeechSynthesisTask_593036, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLexicons_593048 = ref object of OpenApiRestCall_592365
proc url_ListLexicons_593050(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLexicons_593049(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593051 = query.getOrDefault("NextToken")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "NextToken", valid_593051
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
  var valid_593052 = header.getOrDefault("X-Amz-Signature")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Signature", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Content-Sha256", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Date")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Date", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Credential")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Credential", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-Security-Token")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-Security-Token", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-Algorithm")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-Algorithm", valid_593057
  var valid_593058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "X-Amz-SignedHeaders", valid_593058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593059: Call_ListLexicons_593048; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of pronunciation lexicons stored in an AWS Region. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.
  ## 
  let valid = call_593059.validator(path, query, header, formData, body)
  let scheme = call_593059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593059.url(scheme.get, call_593059.host, call_593059.base,
                         call_593059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593059, url, valid)

proc call*(call_593060: Call_ListLexicons_593048; NextToken: string = ""): Recallable =
  ## listLexicons
  ## Returns a list of pronunciation lexicons stored in an AWS Region. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.
  ##   NextToken: string
  ##            : An opaque pagination token returned from previous <code>ListLexicons</code> operation. If present, indicates where to continue the list of lexicons.
  var query_593061 = newJObject()
  add(query_593061, "NextToken", newJString(NextToken))
  result = call_593060.call(nil, query_593061, nil, nil, nil)

var listLexicons* = Call_ListLexicons_593048(name: "listLexicons",
    meth: HttpMethod.HttpGet, host: "polly.amazonaws.com", route: "/v1/lexicons",
    validator: validate_ListLexicons_593049, base: "/", url: url_ListLexicons_593050,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSpeechSynthesisTask_593078 = ref object of OpenApiRestCall_592365
proc url_StartSpeechSynthesisTask_593080(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartSpeechSynthesisTask_593079(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593081 = header.getOrDefault("X-Amz-Signature")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-Signature", valid_593081
  var valid_593082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-Content-Sha256", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-Date")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-Date", valid_593083
  var valid_593084 = header.getOrDefault("X-Amz-Credential")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "X-Amz-Credential", valid_593084
  var valid_593085 = header.getOrDefault("X-Amz-Security-Token")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-Security-Token", valid_593085
  var valid_593086 = header.getOrDefault("X-Amz-Algorithm")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "X-Amz-Algorithm", valid_593086
  var valid_593087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-SignedHeaders", valid_593087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593089: Call_StartSpeechSynthesisTask_593078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows the creation of an asynchronous synthesis task, by starting a new <code>SpeechSynthesisTask</code>. This operation requires all the standard information needed for speech synthesis, plus the name of an Amazon S3 bucket for the service to store the output of the synthesis task and two optional parameters (OutputS3KeyPrefix and SnsTopicArn). Once the synthesis task is created, this operation will return a SpeechSynthesisTask object, which will include an identifier of this task as well as the current status.
  ## 
  let valid = call_593089.validator(path, query, header, formData, body)
  let scheme = call_593089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593089.url(scheme.get, call_593089.host, call_593089.base,
                         call_593089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593089, url, valid)

proc call*(call_593090: Call_StartSpeechSynthesisTask_593078; body: JsonNode): Recallable =
  ## startSpeechSynthesisTask
  ## Allows the creation of an asynchronous synthesis task, by starting a new <code>SpeechSynthesisTask</code>. This operation requires all the standard information needed for speech synthesis, plus the name of an Amazon S3 bucket for the service to store the output of the synthesis task and two optional parameters (OutputS3KeyPrefix and SnsTopicArn). Once the synthesis task is created, this operation will return a SpeechSynthesisTask object, which will include an identifier of this task as well as the current status.
  ##   body: JObject (required)
  var body_593091 = newJObject()
  if body != nil:
    body_593091 = body
  result = call_593090.call(nil, nil, nil, nil, body_593091)

var startSpeechSynthesisTask* = Call_StartSpeechSynthesisTask_593078(
    name: "startSpeechSynthesisTask", meth: HttpMethod.HttpPost,
    host: "polly.amazonaws.com", route: "/v1/synthesisTasks",
    validator: validate_StartSpeechSynthesisTask_593079, base: "/",
    url: url_StartSpeechSynthesisTask_593080, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSpeechSynthesisTasks_593062 = ref object of OpenApiRestCall_592365
proc url_ListSpeechSynthesisTasks_593064(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSpeechSynthesisTasks_593063(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of SpeechSynthesisTask objects ordered by their creation date. This operation can filter the tasks by their status, for example, allowing users to list only tasks that are completed.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
  ##             : Maximum number of speech synthesis tasks returned in a List operation.
  ##   Status: JString
  ##         : Status of the speech synthesis tasks returned in a List operation
  ##   NextToken: JString
  ##            : The pagination token to use in the next request to continue the listing of speech synthesis tasks. 
  section = newJObject()
  var valid_593065 = query.getOrDefault("MaxResults")
  valid_593065 = validateParameter(valid_593065, JInt, required = false, default = nil)
  if valid_593065 != nil:
    section.add "MaxResults", valid_593065
  var valid_593066 = query.getOrDefault("Status")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = newJString("scheduled"))
  if valid_593066 != nil:
    section.add "Status", valid_593066
  var valid_593067 = query.getOrDefault("NextToken")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "NextToken", valid_593067
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
  var valid_593068 = header.getOrDefault("X-Amz-Signature")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Signature", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-Content-Sha256", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-Date")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Date", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-Credential")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-Credential", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-Security-Token")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-Security-Token", valid_593072
  var valid_593073 = header.getOrDefault("X-Amz-Algorithm")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "X-Amz-Algorithm", valid_593073
  var valid_593074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "X-Amz-SignedHeaders", valid_593074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593075: Call_ListSpeechSynthesisTasks_593062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of SpeechSynthesisTask objects ordered by their creation date. This operation can filter the tasks by their status, for example, allowing users to list only tasks that are completed.
  ## 
  let valid = call_593075.validator(path, query, header, formData, body)
  let scheme = call_593075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593075.url(scheme.get, call_593075.host, call_593075.base,
                         call_593075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593075, url, valid)

proc call*(call_593076: Call_ListSpeechSynthesisTasks_593062; MaxResults: int = 0;
          Status: string = "scheduled"; NextToken: string = ""): Recallable =
  ## listSpeechSynthesisTasks
  ## Returns a list of SpeechSynthesisTask objects ordered by their creation date. This operation can filter the tasks by their status, for example, allowing users to list only tasks that are completed.
  ##   MaxResults: int
  ##             : Maximum number of speech synthesis tasks returned in a List operation.
  ##   Status: string
  ##         : Status of the speech synthesis tasks returned in a List operation
  ##   NextToken: string
  ##            : The pagination token to use in the next request to continue the listing of speech synthesis tasks. 
  var query_593077 = newJObject()
  add(query_593077, "MaxResults", newJInt(MaxResults))
  add(query_593077, "Status", newJString(Status))
  add(query_593077, "NextToken", newJString(NextToken))
  result = call_593076.call(nil, query_593077, nil, nil, nil)

var listSpeechSynthesisTasks* = Call_ListSpeechSynthesisTasks_593062(
    name: "listSpeechSynthesisTasks", meth: HttpMethod.HttpGet,
    host: "polly.amazonaws.com", route: "/v1/synthesisTasks",
    validator: validate_ListSpeechSynthesisTasks_593063, base: "/",
    url: url_ListSpeechSynthesisTasks_593064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SynthesizeSpeech_593092 = ref object of OpenApiRestCall_592365
proc url_SynthesizeSpeech_593094(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SynthesizeSpeech_593093(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593095 = header.getOrDefault("X-Amz-Signature")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "X-Amz-Signature", valid_593095
  var valid_593096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-Content-Sha256", valid_593096
  var valid_593097 = header.getOrDefault("X-Amz-Date")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Date", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-Credential")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-Credential", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-Security-Token")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-Security-Token", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-Algorithm")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Algorithm", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-SignedHeaders", valid_593101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593103: Call_SynthesizeSpeech_593092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Synthesizes UTF-8 input, plain text or SSML, to a stream of bytes. SSML input must be valid, well-formed SSML. Some alphabets might not be available with all the voices (for example, Cyrillic might not be read at all by English voices) unless phoneme mapping is used. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/how-text-to-speech-works.html">How it Works</a>.
  ## 
  let valid = call_593103.validator(path, query, header, formData, body)
  let scheme = call_593103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593103.url(scheme.get, call_593103.host, call_593103.base,
                         call_593103.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593103, url, valid)

proc call*(call_593104: Call_SynthesizeSpeech_593092; body: JsonNode): Recallable =
  ## synthesizeSpeech
  ## Synthesizes UTF-8 input, plain text or SSML, to a stream of bytes. SSML input must be valid, well-formed SSML. Some alphabets might not be available with all the voices (for example, Cyrillic might not be read at all by English voices) unless phoneme mapping is used. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/how-text-to-speech-works.html">How it Works</a>.
  ##   body: JObject (required)
  var body_593105 = newJObject()
  if body != nil:
    body_593105 = body
  result = call_593104.call(nil, nil, nil, nil, body_593105)

var synthesizeSpeech* = Call_SynthesizeSpeech_593092(name: "synthesizeSpeech",
    meth: HttpMethod.HttpPost, host: "polly.amazonaws.com", route: "/v1/speech",
    validator: validate_SynthesizeSpeech_593093, base: "/",
    url: url_SynthesizeSpeech_593094, schemes: {Scheme.Https, Scheme.Http})
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
