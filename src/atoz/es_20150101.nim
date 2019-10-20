
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddTags_592703 = ref object of OpenApiRestCall_592364
proc url_AddTags_592705(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddTags_592704(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592817 = header.getOrDefault("X-Amz-Signature")
  valid_592817 = validateParameter(valid_592817, JString, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "X-Amz-Signature", valid_592817
  var valid_592818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "X-Amz-Content-Sha256", valid_592818
  var valid_592819 = header.getOrDefault("X-Amz-Date")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "X-Amz-Date", valid_592819
  var valid_592820 = header.getOrDefault("X-Amz-Credential")
  valid_592820 = validateParameter(valid_592820, JString, required = false,
                                 default = nil)
  if valid_592820 != nil:
    section.add "X-Amz-Credential", valid_592820
  var valid_592821 = header.getOrDefault("X-Amz-Security-Token")
  valid_592821 = validateParameter(valid_592821, JString, required = false,
                                 default = nil)
  if valid_592821 != nil:
    section.add "X-Amz-Security-Token", valid_592821
  var valid_592822 = header.getOrDefault("X-Amz-Algorithm")
  valid_592822 = validateParameter(valid_592822, JString, required = false,
                                 default = nil)
  if valid_592822 != nil:
    section.add "X-Amz-Algorithm", valid_592822
  var valid_592823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-SignedHeaders", valid_592823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592847: Call_AddTags_592703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches tags to an existing Elasticsearch domain. Tags are a set of case-sensitive key value pairs. An Elasticsearch domain may have up to 10 tags. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-managedomains.html#es-managedomains-awsresorcetagging" target="_blank"> Tagging Amazon Elasticsearch Service Domains for more information.</a>
  ## 
  let valid = call_592847.validator(path, query, header, formData, body)
  let scheme = call_592847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592847.url(scheme.get, call_592847.host, call_592847.base,
                         call_592847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592847, url, valid)

proc call*(call_592918: Call_AddTags_592703; body: JsonNode): Recallable =
  ## addTags
  ## Attaches tags to an existing Elasticsearch domain. Tags are a set of case-sensitive key value pairs. An Elasticsearch domain may have up to 10 tags. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-managedomains.html#es-managedomains-awsresorcetagging" target="_blank"> Tagging Amazon Elasticsearch Service Domains for more information.</a>
  ##   body: JObject (required)
  var body_592919 = newJObject()
  if body != nil:
    body_592919 = body
  result = call_592918.call(nil, nil, nil, nil, body_592919)

var addTags* = Call_AddTags_592703(name: "addTags", meth: HttpMethod.HttpPost,
                                host: "es.amazonaws.com",
                                route: "/2015-01-01/tags",
                                validator: validate_AddTags_592704, base: "/",
                                url: url_AddTags_592705,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelElasticsearchServiceSoftwareUpdate_592958 = ref object of OpenApiRestCall_592364
proc url_CancelElasticsearchServiceSoftwareUpdate_592960(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelElasticsearchServiceSoftwareUpdate_592959(path: JsonNode;
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
  var valid_592961 = header.getOrDefault("X-Amz-Signature")
  valid_592961 = validateParameter(valid_592961, JString, required = false,
                                 default = nil)
  if valid_592961 != nil:
    section.add "X-Amz-Signature", valid_592961
  var valid_592962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592962 = validateParameter(valid_592962, JString, required = false,
                                 default = nil)
  if valid_592962 != nil:
    section.add "X-Amz-Content-Sha256", valid_592962
  var valid_592963 = header.getOrDefault("X-Amz-Date")
  valid_592963 = validateParameter(valid_592963, JString, required = false,
                                 default = nil)
  if valid_592963 != nil:
    section.add "X-Amz-Date", valid_592963
  var valid_592964 = header.getOrDefault("X-Amz-Credential")
  valid_592964 = validateParameter(valid_592964, JString, required = false,
                                 default = nil)
  if valid_592964 != nil:
    section.add "X-Amz-Credential", valid_592964
  var valid_592965 = header.getOrDefault("X-Amz-Security-Token")
  valid_592965 = validateParameter(valid_592965, JString, required = false,
                                 default = nil)
  if valid_592965 != nil:
    section.add "X-Amz-Security-Token", valid_592965
  var valid_592966 = header.getOrDefault("X-Amz-Algorithm")
  valid_592966 = validateParameter(valid_592966, JString, required = false,
                                 default = nil)
  if valid_592966 != nil:
    section.add "X-Amz-Algorithm", valid_592966
  var valid_592967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592967 = validateParameter(valid_592967, JString, required = false,
                                 default = nil)
  if valid_592967 != nil:
    section.add "X-Amz-SignedHeaders", valid_592967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592969: Call_CancelElasticsearchServiceSoftwareUpdate_592958;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Cancels a scheduled service software update for an Amazon ES domain. You can only perform this operation before the <code>AutomatedUpdateDate</code> and when the <code>UpdateStatus</code> is in the <code>PENDING_UPDATE</code> state.
  ## 
  let valid = call_592969.validator(path, query, header, formData, body)
  let scheme = call_592969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592969.url(scheme.get, call_592969.host, call_592969.base,
                         call_592969.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592969, url, valid)

proc call*(call_592970: Call_CancelElasticsearchServiceSoftwareUpdate_592958;
          body: JsonNode): Recallable =
  ## cancelElasticsearchServiceSoftwareUpdate
  ## Cancels a scheduled service software update for an Amazon ES domain. You can only perform this operation before the <code>AutomatedUpdateDate</code> and when the <code>UpdateStatus</code> is in the <code>PENDING_UPDATE</code> state.
  ##   body: JObject (required)
  var body_592971 = newJObject()
  if body != nil:
    body_592971 = body
  result = call_592970.call(nil, nil, nil, nil, body_592971)

var cancelElasticsearchServiceSoftwareUpdate* = Call_CancelElasticsearchServiceSoftwareUpdate_592958(
    name: "cancelElasticsearchServiceSoftwareUpdate", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com",
    route: "/2015-01-01/es/serviceSoftwareUpdate/cancel",
    validator: validate_CancelElasticsearchServiceSoftwareUpdate_592959,
    base: "/", url: url_CancelElasticsearchServiceSoftwareUpdate_592960,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateElasticsearchDomain_592972 = ref object of OpenApiRestCall_592364
proc url_CreateElasticsearchDomain_592974(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateElasticsearchDomain_592973(path: JsonNode; query: JsonNode;
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
  var valid_592975 = header.getOrDefault("X-Amz-Signature")
  valid_592975 = validateParameter(valid_592975, JString, required = false,
                                 default = nil)
  if valid_592975 != nil:
    section.add "X-Amz-Signature", valid_592975
  var valid_592976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592976 = validateParameter(valid_592976, JString, required = false,
                                 default = nil)
  if valid_592976 != nil:
    section.add "X-Amz-Content-Sha256", valid_592976
  var valid_592977 = header.getOrDefault("X-Amz-Date")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Date", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Credential")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Credential", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Security-Token")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Security-Token", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Algorithm")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Algorithm", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-SignedHeaders", valid_592981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592983: Call_CreateElasticsearchDomain_592972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Elasticsearch domain. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomains" target="_blank">Creating Elasticsearch Domains</a> in the <i>Amazon Elasticsearch Service Developer Guide</i>.
  ## 
  let valid = call_592983.validator(path, query, header, formData, body)
  let scheme = call_592983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592983.url(scheme.get, call_592983.host, call_592983.base,
                         call_592983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592983, url, valid)

proc call*(call_592984: Call_CreateElasticsearchDomain_592972; body: JsonNode): Recallable =
  ## createElasticsearchDomain
  ## Creates a new Elasticsearch domain. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomains" target="_blank">Creating Elasticsearch Domains</a> in the <i>Amazon Elasticsearch Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_592985 = newJObject()
  if body != nil:
    body_592985 = body
  result = call_592984.call(nil, nil, nil, nil, body_592985)

var createElasticsearchDomain* = Call_CreateElasticsearchDomain_592972(
    name: "createElasticsearchDomain", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain",
    validator: validate_CreateElasticsearchDomain_592973, base: "/",
    url: url_CreateElasticsearchDomain_592974,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchDomain_592986 = ref object of OpenApiRestCall_592364
proc url_DescribeElasticsearchDomain_592988(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DescribeElasticsearchDomain_592987(path: JsonNode; query: JsonNode;
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
  var valid_593003 = path.getOrDefault("DomainName")
  valid_593003 = validateParameter(valid_593003, JString, required = true,
                                 default = nil)
  if valid_593003 != nil:
    section.add "DomainName", valid_593003
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
  var valid_593004 = header.getOrDefault("X-Amz-Signature")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-Signature", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-Content-Sha256", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-Date")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Date", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Credential")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Credential", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Security-Token")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Security-Token", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-Algorithm")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Algorithm", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-SignedHeaders", valid_593010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593011: Call_DescribeElasticsearchDomain_592986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns domain configuration information about the specified Elasticsearch domain, including the domain ID, domain endpoint, and domain ARN.
  ## 
  let valid = call_593011.validator(path, query, header, formData, body)
  let scheme = call_593011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593011.url(scheme.get, call_593011.host, call_593011.base,
                         call_593011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593011, url, valid)

proc call*(call_593012: Call_DescribeElasticsearchDomain_592986; DomainName: string): Recallable =
  ## describeElasticsearchDomain
  ## Returns domain configuration information about the specified Elasticsearch domain, including the domain ID, domain endpoint, and domain ARN.
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var path_593013 = newJObject()
  add(path_593013, "DomainName", newJString(DomainName))
  result = call_593012.call(path_593013, nil, nil, nil, nil)

var describeElasticsearchDomain* = Call_DescribeElasticsearchDomain_592986(
    name: "describeElasticsearchDomain", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain/{DomainName}",
    validator: validate_DescribeElasticsearchDomain_592987, base: "/",
    url: url_DescribeElasticsearchDomain_592988,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteElasticsearchDomain_593015 = ref object of OpenApiRestCall_592364
proc url_DeleteElasticsearchDomain_593017(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DeleteElasticsearchDomain_593016(path: JsonNode; query: JsonNode;
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
  var valid_593018 = path.getOrDefault("DomainName")
  valid_593018 = validateParameter(valid_593018, JString, required = true,
                                 default = nil)
  if valid_593018 != nil:
    section.add "DomainName", valid_593018
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
  var valid_593019 = header.getOrDefault("X-Amz-Signature")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-Signature", valid_593019
  var valid_593020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "X-Amz-Content-Sha256", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Date")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Date", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Credential")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Credential", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Security-Token")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Security-Token", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Algorithm")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Algorithm", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-SignedHeaders", valid_593025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593026: Call_DeleteElasticsearchDomain_593015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes the specified Elasticsearch domain and all of its data. Once a domain is deleted, it cannot be recovered.
  ## 
  let valid = call_593026.validator(path, query, header, formData, body)
  let scheme = call_593026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593026.url(scheme.get, call_593026.host, call_593026.base,
                         call_593026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593026, url, valid)

proc call*(call_593027: Call_DeleteElasticsearchDomain_593015; DomainName: string): Recallable =
  ## deleteElasticsearchDomain
  ## Permanently deletes the specified Elasticsearch domain and all of its data. Once a domain is deleted, it cannot be recovered.
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var path_593028 = newJObject()
  add(path_593028, "DomainName", newJString(DomainName))
  result = call_593027.call(path_593028, nil, nil, nil, nil)

var deleteElasticsearchDomain* = Call_DeleteElasticsearchDomain_593015(
    name: "deleteElasticsearchDomain", meth: HttpMethod.HttpDelete,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain/{DomainName}",
    validator: validate_DeleteElasticsearchDomain_593016, base: "/",
    url: url_DeleteElasticsearchDomain_593017,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteElasticsearchServiceRole_593029 = ref object of OpenApiRestCall_592364
proc url_DeleteElasticsearchServiceRole_593031(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteElasticsearchServiceRole_593030(path: JsonNode;
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
  var valid_593032 = header.getOrDefault("X-Amz-Signature")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "X-Amz-Signature", valid_593032
  var valid_593033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "X-Amz-Content-Sha256", valid_593033
  var valid_593034 = header.getOrDefault("X-Amz-Date")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "X-Amz-Date", valid_593034
  var valid_593035 = header.getOrDefault("X-Amz-Credential")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "X-Amz-Credential", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-Security-Token")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Security-Token", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-Algorithm")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Algorithm", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-SignedHeaders", valid_593038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593039: Call_DeleteElasticsearchServiceRole_593029; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the service-linked role that Elasticsearch Service uses to manage and maintain VPC domains. Role deletion will fail if any existing VPC domains use the role. You must delete any such Elasticsearch domains before deleting the role. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html#es-enabling-slr" target="_blank">Deleting Elasticsearch Service Role</a> in <i>VPC Endpoints for Amazon Elasticsearch Service Domains</i>.
  ## 
  let valid = call_593039.validator(path, query, header, formData, body)
  let scheme = call_593039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593039.url(scheme.get, call_593039.host, call_593039.base,
                         call_593039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593039, url, valid)

proc call*(call_593040: Call_DeleteElasticsearchServiceRole_593029): Recallable =
  ## deleteElasticsearchServiceRole
  ## Deletes the service-linked role that Elasticsearch Service uses to manage and maintain VPC domains. Role deletion will fail if any existing VPC domains use the role. You must delete any such Elasticsearch domains before deleting the role. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html#es-enabling-slr" target="_blank">Deleting Elasticsearch Service Role</a> in <i>VPC Endpoints for Amazon Elasticsearch Service Domains</i>.
  result = call_593040.call(nil, nil, nil, nil, nil)

var deleteElasticsearchServiceRole* = Call_DeleteElasticsearchServiceRole_593029(
    name: "deleteElasticsearchServiceRole", meth: HttpMethod.HttpDelete,
    host: "es.amazonaws.com", route: "/2015-01-01/es/role",
    validator: validate_DeleteElasticsearchServiceRole_593030, base: "/",
    url: url_DeleteElasticsearchServiceRole_593031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateElasticsearchDomainConfig_593055 = ref object of OpenApiRestCall_592364
proc url_UpdateElasticsearchDomainConfig_593057(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_UpdateElasticsearchDomainConfig_593056(path: JsonNode;
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
  var valid_593058 = path.getOrDefault("DomainName")
  valid_593058 = validateParameter(valid_593058, JString, required = true,
                                 default = nil)
  if valid_593058 != nil:
    section.add "DomainName", valid_593058
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
  var valid_593059 = header.getOrDefault("X-Amz-Signature")
  valid_593059 = validateParameter(valid_593059, JString, required = false,
                                 default = nil)
  if valid_593059 != nil:
    section.add "X-Amz-Signature", valid_593059
  var valid_593060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-Content-Sha256", valid_593060
  var valid_593061 = header.getOrDefault("X-Amz-Date")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "X-Amz-Date", valid_593061
  var valid_593062 = header.getOrDefault("X-Amz-Credential")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "X-Amz-Credential", valid_593062
  var valid_593063 = header.getOrDefault("X-Amz-Security-Token")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Security-Token", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-Algorithm")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-Algorithm", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-SignedHeaders", valid_593065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593067: Call_UpdateElasticsearchDomainConfig_593055;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies the cluster configuration of the specified Elasticsearch domain, setting as setting the instance type and the number of instances. 
  ## 
  let valid = call_593067.validator(path, query, header, formData, body)
  let scheme = call_593067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593067.url(scheme.get, call_593067.host, call_593067.base,
                         call_593067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593067, url, valid)

proc call*(call_593068: Call_UpdateElasticsearchDomainConfig_593055;
          DomainName: string; body: JsonNode): Recallable =
  ## updateElasticsearchDomainConfig
  ## Modifies the cluster configuration of the specified Elasticsearch domain, setting as setting the instance type and the number of instances. 
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   body: JObject (required)
  var path_593069 = newJObject()
  var body_593070 = newJObject()
  add(path_593069, "DomainName", newJString(DomainName))
  if body != nil:
    body_593070 = body
  result = call_593068.call(path_593069, nil, nil, nil, body_593070)

var updateElasticsearchDomainConfig* = Call_UpdateElasticsearchDomainConfig_593055(
    name: "updateElasticsearchDomainConfig", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain/{DomainName}/config",
    validator: validate_UpdateElasticsearchDomainConfig_593056, base: "/",
    url: url_UpdateElasticsearchDomainConfig_593057,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchDomainConfig_593041 = ref object of OpenApiRestCall_592364
proc url_DescribeElasticsearchDomainConfig_593043(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DescribeElasticsearchDomainConfig_593042(path: JsonNode;
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
  var valid_593044 = path.getOrDefault("DomainName")
  valid_593044 = validateParameter(valid_593044, JString, required = true,
                                 default = nil)
  if valid_593044 != nil:
    section.add "DomainName", valid_593044
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
  var valid_593045 = header.getOrDefault("X-Amz-Signature")
  valid_593045 = validateParameter(valid_593045, JString, required = false,
                                 default = nil)
  if valid_593045 != nil:
    section.add "X-Amz-Signature", valid_593045
  var valid_593046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593046 = validateParameter(valid_593046, JString, required = false,
                                 default = nil)
  if valid_593046 != nil:
    section.add "X-Amz-Content-Sha256", valid_593046
  var valid_593047 = header.getOrDefault("X-Amz-Date")
  valid_593047 = validateParameter(valid_593047, JString, required = false,
                                 default = nil)
  if valid_593047 != nil:
    section.add "X-Amz-Date", valid_593047
  var valid_593048 = header.getOrDefault("X-Amz-Credential")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "X-Amz-Credential", valid_593048
  var valid_593049 = header.getOrDefault("X-Amz-Security-Token")
  valid_593049 = validateParameter(valid_593049, JString, required = false,
                                 default = nil)
  if valid_593049 != nil:
    section.add "X-Amz-Security-Token", valid_593049
  var valid_593050 = header.getOrDefault("X-Amz-Algorithm")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "X-Amz-Algorithm", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-SignedHeaders", valid_593051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593052: Call_DescribeElasticsearchDomainConfig_593041;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Provides cluster configuration information about the specified Elasticsearch domain, such as the state, creation date, update version, and update date for cluster options.
  ## 
  let valid = call_593052.validator(path, query, header, formData, body)
  let scheme = call_593052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593052.url(scheme.get, call_593052.host, call_593052.base,
                         call_593052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593052, url, valid)

proc call*(call_593053: Call_DescribeElasticsearchDomainConfig_593041;
          DomainName: string): Recallable =
  ## describeElasticsearchDomainConfig
  ## Provides cluster configuration information about the specified Elasticsearch domain, such as the state, creation date, update version, and update date for cluster options.
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var path_593054 = newJObject()
  add(path_593054, "DomainName", newJString(DomainName))
  result = call_593053.call(path_593054, nil, nil, nil, nil)

var describeElasticsearchDomainConfig* = Call_DescribeElasticsearchDomainConfig_593041(
    name: "describeElasticsearchDomainConfig", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain/{DomainName}/config",
    validator: validate_DescribeElasticsearchDomainConfig_593042, base: "/",
    url: url_DescribeElasticsearchDomainConfig_593043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchDomains_593071 = ref object of OpenApiRestCall_592364
proc url_DescribeElasticsearchDomains_593073(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeElasticsearchDomains_593072(path: JsonNode; query: JsonNode;
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
  var valid_593074 = header.getOrDefault("X-Amz-Signature")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "X-Amz-Signature", valid_593074
  var valid_593075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-Content-Sha256", valid_593075
  var valid_593076 = header.getOrDefault("X-Amz-Date")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Date", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-Credential")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Credential", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-Security-Token")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-Security-Token", valid_593078
  var valid_593079 = header.getOrDefault("X-Amz-Algorithm")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-Algorithm", valid_593079
  var valid_593080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "X-Amz-SignedHeaders", valid_593080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593082: Call_DescribeElasticsearchDomains_593071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns domain configuration information about the specified Elasticsearch domains, including the domain ID, domain endpoint, and domain ARN.
  ## 
  let valid = call_593082.validator(path, query, header, formData, body)
  let scheme = call_593082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593082.url(scheme.get, call_593082.host, call_593082.base,
                         call_593082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593082, url, valid)

proc call*(call_593083: Call_DescribeElasticsearchDomains_593071; body: JsonNode): Recallable =
  ## describeElasticsearchDomains
  ## Returns domain configuration information about the specified Elasticsearch domains, including the domain ID, domain endpoint, and domain ARN.
  ##   body: JObject (required)
  var body_593084 = newJObject()
  if body != nil:
    body_593084 = body
  result = call_593083.call(nil, nil, nil, nil, body_593084)

var describeElasticsearchDomains* = Call_DescribeElasticsearchDomains_593071(
    name: "describeElasticsearchDomains", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain-info",
    validator: validate_DescribeElasticsearchDomains_593072, base: "/",
    url: url_DescribeElasticsearchDomains_593073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchInstanceTypeLimits_593085 = ref object of OpenApiRestCall_592364
proc url_DescribeElasticsearchInstanceTypeLimits_593087(protocol: Scheme;
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
  result.path = base & hydrated.get

proc validate_DescribeElasticsearchInstanceTypeLimits_593086(path: JsonNode;
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
  var valid_593101 = path.getOrDefault("InstanceType")
  valid_593101 = validateParameter(valid_593101, JString, required = true, default = newJString(
      "m3.medium.elasticsearch"))
  if valid_593101 != nil:
    section.add "InstanceType", valid_593101
  var valid_593102 = path.getOrDefault("ElasticsearchVersion")
  valid_593102 = validateParameter(valid_593102, JString, required = true,
                                 default = nil)
  if valid_593102 != nil:
    section.add "ElasticsearchVersion", valid_593102
  result.add "path", section
  ## parameters in `query` object:
  ##   domainName: JString
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_593103 = query.getOrDefault("domainName")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "domainName", valid_593103
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
  var valid_593104 = header.getOrDefault("X-Amz-Signature")
  valid_593104 = validateParameter(valid_593104, JString, required = false,
                                 default = nil)
  if valid_593104 != nil:
    section.add "X-Amz-Signature", valid_593104
  var valid_593105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-Content-Sha256", valid_593105
  var valid_593106 = header.getOrDefault("X-Amz-Date")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "X-Amz-Date", valid_593106
  var valid_593107 = header.getOrDefault("X-Amz-Credential")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "X-Amz-Credential", valid_593107
  var valid_593108 = header.getOrDefault("X-Amz-Security-Token")
  valid_593108 = validateParameter(valid_593108, JString, required = false,
                                 default = nil)
  if valid_593108 != nil:
    section.add "X-Amz-Security-Token", valid_593108
  var valid_593109 = header.getOrDefault("X-Amz-Algorithm")
  valid_593109 = validateParameter(valid_593109, JString, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "X-Amz-Algorithm", valid_593109
  var valid_593110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = nil)
  if valid_593110 != nil:
    section.add "X-Amz-SignedHeaders", valid_593110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593111: Call_DescribeElasticsearchInstanceTypeLimits_593085;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Describe Elasticsearch Limits for a given InstanceType and ElasticsearchVersion. When modifying existing Domain, specify the <code> <a>DomainName</a> </code> to know what Limits are supported for modifying. 
  ## 
  let valid = call_593111.validator(path, query, header, formData, body)
  let scheme = call_593111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593111.url(scheme.get, call_593111.host, call_593111.base,
                         call_593111.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593111, url, valid)

proc call*(call_593112: Call_DescribeElasticsearchInstanceTypeLimits_593085;
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
  var path_593113 = newJObject()
  var query_593114 = newJObject()
  add(path_593113, "InstanceType", newJString(InstanceType))
  add(query_593114, "domainName", newJString(domainName))
  add(path_593113, "ElasticsearchVersion", newJString(ElasticsearchVersion))
  result = call_593112.call(path_593113, query_593114, nil, nil, nil)

var describeElasticsearchInstanceTypeLimits* = Call_DescribeElasticsearchInstanceTypeLimits_593085(
    name: "describeElasticsearchInstanceTypeLimits", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/instanceTypeLimits/{ElasticsearchVersion}/{InstanceType}",
    validator: validate_DescribeElasticsearchInstanceTypeLimits_593086, base: "/",
    url: url_DescribeElasticsearchInstanceTypeLimits_593087,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReservedElasticsearchInstanceOfferings_593115 = ref object of OpenApiRestCall_592364
proc url_DescribeReservedElasticsearchInstanceOfferings_593117(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeReservedElasticsearchInstanceOfferings_593116(
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
  var valid_593118 = query.getOrDefault("nextToken")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "nextToken", valid_593118
  var valid_593119 = query.getOrDefault("MaxResults")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "MaxResults", valid_593119
  var valid_593120 = query.getOrDefault("NextToken")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "NextToken", valid_593120
  var valid_593121 = query.getOrDefault("offeringId")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "offeringId", valid_593121
  var valid_593122 = query.getOrDefault("maxResults")
  valid_593122 = validateParameter(valid_593122, JInt, required = false, default = nil)
  if valid_593122 != nil:
    section.add "maxResults", valid_593122
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
  var valid_593123 = header.getOrDefault("X-Amz-Signature")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-Signature", valid_593123
  var valid_593124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = nil)
  if valid_593124 != nil:
    section.add "X-Amz-Content-Sha256", valid_593124
  var valid_593125 = header.getOrDefault("X-Amz-Date")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "X-Amz-Date", valid_593125
  var valid_593126 = header.getOrDefault("X-Amz-Credential")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Credential", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Security-Token")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Security-Token", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-Algorithm")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-Algorithm", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-SignedHeaders", valid_593129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593130: Call_DescribeReservedElasticsearchInstanceOfferings_593115;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists available reserved Elasticsearch instance offerings.
  ## 
  let valid = call_593130.validator(path, query, header, formData, body)
  let scheme = call_593130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593130.url(scheme.get, call_593130.host, call_593130.base,
                         call_593130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593130, url, valid)

proc call*(call_593131: Call_DescribeReservedElasticsearchInstanceOfferings_593115;
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
  var query_593132 = newJObject()
  add(query_593132, "nextToken", newJString(nextToken))
  add(query_593132, "MaxResults", newJString(MaxResults))
  add(query_593132, "NextToken", newJString(NextToken))
  add(query_593132, "offeringId", newJString(offeringId))
  add(query_593132, "maxResults", newJInt(maxResults))
  result = call_593131.call(nil, query_593132, nil, nil, nil)

var describeReservedElasticsearchInstanceOfferings* = Call_DescribeReservedElasticsearchInstanceOfferings_593115(
    name: "describeReservedElasticsearchInstanceOfferings",
    meth: HttpMethod.HttpGet, host: "es.amazonaws.com",
    route: "/2015-01-01/es/reservedInstanceOfferings",
    validator: validate_DescribeReservedElasticsearchInstanceOfferings_593116,
    base: "/", url: url_DescribeReservedElasticsearchInstanceOfferings_593117,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReservedElasticsearchInstances_593133 = ref object of OpenApiRestCall_592364
proc url_DescribeReservedElasticsearchInstances_593135(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeReservedElasticsearchInstances_593134(path: JsonNode;
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
  var valid_593136 = query.getOrDefault("nextToken")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "nextToken", valid_593136
  var valid_593137 = query.getOrDefault("MaxResults")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "MaxResults", valid_593137
  var valid_593138 = query.getOrDefault("reservationId")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "reservationId", valid_593138
  var valid_593139 = query.getOrDefault("NextToken")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "NextToken", valid_593139
  var valid_593140 = query.getOrDefault("maxResults")
  valid_593140 = validateParameter(valid_593140, JInt, required = false, default = nil)
  if valid_593140 != nil:
    section.add "maxResults", valid_593140
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
  var valid_593141 = header.getOrDefault("X-Amz-Signature")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-Signature", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Content-Sha256", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-Date")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Date", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-Credential")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-Credential", valid_593144
  var valid_593145 = header.getOrDefault("X-Amz-Security-Token")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "X-Amz-Security-Token", valid_593145
  var valid_593146 = header.getOrDefault("X-Amz-Algorithm")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "X-Amz-Algorithm", valid_593146
  var valid_593147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "X-Amz-SignedHeaders", valid_593147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593148: Call_DescribeReservedElasticsearchInstances_593133;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns information about reserved Elasticsearch instances for this account.
  ## 
  let valid = call_593148.validator(path, query, header, formData, body)
  let scheme = call_593148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593148.url(scheme.get, call_593148.host, call_593148.base,
                         call_593148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593148, url, valid)

proc call*(call_593149: Call_DescribeReservedElasticsearchInstances_593133;
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
  var query_593150 = newJObject()
  add(query_593150, "nextToken", newJString(nextToken))
  add(query_593150, "MaxResults", newJString(MaxResults))
  add(query_593150, "reservationId", newJString(reservationId))
  add(query_593150, "NextToken", newJString(NextToken))
  add(query_593150, "maxResults", newJInt(maxResults))
  result = call_593149.call(nil, query_593150, nil, nil, nil)

var describeReservedElasticsearchInstances* = Call_DescribeReservedElasticsearchInstances_593133(
    name: "describeReservedElasticsearchInstances", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/reservedInstances",
    validator: validate_DescribeReservedElasticsearchInstances_593134, base: "/",
    url: url_DescribeReservedElasticsearchInstances_593135,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCompatibleElasticsearchVersions_593151 = ref object of OpenApiRestCall_592364
proc url_GetCompatibleElasticsearchVersions_593153(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCompatibleElasticsearchVersions_593152(path: JsonNode;
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
  var valid_593154 = query.getOrDefault("domainName")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "domainName", valid_593154
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
  var valid_593155 = header.getOrDefault("X-Amz-Signature")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "X-Amz-Signature", valid_593155
  var valid_593156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-Content-Sha256", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-Date")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Date", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-Credential")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Credential", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-Security-Token")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-Security-Token", valid_593159
  var valid_593160 = header.getOrDefault("X-Amz-Algorithm")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "X-Amz-Algorithm", valid_593160
  var valid_593161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-SignedHeaders", valid_593161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593162: Call_GetCompatibleElasticsearchVersions_593151;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Returns a list of upgrade compatible Elastisearch versions. You can optionally pass a <code> <a>DomainName</a> </code> to get all upgrade compatible Elasticsearch versions for that specific domain. 
  ## 
  let valid = call_593162.validator(path, query, header, formData, body)
  let scheme = call_593162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593162.url(scheme.get, call_593162.host, call_593162.base,
                         call_593162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593162, url, valid)

proc call*(call_593163: Call_GetCompatibleElasticsearchVersions_593151;
          domainName: string = ""): Recallable =
  ## getCompatibleElasticsearchVersions
  ##  Returns a list of upgrade compatible Elastisearch versions. You can optionally pass a <code> <a>DomainName</a> </code> to get all upgrade compatible Elasticsearch versions for that specific domain. 
  ##   domainName: string
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var query_593164 = newJObject()
  add(query_593164, "domainName", newJString(domainName))
  result = call_593163.call(nil, query_593164, nil, nil, nil)

var getCompatibleElasticsearchVersions* = Call_GetCompatibleElasticsearchVersions_593151(
    name: "getCompatibleElasticsearchVersions", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/compatibleVersions",
    validator: validate_GetCompatibleElasticsearchVersions_593152, base: "/",
    url: url_GetCompatibleElasticsearchVersions_593153,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpgradeHistory_593165 = ref object of OpenApiRestCall_592364
proc url_GetUpgradeHistory_593167(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetUpgradeHistory_593166(path: JsonNode; query: JsonNode;
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
  var valid_593168 = path.getOrDefault("DomainName")
  valid_593168 = validateParameter(valid_593168, JString, required = true,
                                 default = nil)
  if valid_593168 != nil:
    section.add "DomainName", valid_593168
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
  var valid_593169 = query.getOrDefault("nextToken")
  valid_593169 = validateParameter(valid_593169, JString, required = false,
                                 default = nil)
  if valid_593169 != nil:
    section.add "nextToken", valid_593169
  var valid_593170 = query.getOrDefault("MaxResults")
  valid_593170 = validateParameter(valid_593170, JString, required = false,
                                 default = nil)
  if valid_593170 != nil:
    section.add "MaxResults", valid_593170
  var valid_593171 = query.getOrDefault("NextToken")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "NextToken", valid_593171
  var valid_593172 = query.getOrDefault("maxResults")
  valid_593172 = validateParameter(valid_593172, JInt, required = false, default = nil)
  if valid_593172 != nil:
    section.add "maxResults", valid_593172
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
  var valid_593173 = header.getOrDefault("X-Amz-Signature")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-Signature", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-Content-Sha256", valid_593174
  var valid_593175 = header.getOrDefault("X-Amz-Date")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "X-Amz-Date", valid_593175
  var valid_593176 = header.getOrDefault("X-Amz-Credential")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-Credential", valid_593176
  var valid_593177 = header.getOrDefault("X-Amz-Security-Token")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "X-Amz-Security-Token", valid_593177
  var valid_593178 = header.getOrDefault("X-Amz-Algorithm")
  valid_593178 = validateParameter(valid_593178, JString, required = false,
                                 default = nil)
  if valid_593178 != nil:
    section.add "X-Amz-Algorithm", valid_593178
  var valid_593179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593179 = validateParameter(valid_593179, JString, required = false,
                                 default = nil)
  if valid_593179 != nil:
    section.add "X-Amz-SignedHeaders", valid_593179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593180: Call_GetUpgradeHistory_593165; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the complete history of the last 10 upgrades that were performed on the domain.
  ## 
  let valid = call_593180.validator(path, query, header, formData, body)
  let scheme = call_593180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593180.url(scheme.get, call_593180.host, call_593180.base,
                         call_593180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593180, url, valid)

proc call*(call_593181: Call_GetUpgradeHistory_593165; DomainName: string;
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
  var path_593182 = newJObject()
  var query_593183 = newJObject()
  add(query_593183, "nextToken", newJString(nextToken))
  add(query_593183, "MaxResults", newJString(MaxResults))
  add(query_593183, "NextToken", newJString(NextToken))
  add(path_593182, "DomainName", newJString(DomainName))
  add(query_593183, "maxResults", newJInt(maxResults))
  result = call_593181.call(path_593182, query_593183, nil, nil, nil)

var getUpgradeHistory* = Call_GetUpgradeHistory_593165(name: "getUpgradeHistory",
    meth: HttpMethod.HttpGet, host: "es.amazonaws.com",
    route: "/2015-01-01/es/upgradeDomain/{DomainName}/history",
    validator: validate_GetUpgradeHistory_593166, base: "/",
    url: url_GetUpgradeHistory_593167, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpgradeStatus_593184 = ref object of OpenApiRestCall_592364
proc url_GetUpgradeStatus_593186(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetUpgradeStatus_593185(path: JsonNode; query: JsonNode;
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
  var valid_593187 = path.getOrDefault("DomainName")
  valid_593187 = validateParameter(valid_593187, JString, required = true,
                                 default = nil)
  if valid_593187 != nil:
    section.add "DomainName", valid_593187
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
  var valid_593188 = header.getOrDefault("X-Amz-Signature")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Signature", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Content-Sha256", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-Date")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-Date", valid_593190
  var valid_593191 = header.getOrDefault("X-Amz-Credential")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-Credential", valid_593191
  var valid_593192 = header.getOrDefault("X-Amz-Security-Token")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-Security-Token", valid_593192
  var valid_593193 = header.getOrDefault("X-Amz-Algorithm")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "X-Amz-Algorithm", valid_593193
  var valid_593194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593194 = validateParameter(valid_593194, JString, required = false,
                                 default = nil)
  if valid_593194 != nil:
    section.add "X-Amz-SignedHeaders", valid_593194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593195: Call_GetUpgradeStatus_593184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the latest status of the last upgrade or upgrade eligibility check that was performed on the domain.
  ## 
  let valid = call_593195.validator(path, query, header, formData, body)
  let scheme = call_593195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593195.url(scheme.get, call_593195.host, call_593195.base,
                         call_593195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593195, url, valid)

proc call*(call_593196: Call_GetUpgradeStatus_593184; DomainName: string): Recallable =
  ## getUpgradeStatus
  ## Retrieves the latest status of the last upgrade or upgrade eligibility check that was performed on the domain.
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var path_593197 = newJObject()
  add(path_593197, "DomainName", newJString(DomainName))
  result = call_593196.call(path_593197, nil, nil, nil, nil)

var getUpgradeStatus* = Call_GetUpgradeStatus_593184(name: "getUpgradeStatus",
    meth: HttpMethod.HttpGet, host: "es.amazonaws.com",
    route: "/2015-01-01/es/upgradeDomain/{DomainName}/status",
    validator: validate_GetUpgradeStatus_593185, base: "/",
    url: url_GetUpgradeStatus_593186, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomainNames_593198 = ref object of OpenApiRestCall_592364
proc url_ListDomainNames_593200(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDomainNames_593199(path: JsonNode; query: JsonNode;
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
  var valid_593201 = header.getOrDefault("X-Amz-Signature")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "X-Amz-Signature", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Content-Sha256", valid_593202
  var valid_593203 = header.getOrDefault("X-Amz-Date")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-Date", valid_593203
  var valid_593204 = header.getOrDefault("X-Amz-Credential")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-Credential", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-Security-Token")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-Security-Token", valid_593205
  var valid_593206 = header.getOrDefault("X-Amz-Algorithm")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-Algorithm", valid_593206
  var valid_593207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "X-Amz-SignedHeaders", valid_593207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593208: Call_ListDomainNames_593198; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the name of all Elasticsearch domains owned by the current user's account. 
  ## 
  let valid = call_593208.validator(path, query, header, formData, body)
  let scheme = call_593208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593208.url(scheme.get, call_593208.host, call_593208.base,
                         call_593208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593208, url, valid)

proc call*(call_593209: Call_ListDomainNames_593198): Recallable =
  ## listDomainNames
  ## Returns the name of all Elasticsearch domains owned by the current user's account. 
  result = call_593209.call(nil, nil, nil, nil, nil)

var listDomainNames* = Call_ListDomainNames_593198(name: "listDomainNames",
    meth: HttpMethod.HttpGet, host: "es.amazonaws.com", route: "/2015-01-01/domain",
    validator: validate_ListDomainNames_593199, base: "/", url: url_ListDomainNames_593200,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListElasticsearchInstanceTypes_593210 = ref object of OpenApiRestCall_592364
proc url_ListElasticsearchInstanceTypes_593212(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_ListElasticsearchInstanceTypes_593211(path: JsonNode;
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
  var valid_593213 = path.getOrDefault("ElasticsearchVersion")
  valid_593213 = validateParameter(valid_593213, JString, required = true,
                                 default = nil)
  if valid_593213 != nil:
    section.add "ElasticsearchVersion", valid_593213
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
  var valid_593214 = query.getOrDefault("nextToken")
  valid_593214 = validateParameter(valid_593214, JString, required = false,
                                 default = nil)
  if valid_593214 != nil:
    section.add "nextToken", valid_593214
  var valid_593215 = query.getOrDefault("MaxResults")
  valid_593215 = validateParameter(valid_593215, JString, required = false,
                                 default = nil)
  if valid_593215 != nil:
    section.add "MaxResults", valid_593215
  var valid_593216 = query.getOrDefault("domainName")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "domainName", valid_593216
  var valid_593217 = query.getOrDefault("NextToken")
  valid_593217 = validateParameter(valid_593217, JString, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "NextToken", valid_593217
  var valid_593218 = query.getOrDefault("maxResults")
  valid_593218 = validateParameter(valid_593218, JInt, required = false, default = nil)
  if valid_593218 != nil:
    section.add "maxResults", valid_593218
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
  var valid_593219 = header.getOrDefault("X-Amz-Signature")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-Signature", valid_593219
  var valid_593220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-Content-Sha256", valid_593220
  var valid_593221 = header.getOrDefault("X-Amz-Date")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-Date", valid_593221
  var valid_593222 = header.getOrDefault("X-Amz-Credential")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-Credential", valid_593222
  var valid_593223 = header.getOrDefault("X-Amz-Security-Token")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "X-Amz-Security-Token", valid_593223
  var valid_593224 = header.getOrDefault("X-Amz-Algorithm")
  valid_593224 = validateParameter(valid_593224, JString, required = false,
                                 default = nil)
  if valid_593224 != nil:
    section.add "X-Amz-Algorithm", valid_593224
  var valid_593225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593225 = validateParameter(valid_593225, JString, required = false,
                                 default = nil)
  if valid_593225 != nil:
    section.add "X-Amz-SignedHeaders", valid_593225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593226: Call_ListElasticsearchInstanceTypes_593210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all Elasticsearch instance types that are supported for given ElasticsearchVersion
  ## 
  let valid = call_593226.validator(path, query, header, formData, body)
  let scheme = call_593226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593226.url(scheme.get, call_593226.host, call_593226.base,
                         call_593226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593226, url, valid)

proc call*(call_593227: Call_ListElasticsearchInstanceTypes_593210;
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
  var path_593228 = newJObject()
  var query_593229 = newJObject()
  add(query_593229, "nextToken", newJString(nextToken))
  add(query_593229, "MaxResults", newJString(MaxResults))
  add(query_593229, "domainName", newJString(domainName))
  add(query_593229, "NextToken", newJString(NextToken))
  add(path_593228, "ElasticsearchVersion", newJString(ElasticsearchVersion))
  add(query_593229, "maxResults", newJInt(maxResults))
  result = call_593227.call(path_593228, query_593229, nil, nil, nil)

var listElasticsearchInstanceTypes* = Call_ListElasticsearchInstanceTypes_593210(
    name: "listElasticsearchInstanceTypes", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com",
    route: "/2015-01-01/es/instanceTypes/{ElasticsearchVersion}",
    validator: validate_ListElasticsearchInstanceTypes_593211, base: "/",
    url: url_ListElasticsearchInstanceTypes_593212,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListElasticsearchVersions_593230 = ref object of OpenApiRestCall_592364
proc url_ListElasticsearchVersions_593232(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListElasticsearchVersions_593231(path: JsonNode; query: JsonNode;
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
  var valid_593233 = query.getOrDefault("nextToken")
  valid_593233 = validateParameter(valid_593233, JString, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "nextToken", valid_593233
  var valid_593234 = query.getOrDefault("MaxResults")
  valid_593234 = validateParameter(valid_593234, JString, required = false,
                                 default = nil)
  if valid_593234 != nil:
    section.add "MaxResults", valid_593234
  var valid_593235 = query.getOrDefault("NextToken")
  valid_593235 = validateParameter(valid_593235, JString, required = false,
                                 default = nil)
  if valid_593235 != nil:
    section.add "NextToken", valid_593235
  var valid_593236 = query.getOrDefault("maxResults")
  valid_593236 = validateParameter(valid_593236, JInt, required = false, default = nil)
  if valid_593236 != nil:
    section.add "maxResults", valid_593236
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
  var valid_593237 = header.getOrDefault("X-Amz-Signature")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "X-Amz-Signature", valid_593237
  var valid_593238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593238 = validateParameter(valid_593238, JString, required = false,
                                 default = nil)
  if valid_593238 != nil:
    section.add "X-Amz-Content-Sha256", valid_593238
  var valid_593239 = header.getOrDefault("X-Amz-Date")
  valid_593239 = validateParameter(valid_593239, JString, required = false,
                                 default = nil)
  if valid_593239 != nil:
    section.add "X-Amz-Date", valid_593239
  var valid_593240 = header.getOrDefault("X-Amz-Credential")
  valid_593240 = validateParameter(valid_593240, JString, required = false,
                                 default = nil)
  if valid_593240 != nil:
    section.add "X-Amz-Credential", valid_593240
  var valid_593241 = header.getOrDefault("X-Amz-Security-Token")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "X-Amz-Security-Token", valid_593241
  var valid_593242 = header.getOrDefault("X-Amz-Algorithm")
  valid_593242 = validateParameter(valid_593242, JString, required = false,
                                 default = nil)
  if valid_593242 != nil:
    section.add "X-Amz-Algorithm", valid_593242
  var valid_593243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593243 = validateParameter(valid_593243, JString, required = false,
                                 default = nil)
  if valid_593243 != nil:
    section.add "X-Amz-SignedHeaders", valid_593243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593244: Call_ListElasticsearchVersions_593230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all supported Elasticsearch versions
  ## 
  let valid = call_593244.validator(path, query, header, formData, body)
  let scheme = call_593244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593244.url(scheme.get, call_593244.host, call_593244.base,
                         call_593244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593244, url, valid)

proc call*(call_593245: Call_ListElasticsearchVersions_593230;
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
  var query_593246 = newJObject()
  add(query_593246, "nextToken", newJString(nextToken))
  add(query_593246, "MaxResults", newJString(MaxResults))
  add(query_593246, "NextToken", newJString(NextToken))
  add(query_593246, "maxResults", newJInt(maxResults))
  result = call_593245.call(nil, query_593246, nil, nil, nil)

var listElasticsearchVersions* = Call_ListElasticsearchVersions_593230(
    name: "listElasticsearchVersions", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/versions",
    validator: validate_ListElasticsearchVersions_593231, base: "/",
    url: url_ListElasticsearchVersions_593232,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_593247 = ref object of OpenApiRestCall_592364
proc url_ListTags_593249(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTags_593248(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593250 = query.getOrDefault("arn")
  valid_593250 = validateParameter(valid_593250, JString, required = true,
                                 default = nil)
  if valid_593250 != nil:
    section.add "arn", valid_593250
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
  var valid_593251 = header.getOrDefault("X-Amz-Signature")
  valid_593251 = validateParameter(valid_593251, JString, required = false,
                                 default = nil)
  if valid_593251 != nil:
    section.add "X-Amz-Signature", valid_593251
  var valid_593252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593252 = validateParameter(valid_593252, JString, required = false,
                                 default = nil)
  if valid_593252 != nil:
    section.add "X-Amz-Content-Sha256", valid_593252
  var valid_593253 = header.getOrDefault("X-Amz-Date")
  valid_593253 = validateParameter(valid_593253, JString, required = false,
                                 default = nil)
  if valid_593253 != nil:
    section.add "X-Amz-Date", valid_593253
  var valid_593254 = header.getOrDefault("X-Amz-Credential")
  valid_593254 = validateParameter(valid_593254, JString, required = false,
                                 default = nil)
  if valid_593254 != nil:
    section.add "X-Amz-Credential", valid_593254
  var valid_593255 = header.getOrDefault("X-Amz-Security-Token")
  valid_593255 = validateParameter(valid_593255, JString, required = false,
                                 default = nil)
  if valid_593255 != nil:
    section.add "X-Amz-Security-Token", valid_593255
  var valid_593256 = header.getOrDefault("X-Amz-Algorithm")
  valid_593256 = validateParameter(valid_593256, JString, required = false,
                                 default = nil)
  if valid_593256 != nil:
    section.add "X-Amz-Algorithm", valid_593256
  var valid_593257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593257 = validateParameter(valid_593257, JString, required = false,
                                 default = nil)
  if valid_593257 != nil:
    section.add "X-Amz-SignedHeaders", valid_593257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593258: Call_ListTags_593247; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tags for the given Elasticsearch domain.
  ## 
  let valid = call_593258.validator(path, query, header, formData, body)
  let scheme = call_593258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593258.url(scheme.get, call_593258.host, call_593258.base,
                         call_593258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593258, url, valid)

proc call*(call_593259: Call_ListTags_593247; arn: string): Recallable =
  ## listTags
  ## Returns all tags for the given Elasticsearch domain.
  ##   arn: string (required)
  ##      : The Amazon Resource Name (ARN) of the Elasticsearch domain. See <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?Using_Identifiers.html" target="_blank">Identifiers for IAM Entities</a> in <i>Using AWS Identity and Access Management</i> for more information.
  var query_593260 = newJObject()
  add(query_593260, "arn", newJString(arn))
  result = call_593259.call(nil, query_593260, nil, nil, nil)

var listTags* = Call_ListTags_593247(name: "listTags", meth: HttpMethod.HttpGet,
                                  host: "es.amazonaws.com",
                                  route: "/2015-01-01/tags/#arn",
                                  validator: validate_ListTags_593248, base: "/",
                                  url: url_ListTags_593249,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseReservedElasticsearchInstanceOffering_593261 = ref object of OpenApiRestCall_592364
proc url_PurchaseReservedElasticsearchInstanceOffering_593263(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PurchaseReservedElasticsearchInstanceOffering_593262(
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
  var valid_593264 = header.getOrDefault("X-Amz-Signature")
  valid_593264 = validateParameter(valid_593264, JString, required = false,
                                 default = nil)
  if valid_593264 != nil:
    section.add "X-Amz-Signature", valid_593264
  var valid_593265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593265 = validateParameter(valid_593265, JString, required = false,
                                 default = nil)
  if valid_593265 != nil:
    section.add "X-Amz-Content-Sha256", valid_593265
  var valid_593266 = header.getOrDefault("X-Amz-Date")
  valid_593266 = validateParameter(valid_593266, JString, required = false,
                                 default = nil)
  if valid_593266 != nil:
    section.add "X-Amz-Date", valid_593266
  var valid_593267 = header.getOrDefault("X-Amz-Credential")
  valid_593267 = validateParameter(valid_593267, JString, required = false,
                                 default = nil)
  if valid_593267 != nil:
    section.add "X-Amz-Credential", valid_593267
  var valid_593268 = header.getOrDefault("X-Amz-Security-Token")
  valid_593268 = validateParameter(valid_593268, JString, required = false,
                                 default = nil)
  if valid_593268 != nil:
    section.add "X-Amz-Security-Token", valid_593268
  var valid_593269 = header.getOrDefault("X-Amz-Algorithm")
  valid_593269 = validateParameter(valid_593269, JString, required = false,
                                 default = nil)
  if valid_593269 != nil:
    section.add "X-Amz-Algorithm", valid_593269
  var valid_593270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593270 = validateParameter(valid_593270, JString, required = false,
                                 default = nil)
  if valid_593270 != nil:
    section.add "X-Amz-SignedHeaders", valid_593270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593272: Call_PurchaseReservedElasticsearchInstanceOffering_593261;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Allows you to purchase reserved Elasticsearch instances.
  ## 
  let valid = call_593272.validator(path, query, header, formData, body)
  let scheme = call_593272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593272.url(scheme.get, call_593272.host, call_593272.base,
                         call_593272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593272, url, valid)

proc call*(call_593273: Call_PurchaseReservedElasticsearchInstanceOffering_593261;
          body: JsonNode): Recallable =
  ## purchaseReservedElasticsearchInstanceOffering
  ## Allows you to purchase reserved Elasticsearch instances.
  ##   body: JObject (required)
  var body_593274 = newJObject()
  if body != nil:
    body_593274 = body
  result = call_593273.call(nil, nil, nil, nil, body_593274)

var purchaseReservedElasticsearchInstanceOffering* = Call_PurchaseReservedElasticsearchInstanceOffering_593261(
    name: "purchaseReservedElasticsearchInstanceOffering",
    meth: HttpMethod.HttpPost, host: "es.amazonaws.com",
    route: "/2015-01-01/es/purchaseReservedInstanceOffering",
    validator: validate_PurchaseReservedElasticsearchInstanceOffering_593262,
    base: "/", url: url_PurchaseReservedElasticsearchInstanceOffering_593263,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTags_593275 = ref object of OpenApiRestCall_592364
proc url_RemoveTags_593277(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RemoveTags_593276(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593278 = header.getOrDefault("X-Amz-Signature")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "X-Amz-Signature", valid_593278
  var valid_593279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593279 = validateParameter(valid_593279, JString, required = false,
                                 default = nil)
  if valid_593279 != nil:
    section.add "X-Amz-Content-Sha256", valid_593279
  var valid_593280 = header.getOrDefault("X-Amz-Date")
  valid_593280 = validateParameter(valid_593280, JString, required = false,
                                 default = nil)
  if valid_593280 != nil:
    section.add "X-Amz-Date", valid_593280
  var valid_593281 = header.getOrDefault("X-Amz-Credential")
  valid_593281 = validateParameter(valid_593281, JString, required = false,
                                 default = nil)
  if valid_593281 != nil:
    section.add "X-Amz-Credential", valid_593281
  var valid_593282 = header.getOrDefault("X-Amz-Security-Token")
  valid_593282 = validateParameter(valid_593282, JString, required = false,
                                 default = nil)
  if valid_593282 != nil:
    section.add "X-Amz-Security-Token", valid_593282
  var valid_593283 = header.getOrDefault("X-Amz-Algorithm")
  valid_593283 = validateParameter(valid_593283, JString, required = false,
                                 default = nil)
  if valid_593283 != nil:
    section.add "X-Amz-Algorithm", valid_593283
  var valid_593284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593284 = validateParameter(valid_593284, JString, required = false,
                                 default = nil)
  if valid_593284 != nil:
    section.add "X-Amz-SignedHeaders", valid_593284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593286: Call_RemoveTags_593275; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified set of tags from the specified Elasticsearch domain.
  ## 
  let valid = call_593286.validator(path, query, header, formData, body)
  let scheme = call_593286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593286.url(scheme.get, call_593286.host, call_593286.base,
                         call_593286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593286, url, valid)

proc call*(call_593287: Call_RemoveTags_593275; body: JsonNode): Recallable =
  ## removeTags
  ## Removes the specified set of tags from the specified Elasticsearch domain.
  ##   body: JObject (required)
  var body_593288 = newJObject()
  if body != nil:
    body_593288 = body
  result = call_593287.call(nil, nil, nil, nil, body_593288)

var removeTags* = Call_RemoveTags_593275(name: "removeTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "es.amazonaws.com",
                                      route: "/2015-01-01/tags-removal",
                                      validator: validate_RemoveTags_593276,
                                      base: "/", url: url_RemoveTags_593277,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartElasticsearchServiceSoftwareUpdate_593289 = ref object of OpenApiRestCall_592364
proc url_StartElasticsearchServiceSoftwareUpdate_593291(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartElasticsearchServiceSoftwareUpdate_593290(path: JsonNode;
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
  var valid_593292 = header.getOrDefault("X-Amz-Signature")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-Signature", valid_593292
  var valid_593293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593293 = validateParameter(valid_593293, JString, required = false,
                                 default = nil)
  if valid_593293 != nil:
    section.add "X-Amz-Content-Sha256", valid_593293
  var valid_593294 = header.getOrDefault("X-Amz-Date")
  valid_593294 = validateParameter(valid_593294, JString, required = false,
                                 default = nil)
  if valid_593294 != nil:
    section.add "X-Amz-Date", valid_593294
  var valid_593295 = header.getOrDefault("X-Amz-Credential")
  valid_593295 = validateParameter(valid_593295, JString, required = false,
                                 default = nil)
  if valid_593295 != nil:
    section.add "X-Amz-Credential", valid_593295
  var valid_593296 = header.getOrDefault("X-Amz-Security-Token")
  valid_593296 = validateParameter(valid_593296, JString, required = false,
                                 default = nil)
  if valid_593296 != nil:
    section.add "X-Amz-Security-Token", valid_593296
  var valid_593297 = header.getOrDefault("X-Amz-Algorithm")
  valid_593297 = validateParameter(valid_593297, JString, required = false,
                                 default = nil)
  if valid_593297 != nil:
    section.add "X-Amz-Algorithm", valid_593297
  var valid_593298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593298 = validateParameter(valid_593298, JString, required = false,
                                 default = nil)
  if valid_593298 != nil:
    section.add "X-Amz-SignedHeaders", valid_593298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593300: Call_StartElasticsearchServiceSoftwareUpdate_593289;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Schedules a service software update for an Amazon ES domain.
  ## 
  let valid = call_593300.validator(path, query, header, formData, body)
  let scheme = call_593300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593300.url(scheme.get, call_593300.host, call_593300.base,
                         call_593300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593300, url, valid)

proc call*(call_593301: Call_StartElasticsearchServiceSoftwareUpdate_593289;
          body: JsonNode): Recallable =
  ## startElasticsearchServiceSoftwareUpdate
  ## Schedules a service software update for an Amazon ES domain.
  ##   body: JObject (required)
  var body_593302 = newJObject()
  if body != nil:
    body_593302 = body
  result = call_593301.call(nil, nil, nil, nil, body_593302)

var startElasticsearchServiceSoftwareUpdate* = Call_StartElasticsearchServiceSoftwareUpdate_593289(
    name: "startElasticsearchServiceSoftwareUpdate", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/serviceSoftwareUpdate/start",
    validator: validate_StartElasticsearchServiceSoftwareUpdate_593290, base: "/",
    url: url_StartElasticsearchServiceSoftwareUpdate_593291,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradeElasticsearchDomain_593303 = ref object of OpenApiRestCall_592364
proc url_UpgradeElasticsearchDomain_593305(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpgradeElasticsearchDomain_593304(path: JsonNode; query: JsonNode;
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
  var valid_593306 = header.getOrDefault("X-Amz-Signature")
  valid_593306 = validateParameter(valid_593306, JString, required = false,
                                 default = nil)
  if valid_593306 != nil:
    section.add "X-Amz-Signature", valid_593306
  var valid_593307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593307 = validateParameter(valid_593307, JString, required = false,
                                 default = nil)
  if valid_593307 != nil:
    section.add "X-Amz-Content-Sha256", valid_593307
  var valid_593308 = header.getOrDefault("X-Amz-Date")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "X-Amz-Date", valid_593308
  var valid_593309 = header.getOrDefault("X-Amz-Credential")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "X-Amz-Credential", valid_593309
  var valid_593310 = header.getOrDefault("X-Amz-Security-Token")
  valid_593310 = validateParameter(valid_593310, JString, required = false,
                                 default = nil)
  if valid_593310 != nil:
    section.add "X-Amz-Security-Token", valid_593310
  var valid_593311 = header.getOrDefault("X-Amz-Algorithm")
  valid_593311 = validateParameter(valid_593311, JString, required = false,
                                 default = nil)
  if valid_593311 != nil:
    section.add "X-Amz-Algorithm", valid_593311
  var valid_593312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593312 = validateParameter(valid_593312, JString, required = false,
                                 default = nil)
  if valid_593312 != nil:
    section.add "X-Amz-SignedHeaders", valid_593312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593314: Call_UpgradeElasticsearchDomain_593303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows you to either upgrade your domain or perform an Upgrade eligibility check to a compatible Elasticsearch version.
  ## 
  let valid = call_593314.validator(path, query, header, formData, body)
  let scheme = call_593314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593314.url(scheme.get, call_593314.host, call_593314.base,
                         call_593314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593314, url, valid)

proc call*(call_593315: Call_UpgradeElasticsearchDomain_593303; body: JsonNode): Recallable =
  ## upgradeElasticsearchDomain
  ## Allows you to either upgrade your domain or perform an Upgrade eligibility check to a compatible Elasticsearch version.
  ##   body: JObject (required)
  var body_593316 = newJObject()
  if body != nil:
    body_593316 = body
  result = call_593315.call(nil, nil, nil, nil, body_593316)

var upgradeElasticsearchDomain* = Call_UpgradeElasticsearchDomain_593303(
    name: "upgradeElasticsearchDomain", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/upgradeDomain",
    validator: validate_UpgradeElasticsearchDomain_593304, base: "/",
    url: url_UpgradeElasticsearchDomain_593305,
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

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
