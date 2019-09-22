
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Elasticsearch Service
## version: 2015-01-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Elasticsearch Configuration Service</fullname> <p>Use the Amazon Elasticsearch configuration API to create, configure, and manage Elasticsearch domains.</p> <p>The endpoint for configuration service requests is region-specific: es.<i>region</i>.amazonaws.com. For example, es.us-east-1.amazonaws.com. For a current list of supported regions and endpoints, see <a href="http://docs.aws.amazon.com/general/latest/gr/rande.html#elasticsearch-service-regions" target="_blank">Regions and Endpoints</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/es/
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

  OpenApiRestCall_602433 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602433](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602433): Option[Scheme] {.used.} =
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
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "es.ap-northeast-1.amazonaws.com",
                           "ap-southeast-1": "es.ap-southeast-1.amazonaws.com",
                           "us-west-2": "es.us-west-2.amazonaws.com",
                           "eu-west-2": "es.eu-west-2.amazonaws.com",
                           "ap-northeast-3": "es.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "es.eu-central-1.amazonaws.com",
                           "us-east-2": "es.us-east-2.amazonaws.com",
                           "us-east-1": "es.us-east-1.amazonaws.com", "cn-northwest-1": "es.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "es.ap-south-1.amazonaws.com",
                           "eu-north-1": "es.eu-north-1.amazonaws.com",
                           "ap-northeast-2": "es.ap-northeast-2.amazonaws.com",
                           "us-west-1": "es.us-west-1.amazonaws.com",
                           "us-gov-east-1": "es.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "es.eu-west-3.amazonaws.com",
                           "cn-north-1": "es.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "es.sa-east-1.amazonaws.com",
                           "eu-west-1": "es.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "es.us-gov-west-1.amazonaws.com",
                           "ap-southeast-2": "es.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "es.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "es.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "es.ap-southeast-1.amazonaws.com",
      "us-west-2": "es.us-west-2.amazonaws.com",
      "eu-west-2": "es.eu-west-2.amazonaws.com",
      "ap-northeast-3": "es.ap-northeast-3.amazonaws.com",
      "eu-central-1": "es.eu-central-1.amazonaws.com",
      "us-east-2": "es.us-east-2.amazonaws.com",
      "us-east-1": "es.us-east-1.amazonaws.com",
      "cn-northwest-1": "es.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "es.ap-south-1.amazonaws.com",
      "eu-north-1": "es.eu-north-1.amazonaws.com",
      "ap-northeast-2": "es.ap-northeast-2.amazonaws.com",
      "us-west-1": "es.us-west-1.amazonaws.com",
      "us-gov-east-1": "es.us-gov-east-1.amazonaws.com",
      "eu-west-3": "es.eu-west-3.amazonaws.com",
      "cn-north-1": "es.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "es.sa-east-1.amazonaws.com",
      "eu-west-1": "es.eu-west-1.amazonaws.com",
      "us-gov-west-1": "es.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "es.ap-southeast-2.amazonaws.com",
      "ca-central-1": "es.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "es"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AddTags_602770 = ref object of OpenApiRestCall_602433
proc url_AddTags_602772(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AddTags_602771(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Attaches tags to an existing Elasticsearch domain. Tags are a set of case-sensitive key value pairs. An Elasticsearch domain may have up to 10 tags. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-managedomains.html#es-managedomains-awsresorcetagging" target="_blank"> Tagging Amazon Elasticsearch Service Domains for more information.</a>
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
  var valid_602884 = header.getOrDefault("X-Amz-Date")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "X-Amz-Date", valid_602884
  var valid_602885 = header.getOrDefault("X-Amz-Security-Token")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-Security-Token", valid_602885
  var valid_602886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602886 = validateParameter(valid_602886, JString, required = false,
                                 default = nil)
  if valid_602886 != nil:
    section.add "X-Amz-Content-Sha256", valid_602886
  var valid_602887 = header.getOrDefault("X-Amz-Algorithm")
  valid_602887 = validateParameter(valid_602887, JString, required = false,
                                 default = nil)
  if valid_602887 != nil:
    section.add "X-Amz-Algorithm", valid_602887
  var valid_602888 = header.getOrDefault("X-Amz-Signature")
  valid_602888 = validateParameter(valid_602888, JString, required = false,
                                 default = nil)
  if valid_602888 != nil:
    section.add "X-Amz-Signature", valid_602888
  var valid_602889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "X-Amz-SignedHeaders", valid_602889
  var valid_602890 = header.getOrDefault("X-Amz-Credential")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "X-Amz-Credential", valid_602890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602914: Call_AddTags_602770; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches tags to an existing Elasticsearch domain. Tags are a set of case-sensitive key value pairs. An Elasticsearch domain may have up to 10 tags. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-managedomains.html#es-managedomains-awsresorcetagging" target="_blank"> Tagging Amazon Elasticsearch Service Domains for more information.</a>
  ## 
  let valid = call_602914.validator(path, query, header, formData, body)
  let scheme = call_602914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602914.url(scheme.get, call_602914.host, call_602914.base,
                         call_602914.route, valid.getOrDefault("path"))
  result = hook(call_602914, url, valid)

proc call*(call_602985: Call_AddTags_602770; body: JsonNode): Recallable =
  ## addTags
  ## Attaches tags to an existing Elasticsearch domain. Tags are a set of case-sensitive key value pairs. An Elasticsearch domain may have up to 10 tags. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-managedomains.html#es-managedomains-awsresorcetagging" target="_blank"> Tagging Amazon Elasticsearch Service Domains for more information.</a>
  ##   body: JObject (required)
  var body_602986 = newJObject()
  if body != nil:
    body_602986 = body
  result = call_602985.call(nil, nil, nil, nil, body_602986)

var addTags* = Call_AddTags_602770(name: "addTags", meth: HttpMethod.HttpPost,
                                host: "es.amazonaws.com",
                                route: "/2015-01-01/tags",
                                validator: validate_AddTags_602771, base: "/",
                                url: url_AddTags_602772,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelElasticsearchServiceSoftwareUpdate_603025 = ref object of OpenApiRestCall_602433
proc url_CancelElasticsearchServiceSoftwareUpdate_603027(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CancelElasticsearchServiceSoftwareUpdate_603026(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Cancels a scheduled service software update for an Amazon ES domain. You can only perform this operation before the <code>AutomatedUpdateDate</code> and when the <code>UpdateStatus</code> is in the <code>PENDING_UPDATE</code> state.
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
  var valid_603028 = header.getOrDefault("X-Amz-Date")
  valid_603028 = validateParameter(valid_603028, JString, required = false,
                                 default = nil)
  if valid_603028 != nil:
    section.add "X-Amz-Date", valid_603028
  var valid_603029 = header.getOrDefault("X-Amz-Security-Token")
  valid_603029 = validateParameter(valid_603029, JString, required = false,
                                 default = nil)
  if valid_603029 != nil:
    section.add "X-Amz-Security-Token", valid_603029
  var valid_603030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603030 = validateParameter(valid_603030, JString, required = false,
                                 default = nil)
  if valid_603030 != nil:
    section.add "X-Amz-Content-Sha256", valid_603030
  var valid_603031 = header.getOrDefault("X-Amz-Algorithm")
  valid_603031 = validateParameter(valid_603031, JString, required = false,
                                 default = nil)
  if valid_603031 != nil:
    section.add "X-Amz-Algorithm", valid_603031
  var valid_603032 = header.getOrDefault("X-Amz-Signature")
  valid_603032 = validateParameter(valid_603032, JString, required = false,
                                 default = nil)
  if valid_603032 != nil:
    section.add "X-Amz-Signature", valid_603032
  var valid_603033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603033 = validateParameter(valid_603033, JString, required = false,
                                 default = nil)
  if valid_603033 != nil:
    section.add "X-Amz-SignedHeaders", valid_603033
  var valid_603034 = header.getOrDefault("X-Amz-Credential")
  valid_603034 = validateParameter(valid_603034, JString, required = false,
                                 default = nil)
  if valid_603034 != nil:
    section.add "X-Amz-Credential", valid_603034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603036: Call_CancelElasticsearchServiceSoftwareUpdate_603025;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Cancels a scheduled service software update for an Amazon ES domain. You can only perform this operation before the <code>AutomatedUpdateDate</code> and when the <code>UpdateStatus</code> is in the <code>PENDING_UPDATE</code> state.
  ## 
  let valid = call_603036.validator(path, query, header, formData, body)
  let scheme = call_603036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603036.url(scheme.get, call_603036.host, call_603036.base,
                         call_603036.route, valid.getOrDefault("path"))
  result = hook(call_603036, url, valid)

proc call*(call_603037: Call_CancelElasticsearchServiceSoftwareUpdate_603025;
          body: JsonNode): Recallable =
  ## cancelElasticsearchServiceSoftwareUpdate
  ## Cancels a scheduled service software update for an Amazon ES domain. You can only perform this operation before the <code>AutomatedUpdateDate</code> and when the <code>UpdateStatus</code> is in the <code>PENDING_UPDATE</code> state.
  ##   body: JObject (required)
  var body_603038 = newJObject()
  if body != nil:
    body_603038 = body
  result = call_603037.call(nil, nil, nil, nil, body_603038)

var cancelElasticsearchServiceSoftwareUpdate* = Call_CancelElasticsearchServiceSoftwareUpdate_603025(
    name: "cancelElasticsearchServiceSoftwareUpdate", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com",
    route: "/2015-01-01/es/serviceSoftwareUpdate/cancel",
    validator: validate_CancelElasticsearchServiceSoftwareUpdate_603026,
    base: "/", url: url_CancelElasticsearchServiceSoftwareUpdate_603027,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateElasticsearchDomain_603039 = ref object of OpenApiRestCall_602433
proc url_CreateElasticsearchDomain_603041(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateElasticsearchDomain_603040(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new Elasticsearch domain. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomains" target="_blank">Creating Elasticsearch Domains</a> in the <i>Amazon Elasticsearch Service Developer Guide</i>.
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
  var valid_603042 = header.getOrDefault("X-Amz-Date")
  valid_603042 = validateParameter(valid_603042, JString, required = false,
                                 default = nil)
  if valid_603042 != nil:
    section.add "X-Amz-Date", valid_603042
  var valid_603043 = header.getOrDefault("X-Amz-Security-Token")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "X-Amz-Security-Token", valid_603043
  var valid_603044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603044 = validateParameter(valid_603044, JString, required = false,
                                 default = nil)
  if valid_603044 != nil:
    section.add "X-Amz-Content-Sha256", valid_603044
  var valid_603045 = header.getOrDefault("X-Amz-Algorithm")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "X-Amz-Algorithm", valid_603045
  var valid_603046 = header.getOrDefault("X-Amz-Signature")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-Signature", valid_603046
  var valid_603047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-SignedHeaders", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-Credential")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-Credential", valid_603048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603050: Call_CreateElasticsearchDomain_603039; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Elasticsearch domain. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomains" target="_blank">Creating Elasticsearch Domains</a> in the <i>Amazon Elasticsearch Service Developer Guide</i>.
  ## 
  let valid = call_603050.validator(path, query, header, formData, body)
  let scheme = call_603050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603050.url(scheme.get, call_603050.host, call_603050.base,
                         call_603050.route, valid.getOrDefault("path"))
  result = hook(call_603050, url, valid)

proc call*(call_603051: Call_CreateElasticsearchDomain_603039; body: JsonNode): Recallable =
  ## createElasticsearchDomain
  ## Creates a new Elasticsearch domain. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomains" target="_blank">Creating Elasticsearch Domains</a> in the <i>Amazon Elasticsearch Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_603052 = newJObject()
  if body != nil:
    body_603052 = body
  result = call_603051.call(nil, nil, nil, nil, body_603052)

var createElasticsearchDomain* = Call_CreateElasticsearchDomain_603039(
    name: "createElasticsearchDomain", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain",
    validator: validate_CreateElasticsearchDomain_603040, base: "/",
    url: url_CreateElasticsearchDomain_603041,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchDomain_603053 = ref object of OpenApiRestCall_602433
proc url_DescribeElasticsearchDomain_603055(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/domain/"),
               (kind: VariableSegment, value: "DomainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DescribeElasticsearchDomain_603054(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns domain configuration information about the specified Elasticsearch domain, including the domain ID, domain endpoint, and domain ARN.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DomainName: JString (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DomainName` field"
  var valid_603070 = path.getOrDefault("DomainName")
  valid_603070 = validateParameter(valid_603070, JString, required = true,
                                 default = nil)
  if valid_603070 != nil:
    section.add "DomainName", valid_603070
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
  var valid_603071 = header.getOrDefault("X-Amz-Date")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Date", valid_603071
  var valid_603072 = header.getOrDefault("X-Amz-Security-Token")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-Security-Token", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Content-Sha256", valid_603073
  var valid_603074 = header.getOrDefault("X-Amz-Algorithm")
  valid_603074 = validateParameter(valid_603074, JString, required = false,
                                 default = nil)
  if valid_603074 != nil:
    section.add "X-Amz-Algorithm", valid_603074
  var valid_603075 = header.getOrDefault("X-Amz-Signature")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Signature", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-SignedHeaders", valid_603076
  var valid_603077 = header.getOrDefault("X-Amz-Credential")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Credential", valid_603077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603078: Call_DescribeElasticsearchDomain_603053; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns domain configuration information about the specified Elasticsearch domain, including the domain ID, domain endpoint, and domain ARN.
  ## 
  let valid = call_603078.validator(path, query, header, formData, body)
  let scheme = call_603078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603078.url(scheme.get, call_603078.host, call_603078.base,
                         call_603078.route, valid.getOrDefault("path"))
  result = hook(call_603078, url, valid)

proc call*(call_603079: Call_DescribeElasticsearchDomain_603053; DomainName: string): Recallable =
  ## describeElasticsearchDomain
  ## Returns domain configuration information about the specified Elasticsearch domain, including the domain ID, domain endpoint, and domain ARN.
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var path_603080 = newJObject()
  add(path_603080, "DomainName", newJString(DomainName))
  result = call_603079.call(path_603080, nil, nil, nil, nil)

var describeElasticsearchDomain* = Call_DescribeElasticsearchDomain_603053(
    name: "describeElasticsearchDomain", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain/{DomainName}",
    validator: validate_DescribeElasticsearchDomain_603054, base: "/",
    url: url_DescribeElasticsearchDomain_603055,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteElasticsearchDomain_603082 = ref object of OpenApiRestCall_602433
proc url_DeleteElasticsearchDomain_603084(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/domain/"),
               (kind: VariableSegment, value: "DomainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteElasticsearchDomain_603083(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Permanently deletes the specified Elasticsearch domain and all of its data. Once a domain is deleted, it cannot be recovered.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DomainName: JString (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DomainName` field"
  var valid_603085 = path.getOrDefault("DomainName")
  valid_603085 = validateParameter(valid_603085, JString, required = true,
                                 default = nil)
  if valid_603085 != nil:
    section.add "DomainName", valid_603085
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
  var valid_603086 = header.getOrDefault("X-Amz-Date")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Date", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-Security-Token")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Security-Token", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Content-Sha256", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-Algorithm")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-Algorithm", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-Signature")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Signature", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-SignedHeaders", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Credential")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Credential", valid_603092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603093: Call_DeleteElasticsearchDomain_603082; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes the specified Elasticsearch domain and all of its data. Once a domain is deleted, it cannot be recovered.
  ## 
  let valid = call_603093.validator(path, query, header, formData, body)
  let scheme = call_603093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603093.url(scheme.get, call_603093.host, call_603093.base,
                         call_603093.route, valid.getOrDefault("path"))
  result = hook(call_603093, url, valid)

proc call*(call_603094: Call_DeleteElasticsearchDomain_603082; DomainName: string): Recallable =
  ## deleteElasticsearchDomain
  ## Permanently deletes the specified Elasticsearch domain and all of its data. Once a domain is deleted, it cannot be recovered.
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var path_603095 = newJObject()
  add(path_603095, "DomainName", newJString(DomainName))
  result = call_603094.call(path_603095, nil, nil, nil, nil)

var deleteElasticsearchDomain* = Call_DeleteElasticsearchDomain_603082(
    name: "deleteElasticsearchDomain", meth: HttpMethod.HttpDelete,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain/{DomainName}",
    validator: validate_DeleteElasticsearchDomain_603083, base: "/",
    url: url_DeleteElasticsearchDomain_603084,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteElasticsearchServiceRole_603096 = ref object of OpenApiRestCall_602433
proc url_DeleteElasticsearchServiceRole_603098(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteElasticsearchServiceRole_603097(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the service-linked role that Elasticsearch Service uses to manage and maintain VPC domains. Role deletion will fail if any existing VPC domains use the role. You must delete any such Elasticsearch domains before deleting the role. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html#es-enabling-slr" target="_blank">Deleting Elasticsearch Service Role</a> in <i>VPC Endpoints for Amazon Elasticsearch Service Domains</i>.
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
  var valid_603099 = header.getOrDefault("X-Amz-Date")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Date", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Security-Token")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Security-Token", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Content-Sha256", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Algorithm")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Algorithm", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Signature")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Signature", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-SignedHeaders", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Credential")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Credential", valid_603105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603106: Call_DeleteElasticsearchServiceRole_603096; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the service-linked role that Elasticsearch Service uses to manage and maintain VPC domains. Role deletion will fail if any existing VPC domains use the role. You must delete any such Elasticsearch domains before deleting the role. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html#es-enabling-slr" target="_blank">Deleting Elasticsearch Service Role</a> in <i>VPC Endpoints for Amazon Elasticsearch Service Domains</i>.
  ## 
  let valid = call_603106.validator(path, query, header, formData, body)
  let scheme = call_603106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603106.url(scheme.get, call_603106.host, call_603106.base,
                         call_603106.route, valid.getOrDefault("path"))
  result = hook(call_603106, url, valid)

proc call*(call_603107: Call_DeleteElasticsearchServiceRole_603096): Recallable =
  ## deleteElasticsearchServiceRole
  ## Deletes the service-linked role that Elasticsearch Service uses to manage and maintain VPC domains. Role deletion will fail if any existing VPC domains use the role. You must delete any such Elasticsearch domains before deleting the role. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html#es-enabling-slr" target="_blank">Deleting Elasticsearch Service Role</a> in <i>VPC Endpoints for Amazon Elasticsearch Service Domains</i>.
  result = call_603107.call(nil, nil, nil, nil, nil)

var deleteElasticsearchServiceRole* = Call_DeleteElasticsearchServiceRole_603096(
    name: "deleteElasticsearchServiceRole", meth: HttpMethod.HttpDelete,
    host: "es.amazonaws.com", route: "/2015-01-01/es/role",
    validator: validate_DeleteElasticsearchServiceRole_603097, base: "/",
    url: url_DeleteElasticsearchServiceRole_603098,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateElasticsearchDomainConfig_603122 = ref object of OpenApiRestCall_602433
proc url_UpdateElasticsearchDomainConfig_603124(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/domain/"),
               (kind: VariableSegment, value: "DomainName"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateElasticsearchDomainConfig_603123(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies the cluster configuration of the specified Elasticsearch domain, setting as setting the instance type and the number of instances. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DomainName: JString (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DomainName` field"
  var valid_603125 = path.getOrDefault("DomainName")
  valid_603125 = validateParameter(valid_603125, JString, required = true,
                                 default = nil)
  if valid_603125 != nil:
    section.add "DomainName", valid_603125
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
  var valid_603126 = header.getOrDefault("X-Amz-Date")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Date", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Security-Token")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Security-Token", valid_603127
  var valid_603128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-Content-Sha256", valid_603128
  var valid_603129 = header.getOrDefault("X-Amz-Algorithm")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "X-Amz-Algorithm", valid_603129
  var valid_603130 = header.getOrDefault("X-Amz-Signature")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "X-Amz-Signature", valid_603130
  var valid_603131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "X-Amz-SignedHeaders", valid_603131
  var valid_603132 = header.getOrDefault("X-Amz-Credential")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Credential", valid_603132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603134: Call_UpdateElasticsearchDomainConfig_603122;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies the cluster configuration of the specified Elasticsearch domain, setting as setting the instance type and the number of instances. 
  ## 
  let valid = call_603134.validator(path, query, header, formData, body)
  let scheme = call_603134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603134.url(scheme.get, call_603134.host, call_603134.base,
                         call_603134.route, valid.getOrDefault("path"))
  result = hook(call_603134, url, valid)

proc call*(call_603135: Call_UpdateElasticsearchDomainConfig_603122;
          DomainName: string; body: JsonNode): Recallable =
  ## updateElasticsearchDomainConfig
  ## Modifies the cluster configuration of the specified Elasticsearch domain, setting as setting the instance type and the number of instances. 
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   body: JObject (required)
  var path_603136 = newJObject()
  var body_603137 = newJObject()
  add(path_603136, "DomainName", newJString(DomainName))
  if body != nil:
    body_603137 = body
  result = call_603135.call(path_603136, nil, nil, nil, body_603137)

var updateElasticsearchDomainConfig* = Call_UpdateElasticsearchDomainConfig_603122(
    name: "updateElasticsearchDomainConfig", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain/{DomainName}/config",
    validator: validate_UpdateElasticsearchDomainConfig_603123, base: "/",
    url: url_UpdateElasticsearchDomainConfig_603124,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchDomainConfig_603108 = ref object of OpenApiRestCall_602433
proc url_DescribeElasticsearchDomainConfig_603110(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/domain/"),
               (kind: VariableSegment, value: "DomainName"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DescribeElasticsearchDomainConfig_603109(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides cluster configuration information about the specified Elasticsearch domain, such as the state, creation date, update version, and update date for cluster options.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DomainName: JString (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DomainName` field"
  var valid_603111 = path.getOrDefault("DomainName")
  valid_603111 = validateParameter(valid_603111, JString, required = true,
                                 default = nil)
  if valid_603111 != nil:
    section.add "DomainName", valid_603111
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
  var valid_603112 = header.getOrDefault("X-Amz-Date")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Date", valid_603112
  var valid_603113 = header.getOrDefault("X-Amz-Security-Token")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Security-Token", valid_603113
  var valid_603114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-Content-Sha256", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-Algorithm")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Algorithm", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-Signature")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Signature", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-SignedHeaders", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Credential")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Credential", valid_603118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603119: Call_DescribeElasticsearchDomainConfig_603108;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Provides cluster configuration information about the specified Elasticsearch domain, such as the state, creation date, update version, and update date for cluster options.
  ## 
  let valid = call_603119.validator(path, query, header, formData, body)
  let scheme = call_603119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603119.url(scheme.get, call_603119.host, call_603119.base,
                         call_603119.route, valid.getOrDefault("path"))
  result = hook(call_603119, url, valid)

proc call*(call_603120: Call_DescribeElasticsearchDomainConfig_603108;
          DomainName: string): Recallable =
  ## describeElasticsearchDomainConfig
  ## Provides cluster configuration information about the specified Elasticsearch domain, such as the state, creation date, update version, and update date for cluster options.
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var path_603121 = newJObject()
  add(path_603121, "DomainName", newJString(DomainName))
  result = call_603120.call(path_603121, nil, nil, nil, nil)

var describeElasticsearchDomainConfig* = Call_DescribeElasticsearchDomainConfig_603108(
    name: "describeElasticsearchDomainConfig", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain/{DomainName}/config",
    validator: validate_DescribeElasticsearchDomainConfig_603109, base: "/",
    url: url_DescribeElasticsearchDomainConfig_603110,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchDomains_603138 = ref object of OpenApiRestCall_602433
proc url_DescribeElasticsearchDomains_603140(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeElasticsearchDomains_603139(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns domain configuration information about the specified Elasticsearch domains, including the domain ID, domain endpoint, and domain ARN.
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
  var valid_603141 = header.getOrDefault("X-Amz-Date")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Date", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Security-Token")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Security-Token", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Content-Sha256", valid_603143
  var valid_603144 = header.getOrDefault("X-Amz-Algorithm")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-Algorithm", valid_603144
  var valid_603145 = header.getOrDefault("X-Amz-Signature")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "X-Amz-Signature", valid_603145
  var valid_603146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "X-Amz-SignedHeaders", valid_603146
  var valid_603147 = header.getOrDefault("X-Amz-Credential")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-Credential", valid_603147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603149: Call_DescribeElasticsearchDomains_603138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns domain configuration information about the specified Elasticsearch domains, including the domain ID, domain endpoint, and domain ARN.
  ## 
  let valid = call_603149.validator(path, query, header, formData, body)
  let scheme = call_603149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603149.url(scheme.get, call_603149.host, call_603149.base,
                         call_603149.route, valid.getOrDefault("path"))
  result = hook(call_603149, url, valid)

proc call*(call_603150: Call_DescribeElasticsearchDomains_603138; body: JsonNode): Recallable =
  ## describeElasticsearchDomains
  ## Returns domain configuration information about the specified Elasticsearch domains, including the domain ID, domain endpoint, and domain ARN.
  ##   body: JObject (required)
  var body_603151 = newJObject()
  if body != nil:
    body_603151 = body
  result = call_603150.call(nil, nil, nil, nil, body_603151)

var describeElasticsearchDomains* = Call_DescribeElasticsearchDomains_603138(
    name: "describeElasticsearchDomains", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain-info",
    validator: validate_DescribeElasticsearchDomains_603139, base: "/",
    url: url_DescribeElasticsearchDomains_603140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchInstanceTypeLimits_603152 = ref object of OpenApiRestCall_602433
proc url_DescribeElasticsearchInstanceTypeLimits_603154(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ElasticsearchVersion" in path,
        "`ElasticsearchVersion` is a required path parameter"
  assert "InstanceType" in path, "`InstanceType` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/instanceTypeLimits/"),
               (kind: VariableSegment, value: "ElasticsearchVersion"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "InstanceType")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DescribeElasticsearchInstanceTypeLimits_603153(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Describe Elasticsearch Limits for a given InstanceType and ElasticsearchVersion. When modifying existing Domain, specify the <code> <a>DomainName</a> </code> to know what Limits are supported for modifying. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceType: JString (required)
  ##               :  The instance type for an Elasticsearch cluster for which Elasticsearch <code> <a>Limits</a> </code> are needed. 
  ##   ElasticsearchVersion: JString (required)
  ##                       :  Version of Elasticsearch for which <code> <a>Limits</a> </code> are needed. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceType` field"
  var valid_603168 = path.getOrDefault("InstanceType")
  valid_603168 = validateParameter(valid_603168, JString, required = true, default = newJString(
      "m3.medium.elasticsearch"))
  if valid_603168 != nil:
    section.add "InstanceType", valid_603168
  var valid_603169 = path.getOrDefault("ElasticsearchVersion")
  valid_603169 = validateParameter(valid_603169, JString, required = true,
                                 default = nil)
  if valid_603169 != nil:
    section.add "ElasticsearchVersion", valid_603169
  result.add "path", section
  ## parameters in `query` object:
  ##   domainName: JString
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_603170 = query.getOrDefault("domainName")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "domainName", valid_603170
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
  var valid_603171 = header.getOrDefault("X-Amz-Date")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Date", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Security-Token")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Security-Token", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Content-Sha256", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-Algorithm")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Algorithm", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-Signature")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Signature", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-SignedHeaders", valid_603176
  var valid_603177 = header.getOrDefault("X-Amz-Credential")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Credential", valid_603177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603178: Call_DescribeElasticsearchInstanceTypeLimits_603152;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Describe Elasticsearch Limits for a given InstanceType and ElasticsearchVersion. When modifying existing Domain, specify the <code> <a>DomainName</a> </code> to know what Limits are supported for modifying. 
  ## 
  let valid = call_603178.validator(path, query, header, formData, body)
  let scheme = call_603178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603178.url(scheme.get, call_603178.host, call_603178.base,
                         call_603178.route, valid.getOrDefault("path"))
  result = hook(call_603178, url, valid)

proc call*(call_603179: Call_DescribeElasticsearchInstanceTypeLimits_603152;
          ElasticsearchVersion: string;
          InstanceType: string = "m3.medium.elasticsearch"; domainName: string = ""): Recallable =
  ## describeElasticsearchInstanceTypeLimits
  ##  Describe Elasticsearch Limits for a given InstanceType and ElasticsearchVersion. When modifying existing Domain, specify the <code> <a>DomainName</a> </code> to know what Limits are supported for modifying. 
  ##   InstanceType: string (required)
  ##               :  The instance type for an Elasticsearch cluster for which Elasticsearch <code> <a>Limits</a> </code> are needed. 
  ##   ElasticsearchVersion: string (required)
  ##                       :  Version of Elasticsearch for which <code> <a>Limits</a> </code> are needed. 
  ##   domainName: string
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var path_603180 = newJObject()
  var query_603181 = newJObject()
  add(path_603180, "InstanceType", newJString(InstanceType))
  add(path_603180, "ElasticsearchVersion", newJString(ElasticsearchVersion))
  add(query_603181, "domainName", newJString(domainName))
  result = call_603179.call(path_603180, query_603181, nil, nil, nil)

var describeElasticsearchInstanceTypeLimits* = Call_DescribeElasticsearchInstanceTypeLimits_603152(
    name: "describeElasticsearchInstanceTypeLimits", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/instanceTypeLimits/{ElasticsearchVersion}/{InstanceType}",
    validator: validate_DescribeElasticsearchInstanceTypeLimits_603153, base: "/",
    url: url_DescribeElasticsearchInstanceTypeLimits_603154,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReservedElasticsearchInstanceOfferings_603182 = ref object of OpenApiRestCall_602433
proc url_DescribeReservedElasticsearchInstanceOfferings_603184(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeReservedElasticsearchInstanceOfferings_603183(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Lists available reserved Elasticsearch instance offerings.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             :  Set this value to limit the number of results returned. 
  ##   nextToken: JString
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   offeringId: JString
  ##             : The offering identifier filter value. Use this parameter to show only the available offering that matches the specified reservation identifier.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603185 = query.getOrDefault("NextToken")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "NextToken", valid_603185
  var valid_603186 = query.getOrDefault("maxResults")
  valid_603186 = validateParameter(valid_603186, JInt, required = false, default = nil)
  if valid_603186 != nil:
    section.add "maxResults", valid_603186
  var valid_603187 = query.getOrDefault("nextToken")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "nextToken", valid_603187
  var valid_603188 = query.getOrDefault("offeringId")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "offeringId", valid_603188
  var valid_603189 = query.getOrDefault("MaxResults")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "MaxResults", valid_603189
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
  var valid_603190 = header.getOrDefault("X-Amz-Date")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Date", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-Security-Token")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Security-Token", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Content-Sha256", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Algorithm")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Algorithm", valid_603193
  var valid_603194 = header.getOrDefault("X-Amz-Signature")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Signature", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-SignedHeaders", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Credential")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Credential", valid_603196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603197: Call_DescribeReservedElasticsearchInstanceOfferings_603182;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists available reserved Elasticsearch instance offerings.
  ## 
  let valid = call_603197.validator(path, query, header, formData, body)
  let scheme = call_603197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603197.url(scheme.get, call_603197.host, call_603197.base,
                         call_603197.route, valid.getOrDefault("path"))
  result = hook(call_603197, url, valid)

proc call*(call_603198: Call_DescribeReservedElasticsearchInstanceOfferings_603182;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          offeringId: string = ""; MaxResults: string = ""): Recallable =
  ## describeReservedElasticsearchInstanceOfferings
  ## Lists available reserved Elasticsearch instance offerings.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             :  Set this value to limit the number of results returned. 
  ##   nextToken: string
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   offeringId: string
  ##             : The offering identifier filter value. Use this parameter to show only the available offering that matches the specified reservation identifier.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603199 = newJObject()
  add(query_603199, "NextToken", newJString(NextToken))
  add(query_603199, "maxResults", newJInt(maxResults))
  add(query_603199, "nextToken", newJString(nextToken))
  add(query_603199, "offeringId", newJString(offeringId))
  add(query_603199, "MaxResults", newJString(MaxResults))
  result = call_603198.call(nil, query_603199, nil, nil, nil)

var describeReservedElasticsearchInstanceOfferings* = Call_DescribeReservedElasticsearchInstanceOfferings_603182(
    name: "describeReservedElasticsearchInstanceOfferings",
    meth: HttpMethod.HttpGet, host: "es.amazonaws.com",
    route: "/2015-01-01/es/reservedInstanceOfferings",
    validator: validate_DescribeReservedElasticsearchInstanceOfferings_603183,
    base: "/", url: url_DescribeReservedElasticsearchInstanceOfferings_603184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReservedElasticsearchInstances_603200 = ref object of OpenApiRestCall_602433
proc url_DescribeReservedElasticsearchInstances_603202(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeReservedElasticsearchInstances_603201(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about reserved Elasticsearch instances for this account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   reservationId: JString
  ##                : The reserved instance identifier filter value. Use this parameter to show only the reservation that matches the specified reserved Elasticsearch instance ID.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             :  Set this value to limit the number of results returned. 
  ##   nextToken: JString
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603203 = query.getOrDefault("reservationId")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "reservationId", valid_603203
  var valid_603204 = query.getOrDefault("NextToken")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "NextToken", valid_603204
  var valid_603205 = query.getOrDefault("maxResults")
  valid_603205 = validateParameter(valid_603205, JInt, required = false, default = nil)
  if valid_603205 != nil:
    section.add "maxResults", valid_603205
  var valid_603206 = query.getOrDefault("nextToken")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "nextToken", valid_603206
  var valid_603207 = query.getOrDefault("MaxResults")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "MaxResults", valid_603207
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
  var valid_603208 = header.getOrDefault("X-Amz-Date")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Date", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-Security-Token")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Security-Token", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Content-Sha256", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Algorithm")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Algorithm", valid_603211
  var valid_603212 = header.getOrDefault("X-Amz-Signature")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Signature", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-SignedHeaders", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Credential")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Credential", valid_603214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603215: Call_DescribeReservedElasticsearchInstances_603200;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns information about reserved Elasticsearch instances for this account.
  ## 
  let valid = call_603215.validator(path, query, header, formData, body)
  let scheme = call_603215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603215.url(scheme.get, call_603215.host, call_603215.base,
                         call_603215.route, valid.getOrDefault("path"))
  result = hook(call_603215, url, valid)

proc call*(call_603216: Call_DescribeReservedElasticsearchInstances_603200;
          reservationId: string = ""; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeReservedElasticsearchInstances
  ## Returns information about reserved Elasticsearch instances for this account.
  ##   reservationId: string
  ##                : The reserved instance identifier filter value. Use this parameter to show only the reservation that matches the specified reserved Elasticsearch instance ID.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             :  Set this value to limit the number of results returned. 
  ##   nextToken: string
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603217 = newJObject()
  add(query_603217, "reservationId", newJString(reservationId))
  add(query_603217, "NextToken", newJString(NextToken))
  add(query_603217, "maxResults", newJInt(maxResults))
  add(query_603217, "nextToken", newJString(nextToken))
  add(query_603217, "MaxResults", newJString(MaxResults))
  result = call_603216.call(nil, query_603217, nil, nil, nil)

var describeReservedElasticsearchInstances* = Call_DescribeReservedElasticsearchInstances_603200(
    name: "describeReservedElasticsearchInstances", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/reservedInstances",
    validator: validate_DescribeReservedElasticsearchInstances_603201, base: "/",
    url: url_DescribeReservedElasticsearchInstances_603202,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCompatibleElasticsearchVersions_603218 = ref object of OpenApiRestCall_602433
proc url_GetCompatibleElasticsearchVersions_603220(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCompatibleElasticsearchVersions_603219(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Returns a list of upgrade compatible Elastisearch versions. You can optionally pass a <code> <a>DomainName</a> </code> to get all upgrade compatible Elasticsearch versions for that specific domain. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   domainName: JString
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_603221 = query.getOrDefault("domainName")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "domainName", valid_603221
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
  var valid_603222 = header.getOrDefault("X-Amz-Date")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Date", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Security-Token")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Security-Token", valid_603223
  var valid_603224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-Content-Sha256", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-Algorithm")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Algorithm", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Signature")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Signature", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-SignedHeaders", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Credential")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Credential", valid_603228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603229: Call_GetCompatibleElasticsearchVersions_603218;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Returns a list of upgrade compatible Elastisearch versions. You can optionally pass a <code> <a>DomainName</a> </code> to get all upgrade compatible Elasticsearch versions for that specific domain. 
  ## 
  let valid = call_603229.validator(path, query, header, formData, body)
  let scheme = call_603229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603229.url(scheme.get, call_603229.host, call_603229.base,
                         call_603229.route, valid.getOrDefault("path"))
  result = hook(call_603229, url, valid)

proc call*(call_603230: Call_GetCompatibleElasticsearchVersions_603218;
          domainName: string = ""): Recallable =
  ## getCompatibleElasticsearchVersions
  ##  Returns a list of upgrade compatible Elastisearch versions. You can optionally pass a <code> <a>DomainName</a> </code> to get all upgrade compatible Elasticsearch versions for that specific domain. 
  ##   domainName: string
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var query_603231 = newJObject()
  add(query_603231, "domainName", newJString(domainName))
  result = call_603230.call(nil, query_603231, nil, nil, nil)

var getCompatibleElasticsearchVersions* = Call_GetCompatibleElasticsearchVersions_603218(
    name: "getCompatibleElasticsearchVersions", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/compatibleVersions",
    validator: validate_GetCompatibleElasticsearchVersions_603219, base: "/",
    url: url_GetCompatibleElasticsearchVersions_603220,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpgradeHistory_603232 = ref object of OpenApiRestCall_602433
proc url_GetUpgradeHistory_603234(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/upgradeDomain/"),
               (kind: VariableSegment, value: "DomainName"),
               (kind: ConstantSegment, value: "/history")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetUpgradeHistory_603233(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves the complete history of the last 10 upgrades that were performed on the domain.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DomainName: JString (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DomainName` field"
  var valid_603235 = path.getOrDefault("DomainName")
  valid_603235 = validateParameter(valid_603235, JString, required = true,
                                 default = nil)
  if valid_603235 != nil:
    section.add "DomainName", valid_603235
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             :  Set this value to limit the number of results returned. 
  ##   nextToken: JString
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603236 = query.getOrDefault("NextToken")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "NextToken", valid_603236
  var valid_603237 = query.getOrDefault("maxResults")
  valid_603237 = validateParameter(valid_603237, JInt, required = false, default = nil)
  if valid_603237 != nil:
    section.add "maxResults", valid_603237
  var valid_603238 = query.getOrDefault("nextToken")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "nextToken", valid_603238
  var valid_603239 = query.getOrDefault("MaxResults")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "MaxResults", valid_603239
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
  var valid_603240 = header.getOrDefault("X-Amz-Date")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Date", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Security-Token")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Security-Token", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Content-Sha256", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Algorithm")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Algorithm", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Signature")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Signature", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-SignedHeaders", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-Credential")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Credential", valid_603246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603247: Call_GetUpgradeHistory_603232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the complete history of the last 10 upgrades that were performed on the domain.
  ## 
  let valid = call_603247.validator(path, query, header, formData, body)
  let scheme = call_603247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603247.url(scheme.get, call_603247.host, call_603247.base,
                         call_603247.route, valid.getOrDefault("path"))
  result = hook(call_603247, url, valid)

proc call*(call_603248: Call_GetUpgradeHistory_603232; DomainName: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## getUpgradeHistory
  ## Retrieves the complete history of the last 10 upgrades that were performed on the domain.
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             :  Set this value to limit the number of results returned. 
  ##   nextToken: string
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   MaxResults: string
  ##             : Pagination limit
  var path_603249 = newJObject()
  var query_603250 = newJObject()
  add(path_603249, "DomainName", newJString(DomainName))
  add(query_603250, "NextToken", newJString(NextToken))
  add(query_603250, "maxResults", newJInt(maxResults))
  add(query_603250, "nextToken", newJString(nextToken))
  add(query_603250, "MaxResults", newJString(MaxResults))
  result = call_603248.call(path_603249, query_603250, nil, nil, nil)

var getUpgradeHistory* = Call_GetUpgradeHistory_603232(name: "getUpgradeHistory",
    meth: HttpMethod.HttpGet, host: "es.amazonaws.com",
    route: "/2015-01-01/es/upgradeDomain/{DomainName}/history",
    validator: validate_GetUpgradeHistory_603233, base: "/",
    url: url_GetUpgradeHistory_603234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpgradeStatus_603251 = ref object of OpenApiRestCall_602433
proc url_GetUpgradeStatus_603253(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/upgradeDomain/"),
               (kind: VariableSegment, value: "DomainName"),
               (kind: ConstantSegment, value: "/status")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetUpgradeStatus_603252(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieves the latest status of the last upgrade or upgrade eligibility check that was performed on the domain.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DomainName: JString (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DomainName` field"
  var valid_603254 = path.getOrDefault("DomainName")
  valid_603254 = validateParameter(valid_603254, JString, required = true,
                                 default = nil)
  if valid_603254 != nil:
    section.add "DomainName", valid_603254
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
  var valid_603255 = header.getOrDefault("X-Amz-Date")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Date", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Security-Token")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Security-Token", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Content-Sha256", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Algorithm")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Algorithm", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Signature")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Signature", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-SignedHeaders", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-Credential")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Credential", valid_603261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603262: Call_GetUpgradeStatus_603251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the latest status of the last upgrade or upgrade eligibility check that was performed on the domain.
  ## 
  let valid = call_603262.validator(path, query, header, formData, body)
  let scheme = call_603262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603262.url(scheme.get, call_603262.host, call_603262.base,
                         call_603262.route, valid.getOrDefault("path"))
  result = hook(call_603262, url, valid)

proc call*(call_603263: Call_GetUpgradeStatus_603251; DomainName: string): Recallable =
  ## getUpgradeStatus
  ## Retrieves the latest status of the last upgrade or upgrade eligibility check that was performed on the domain.
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var path_603264 = newJObject()
  add(path_603264, "DomainName", newJString(DomainName))
  result = call_603263.call(path_603264, nil, nil, nil, nil)

var getUpgradeStatus* = Call_GetUpgradeStatus_603251(name: "getUpgradeStatus",
    meth: HttpMethod.HttpGet, host: "es.amazonaws.com",
    route: "/2015-01-01/es/upgradeDomain/{DomainName}/status",
    validator: validate_GetUpgradeStatus_603252, base: "/",
    url: url_GetUpgradeStatus_603253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomainNames_603265 = ref object of OpenApiRestCall_602433
proc url_ListDomainNames_603267(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDomainNames_603266(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns the name of all Elasticsearch domains owned by the current user's account. 
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
  var valid_603268 = header.getOrDefault("X-Amz-Date")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Date", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-Security-Token")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-Security-Token", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Content-Sha256", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Algorithm")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Algorithm", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-Signature")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Signature", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-SignedHeaders", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Credential")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Credential", valid_603274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603275: Call_ListDomainNames_603265; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the name of all Elasticsearch domains owned by the current user's account. 
  ## 
  let valid = call_603275.validator(path, query, header, formData, body)
  let scheme = call_603275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603275.url(scheme.get, call_603275.host, call_603275.base,
                         call_603275.route, valid.getOrDefault("path"))
  result = hook(call_603275, url, valid)

proc call*(call_603276: Call_ListDomainNames_603265): Recallable =
  ## listDomainNames
  ## Returns the name of all Elasticsearch domains owned by the current user's account. 
  result = call_603276.call(nil, nil, nil, nil, nil)

var listDomainNames* = Call_ListDomainNames_603265(name: "listDomainNames",
    meth: HttpMethod.HttpGet, host: "es.amazonaws.com", route: "/2015-01-01/domain",
    validator: validate_ListDomainNames_603266, base: "/", url: url_ListDomainNames_603267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListElasticsearchInstanceTypes_603277 = ref object of OpenApiRestCall_602433
proc url_ListElasticsearchInstanceTypes_603279(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ElasticsearchVersion" in path,
        "`ElasticsearchVersion` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/instanceTypes/"),
               (kind: VariableSegment, value: "ElasticsearchVersion")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListElasticsearchInstanceTypes_603278(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all Elasticsearch instance types that are supported for given ElasticsearchVersion
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ElasticsearchVersion: JString (required)
  ##                       : Version of Elasticsearch for which list of supported elasticsearch instance types are needed. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ElasticsearchVersion` field"
  var valid_603280 = path.getOrDefault("ElasticsearchVersion")
  valid_603280 = validateParameter(valid_603280, JString, required = true,
                                 default = nil)
  if valid_603280 != nil:
    section.add "ElasticsearchVersion", valid_603280
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             :  Set this value to limit the number of results returned. 
  ##   nextToken: JString
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   domainName: JString
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603281 = query.getOrDefault("NextToken")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "NextToken", valid_603281
  var valid_603282 = query.getOrDefault("maxResults")
  valid_603282 = validateParameter(valid_603282, JInt, required = false, default = nil)
  if valid_603282 != nil:
    section.add "maxResults", valid_603282
  var valid_603283 = query.getOrDefault("nextToken")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "nextToken", valid_603283
  var valid_603284 = query.getOrDefault("domainName")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "domainName", valid_603284
  var valid_603285 = query.getOrDefault("MaxResults")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "MaxResults", valid_603285
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
  var valid_603286 = header.getOrDefault("X-Amz-Date")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Date", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-Security-Token")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Security-Token", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Content-Sha256", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Algorithm")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Algorithm", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Signature")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Signature", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-SignedHeaders", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Credential")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Credential", valid_603292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603293: Call_ListElasticsearchInstanceTypes_603277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all Elasticsearch instance types that are supported for given ElasticsearchVersion
  ## 
  let valid = call_603293.validator(path, query, header, formData, body)
  let scheme = call_603293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603293.url(scheme.get, call_603293.host, call_603293.base,
                         call_603293.route, valid.getOrDefault("path"))
  result = hook(call_603293, url, valid)

proc call*(call_603294: Call_ListElasticsearchInstanceTypes_603277;
          ElasticsearchVersion: string; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; domainName: string = ""; MaxResults: string = ""): Recallable =
  ## listElasticsearchInstanceTypes
  ## List all Elasticsearch instance types that are supported for given ElasticsearchVersion
  ##   ElasticsearchVersion: string (required)
  ##                       : Version of Elasticsearch for which list of supported elasticsearch instance types are needed. 
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             :  Set this value to limit the number of results returned. 
  ##   nextToken: string
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   domainName: string
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   MaxResults: string
  ##             : Pagination limit
  var path_603295 = newJObject()
  var query_603296 = newJObject()
  add(path_603295, "ElasticsearchVersion", newJString(ElasticsearchVersion))
  add(query_603296, "NextToken", newJString(NextToken))
  add(query_603296, "maxResults", newJInt(maxResults))
  add(query_603296, "nextToken", newJString(nextToken))
  add(query_603296, "domainName", newJString(domainName))
  add(query_603296, "MaxResults", newJString(MaxResults))
  result = call_603294.call(path_603295, query_603296, nil, nil, nil)

var listElasticsearchInstanceTypes* = Call_ListElasticsearchInstanceTypes_603277(
    name: "listElasticsearchInstanceTypes", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com",
    route: "/2015-01-01/es/instanceTypes/{ElasticsearchVersion}",
    validator: validate_ListElasticsearchInstanceTypes_603278, base: "/",
    url: url_ListElasticsearchInstanceTypes_603279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListElasticsearchVersions_603297 = ref object of OpenApiRestCall_602433
proc url_ListElasticsearchVersions_603299(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListElasticsearchVersions_603298(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all supported Elasticsearch versions
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             :  Set this value to limit the number of results returned. 
  ##   nextToken: JString
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603300 = query.getOrDefault("NextToken")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "NextToken", valid_603300
  var valid_603301 = query.getOrDefault("maxResults")
  valid_603301 = validateParameter(valid_603301, JInt, required = false, default = nil)
  if valid_603301 != nil:
    section.add "maxResults", valid_603301
  var valid_603302 = query.getOrDefault("nextToken")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "nextToken", valid_603302
  var valid_603303 = query.getOrDefault("MaxResults")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "MaxResults", valid_603303
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
  var valid_603304 = header.getOrDefault("X-Amz-Date")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Date", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Security-Token")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Security-Token", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-Content-Sha256", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Algorithm")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Algorithm", valid_603307
  var valid_603308 = header.getOrDefault("X-Amz-Signature")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Signature", valid_603308
  var valid_603309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "X-Amz-SignedHeaders", valid_603309
  var valid_603310 = header.getOrDefault("X-Amz-Credential")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Credential", valid_603310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603311: Call_ListElasticsearchVersions_603297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all supported Elasticsearch versions
  ## 
  let valid = call_603311.validator(path, query, header, formData, body)
  let scheme = call_603311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603311.url(scheme.get, call_603311.host, call_603311.base,
                         call_603311.route, valid.getOrDefault("path"))
  result = hook(call_603311, url, valid)

proc call*(call_603312: Call_ListElasticsearchVersions_603297;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listElasticsearchVersions
  ## List all supported Elasticsearch versions
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             :  Set this value to limit the number of results returned. 
  ##   nextToken: string
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603313 = newJObject()
  add(query_603313, "NextToken", newJString(NextToken))
  add(query_603313, "maxResults", newJInt(maxResults))
  add(query_603313, "nextToken", newJString(nextToken))
  add(query_603313, "MaxResults", newJString(MaxResults))
  result = call_603312.call(nil, query_603313, nil, nil, nil)

var listElasticsearchVersions* = Call_ListElasticsearchVersions_603297(
    name: "listElasticsearchVersions", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/versions",
    validator: validate_ListElasticsearchVersions_603298, base: "/",
    url: url_ListElasticsearchVersions_603299,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_603314 = ref object of OpenApiRestCall_602433
proc url_ListTags_603316(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTags_603315(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all tags for the given Elasticsearch domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   arn: JString (required)
  ##      : The Amazon Resource Name (ARN) of the Elasticsearch domain. See <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?Using_Identifiers.html" target="_blank">Identifiers for IAM Entities</a> in <i>Using AWS Identity and Access Management</i> for more information.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `arn` field"
  var valid_603317 = query.getOrDefault("arn")
  valid_603317 = validateParameter(valid_603317, JString, required = true,
                                 default = nil)
  if valid_603317 != nil:
    section.add "arn", valid_603317
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
  var valid_603318 = header.getOrDefault("X-Amz-Date")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Date", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Security-Token")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Security-Token", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Content-Sha256", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-Algorithm")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Algorithm", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Signature")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Signature", valid_603322
  var valid_603323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-SignedHeaders", valid_603323
  var valid_603324 = header.getOrDefault("X-Amz-Credential")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "X-Amz-Credential", valid_603324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603325: Call_ListTags_603314; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tags for the given Elasticsearch domain.
  ## 
  let valid = call_603325.validator(path, query, header, formData, body)
  let scheme = call_603325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603325.url(scheme.get, call_603325.host, call_603325.base,
                         call_603325.route, valid.getOrDefault("path"))
  result = hook(call_603325, url, valid)

proc call*(call_603326: Call_ListTags_603314; arn: string): Recallable =
  ## listTags
  ## Returns all tags for the given Elasticsearch domain.
  ##   arn: string (required)
  ##      : The Amazon Resource Name (ARN) of the Elasticsearch domain. See <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?Using_Identifiers.html" target="_blank">Identifiers for IAM Entities</a> in <i>Using AWS Identity and Access Management</i> for more information.
  var query_603327 = newJObject()
  add(query_603327, "arn", newJString(arn))
  result = call_603326.call(nil, query_603327, nil, nil, nil)

var listTags* = Call_ListTags_603314(name: "listTags", meth: HttpMethod.HttpGet,
                                  host: "es.amazonaws.com",
                                  route: "/2015-01-01/tags/#arn",
                                  validator: validate_ListTags_603315, base: "/",
                                  url: url_ListTags_603316,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseReservedElasticsearchInstanceOffering_603328 = ref object of OpenApiRestCall_602433
proc url_PurchaseReservedElasticsearchInstanceOffering_603330(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PurchaseReservedElasticsearchInstanceOffering_603329(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Allows you to purchase reserved Elasticsearch instances.
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
  var valid_603331 = header.getOrDefault("X-Amz-Date")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Date", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-Security-Token")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Security-Token", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Content-Sha256", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Algorithm")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Algorithm", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Signature")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Signature", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-SignedHeaders", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Credential")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Credential", valid_603337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603339: Call_PurchaseReservedElasticsearchInstanceOffering_603328;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Allows you to purchase reserved Elasticsearch instances.
  ## 
  let valid = call_603339.validator(path, query, header, formData, body)
  let scheme = call_603339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603339.url(scheme.get, call_603339.host, call_603339.base,
                         call_603339.route, valid.getOrDefault("path"))
  result = hook(call_603339, url, valid)

proc call*(call_603340: Call_PurchaseReservedElasticsearchInstanceOffering_603328;
          body: JsonNode): Recallable =
  ## purchaseReservedElasticsearchInstanceOffering
  ## Allows you to purchase reserved Elasticsearch instances.
  ##   body: JObject (required)
  var body_603341 = newJObject()
  if body != nil:
    body_603341 = body
  result = call_603340.call(nil, nil, nil, nil, body_603341)

var purchaseReservedElasticsearchInstanceOffering* = Call_PurchaseReservedElasticsearchInstanceOffering_603328(
    name: "purchaseReservedElasticsearchInstanceOffering",
    meth: HttpMethod.HttpPost, host: "es.amazonaws.com",
    route: "/2015-01-01/es/purchaseReservedInstanceOffering",
    validator: validate_PurchaseReservedElasticsearchInstanceOffering_603329,
    base: "/", url: url_PurchaseReservedElasticsearchInstanceOffering_603330,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTags_603342 = ref object of OpenApiRestCall_602433
proc url_RemoveTags_603344(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RemoveTags_603343(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the specified set of tags from the specified Elasticsearch domain.
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
  var valid_603345 = header.getOrDefault("X-Amz-Date")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Date", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Security-Token")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Security-Token", valid_603346
  var valid_603347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-Content-Sha256", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Algorithm")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Algorithm", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Signature")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Signature", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-SignedHeaders", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-Credential")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-Credential", valid_603351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603353: Call_RemoveTags_603342; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified set of tags from the specified Elasticsearch domain.
  ## 
  let valid = call_603353.validator(path, query, header, formData, body)
  let scheme = call_603353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603353.url(scheme.get, call_603353.host, call_603353.base,
                         call_603353.route, valid.getOrDefault("path"))
  result = hook(call_603353, url, valid)

proc call*(call_603354: Call_RemoveTags_603342; body: JsonNode): Recallable =
  ## removeTags
  ## Removes the specified set of tags from the specified Elasticsearch domain.
  ##   body: JObject (required)
  var body_603355 = newJObject()
  if body != nil:
    body_603355 = body
  result = call_603354.call(nil, nil, nil, nil, body_603355)

var removeTags* = Call_RemoveTags_603342(name: "removeTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "es.amazonaws.com",
                                      route: "/2015-01-01/tags-removal",
                                      validator: validate_RemoveTags_603343,
                                      base: "/", url: url_RemoveTags_603344,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartElasticsearchServiceSoftwareUpdate_603356 = ref object of OpenApiRestCall_602433
proc url_StartElasticsearchServiceSoftwareUpdate_603358(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartElasticsearchServiceSoftwareUpdate_603357(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Schedules a service software update for an Amazon ES domain.
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
  var valid_603359 = header.getOrDefault("X-Amz-Date")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Date", valid_603359
  var valid_603360 = header.getOrDefault("X-Amz-Security-Token")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Security-Token", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Content-Sha256", valid_603361
  var valid_603362 = header.getOrDefault("X-Amz-Algorithm")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-Algorithm", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Signature")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Signature", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-SignedHeaders", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Credential")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Credential", valid_603365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603367: Call_StartElasticsearchServiceSoftwareUpdate_603356;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Schedules a service software update for an Amazon ES domain.
  ## 
  let valid = call_603367.validator(path, query, header, formData, body)
  let scheme = call_603367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603367.url(scheme.get, call_603367.host, call_603367.base,
                         call_603367.route, valid.getOrDefault("path"))
  result = hook(call_603367, url, valid)

proc call*(call_603368: Call_StartElasticsearchServiceSoftwareUpdate_603356;
          body: JsonNode): Recallable =
  ## startElasticsearchServiceSoftwareUpdate
  ## Schedules a service software update for an Amazon ES domain.
  ##   body: JObject (required)
  var body_603369 = newJObject()
  if body != nil:
    body_603369 = body
  result = call_603368.call(nil, nil, nil, nil, body_603369)

var startElasticsearchServiceSoftwareUpdate* = Call_StartElasticsearchServiceSoftwareUpdate_603356(
    name: "startElasticsearchServiceSoftwareUpdate", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/serviceSoftwareUpdate/start",
    validator: validate_StartElasticsearchServiceSoftwareUpdate_603357, base: "/",
    url: url_StartElasticsearchServiceSoftwareUpdate_603358,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradeElasticsearchDomain_603370 = ref object of OpenApiRestCall_602433
proc url_UpgradeElasticsearchDomain_603372(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpgradeElasticsearchDomain_603371(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows you to either upgrade your domain or perform an Upgrade eligibility check to a compatible Elasticsearch version.
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
  var valid_603373 = header.getOrDefault("X-Amz-Date")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Date", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-Security-Token")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-Security-Token", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Content-Sha256", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Algorithm")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Algorithm", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-Signature")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Signature", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-SignedHeaders", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Credential")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Credential", valid_603379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603381: Call_UpgradeElasticsearchDomain_603370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows you to either upgrade your domain or perform an Upgrade eligibility check to a compatible Elasticsearch version.
  ## 
  let valid = call_603381.validator(path, query, header, formData, body)
  let scheme = call_603381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603381.url(scheme.get, call_603381.host, call_603381.base,
                         call_603381.route, valid.getOrDefault("path"))
  result = hook(call_603381, url, valid)

proc call*(call_603382: Call_UpgradeElasticsearchDomain_603370; body: JsonNode): Recallable =
  ## upgradeElasticsearchDomain
  ## Allows you to either upgrade your domain or perform an Upgrade eligibility check to a compatible Elasticsearch version.
  ##   body: JObject (required)
  var body_603383 = newJObject()
  if body != nil:
    body_603383 = body
  result = call_603382.call(nil, nil, nil, nil, body_603383)

var upgradeElasticsearchDomain* = Call_UpgradeElasticsearchDomain_603370(
    name: "upgradeElasticsearchDomain", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/upgradeDomain",
    validator: validate_UpgradeElasticsearchDomain_603371, base: "/",
    url: url_UpgradeElasticsearchDomain_603372,
    schemes: {Scheme.Https, Scheme.Http})
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

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
