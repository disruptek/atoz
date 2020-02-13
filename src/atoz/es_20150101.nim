
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Elasticsearch Service
## version: 2015-01-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Elasticsearch Configuration Service</fullname> <p>Use the Amazon Elasticsearch Configuration API to create, configure, and manage Elasticsearch domains.</p> <p>For sample code that uses the Configuration API, see the <a href="https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-configuration-samples.html">Amazon Elasticsearch Service Developer Guide</a>. The guide also contains <a href="https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-request-signing.html">sample code for sending signed HTTP requests to the Elasticsearch APIs</a>.</p> <p>The endpoint for configuration service requests is region-specific: es.<i>region</i>.amazonaws.com. For example, es.us-east-1.amazonaws.com. For a current list of supported regions and endpoints, see <a href="http://docs.aws.amazon.com/general/latest/gr/rande.html#elasticsearch-service-regions" target="_blank">Regions and Endpoints</a>.</p>
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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddTags_610996 = ref object of OpenApiRestCall_610658
proc url_AddTags_610998(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddTags_610997(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611110 = header.getOrDefault("X-Amz-Signature")
  valid_611110 = validateParameter(valid_611110, JString, required = false,
                                 default = nil)
  if valid_611110 != nil:
    section.add "X-Amz-Signature", valid_611110
  var valid_611111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611111 = validateParameter(valid_611111, JString, required = false,
                                 default = nil)
  if valid_611111 != nil:
    section.add "X-Amz-Content-Sha256", valid_611111
  var valid_611112 = header.getOrDefault("X-Amz-Date")
  valid_611112 = validateParameter(valid_611112, JString, required = false,
                                 default = nil)
  if valid_611112 != nil:
    section.add "X-Amz-Date", valid_611112
  var valid_611113 = header.getOrDefault("X-Amz-Credential")
  valid_611113 = validateParameter(valid_611113, JString, required = false,
                                 default = nil)
  if valid_611113 != nil:
    section.add "X-Amz-Credential", valid_611113
  var valid_611114 = header.getOrDefault("X-Amz-Security-Token")
  valid_611114 = validateParameter(valid_611114, JString, required = false,
                                 default = nil)
  if valid_611114 != nil:
    section.add "X-Amz-Security-Token", valid_611114
  var valid_611115 = header.getOrDefault("X-Amz-Algorithm")
  valid_611115 = validateParameter(valid_611115, JString, required = false,
                                 default = nil)
  if valid_611115 != nil:
    section.add "X-Amz-Algorithm", valid_611115
  var valid_611116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611116 = validateParameter(valid_611116, JString, required = false,
                                 default = nil)
  if valid_611116 != nil:
    section.add "X-Amz-SignedHeaders", valid_611116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611140: Call_AddTags_610996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches tags to an existing Elasticsearch domain. Tags are a set of case-sensitive key value pairs. An Elasticsearch domain may have up to 10 tags. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-managedomains.html#es-managedomains-awsresorcetagging" target="_blank"> Tagging Amazon Elasticsearch Service Domains for more information.</a>
  ## 
  let valid = call_611140.validator(path, query, header, formData, body)
  let scheme = call_611140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611140.url(scheme.get, call_611140.host, call_611140.base,
                         call_611140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611140, url, valid)

proc call*(call_611211: Call_AddTags_610996; body: JsonNode): Recallable =
  ## addTags
  ## Attaches tags to an existing Elasticsearch domain. Tags are a set of case-sensitive key value pairs. An Elasticsearch domain may have up to 10 tags. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-managedomains.html#es-managedomains-awsresorcetagging" target="_blank"> Tagging Amazon Elasticsearch Service Domains for more information.</a>
  ##   body: JObject (required)
  var body_611212 = newJObject()
  if body != nil:
    body_611212 = body
  result = call_611211.call(nil, nil, nil, nil, body_611212)

var addTags* = Call_AddTags_610996(name: "addTags", meth: HttpMethod.HttpPost,
                                host: "es.amazonaws.com",
                                route: "/2015-01-01/tags",
                                validator: validate_AddTags_610997, base: "/",
                                url: url_AddTags_610998,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelElasticsearchServiceSoftwareUpdate_611251 = ref object of OpenApiRestCall_610658
proc url_CancelElasticsearchServiceSoftwareUpdate_611253(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelElasticsearchServiceSoftwareUpdate_611252(path: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611254 = header.getOrDefault("X-Amz-Signature")
  valid_611254 = validateParameter(valid_611254, JString, required = false,
                                 default = nil)
  if valid_611254 != nil:
    section.add "X-Amz-Signature", valid_611254
  var valid_611255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611255 = validateParameter(valid_611255, JString, required = false,
                                 default = nil)
  if valid_611255 != nil:
    section.add "X-Amz-Content-Sha256", valid_611255
  var valid_611256 = header.getOrDefault("X-Amz-Date")
  valid_611256 = validateParameter(valid_611256, JString, required = false,
                                 default = nil)
  if valid_611256 != nil:
    section.add "X-Amz-Date", valid_611256
  var valid_611257 = header.getOrDefault("X-Amz-Credential")
  valid_611257 = validateParameter(valid_611257, JString, required = false,
                                 default = nil)
  if valid_611257 != nil:
    section.add "X-Amz-Credential", valid_611257
  var valid_611258 = header.getOrDefault("X-Amz-Security-Token")
  valid_611258 = validateParameter(valid_611258, JString, required = false,
                                 default = nil)
  if valid_611258 != nil:
    section.add "X-Amz-Security-Token", valid_611258
  var valid_611259 = header.getOrDefault("X-Amz-Algorithm")
  valid_611259 = validateParameter(valid_611259, JString, required = false,
                                 default = nil)
  if valid_611259 != nil:
    section.add "X-Amz-Algorithm", valid_611259
  var valid_611260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611260 = validateParameter(valid_611260, JString, required = false,
                                 default = nil)
  if valid_611260 != nil:
    section.add "X-Amz-SignedHeaders", valid_611260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611262: Call_CancelElasticsearchServiceSoftwareUpdate_611251;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Cancels a scheduled service software update for an Amazon ES domain. You can only perform this operation before the <code>AutomatedUpdateDate</code> and when the <code>UpdateStatus</code> is in the <code>PENDING_UPDATE</code> state.
  ## 
  let valid = call_611262.validator(path, query, header, formData, body)
  let scheme = call_611262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611262.url(scheme.get, call_611262.host, call_611262.base,
                         call_611262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611262, url, valid)

proc call*(call_611263: Call_CancelElasticsearchServiceSoftwareUpdate_611251;
          body: JsonNode): Recallable =
  ## cancelElasticsearchServiceSoftwareUpdate
  ## Cancels a scheduled service software update for an Amazon ES domain. You can only perform this operation before the <code>AutomatedUpdateDate</code> and when the <code>UpdateStatus</code> is in the <code>PENDING_UPDATE</code> state.
  ##   body: JObject (required)
  var body_611264 = newJObject()
  if body != nil:
    body_611264 = body
  result = call_611263.call(nil, nil, nil, nil, body_611264)

var cancelElasticsearchServiceSoftwareUpdate* = Call_CancelElasticsearchServiceSoftwareUpdate_611251(
    name: "cancelElasticsearchServiceSoftwareUpdate", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com",
    route: "/2015-01-01/es/serviceSoftwareUpdate/cancel",
    validator: validate_CancelElasticsearchServiceSoftwareUpdate_611252,
    base: "/", url: url_CancelElasticsearchServiceSoftwareUpdate_611253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateElasticsearchDomain_611265 = ref object of OpenApiRestCall_610658
proc url_CreateElasticsearchDomain_611267(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateElasticsearchDomain_611266(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611268 = header.getOrDefault("X-Amz-Signature")
  valid_611268 = validateParameter(valid_611268, JString, required = false,
                                 default = nil)
  if valid_611268 != nil:
    section.add "X-Amz-Signature", valid_611268
  var valid_611269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611269 = validateParameter(valid_611269, JString, required = false,
                                 default = nil)
  if valid_611269 != nil:
    section.add "X-Amz-Content-Sha256", valid_611269
  var valid_611270 = header.getOrDefault("X-Amz-Date")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Date", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Credential")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Credential", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Security-Token")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Security-Token", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Algorithm")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Algorithm", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-SignedHeaders", valid_611274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611276: Call_CreateElasticsearchDomain_611265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Elasticsearch domain. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomains" target="_blank">Creating Elasticsearch Domains</a> in the <i>Amazon Elasticsearch Service Developer Guide</i>.
  ## 
  let valid = call_611276.validator(path, query, header, formData, body)
  let scheme = call_611276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611276.url(scheme.get, call_611276.host, call_611276.base,
                         call_611276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611276, url, valid)

proc call*(call_611277: Call_CreateElasticsearchDomain_611265; body: JsonNode): Recallable =
  ## createElasticsearchDomain
  ## Creates a new Elasticsearch domain. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomains" target="_blank">Creating Elasticsearch Domains</a> in the <i>Amazon Elasticsearch Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_611278 = newJObject()
  if body != nil:
    body_611278 = body
  result = call_611277.call(nil, nil, nil, nil, body_611278)

var createElasticsearchDomain* = Call_CreateElasticsearchDomain_611265(
    name: "createElasticsearchDomain", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain",
    validator: validate_CreateElasticsearchDomain_611266, base: "/",
    url: url_CreateElasticsearchDomain_611267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchDomain_611279 = ref object of OpenApiRestCall_610658
proc url_DescribeElasticsearchDomain_611281(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/domain/"),
               (kind: VariableSegment, value: "DomainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeElasticsearchDomain_611280(path: JsonNode; query: JsonNode;
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
  var valid_611296 = path.getOrDefault("DomainName")
  valid_611296 = validateParameter(valid_611296, JString, required = true,
                                 default = nil)
  if valid_611296 != nil:
    section.add "DomainName", valid_611296
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
  var valid_611297 = header.getOrDefault("X-Amz-Signature")
  valid_611297 = validateParameter(valid_611297, JString, required = false,
                                 default = nil)
  if valid_611297 != nil:
    section.add "X-Amz-Signature", valid_611297
  var valid_611298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611298 = validateParameter(valid_611298, JString, required = false,
                                 default = nil)
  if valid_611298 != nil:
    section.add "X-Amz-Content-Sha256", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Date")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Date", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Credential")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Credential", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Security-Token")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Security-Token", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-Algorithm")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Algorithm", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-SignedHeaders", valid_611303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611304: Call_DescribeElasticsearchDomain_611279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns domain configuration information about the specified Elasticsearch domain, including the domain ID, domain endpoint, and domain ARN.
  ## 
  let valid = call_611304.validator(path, query, header, formData, body)
  let scheme = call_611304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611304.url(scheme.get, call_611304.host, call_611304.base,
                         call_611304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611304, url, valid)

proc call*(call_611305: Call_DescribeElasticsearchDomain_611279; DomainName: string): Recallable =
  ## describeElasticsearchDomain
  ## Returns domain configuration information about the specified Elasticsearch domain, including the domain ID, domain endpoint, and domain ARN.
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var path_611306 = newJObject()
  add(path_611306, "DomainName", newJString(DomainName))
  result = call_611305.call(path_611306, nil, nil, nil, nil)

var describeElasticsearchDomain* = Call_DescribeElasticsearchDomain_611279(
    name: "describeElasticsearchDomain", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain/{DomainName}",
    validator: validate_DescribeElasticsearchDomain_611280, base: "/",
    url: url_DescribeElasticsearchDomain_611281,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteElasticsearchDomain_611308 = ref object of OpenApiRestCall_610658
proc url_DeleteElasticsearchDomain_611310(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/domain/"),
               (kind: VariableSegment, value: "DomainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteElasticsearchDomain_611309(path: JsonNode; query: JsonNode;
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
  var valid_611311 = path.getOrDefault("DomainName")
  valid_611311 = validateParameter(valid_611311, JString, required = true,
                                 default = nil)
  if valid_611311 != nil:
    section.add "DomainName", valid_611311
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
  var valid_611312 = header.getOrDefault("X-Amz-Signature")
  valid_611312 = validateParameter(valid_611312, JString, required = false,
                                 default = nil)
  if valid_611312 != nil:
    section.add "X-Amz-Signature", valid_611312
  var valid_611313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "X-Amz-Content-Sha256", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Date")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Date", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Credential")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Credential", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Security-Token")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Security-Token", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Algorithm")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Algorithm", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-SignedHeaders", valid_611318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611319: Call_DeleteElasticsearchDomain_611308; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes the specified Elasticsearch domain and all of its data. Once a domain is deleted, it cannot be recovered.
  ## 
  let valid = call_611319.validator(path, query, header, formData, body)
  let scheme = call_611319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611319.url(scheme.get, call_611319.host, call_611319.base,
                         call_611319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611319, url, valid)

proc call*(call_611320: Call_DeleteElasticsearchDomain_611308; DomainName: string): Recallable =
  ## deleteElasticsearchDomain
  ## Permanently deletes the specified Elasticsearch domain and all of its data. Once a domain is deleted, it cannot be recovered.
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var path_611321 = newJObject()
  add(path_611321, "DomainName", newJString(DomainName))
  result = call_611320.call(path_611321, nil, nil, nil, nil)

var deleteElasticsearchDomain* = Call_DeleteElasticsearchDomain_611308(
    name: "deleteElasticsearchDomain", meth: HttpMethod.HttpDelete,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain/{DomainName}",
    validator: validate_DeleteElasticsearchDomain_611309, base: "/",
    url: url_DeleteElasticsearchDomain_611310,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteElasticsearchServiceRole_611322 = ref object of OpenApiRestCall_610658
proc url_DeleteElasticsearchServiceRole_611324(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteElasticsearchServiceRole_611323(path: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611325 = header.getOrDefault("X-Amz-Signature")
  valid_611325 = validateParameter(valid_611325, JString, required = false,
                                 default = nil)
  if valid_611325 != nil:
    section.add "X-Amz-Signature", valid_611325
  var valid_611326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611326 = validateParameter(valid_611326, JString, required = false,
                                 default = nil)
  if valid_611326 != nil:
    section.add "X-Amz-Content-Sha256", valid_611326
  var valid_611327 = header.getOrDefault("X-Amz-Date")
  valid_611327 = validateParameter(valid_611327, JString, required = false,
                                 default = nil)
  if valid_611327 != nil:
    section.add "X-Amz-Date", valid_611327
  var valid_611328 = header.getOrDefault("X-Amz-Credential")
  valid_611328 = validateParameter(valid_611328, JString, required = false,
                                 default = nil)
  if valid_611328 != nil:
    section.add "X-Amz-Credential", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-Security-Token")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Security-Token", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-Algorithm")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Algorithm", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-SignedHeaders", valid_611331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611332: Call_DeleteElasticsearchServiceRole_611322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the service-linked role that Elasticsearch Service uses to manage and maintain VPC domains. Role deletion will fail if any existing VPC domains use the role. You must delete any such Elasticsearch domains before deleting the role. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html#es-enabling-slr" target="_blank">Deleting Elasticsearch Service Role</a> in <i>VPC Endpoints for Amazon Elasticsearch Service Domains</i>.
  ## 
  let valid = call_611332.validator(path, query, header, formData, body)
  let scheme = call_611332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611332.url(scheme.get, call_611332.host, call_611332.base,
                         call_611332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611332, url, valid)

proc call*(call_611333: Call_DeleteElasticsearchServiceRole_611322): Recallable =
  ## deleteElasticsearchServiceRole
  ## Deletes the service-linked role that Elasticsearch Service uses to manage and maintain VPC domains. Role deletion will fail if any existing VPC domains use the role. You must delete any such Elasticsearch domains before deleting the role. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html#es-enabling-slr" target="_blank">Deleting Elasticsearch Service Role</a> in <i>VPC Endpoints for Amazon Elasticsearch Service Domains</i>.
  result = call_611333.call(nil, nil, nil, nil, nil)

var deleteElasticsearchServiceRole* = Call_DeleteElasticsearchServiceRole_611322(
    name: "deleteElasticsearchServiceRole", meth: HttpMethod.HttpDelete,
    host: "es.amazonaws.com", route: "/2015-01-01/es/role",
    validator: validate_DeleteElasticsearchServiceRole_611323, base: "/",
    url: url_DeleteElasticsearchServiceRole_611324,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateElasticsearchDomainConfig_611348 = ref object of OpenApiRestCall_610658
proc url_UpdateElasticsearchDomainConfig_611350(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/domain/"),
               (kind: VariableSegment, value: "DomainName"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateElasticsearchDomainConfig_611349(path: JsonNode;
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
  var valid_611351 = path.getOrDefault("DomainName")
  valid_611351 = validateParameter(valid_611351, JString, required = true,
                                 default = nil)
  if valid_611351 != nil:
    section.add "DomainName", valid_611351
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
  var valid_611352 = header.getOrDefault("X-Amz-Signature")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-Signature", valid_611352
  var valid_611353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-Content-Sha256", valid_611353
  var valid_611354 = header.getOrDefault("X-Amz-Date")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "X-Amz-Date", valid_611354
  var valid_611355 = header.getOrDefault("X-Amz-Credential")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Credential", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-Security-Token")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-Security-Token", valid_611356
  var valid_611357 = header.getOrDefault("X-Amz-Algorithm")
  valid_611357 = validateParameter(valid_611357, JString, required = false,
                                 default = nil)
  if valid_611357 != nil:
    section.add "X-Amz-Algorithm", valid_611357
  var valid_611358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-SignedHeaders", valid_611358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611360: Call_UpdateElasticsearchDomainConfig_611348;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies the cluster configuration of the specified Elasticsearch domain, setting as setting the instance type and the number of instances. 
  ## 
  let valid = call_611360.validator(path, query, header, formData, body)
  let scheme = call_611360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611360.url(scheme.get, call_611360.host, call_611360.base,
                         call_611360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611360, url, valid)

proc call*(call_611361: Call_UpdateElasticsearchDomainConfig_611348;
          DomainName: string; body: JsonNode): Recallable =
  ## updateElasticsearchDomainConfig
  ## Modifies the cluster configuration of the specified Elasticsearch domain, setting as setting the instance type and the number of instances. 
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   body: JObject (required)
  var path_611362 = newJObject()
  var body_611363 = newJObject()
  add(path_611362, "DomainName", newJString(DomainName))
  if body != nil:
    body_611363 = body
  result = call_611361.call(path_611362, nil, nil, nil, body_611363)

var updateElasticsearchDomainConfig* = Call_UpdateElasticsearchDomainConfig_611348(
    name: "updateElasticsearchDomainConfig", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain/{DomainName}/config",
    validator: validate_UpdateElasticsearchDomainConfig_611349, base: "/",
    url: url_UpdateElasticsearchDomainConfig_611350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchDomainConfig_611334 = ref object of OpenApiRestCall_610658
proc url_DescribeElasticsearchDomainConfig_611336(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/domain/"),
               (kind: VariableSegment, value: "DomainName"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeElasticsearchDomainConfig_611335(path: JsonNode;
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
  var valid_611337 = path.getOrDefault("DomainName")
  valid_611337 = validateParameter(valid_611337, JString, required = true,
                                 default = nil)
  if valid_611337 != nil:
    section.add "DomainName", valid_611337
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
  var valid_611338 = header.getOrDefault("X-Amz-Signature")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "X-Amz-Signature", valid_611338
  var valid_611339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "X-Amz-Content-Sha256", valid_611339
  var valid_611340 = header.getOrDefault("X-Amz-Date")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amz-Date", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-Credential")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-Credential", valid_611341
  var valid_611342 = header.getOrDefault("X-Amz-Security-Token")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "X-Amz-Security-Token", valid_611342
  var valid_611343 = header.getOrDefault("X-Amz-Algorithm")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-Algorithm", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-SignedHeaders", valid_611344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611345: Call_DescribeElasticsearchDomainConfig_611334;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Provides cluster configuration information about the specified Elasticsearch domain, such as the state, creation date, update version, and update date for cluster options.
  ## 
  let valid = call_611345.validator(path, query, header, formData, body)
  let scheme = call_611345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611345.url(scheme.get, call_611345.host, call_611345.base,
                         call_611345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611345, url, valid)

proc call*(call_611346: Call_DescribeElasticsearchDomainConfig_611334;
          DomainName: string): Recallable =
  ## describeElasticsearchDomainConfig
  ## Provides cluster configuration information about the specified Elasticsearch domain, such as the state, creation date, update version, and update date for cluster options.
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var path_611347 = newJObject()
  add(path_611347, "DomainName", newJString(DomainName))
  result = call_611346.call(path_611347, nil, nil, nil, nil)

var describeElasticsearchDomainConfig* = Call_DescribeElasticsearchDomainConfig_611334(
    name: "describeElasticsearchDomainConfig", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain/{DomainName}/config",
    validator: validate_DescribeElasticsearchDomainConfig_611335, base: "/",
    url: url_DescribeElasticsearchDomainConfig_611336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchDomains_611364 = ref object of OpenApiRestCall_610658
proc url_DescribeElasticsearchDomains_611366(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeElasticsearchDomains_611365(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611367 = header.getOrDefault("X-Amz-Signature")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "X-Amz-Signature", valid_611367
  var valid_611368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "X-Amz-Content-Sha256", valid_611368
  var valid_611369 = header.getOrDefault("X-Amz-Date")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "X-Amz-Date", valid_611369
  var valid_611370 = header.getOrDefault("X-Amz-Credential")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-Credential", valid_611370
  var valid_611371 = header.getOrDefault("X-Amz-Security-Token")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-Security-Token", valid_611371
  var valid_611372 = header.getOrDefault("X-Amz-Algorithm")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-Algorithm", valid_611372
  var valid_611373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "X-Amz-SignedHeaders", valid_611373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611375: Call_DescribeElasticsearchDomains_611364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns domain configuration information about the specified Elasticsearch domains, including the domain ID, domain endpoint, and domain ARN.
  ## 
  let valid = call_611375.validator(path, query, header, formData, body)
  let scheme = call_611375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611375.url(scheme.get, call_611375.host, call_611375.base,
                         call_611375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611375, url, valid)

proc call*(call_611376: Call_DescribeElasticsearchDomains_611364; body: JsonNode): Recallable =
  ## describeElasticsearchDomains
  ## Returns domain configuration information about the specified Elasticsearch domains, including the domain ID, domain endpoint, and domain ARN.
  ##   body: JObject (required)
  var body_611377 = newJObject()
  if body != nil:
    body_611377 = body
  result = call_611376.call(nil, nil, nil, nil, body_611377)

var describeElasticsearchDomains* = Call_DescribeElasticsearchDomains_611364(
    name: "describeElasticsearchDomains", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain-info",
    validator: validate_DescribeElasticsearchDomains_611365, base: "/",
    url: url_DescribeElasticsearchDomains_611366,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchInstanceTypeLimits_611378 = ref object of OpenApiRestCall_610658
proc url_DescribeElasticsearchInstanceTypeLimits_611380(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeElasticsearchInstanceTypeLimits_611379(path: JsonNode;
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
  var valid_611394 = path.getOrDefault("InstanceType")
  valid_611394 = validateParameter(valid_611394, JString, required = true, default = newJString(
      "m3.medium.elasticsearch"))
  if valid_611394 != nil:
    section.add "InstanceType", valid_611394
  var valid_611395 = path.getOrDefault("ElasticsearchVersion")
  valid_611395 = validateParameter(valid_611395, JString, required = true,
                                 default = nil)
  if valid_611395 != nil:
    section.add "ElasticsearchVersion", valid_611395
  result.add "path", section
  ## parameters in `query` object:
  ##   domainName: JString
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_611396 = query.getOrDefault("domainName")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "domainName", valid_611396
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
  var valid_611397 = header.getOrDefault("X-Amz-Signature")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "X-Amz-Signature", valid_611397
  var valid_611398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "X-Amz-Content-Sha256", valid_611398
  var valid_611399 = header.getOrDefault("X-Amz-Date")
  valid_611399 = validateParameter(valid_611399, JString, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "X-Amz-Date", valid_611399
  var valid_611400 = header.getOrDefault("X-Amz-Credential")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "X-Amz-Credential", valid_611400
  var valid_611401 = header.getOrDefault("X-Amz-Security-Token")
  valid_611401 = validateParameter(valid_611401, JString, required = false,
                                 default = nil)
  if valid_611401 != nil:
    section.add "X-Amz-Security-Token", valid_611401
  var valid_611402 = header.getOrDefault("X-Amz-Algorithm")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "X-Amz-Algorithm", valid_611402
  var valid_611403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611403 = validateParameter(valid_611403, JString, required = false,
                                 default = nil)
  if valid_611403 != nil:
    section.add "X-Amz-SignedHeaders", valid_611403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611404: Call_DescribeElasticsearchInstanceTypeLimits_611378;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Describe Elasticsearch Limits for a given InstanceType and ElasticsearchVersion. When modifying existing Domain, specify the <code> <a>DomainName</a> </code> to know what Limits are supported for modifying. 
  ## 
  let valid = call_611404.validator(path, query, header, formData, body)
  let scheme = call_611404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611404.url(scheme.get, call_611404.host, call_611404.base,
                         call_611404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611404, url, valid)

proc call*(call_611405: Call_DescribeElasticsearchInstanceTypeLimits_611378;
          ElasticsearchVersion: string;
          InstanceType: string = "m3.medium.elasticsearch"; domainName: string = ""): Recallable =
  ## describeElasticsearchInstanceTypeLimits
  ##  Describe Elasticsearch Limits for a given InstanceType and ElasticsearchVersion. When modifying existing Domain, specify the <code> <a>DomainName</a> </code> to know what Limits are supported for modifying. 
  ##   InstanceType: string (required)
  ##               :  The instance type for an Elasticsearch cluster for which Elasticsearch <code> <a>Limits</a> </code> are needed. 
  ##   domainName: string
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   ElasticsearchVersion: string (required)
  ##                       :  Version of Elasticsearch for which <code> <a>Limits</a> </code> are needed. 
  var path_611406 = newJObject()
  var query_611407 = newJObject()
  add(path_611406, "InstanceType", newJString(InstanceType))
  add(query_611407, "domainName", newJString(domainName))
  add(path_611406, "ElasticsearchVersion", newJString(ElasticsearchVersion))
  result = call_611405.call(path_611406, query_611407, nil, nil, nil)

var describeElasticsearchInstanceTypeLimits* = Call_DescribeElasticsearchInstanceTypeLimits_611378(
    name: "describeElasticsearchInstanceTypeLimits", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/instanceTypeLimits/{ElasticsearchVersion}/{InstanceType}",
    validator: validate_DescribeElasticsearchInstanceTypeLimits_611379, base: "/",
    url: url_DescribeElasticsearchInstanceTypeLimits_611380,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReservedElasticsearchInstanceOfferings_611408 = ref object of OpenApiRestCall_610658
proc url_DescribeReservedElasticsearchInstanceOfferings_611410(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeReservedElasticsearchInstanceOfferings_611409(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Lists available reserved Elasticsearch instance offerings.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   offeringId: JString
  ##             : The offering identifier filter value. Use this parameter to show only the available offering that matches the specified reservation identifier.
  ##   maxResults: JInt
  ##             :  Set this value to limit the number of results returned. 
  section = newJObject()
  var valid_611411 = query.getOrDefault("nextToken")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "nextToken", valid_611411
  var valid_611412 = query.getOrDefault("MaxResults")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "MaxResults", valid_611412
  var valid_611413 = query.getOrDefault("NextToken")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "NextToken", valid_611413
  var valid_611414 = query.getOrDefault("offeringId")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "offeringId", valid_611414
  var valid_611415 = query.getOrDefault("maxResults")
  valid_611415 = validateParameter(valid_611415, JInt, required = false, default = nil)
  if valid_611415 != nil:
    section.add "maxResults", valid_611415
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
  var valid_611416 = header.getOrDefault("X-Amz-Signature")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "X-Amz-Signature", valid_611416
  var valid_611417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611417 = validateParameter(valid_611417, JString, required = false,
                                 default = nil)
  if valid_611417 != nil:
    section.add "X-Amz-Content-Sha256", valid_611417
  var valid_611418 = header.getOrDefault("X-Amz-Date")
  valid_611418 = validateParameter(valid_611418, JString, required = false,
                                 default = nil)
  if valid_611418 != nil:
    section.add "X-Amz-Date", valid_611418
  var valid_611419 = header.getOrDefault("X-Amz-Credential")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-Credential", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-Security-Token")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-Security-Token", valid_611420
  var valid_611421 = header.getOrDefault("X-Amz-Algorithm")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Algorithm", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-SignedHeaders", valid_611422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611423: Call_DescribeReservedElasticsearchInstanceOfferings_611408;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists available reserved Elasticsearch instance offerings.
  ## 
  let valid = call_611423.validator(path, query, header, formData, body)
  let scheme = call_611423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611423.url(scheme.get, call_611423.host, call_611423.base,
                         call_611423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611423, url, valid)

proc call*(call_611424: Call_DescribeReservedElasticsearchInstanceOfferings_611408;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          offeringId: string = ""; maxResults: int = 0): Recallable =
  ## describeReservedElasticsearchInstanceOfferings
  ## Lists available reserved Elasticsearch instance offerings.
  ##   nextToken: string
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   offeringId: string
  ##             : The offering identifier filter value. Use this parameter to show only the available offering that matches the specified reservation identifier.
  ##   maxResults: int
  ##             :  Set this value to limit the number of results returned. 
  var query_611425 = newJObject()
  add(query_611425, "nextToken", newJString(nextToken))
  add(query_611425, "MaxResults", newJString(MaxResults))
  add(query_611425, "NextToken", newJString(NextToken))
  add(query_611425, "offeringId", newJString(offeringId))
  add(query_611425, "maxResults", newJInt(maxResults))
  result = call_611424.call(nil, query_611425, nil, nil, nil)

var describeReservedElasticsearchInstanceOfferings* = Call_DescribeReservedElasticsearchInstanceOfferings_611408(
    name: "describeReservedElasticsearchInstanceOfferings",
    meth: HttpMethod.HttpGet, host: "es.amazonaws.com",
    route: "/2015-01-01/es/reservedInstanceOfferings",
    validator: validate_DescribeReservedElasticsearchInstanceOfferings_611409,
    base: "/", url: url_DescribeReservedElasticsearchInstanceOfferings_611410,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReservedElasticsearchInstances_611426 = ref object of OpenApiRestCall_610658
proc url_DescribeReservedElasticsearchInstances_611428(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeReservedElasticsearchInstances_611427(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about reserved Elasticsearch instances for this account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   reservationId: JString
  ##                : The reserved instance identifier filter value. Use this parameter to show only the reservation that matches the specified reserved Elasticsearch instance ID.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             :  Set this value to limit the number of results returned. 
  section = newJObject()
  var valid_611429 = query.getOrDefault("nextToken")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "nextToken", valid_611429
  var valid_611430 = query.getOrDefault("MaxResults")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "MaxResults", valid_611430
  var valid_611431 = query.getOrDefault("reservationId")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "reservationId", valid_611431
  var valid_611432 = query.getOrDefault("NextToken")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "NextToken", valid_611432
  var valid_611433 = query.getOrDefault("maxResults")
  valid_611433 = validateParameter(valid_611433, JInt, required = false, default = nil)
  if valid_611433 != nil:
    section.add "maxResults", valid_611433
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
  var valid_611434 = header.getOrDefault("X-Amz-Signature")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "X-Amz-Signature", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Content-Sha256", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Date")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Date", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-Credential")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Credential", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-Security-Token")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-Security-Token", valid_611438
  var valid_611439 = header.getOrDefault("X-Amz-Algorithm")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "X-Amz-Algorithm", valid_611439
  var valid_611440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-SignedHeaders", valid_611440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611441: Call_DescribeReservedElasticsearchInstances_611426;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns information about reserved Elasticsearch instances for this account.
  ## 
  let valid = call_611441.validator(path, query, header, formData, body)
  let scheme = call_611441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611441.url(scheme.get, call_611441.host, call_611441.base,
                         call_611441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611441, url, valid)

proc call*(call_611442: Call_DescribeReservedElasticsearchInstances_611426;
          nextToken: string = ""; MaxResults: string = ""; reservationId: string = "";
          NextToken: string = ""; maxResults: int = 0): Recallable =
  ## describeReservedElasticsearchInstances
  ## Returns information about reserved Elasticsearch instances for this account.
  ##   nextToken: string
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   reservationId: string
  ##                : The reserved instance identifier filter value. Use this parameter to show only the reservation that matches the specified reserved Elasticsearch instance ID.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             :  Set this value to limit the number of results returned. 
  var query_611443 = newJObject()
  add(query_611443, "nextToken", newJString(nextToken))
  add(query_611443, "MaxResults", newJString(MaxResults))
  add(query_611443, "reservationId", newJString(reservationId))
  add(query_611443, "NextToken", newJString(NextToken))
  add(query_611443, "maxResults", newJInt(maxResults))
  result = call_611442.call(nil, query_611443, nil, nil, nil)

var describeReservedElasticsearchInstances* = Call_DescribeReservedElasticsearchInstances_611426(
    name: "describeReservedElasticsearchInstances", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/reservedInstances",
    validator: validate_DescribeReservedElasticsearchInstances_611427, base: "/",
    url: url_DescribeReservedElasticsearchInstances_611428,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCompatibleElasticsearchVersions_611444 = ref object of OpenApiRestCall_610658
proc url_GetCompatibleElasticsearchVersions_611446(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCompatibleElasticsearchVersions_611445(path: JsonNode;
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
  var valid_611447 = query.getOrDefault("domainName")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "domainName", valid_611447
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
  var valid_611448 = header.getOrDefault("X-Amz-Signature")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "X-Amz-Signature", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-Content-Sha256", valid_611449
  var valid_611450 = header.getOrDefault("X-Amz-Date")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Date", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-Credential")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Credential", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-Security-Token")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-Security-Token", valid_611452
  var valid_611453 = header.getOrDefault("X-Amz-Algorithm")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "X-Amz-Algorithm", valid_611453
  var valid_611454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-SignedHeaders", valid_611454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611455: Call_GetCompatibleElasticsearchVersions_611444;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Returns a list of upgrade compatible Elastisearch versions. You can optionally pass a <code> <a>DomainName</a> </code> to get all upgrade compatible Elasticsearch versions for that specific domain. 
  ## 
  let valid = call_611455.validator(path, query, header, formData, body)
  let scheme = call_611455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611455.url(scheme.get, call_611455.host, call_611455.base,
                         call_611455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611455, url, valid)

proc call*(call_611456: Call_GetCompatibleElasticsearchVersions_611444;
          domainName: string = ""): Recallable =
  ## getCompatibleElasticsearchVersions
  ##  Returns a list of upgrade compatible Elastisearch versions. You can optionally pass a <code> <a>DomainName</a> </code> to get all upgrade compatible Elasticsearch versions for that specific domain. 
  ##   domainName: string
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var query_611457 = newJObject()
  add(query_611457, "domainName", newJString(domainName))
  result = call_611456.call(nil, query_611457, nil, nil, nil)

var getCompatibleElasticsearchVersions* = Call_GetCompatibleElasticsearchVersions_611444(
    name: "getCompatibleElasticsearchVersions", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/compatibleVersions",
    validator: validate_GetCompatibleElasticsearchVersions_611445, base: "/",
    url: url_GetCompatibleElasticsearchVersions_611446,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpgradeHistory_611458 = ref object of OpenApiRestCall_610658
proc url_GetUpgradeHistory_611460(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/upgradeDomain/"),
               (kind: VariableSegment, value: "DomainName"),
               (kind: ConstantSegment, value: "/history")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetUpgradeHistory_611459(path: JsonNode; query: JsonNode;
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
  var valid_611461 = path.getOrDefault("DomainName")
  valid_611461 = validateParameter(valid_611461, JString, required = true,
                                 default = nil)
  if valid_611461 != nil:
    section.add "DomainName", valid_611461
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             :  Set this value to limit the number of results returned. 
  section = newJObject()
  var valid_611462 = query.getOrDefault("nextToken")
  valid_611462 = validateParameter(valid_611462, JString, required = false,
                                 default = nil)
  if valid_611462 != nil:
    section.add "nextToken", valid_611462
  var valid_611463 = query.getOrDefault("MaxResults")
  valid_611463 = validateParameter(valid_611463, JString, required = false,
                                 default = nil)
  if valid_611463 != nil:
    section.add "MaxResults", valid_611463
  var valid_611464 = query.getOrDefault("NextToken")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "NextToken", valid_611464
  var valid_611465 = query.getOrDefault("maxResults")
  valid_611465 = validateParameter(valid_611465, JInt, required = false, default = nil)
  if valid_611465 != nil:
    section.add "maxResults", valid_611465
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
  var valid_611466 = header.getOrDefault("X-Amz-Signature")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Signature", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Content-Sha256", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-Date")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-Date", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-Credential")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Credential", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-Security-Token")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-Security-Token", valid_611470
  var valid_611471 = header.getOrDefault("X-Amz-Algorithm")
  valid_611471 = validateParameter(valid_611471, JString, required = false,
                                 default = nil)
  if valid_611471 != nil:
    section.add "X-Amz-Algorithm", valid_611471
  var valid_611472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611472 = validateParameter(valid_611472, JString, required = false,
                                 default = nil)
  if valid_611472 != nil:
    section.add "X-Amz-SignedHeaders", valid_611472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611473: Call_GetUpgradeHistory_611458; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the complete history of the last 10 upgrades that were performed on the domain.
  ## 
  let valid = call_611473.validator(path, query, header, formData, body)
  let scheme = call_611473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611473.url(scheme.get, call_611473.host, call_611473.base,
                         call_611473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611473, url, valid)

proc call*(call_611474: Call_GetUpgradeHistory_611458; DomainName: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## getUpgradeHistory
  ## Retrieves the complete history of the last 10 upgrades that were performed on the domain.
  ##   nextToken: string
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   maxResults: int
  ##             :  Set this value to limit the number of results returned. 
  var path_611475 = newJObject()
  var query_611476 = newJObject()
  add(query_611476, "nextToken", newJString(nextToken))
  add(query_611476, "MaxResults", newJString(MaxResults))
  add(query_611476, "NextToken", newJString(NextToken))
  add(path_611475, "DomainName", newJString(DomainName))
  add(query_611476, "maxResults", newJInt(maxResults))
  result = call_611474.call(path_611475, query_611476, nil, nil, nil)

var getUpgradeHistory* = Call_GetUpgradeHistory_611458(name: "getUpgradeHistory",
    meth: HttpMethod.HttpGet, host: "es.amazonaws.com",
    route: "/2015-01-01/es/upgradeDomain/{DomainName}/history",
    validator: validate_GetUpgradeHistory_611459, base: "/",
    url: url_GetUpgradeHistory_611460, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpgradeStatus_611477 = ref object of OpenApiRestCall_610658
proc url_GetUpgradeStatus_611479(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/upgradeDomain/"),
               (kind: VariableSegment, value: "DomainName"),
               (kind: ConstantSegment, value: "/status")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetUpgradeStatus_611478(path: JsonNode; query: JsonNode;
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
  var valid_611480 = path.getOrDefault("DomainName")
  valid_611480 = validateParameter(valid_611480, JString, required = true,
                                 default = nil)
  if valid_611480 != nil:
    section.add "DomainName", valid_611480
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
  var valid_611481 = header.getOrDefault("X-Amz-Signature")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-Signature", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-Content-Sha256", valid_611482
  var valid_611483 = header.getOrDefault("X-Amz-Date")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "X-Amz-Date", valid_611483
  var valid_611484 = header.getOrDefault("X-Amz-Credential")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-Credential", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-Security-Token")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-Security-Token", valid_611485
  var valid_611486 = header.getOrDefault("X-Amz-Algorithm")
  valid_611486 = validateParameter(valid_611486, JString, required = false,
                                 default = nil)
  if valid_611486 != nil:
    section.add "X-Amz-Algorithm", valid_611486
  var valid_611487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611487 = validateParameter(valid_611487, JString, required = false,
                                 default = nil)
  if valid_611487 != nil:
    section.add "X-Amz-SignedHeaders", valid_611487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611488: Call_GetUpgradeStatus_611477; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the latest status of the last upgrade or upgrade eligibility check that was performed on the domain.
  ## 
  let valid = call_611488.validator(path, query, header, formData, body)
  let scheme = call_611488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611488.url(scheme.get, call_611488.host, call_611488.base,
                         call_611488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611488, url, valid)

proc call*(call_611489: Call_GetUpgradeStatus_611477; DomainName: string): Recallable =
  ## getUpgradeStatus
  ## Retrieves the latest status of the last upgrade or upgrade eligibility check that was performed on the domain.
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var path_611490 = newJObject()
  add(path_611490, "DomainName", newJString(DomainName))
  result = call_611489.call(path_611490, nil, nil, nil, nil)

var getUpgradeStatus* = Call_GetUpgradeStatus_611477(name: "getUpgradeStatus",
    meth: HttpMethod.HttpGet, host: "es.amazonaws.com",
    route: "/2015-01-01/es/upgradeDomain/{DomainName}/status",
    validator: validate_GetUpgradeStatus_611478, base: "/",
    url: url_GetUpgradeStatus_611479, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomainNames_611491 = ref object of OpenApiRestCall_610658
proc url_ListDomainNames_611493(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDomainNames_611492(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611494 = header.getOrDefault("X-Amz-Signature")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "X-Amz-Signature", valid_611494
  var valid_611495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-Content-Sha256", valid_611495
  var valid_611496 = header.getOrDefault("X-Amz-Date")
  valid_611496 = validateParameter(valid_611496, JString, required = false,
                                 default = nil)
  if valid_611496 != nil:
    section.add "X-Amz-Date", valid_611496
  var valid_611497 = header.getOrDefault("X-Amz-Credential")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "X-Amz-Credential", valid_611497
  var valid_611498 = header.getOrDefault("X-Amz-Security-Token")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-Security-Token", valid_611498
  var valid_611499 = header.getOrDefault("X-Amz-Algorithm")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-Algorithm", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-SignedHeaders", valid_611500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611501: Call_ListDomainNames_611491; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the name of all Elasticsearch domains owned by the current user's account. 
  ## 
  let valid = call_611501.validator(path, query, header, formData, body)
  let scheme = call_611501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611501.url(scheme.get, call_611501.host, call_611501.base,
                         call_611501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611501, url, valid)

proc call*(call_611502: Call_ListDomainNames_611491): Recallable =
  ## listDomainNames
  ## Returns the name of all Elasticsearch domains owned by the current user's account. 
  result = call_611502.call(nil, nil, nil, nil, nil)

var listDomainNames* = Call_ListDomainNames_611491(name: "listDomainNames",
    meth: HttpMethod.HttpGet, host: "es.amazonaws.com", route: "/2015-01-01/domain",
    validator: validate_ListDomainNames_611492, base: "/", url: url_ListDomainNames_611493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListElasticsearchInstanceTypes_611503 = ref object of OpenApiRestCall_610658
proc url_ListElasticsearchInstanceTypes_611505(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ElasticsearchVersion" in path,
        "`ElasticsearchVersion` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/instanceTypes/"),
               (kind: VariableSegment, value: "ElasticsearchVersion")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListElasticsearchInstanceTypes_611504(path: JsonNode;
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
  var valid_611506 = path.getOrDefault("ElasticsearchVersion")
  valid_611506 = validateParameter(valid_611506, JString, required = true,
                                 default = nil)
  if valid_611506 != nil:
    section.add "ElasticsearchVersion", valid_611506
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   domainName: JString
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             :  Set this value to limit the number of results returned. 
  section = newJObject()
  var valid_611507 = query.getOrDefault("nextToken")
  valid_611507 = validateParameter(valid_611507, JString, required = false,
                                 default = nil)
  if valid_611507 != nil:
    section.add "nextToken", valid_611507
  var valid_611508 = query.getOrDefault("MaxResults")
  valid_611508 = validateParameter(valid_611508, JString, required = false,
                                 default = nil)
  if valid_611508 != nil:
    section.add "MaxResults", valid_611508
  var valid_611509 = query.getOrDefault("domainName")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "domainName", valid_611509
  var valid_611510 = query.getOrDefault("NextToken")
  valid_611510 = validateParameter(valid_611510, JString, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "NextToken", valid_611510
  var valid_611511 = query.getOrDefault("maxResults")
  valid_611511 = validateParameter(valid_611511, JInt, required = false, default = nil)
  if valid_611511 != nil:
    section.add "maxResults", valid_611511
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
  var valid_611512 = header.getOrDefault("X-Amz-Signature")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-Signature", valid_611512
  var valid_611513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-Content-Sha256", valid_611513
  var valid_611514 = header.getOrDefault("X-Amz-Date")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-Date", valid_611514
  var valid_611515 = header.getOrDefault("X-Amz-Credential")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-Credential", valid_611515
  var valid_611516 = header.getOrDefault("X-Amz-Security-Token")
  valid_611516 = validateParameter(valid_611516, JString, required = false,
                                 default = nil)
  if valid_611516 != nil:
    section.add "X-Amz-Security-Token", valid_611516
  var valid_611517 = header.getOrDefault("X-Amz-Algorithm")
  valid_611517 = validateParameter(valid_611517, JString, required = false,
                                 default = nil)
  if valid_611517 != nil:
    section.add "X-Amz-Algorithm", valid_611517
  var valid_611518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611518 = validateParameter(valid_611518, JString, required = false,
                                 default = nil)
  if valid_611518 != nil:
    section.add "X-Amz-SignedHeaders", valid_611518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611519: Call_ListElasticsearchInstanceTypes_611503; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all Elasticsearch instance types that are supported for given ElasticsearchVersion
  ## 
  let valid = call_611519.validator(path, query, header, formData, body)
  let scheme = call_611519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611519.url(scheme.get, call_611519.host, call_611519.base,
                         call_611519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611519, url, valid)

proc call*(call_611520: Call_ListElasticsearchInstanceTypes_611503;
          ElasticsearchVersion: string; nextToken: string = "";
          MaxResults: string = ""; domainName: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listElasticsearchInstanceTypes
  ## List all Elasticsearch instance types that are supported for given ElasticsearchVersion
  ##   nextToken: string
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   domainName: string
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   NextToken: string
  ##            : Pagination token
  ##   ElasticsearchVersion: string (required)
  ##                       : Version of Elasticsearch for which list of supported elasticsearch instance types are needed. 
  ##   maxResults: int
  ##             :  Set this value to limit the number of results returned. 
  var path_611521 = newJObject()
  var query_611522 = newJObject()
  add(query_611522, "nextToken", newJString(nextToken))
  add(query_611522, "MaxResults", newJString(MaxResults))
  add(query_611522, "domainName", newJString(domainName))
  add(query_611522, "NextToken", newJString(NextToken))
  add(path_611521, "ElasticsearchVersion", newJString(ElasticsearchVersion))
  add(query_611522, "maxResults", newJInt(maxResults))
  result = call_611520.call(path_611521, query_611522, nil, nil, nil)

var listElasticsearchInstanceTypes* = Call_ListElasticsearchInstanceTypes_611503(
    name: "listElasticsearchInstanceTypes", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com",
    route: "/2015-01-01/es/instanceTypes/{ElasticsearchVersion}",
    validator: validate_ListElasticsearchInstanceTypes_611504, base: "/",
    url: url_ListElasticsearchInstanceTypes_611505,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListElasticsearchVersions_611523 = ref object of OpenApiRestCall_610658
proc url_ListElasticsearchVersions_611525(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListElasticsearchVersions_611524(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all supported Elasticsearch versions
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             :  Set this value to limit the number of results returned. 
  section = newJObject()
  var valid_611526 = query.getOrDefault("nextToken")
  valid_611526 = validateParameter(valid_611526, JString, required = false,
                                 default = nil)
  if valid_611526 != nil:
    section.add "nextToken", valid_611526
  var valid_611527 = query.getOrDefault("MaxResults")
  valid_611527 = validateParameter(valid_611527, JString, required = false,
                                 default = nil)
  if valid_611527 != nil:
    section.add "MaxResults", valid_611527
  var valid_611528 = query.getOrDefault("NextToken")
  valid_611528 = validateParameter(valid_611528, JString, required = false,
                                 default = nil)
  if valid_611528 != nil:
    section.add "NextToken", valid_611528
  var valid_611529 = query.getOrDefault("maxResults")
  valid_611529 = validateParameter(valid_611529, JInt, required = false, default = nil)
  if valid_611529 != nil:
    section.add "maxResults", valid_611529
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
  var valid_611530 = header.getOrDefault("X-Amz-Signature")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "X-Amz-Signature", valid_611530
  var valid_611531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611531 = validateParameter(valid_611531, JString, required = false,
                                 default = nil)
  if valid_611531 != nil:
    section.add "X-Amz-Content-Sha256", valid_611531
  var valid_611532 = header.getOrDefault("X-Amz-Date")
  valid_611532 = validateParameter(valid_611532, JString, required = false,
                                 default = nil)
  if valid_611532 != nil:
    section.add "X-Amz-Date", valid_611532
  var valid_611533 = header.getOrDefault("X-Amz-Credential")
  valid_611533 = validateParameter(valid_611533, JString, required = false,
                                 default = nil)
  if valid_611533 != nil:
    section.add "X-Amz-Credential", valid_611533
  var valid_611534 = header.getOrDefault("X-Amz-Security-Token")
  valid_611534 = validateParameter(valid_611534, JString, required = false,
                                 default = nil)
  if valid_611534 != nil:
    section.add "X-Amz-Security-Token", valid_611534
  var valid_611535 = header.getOrDefault("X-Amz-Algorithm")
  valid_611535 = validateParameter(valid_611535, JString, required = false,
                                 default = nil)
  if valid_611535 != nil:
    section.add "X-Amz-Algorithm", valid_611535
  var valid_611536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611536 = validateParameter(valid_611536, JString, required = false,
                                 default = nil)
  if valid_611536 != nil:
    section.add "X-Amz-SignedHeaders", valid_611536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611537: Call_ListElasticsearchVersions_611523; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all supported Elasticsearch versions
  ## 
  let valid = call_611537.validator(path, query, header, formData, body)
  let scheme = call_611537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611537.url(scheme.get, call_611537.host, call_611537.base,
                         call_611537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611537, url, valid)

proc call*(call_611538: Call_ListElasticsearchVersions_611523;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listElasticsearchVersions
  ## List all supported Elasticsearch versions
  ##   nextToken: string
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             :  Set this value to limit the number of results returned. 
  var query_611539 = newJObject()
  add(query_611539, "nextToken", newJString(nextToken))
  add(query_611539, "MaxResults", newJString(MaxResults))
  add(query_611539, "NextToken", newJString(NextToken))
  add(query_611539, "maxResults", newJInt(maxResults))
  result = call_611538.call(nil, query_611539, nil, nil, nil)

var listElasticsearchVersions* = Call_ListElasticsearchVersions_611523(
    name: "listElasticsearchVersions", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/versions",
    validator: validate_ListElasticsearchVersions_611524, base: "/",
    url: url_ListElasticsearchVersions_611525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_611540 = ref object of OpenApiRestCall_610658
proc url_ListTags_611542(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTags_611541(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611543 = query.getOrDefault("arn")
  valid_611543 = validateParameter(valid_611543, JString, required = true,
                                 default = nil)
  if valid_611543 != nil:
    section.add "arn", valid_611543
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
  var valid_611544 = header.getOrDefault("X-Amz-Signature")
  valid_611544 = validateParameter(valid_611544, JString, required = false,
                                 default = nil)
  if valid_611544 != nil:
    section.add "X-Amz-Signature", valid_611544
  var valid_611545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "X-Amz-Content-Sha256", valid_611545
  var valid_611546 = header.getOrDefault("X-Amz-Date")
  valid_611546 = validateParameter(valid_611546, JString, required = false,
                                 default = nil)
  if valid_611546 != nil:
    section.add "X-Amz-Date", valid_611546
  var valid_611547 = header.getOrDefault("X-Amz-Credential")
  valid_611547 = validateParameter(valid_611547, JString, required = false,
                                 default = nil)
  if valid_611547 != nil:
    section.add "X-Amz-Credential", valid_611547
  var valid_611548 = header.getOrDefault("X-Amz-Security-Token")
  valid_611548 = validateParameter(valid_611548, JString, required = false,
                                 default = nil)
  if valid_611548 != nil:
    section.add "X-Amz-Security-Token", valid_611548
  var valid_611549 = header.getOrDefault("X-Amz-Algorithm")
  valid_611549 = validateParameter(valid_611549, JString, required = false,
                                 default = nil)
  if valid_611549 != nil:
    section.add "X-Amz-Algorithm", valid_611549
  var valid_611550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611550 = validateParameter(valid_611550, JString, required = false,
                                 default = nil)
  if valid_611550 != nil:
    section.add "X-Amz-SignedHeaders", valid_611550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611551: Call_ListTags_611540; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tags for the given Elasticsearch domain.
  ## 
  let valid = call_611551.validator(path, query, header, formData, body)
  let scheme = call_611551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611551.url(scheme.get, call_611551.host, call_611551.base,
                         call_611551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611551, url, valid)

proc call*(call_611552: Call_ListTags_611540; arn: string): Recallable =
  ## listTags
  ## Returns all tags for the given Elasticsearch domain.
  ##   arn: string (required)
  ##      : The Amazon Resource Name (ARN) of the Elasticsearch domain. See <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?Using_Identifiers.html" target="_blank">Identifiers for IAM Entities</a> in <i>Using AWS Identity and Access Management</i> for more information.
  var query_611553 = newJObject()
  add(query_611553, "arn", newJString(arn))
  result = call_611552.call(nil, query_611553, nil, nil, nil)

var listTags* = Call_ListTags_611540(name: "listTags", meth: HttpMethod.HttpGet,
                                  host: "es.amazonaws.com",
                                  route: "/2015-01-01/tags/#arn",
                                  validator: validate_ListTags_611541, base: "/",
                                  url: url_ListTags_611542,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseReservedElasticsearchInstanceOffering_611554 = ref object of OpenApiRestCall_610658
proc url_PurchaseReservedElasticsearchInstanceOffering_611556(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PurchaseReservedElasticsearchInstanceOffering_611555(
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611557 = header.getOrDefault("X-Amz-Signature")
  valid_611557 = validateParameter(valid_611557, JString, required = false,
                                 default = nil)
  if valid_611557 != nil:
    section.add "X-Amz-Signature", valid_611557
  var valid_611558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611558 = validateParameter(valid_611558, JString, required = false,
                                 default = nil)
  if valid_611558 != nil:
    section.add "X-Amz-Content-Sha256", valid_611558
  var valid_611559 = header.getOrDefault("X-Amz-Date")
  valid_611559 = validateParameter(valid_611559, JString, required = false,
                                 default = nil)
  if valid_611559 != nil:
    section.add "X-Amz-Date", valid_611559
  var valid_611560 = header.getOrDefault("X-Amz-Credential")
  valid_611560 = validateParameter(valid_611560, JString, required = false,
                                 default = nil)
  if valid_611560 != nil:
    section.add "X-Amz-Credential", valid_611560
  var valid_611561 = header.getOrDefault("X-Amz-Security-Token")
  valid_611561 = validateParameter(valid_611561, JString, required = false,
                                 default = nil)
  if valid_611561 != nil:
    section.add "X-Amz-Security-Token", valid_611561
  var valid_611562 = header.getOrDefault("X-Amz-Algorithm")
  valid_611562 = validateParameter(valid_611562, JString, required = false,
                                 default = nil)
  if valid_611562 != nil:
    section.add "X-Amz-Algorithm", valid_611562
  var valid_611563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611563 = validateParameter(valid_611563, JString, required = false,
                                 default = nil)
  if valid_611563 != nil:
    section.add "X-Amz-SignedHeaders", valid_611563
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611565: Call_PurchaseReservedElasticsearchInstanceOffering_611554;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Allows you to purchase reserved Elasticsearch instances.
  ## 
  let valid = call_611565.validator(path, query, header, formData, body)
  let scheme = call_611565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611565.url(scheme.get, call_611565.host, call_611565.base,
                         call_611565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611565, url, valid)

proc call*(call_611566: Call_PurchaseReservedElasticsearchInstanceOffering_611554;
          body: JsonNode): Recallable =
  ## purchaseReservedElasticsearchInstanceOffering
  ## Allows you to purchase reserved Elasticsearch instances.
  ##   body: JObject (required)
  var body_611567 = newJObject()
  if body != nil:
    body_611567 = body
  result = call_611566.call(nil, nil, nil, nil, body_611567)

var purchaseReservedElasticsearchInstanceOffering* = Call_PurchaseReservedElasticsearchInstanceOffering_611554(
    name: "purchaseReservedElasticsearchInstanceOffering",
    meth: HttpMethod.HttpPost, host: "es.amazonaws.com",
    route: "/2015-01-01/es/purchaseReservedInstanceOffering",
    validator: validate_PurchaseReservedElasticsearchInstanceOffering_611555,
    base: "/", url: url_PurchaseReservedElasticsearchInstanceOffering_611556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTags_611568 = ref object of OpenApiRestCall_610658
proc url_RemoveTags_611570(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RemoveTags_611569(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611571 = header.getOrDefault("X-Amz-Signature")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-Signature", valid_611571
  var valid_611572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611572 = validateParameter(valid_611572, JString, required = false,
                                 default = nil)
  if valid_611572 != nil:
    section.add "X-Amz-Content-Sha256", valid_611572
  var valid_611573 = header.getOrDefault("X-Amz-Date")
  valid_611573 = validateParameter(valid_611573, JString, required = false,
                                 default = nil)
  if valid_611573 != nil:
    section.add "X-Amz-Date", valid_611573
  var valid_611574 = header.getOrDefault("X-Amz-Credential")
  valid_611574 = validateParameter(valid_611574, JString, required = false,
                                 default = nil)
  if valid_611574 != nil:
    section.add "X-Amz-Credential", valid_611574
  var valid_611575 = header.getOrDefault("X-Amz-Security-Token")
  valid_611575 = validateParameter(valid_611575, JString, required = false,
                                 default = nil)
  if valid_611575 != nil:
    section.add "X-Amz-Security-Token", valid_611575
  var valid_611576 = header.getOrDefault("X-Amz-Algorithm")
  valid_611576 = validateParameter(valid_611576, JString, required = false,
                                 default = nil)
  if valid_611576 != nil:
    section.add "X-Amz-Algorithm", valid_611576
  var valid_611577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611577 = validateParameter(valid_611577, JString, required = false,
                                 default = nil)
  if valid_611577 != nil:
    section.add "X-Amz-SignedHeaders", valid_611577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611579: Call_RemoveTags_611568; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified set of tags from the specified Elasticsearch domain.
  ## 
  let valid = call_611579.validator(path, query, header, formData, body)
  let scheme = call_611579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611579.url(scheme.get, call_611579.host, call_611579.base,
                         call_611579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611579, url, valid)

proc call*(call_611580: Call_RemoveTags_611568; body: JsonNode): Recallable =
  ## removeTags
  ## Removes the specified set of tags from the specified Elasticsearch domain.
  ##   body: JObject (required)
  var body_611581 = newJObject()
  if body != nil:
    body_611581 = body
  result = call_611580.call(nil, nil, nil, nil, body_611581)

var removeTags* = Call_RemoveTags_611568(name: "removeTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "es.amazonaws.com",
                                      route: "/2015-01-01/tags-removal",
                                      validator: validate_RemoveTags_611569,
                                      base: "/", url: url_RemoveTags_611570,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartElasticsearchServiceSoftwareUpdate_611582 = ref object of OpenApiRestCall_610658
proc url_StartElasticsearchServiceSoftwareUpdate_611584(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartElasticsearchServiceSoftwareUpdate_611583(path: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611585 = header.getOrDefault("X-Amz-Signature")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-Signature", valid_611585
  var valid_611586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "X-Amz-Content-Sha256", valid_611586
  var valid_611587 = header.getOrDefault("X-Amz-Date")
  valid_611587 = validateParameter(valid_611587, JString, required = false,
                                 default = nil)
  if valid_611587 != nil:
    section.add "X-Amz-Date", valid_611587
  var valid_611588 = header.getOrDefault("X-Amz-Credential")
  valid_611588 = validateParameter(valid_611588, JString, required = false,
                                 default = nil)
  if valid_611588 != nil:
    section.add "X-Amz-Credential", valid_611588
  var valid_611589 = header.getOrDefault("X-Amz-Security-Token")
  valid_611589 = validateParameter(valid_611589, JString, required = false,
                                 default = nil)
  if valid_611589 != nil:
    section.add "X-Amz-Security-Token", valid_611589
  var valid_611590 = header.getOrDefault("X-Amz-Algorithm")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "X-Amz-Algorithm", valid_611590
  var valid_611591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611591 = validateParameter(valid_611591, JString, required = false,
                                 default = nil)
  if valid_611591 != nil:
    section.add "X-Amz-SignedHeaders", valid_611591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611593: Call_StartElasticsearchServiceSoftwareUpdate_611582;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Schedules a service software update for an Amazon ES domain.
  ## 
  let valid = call_611593.validator(path, query, header, formData, body)
  let scheme = call_611593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611593.url(scheme.get, call_611593.host, call_611593.base,
                         call_611593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611593, url, valid)

proc call*(call_611594: Call_StartElasticsearchServiceSoftwareUpdate_611582;
          body: JsonNode): Recallable =
  ## startElasticsearchServiceSoftwareUpdate
  ## Schedules a service software update for an Amazon ES domain.
  ##   body: JObject (required)
  var body_611595 = newJObject()
  if body != nil:
    body_611595 = body
  result = call_611594.call(nil, nil, nil, nil, body_611595)

var startElasticsearchServiceSoftwareUpdate* = Call_StartElasticsearchServiceSoftwareUpdate_611582(
    name: "startElasticsearchServiceSoftwareUpdate", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/serviceSoftwareUpdate/start",
    validator: validate_StartElasticsearchServiceSoftwareUpdate_611583, base: "/",
    url: url_StartElasticsearchServiceSoftwareUpdate_611584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradeElasticsearchDomain_611596 = ref object of OpenApiRestCall_610658
proc url_UpgradeElasticsearchDomain_611598(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpgradeElasticsearchDomain_611597(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611599 = header.getOrDefault("X-Amz-Signature")
  valid_611599 = validateParameter(valid_611599, JString, required = false,
                                 default = nil)
  if valid_611599 != nil:
    section.add "X-Amz-Signature", valid_611599
  var valid_611600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611600 = validateParameter(valid_611600, JString, required = false,
                                 default = nil)
  if valid_611600 != nil:
    section.add "X-Amz-Content-Sha256", valid_611600
  var valid_611601 = header.getOrDefault("X-Amz-Date")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Date", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-Credential")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-Credential", valid_611602
  var valid_611603 = header.getOrDefault("X-Amz-Security-Token")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-Security-Token", valid_611603
  var valid_611604 = header.getOrDefault("X-Amz-Algorithm")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "X-Amz-Algorithm", valid_611604
  var valid_611605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-SignedHeaders", valid_611605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611607: Call_UpgradeElasticsearchDomain_611596; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows you to either upgrade your domain or perform an Upgrade eligibility check to a compatible Elasticsearch version.
  ## 
  let valid = call_611607.validator(path, query, header, formData, body)
  let scheme = call_611607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611607.url(scheme.get, call_611607.host, call_611607.base,
                         call_611607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611607, url, valid)

proc call*(call_611608: Call_UpgradeElasticsearchDomain_611596; body: JsonNode): Recallable =
  ## upgradeElasticsearchDomain
  ## Allows you to either upgrade your domain or perform an Upgrade eligibility check to a compatible Elasticsearch version.
  ##   body: JObject (required)
  var body_611609 = newJObject()
  if body != nil:
    body_611609 = body
  result = call_611608.call(nil, nil, nil, nil, body_611609)

var upgradeElasticsearchDomain* = Call_UpgradeElasticsearchDomain_611596(
    name: "upgradeElasticsearchDomain", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/upgradeDomain",
    validator: validate_UpgradeElasticsearchDomain_611597, base: "/",
    url: url_UpgradeElasticsearchDomain_611598,
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
